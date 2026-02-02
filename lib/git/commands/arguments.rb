# frozen_string_literal: true

module Git
  module Commands
    # rubocop:disable Metrics/ParameterLists

    # Git::Commands::Arguments provides a DSL for defining command-line arguments
    # (both options and positional arguments) for Git commands.
    #
    # @api private
    #
    # == Overview
    #
    # This class enables declarative definition of git command arguments, handling:
    # - Option flags (boolean, valued, inline-valued)
    # - Positional arguments (required, optional, variadic)
    # - Validation (type checking, required options, conflicts)
    # - Argument building (converting Ruby values to CLI argument arrays)
    #
    # @example Defining arguments for a command
    #   ARGS = Git::Commands::Arguments.define do
    #     flag :force
    #     value :branch
    #     positional :repository, required: true
    #   end
    #
    # @example Building command-line arguments
    #   ARGS.build('https://github.com/user/repo', force: true, branch: 'main')
    #   # => ['--force', '--branch', 'main', 'https://github.com/user/repo']
    #
    # == Design
    #
    # The class uses a two-phase approach:
    #
    # 1. **Definition phase**: DSL methods ({#flag}, {#value}, {#positional}, etc.)
    #    record argument definitions in internal data structures.
    #
    # 2. **Build phase**: {#build} transforms Ruby values into a CLI argument array
    #    by iterating over definitions in the exact order they were defined.
    #
    # Key internal components:
    #
    # - +@ordered_definitions+: Array tracking all definitions in definition order
    # - +@option_definitions+: Hash mapping option names to their definitions
    # - +@positional_definitions+: Array of positional argument definitions
    # - +@alias_map+: Maps option aliases to their primary names
    # - +BUILDERS+: Hash of lambdas that convert values to CLI arguments by type
    # - {PositionalAllocator}: Handles Ruby-like positional argument allocation
    #
    # == Argument Ordering
    #
    # Arguments are rendered in the exact order they are defined in the DSL block,
    # regardless of type (options, positionals, or static flags). This is important
    # for git commands where argument order matters, such as when using `--` to
    # separate options from pathspecs.
    #
    # @example Ordering example
    #   args = Arguments.define do
    #     positional :ref
    #     static '--'
    #     positional :path
    #   end
    #   args.build('HEAD', 'file.txt')  # => ['HEAD', '--', 'file.txt']
    #
    # == Option Types
    #
    # The DSL supports several option types with orthogonal modifiers:
    #
    # === Primary Option Types
    # - {#flag} - Boolean flag (--flag when true, with `negatable: true` for --no-flag)
    # - {#value} - Valued option (--flag value, with `inline: true` for --flag=value,
    #   or `positional: true` for positional arguments)
    # - {#flag_or_value} - Flag or value (--flag when true, --flag value when string,
    #   with `inline: true` and/or `negatable: true` modifiers)
    # - {#static} - Static flag always included
    # - {#custom} - Custom option with builder block
    # - {#metadata} - Validation-only option (not included in command output)
    #
    # {#value} supports a `multi_valued: true` parameter that allows the option to accept
    # an array of values. This repeats the flag for each value (or outputs each as a
    # positional argument when using `positional: true`):
    #
    # @example Multi-valued options
    #   value :config, multi_valued: true
    #   # config: ['a=b', 'c=d'] => ['--config', 'a=b', '--config', 'c=d']
    #
    #   value :sort, inline: true, multi_valued: true
    #   # sort: ['refname', '-committerdate'] => ['--sort=refname', '--sort=-committerdate']
    #
    #   value :pathspecs, positional: true, separator: '--', multi_valued: true
    #   # pathspecs: ['file1.txt', 'file2.txt'] => ['--', 'file1.txt', 'file2.txt']

    # @note For {#value}, `inline: true` and `positional: true` are mutually exclusive and
    #   will raise ArgumentError if used together. The `separator:` option is only valid
    #   with `positional: true` and raises ArgumentError otherwise.
    #
    # == Common Option Parameters
    #
    # Most option types support parameters that affect **input validation**
    # (checking the provided values before building):
    #
    # - +required:+ - When true, the option key must be present in the provided opts.
    #   Raises ArgumentError if the key is missing.
    #   Supported by: {#flag}, {#value}, {#flag_or_value}, {#custom}.
    # - +allow_nil:+ - When false (with required: true), the value cannot be nil.
    #   Raises ArgumentError if a nil value is provided. Defaults to true.
    #   Supported by: same as +required:+.
    # - +type:+ - Validates the value is an instance of the specified class(es).
    #   Raises ArgumentError if type doesn't match.
    #   Supported by: {#flag}, {#value}, {#flag_or_value}.
    #
    # Note: {#static} and {#metadata} do not support these validation parameters.
    #
    # These parameters affect **output generation** (what CLI arguments are produced):
    #
    # - +args:+ - Custom flag string(s) to output instead of deriving from name.
    # - +allow_empty:+ - ({#value} only) Include flag even for empty strings.
    # - +multi_valued:+ - ({#value} only) Repeat flag for each array element.
    #
    # @example Required option with non-nil value
    #   value :upstream, inline: true, required: true, allow_nil: false
    #   # build()                    => ArgumentError: Required options not provided: :upstream
    #   # build(upstream: nil)       => ArgumentError: Required options cannot be nil: :upstream
    #   # build(upstream: 'origin')  => ['--upstream=origin']
    #
    # @example Required option allowing nil (default)
    #   value :branch, inline: true, required: true
    #   # build()                => ArgumentError: Required options not provided: :branch
    #   # build(branch: nil)     => []  (key present, nil value produces no output)
    #   # build(branch: 'main')  => ['--branch=main']
    #
    # == Positional Arguments
    #
    # Positional arguments are mapped using Ruby-like semantics:
    #
    # 1. Post-variadic required positionals are reserved first (from the end)
    # 2. Pre-variadic positionals are filled with remaining values (required first, then optional)
    # 3. Optional positionals (with defaults) get values only if extras are available
    # 4. Variadic positional gets whatever is left in the middle
    #
    # This matches Ruby's parameter binding behavior, including patterns like
    # `def foo(a = default, *rest, b)` where the required `b` is filled before optional `a`.
    #
    # @example Simple positional (like `def foo(repo)`)
    #   positional :repository, required: true
    #
    # @example Variadic positional (like `def foo(*paths)`)
    #   positional :paths, variadic: true
    #
    # @example git mv pattern (like `def mv(*sources, destination)`)
    #   positional :sources, variadic: true, required: true
    #   positional :destination, required: true
    #   # build('src1', 'src2', 'dest') => ['src1', 'src2', 'dest']
    #
    # == Nil Handling for Positionals
    #
    # Nil values have special meaning for positional arguments:
    #
    # - For non-variadic positionals: nil means "not provided" and is skipped
    # - For variadic positionals: nil within the values is an error
    # - Empty strings are valid and passed through to git
    #
    # @example Skipping optional positional with nil
    #   # positional :commit; positional :paths, variadic: true
    #   build(nil, 'file1', 'file2')  # => ['file1', 'file2']
    #
    # == Type Validation
    #
    # The `type:` parameter provides declarative type validation for option values.
    # When validation fails, an ArgumentError is raised with a descriptive message.
    #
    # @example Single type validation
    #   value :date, type: String, inline: true
    #   # Valid: date: "2024-01-01"
    #   # Invalid: date: 12345
    #   #   => ArgumentError: The :date option must be a String, but was a Integer
    #
    # @example Multiple type validation (allows any of the specified types)
    #   value :timeout, type: [Integer, Float], inline: true
    #   # Valid: timeout: 30 or timeout: 30.5
    #   # Invalid: timeout: "30"
    #   #   => ArgumentError: The :timeout option must be a Integer or Float, but was a String
    #
    # @note The `type:` parameter cannot be combined with a custom `validator:` parameter.
    #   Attempting to use both will raise an ArgumentError during definition.
    #
    # == Conflict Detection
    #
    # Use {#conflicts} to declare mutually exclusive options. When building arguments,
    # if more than one option in a conflict group is provided, an ArgumentError is raised.
    #
    # @example
    #   conflicts :force, :force_force
    #   # build(force: true, force_force: true)
    #   #   => ArgumentError: cannot specify :force and :force_force
    #
    class Arguments
      # Define a new Arguments instance using the DSL
      #
      # @yield The block where arguments are defined using DSL methods
      # @return [Arguments] The configured Arguments instance
      #
      # @example
      #   args = Git::Commands::Arguments.define do
      #     flag :verbose
      #   end
      #
      def self.define(&block)
        args = new
        args.instance_eval(&block) if block
        args
      end

      def initialize
        @option_definitions = {}
        @alias_map = {} # Maps alias keys to primary keys
        @static_flags = []
        @positional_definitions = []
        @conflicts = [] # Array of conflicting option pairs/groups
        @ordered_definitions = [] # Tracks all definitions in definition order
      end

      # Define a boolean flag option (--flag when true)
      #
      # @param names [Symbol, Array<Symbol>] the option name(s), first is primary
      # @param args [String, Array<String>, nil] custom argument(s) to output (e.g., '-r' or ['--amend', '--no-edit'])
      # @param type [Class, Array<Class>, nil] expected type(s) for validation. Raises ArgumentError with
      #   descriptive message if value doesn't match. Cannot be combined with validator:.
      # @param validator [Proc, nil] optional validator block (cannot be combined with type:)
      # @param negatable [Boolean] when true, outputs --no-flag when value is false (default: false)
      # @param required [Boolean] whether the option must be provided (key must exist in opts)
      # @param allow_nil [Boolean] whether nil is allowed when required is true. Defaults to true.
      #   When false with required: true, raises ArgumentError if value is nil.
      # @return [void]
      # @raise [ArgumentError] if inline: and positional: are both true
      # @raise [ArgumentError] if separator: is provided without positional: true
      #
      # @example Basic flag
      #   flag :force
      #   # true  => --force
      #   # false => (nothing)
      #
      # @example Negatable flag
      #   flag :full, negatable: true
      #   # true  => --full
      #   # false => --no-full
      #
      # @example With type validation
      #   flag :force, type: [TrueClass, FalseClass]
      #
      # @example With required and allow_nil: false
      #   flag :force, required: true, allow_nil: false
      #   # Raises ArgumentError if nil or not provided
      #
      def flag(names, args: nil, type: nil, validator: nil, negatable: false, required: false, allow_nil: true)
        option_type = negatable ? :negatable_flag : :flag
        register_option(names, type: option_type, args: args, expected_type: type, validator: validator,
                               required: required, allow_nil: allow_nil)
      end

      # Define a valued option (--flag value as separate arguments)
      #
      # @param names [Symbol, Array<Symbol>] the option name(s), first is primary
      # @param args [String, nil] custom flag string (arrays not supported for value types)
      # @param type [Class, Array<Class>, nil] expected type(s) for validation. Raises ArgumentError with
      #   descriptive message if value doesn't match. Cannot be combined with validator:.
      # @param inline [Boolean] when true, outputs --flag=value as single argument instead of
      #   --flag value as separate arguments (default: false). Cannot be combined with positional:.
      # @param positional [Boolean] when true, outputs value as positional argument without flag
      #   (default: false). Cannot be combined with inline:.
      # @param separator [String, nil] separator string to insert before values when positional: true
      #   (e.g., '--' for pathspec separator). Only valid with positional: true.
      # @param allow_empty [Boolean] whether to include the flag even when value is an empty string.
      #   When false (default), empty strings are skipped entirely. When true, the flag and empty
      #   value are included in the output.
      # @param multi_valued [Boolean] whether to allow multiple values. When true, accepts an array
      #   of values and repeats the flag for each (e.g., --flag v1 --flag v2). A single value or nil
      #   is also accepted.
      # @param required [Boolean] when true, the option key must be present in the provided options hash.
      #   Raises ArgumentError if the key is missing. Defaults to false.
      # @param allow_nil [Boolean] when false (with required: true), the value cannot be nil.
      #   Raises ArgumentError if a nil value is provided. Defaults to true.
      # @return [void]
      #
      # @example Basic value
      #   value :branch
      #   # branch: 'main' => ['--branch', 'main']
      #
      # @example Inline value
      #   value :format, inline: true
      #   # format: 'short' => ['--format=short']
      #
      # @example Positional value
      #   value :paths, positional: true, multi_valued: true, separator: '--'
      #   # paths: ['file.txt'] => ['--', 'file.txt']
      #
      # @example With type validation
      #   value :branch, type: String
      #
      # @example With allow_empty
      #   value :message, allow_empty: true
      #   # message: ""     => ['--message', '']
      #   # message: "text" => ['--message', 'text']
      #
      #   value :message  # allow_empty defaults to false
      #   # message: ""     => [] (skipped)
      #   # message: "text" => ['--message', 'text']
      #
      # @example With multi_valued
      #   value :config, multi_valued: true
      #   # config: 'a=b'          => ['--config', 'a=b']
      #   # config: ['a=b', 'c=d'] => ['--config', 'a=b', '--config', 'c=d']
      #   # config: nil            => []
      #
      # @example With required
      #   value :message, required: true
      #   # Must be provided: build(message: 'text') or build(message: nil)
      #   # Raises ArgumentError if not provided: build()
      #
      # @example With required and allow_nil: false
      #   value :message, required: true, allow_nil: false
      #   # Must be provided with non-nil value: build(message: 'text')
      #   # Raises ArgumentError if nil: build(message: nil)
      #   # Raises ArgumentError if not provided: build()
      #
      def value(names, args: nil, type: nil, inline: false, positional: false, separator: nil,
                allow_empty: false, multi_valued: false, required: false, allow_nil: true)
        validate_value_modifiers!(names, inline, positional, separator)

        option_type = determine_value_option_type(inline, positional)
        register_option(names, type: option_type, args: args, expected_type: type, separator: separator,
                               allow_empty: allow_empty, multi_valued: multi_valued, required: required,
                               allow_nil: allow_nil)
      end

      # Define a flag or value option
      #
      # This is a flexible option type that outputs:
      # - Just the flag (--flag) when value is true
      # - Nothing when value is false (or --no-flag if negatable: true)
      # - Flag with value when value is a string (--flag value or --flag=value if inline: true)
      # - Nothing when value is nil
      #
      # @param names [Symbol, Array<Symbol>] the option name(s), first is primary
      # @param args [String, nil] custom flag string
      # @param type [Class, Array<Class>, nil] expected type(s) for validation
      # @param negatable [Boolean] when true, outputs --no-flag for false values (default: false)
      # @param inline [Boolean] when true, outputs --flag=value instead of --flag value (default: false)
      # @param required [Boolean] whether the option must be provided (key must exist in opts)
      # @param allow_nil [Boolean] whether nil is allowed when required is true. Defaults to true.
      # @return [void]
      # @raise [ArgumentError] if value is not true, false, or a String
      #
      # @example Basic flag or value (new capability - not possible with old DSL)
      #   flag_or_value :contains
      #   # true       => --contains
      #   # false      => (nothing)
      #   # "abc123"   => --contains abc123 (separate arguments)
      #   # nil        => (nothing)
      #
      # @example With inline: true
      #   flag_or_value :gpg_sign, inline: true
      #   # true       => --gpg-sign
      #   # false      => (nothing)
      #   # "KEY"      => --gpg-sign=KEY (inline)
      #   # nil        => (nothing)
      #
      # @example With negatable: true (flag or value with negation)
      #   flag_or_value :verify, negatable: true
      #   # true       => --verify
      #   # false      => --no-verify
      #   # "KEYID"    => --verify KEYID (separate arguments)
      #   # nil        => (nothing)
      #
      # @example With negatable: true and inline: true
      #   flag_or_value :sign, negatable: true, inline: true
      #   # true       => --sign
      #   # false      => --no-sign
      #   # "KEY"      => --sign=KEY (inline)
      #   # nil        => (nothing)
      #
      def flag_or_value(names, args: nil, type: nil, negatable: false, inline: false,
                        required: false, allow_nil: true)
        option_type = determine_flag_or_value_option_type(negatable, inline)
        register_option(names, type: option_type, args: args, expected_type: type,
                               required: required, allow_nil: allow_nil)
      end

      # Define a key-value option that can be specified multiple times
      #
      # This is useful for git options like --trailer that take key=value pairs
      # and can be repeated. Accepts Hash or Array of arrays for flexible input.
      #
      # @param names [Symbol, Array<Symbol>] the option name(s), first is primary
      # @param args [String, nil] custom flag string (e.g., '--trailer')
      # @param key_separator [String] separator between key and value (default: '=')
      # @param inline [Boolean] when true, outputs --flag=key=value instead of --flag key=value
      # @param required [Boolean] whether the option must be provided (key must exist in opts).
      #   Note: empty hash/array is considered "present" and produces no output without error.
      # @param allow_nil [Boolean] whether nil is allowed when required is true
      # @return [void]
      # @raise [ArgumentError] if array input is not a [key, value] pair or array of pairs
      # @raise [ArgumentError] if a sub-array has more than 2 elements
      # @raise [ArgumentError] if a key is nil, empty, or contains the separator
      # @raise [ArgumentError] if a value is a Hash or Array (non-scalar)
      #
      # @example Basic key-value (like --trailer)
      #   key_value :trailers, args: '--trailer'
      #   # trailers: { 'Signed-off-by' => 'John' }
      #   #   => ['--trailer', 'Signed-off-by=John']
      #
      # @example Hash with array values (multiple values for same key)
      #   key_value :trailers, args: '--trailer'
      #   # trailers: { 'Signed-off-by' => ['John', 'Jane'] }
      #   #   => ['--trailer', 'Signed-off-by=John', '--trailer', 'Signed-off-by=Jane']
      #
      # @example Array of arrays (full ordering control)
      #   key_value :trailers, args: '--trailer'
      #   # trailers: [['Signed-off-by', 'John'], ['Acked-by', 'Bob']]
      #   #   => ['--trailer', 'Signed-off-by=John', '--trailer', 'Acked-by=Bob']
      #
      # @example Key without value (nil value omits separator)
      #   key_value :trailers, args: '--trailer'
      #   # trailers: [['Acked-by', nil]]
      #   #   => ['--trailer', 'Acked-by']
      #
      # @example Nil in array values produces key-only entries
      #   key_value :trailers, args: '--trailer'
      #   # trailers: { 'Key' => ['Value1', nil, 'Value2'] }
      #   #   => ['--trailer', 'Key=Value1', '--trailer', 'Key', '--trailer', 'Key=Value2']
      #
      # @example With custom separator
      #   key_value :trailers, args: '--trailer', key_separator: ': '
      #   # trailers: { 'Signed-off-by' => 'John' }
      #   #   => ['--trailer', 'Signed-off-by: John']
      #
      # @example Empty values produce no output
      #   key_value :trailers, args: '--trailer', required: true
      #   # trailers: {}  => []  (no error, empty output)
      #   # trailers: []  => []  (no error, empty output)
      #   # trailers: nil => []  (no error, empty output)
      #
      def key_value(names, args: nil, key_separator: '=', inline: false, required: false, allow_nil: true)
        option_type = inline ? :inline_key_value : :key_value
        register_option(names, type: option_type, args: args, key_separator: key_separator,
                               required: required, allow_nil: allow_nil)
      end

      # Define a static flag that is always included in the output
      #
      # Static flags are output at their definition position (not grouped at the start).
      # This allows precise control over argument ordering, which is important for
      # git commands where argument position matters.
      #
      # @param flag_string [String] the static flag string (e.g., '--', '--no-progress')
      # @return [void]
      #
      # @example Static flag for subcommand mode
      #   static '--delete'
      #   flag :force
      #   positional :branches, variadic: true
      #   # build('feature', force: true) => ['--delete', '--force', 'feature']
      #
      # @example Static separator between options and pathspecs
      #   flag :force
      #   positional :tree_ish
      #   static '--'
      #   positional :paths, variadic: true
      #   # build('HEAD', 'file.txt', force: true) => ['--force', 'HEAD', '--', 'file.txt']
      #
      def static(flag_string)
        @static_flags << flag_string
        @ordered_definitions << { kind: :static, flag: flag_string }
      end

      # Define a custom option with a custom builder block
      #
      # @param names [Symbol, Array<Symbol>] the option name(s), first is primary
      # @param required [Boolean] whether the option must be provided (key must exist in opts)
      # @param allow_nil [Boolean] whether nil is allowed when required is true. Defaults to true.
      #   When false with required: true, raises ArgumentError if value is nil.
      # @yield [value] block that receives the option value and returns the argument string
      # @return [void]
      #
      def custom(names, required: false, allow_nil: true, &block)
        register_option(names, type: :custom, builder: block, required: required, allow_nil: allow_nil)
      end

      # Define a metadata option (for validation only, not included in command)
      #
      # @param names [Symbol, Array<Symbol>] the option name(s), first is primary
      # @return [void]
      #
      def metadata(names)
        register_option(names, type: :metadata)
      end

      # Declare that options conflict with each other (mutually exclusive)
      #
      # Each call to {#conflicts} defines a separate group of mutually exclusive
      # options. When arguments are built, if more than one option in the same
      # conflict group is provided with a truthy value, an ArgumentError is
      # raised. Options whose values are `nil` or `false` do not participate in
      # conflict detection.
      #
      # The error message has the general form:
      #
      #   "cannot specify :option1 and :option2"
      #
      # where the option names correspond to the conflicting options that were
      # given truthy values.
      #
      # @param option_names [Array<Symbol>] the option names that conflict within
      #   this group
      # @return [void]
      #
      # @raise [ArgumentError] if more than one option in the same conflict group
      #   is provided with a truthy value when building arguments
      #
      # @example Simple conflict group
      #   conflicts :gpg_sign, :no_gpg_sign
      #
      # @example Multiple independent conflict groups
      #   conflicts :gpg_sign, :no_gpg_sign
      #   conflicts :force, :no_force
      #
      def conflicts(*option_names)
        @conflicts << option_names.map(&:to_sym)
      end

      # Define a positional argument
      #
      # Positional arguments are mapped to values following Ruby method signature
      # semantics. Required positionals before a variadic are filled left-to-right,
      # required positionals after a variadic are filled from the end, and the
      # variadic gets whatever remains in the middle.
      #
      # @param name [Symbol] the positional argument name (used in error messages)
      # @param required [Boolean] whether the argument is required. For variadic
      #   positionals, this means at least one value must be provided.
      # @param variadic [Boolean] whether the argument accepts multiple values
      #   (like Ruby's splat operator *args). Only one variadic positional is
      #   allowed per definition; attempting to define a second will raise an
      #   ArgumentError.
      # @param default [Object] the default value if not provided. For variadic
      #   positionals, this should be an array (e.g., `default: ['.']`).
      # @param separator [String, nil] separator string to insert before this
      #   positional in the output (e.g., '--' for the common pathspec separator)
      # @param allow_nil [Boolean] whether nil is a valid value for a required
      #   positional. When true, nil consumes the positional slot but is omitted
      #   from output. This is useful for commands like `git checkout` where
      #   the tree-ish is required to consume a slot but may be nil to restore
      #   from the index. Defaults to false.
      # @return [void]
      #
      # @example Required positional (like `def clone(repository)`)
      #   positional :repository, required: true
      #   # build('https://github.com/user/repo')
      #   #   => ['https://github.com/user/repo']
      #
      # @example Optional positional with default (like `def log(commit = 'HEAD')`)
      #   positional :commit, default: 'HEAD'
      #   # build()        => ['HEAD']
      #   # build('main')  => ['main']
      #
      # @example Variadic positional (like `def add(*paths)`)
      #   positional :paths, variadic: true
      #   # build('file1', 'file2', 'file3')
      #   #   => ['file1', 'file2', 'file3']
      #
      # @example Required variadic with at least one value (like `def rm(*paths)` with validation)
      #   positional :paths, variadic: true, required: true
      #   # build()         => raises ArgumentError
      #   # build('file1')  => ['file1']
      #
      # @example git mv pattern (like `def mv(*sources, destination)`)
      #   positional :sources, variadic: true, required: true
      #   positional :destination, required: true
      #   # build('src1', 'src2', 'dest')
      #   #   => ['src1', 'src2', 'dest']
      #   # build('src', 'dest')
      #   #   => ['src', 'dest']
      #
      # @example Optional before variadic with required after (like `def foo(a = 'default', *middle, b)`)
      #   positional :a, default: 'default_a'
      #   positional :middle, variadic: true
      #   positional :b, required: true
      #   # build('x')           => ['default_a', 'x']  (a=default, middle=[], b='x')
      #   # build('x', 'y')      => ['x', 'y']          (a='x', middle=[], b='y')
      #   # build('x', 'm', 'y') => ['x', 'm', 'y']     (a='x', middle=['m'], b='y')
      #
      # @example Positional with separator (pathspec after --)
      #   flag :force
      #   positional :paths, variadic: true, separator: '--'
      #   # build('file1', 'file2', force: true)
      #   #   => ['--force', '--', 'file1', 'file2']
      #
      # @example Complex pattern (like `def diff(commit1, commit2 = nil, *paths)`)
      #   positional :commit1, required: true
      #   positional :commit2
      #   positional :paths, variadic: true, separator: '--'
      #   # build('HEAD~1')
      #   #   => ['HEAD~1']
      #   # build('HEAD~1', 'HEAD')
      #   #   => ['HEAD~1', 'HEAD']
      #   # build('HEAD~1', 'HEAD', 'file.rb')
      #   #   => ['HEAD~1', 'HEAD', '--', 'file.rb']
      #
      # @example Required positional that allows nil (like `git checkout [tree-ish] -- paths`)
      #   positional :tree_ish, required: true, allow_nil: true
      #   positional :paths, variadic: true, separator: '--'
      #   # build('HEAD', 'file.rb')
      #   #   => ['HEAD', '--', 'file.rb']
      #   # build(nil, 'file.rb')
      #   #   => ['--', 'file.rb']  (nil consumes slot but is omitted from output)
      #
      def positional(name, required: false, variadic: false, default: nil, separator: nil, allow_nil: false)
        validate_single_variadic!(name) if variadic

        @positional_definitions << {
          name: name,
          required: required,
          variadic: variadic,
          default: default,
          separator: separator,
          allow_nil: allow_nil
        }
        @ordered_definitions << { kind: :positional, name: name }
      end

      # Build command-line arguments from the given positionals and options
      #
      # Arguments are rendered in the exact order they were defined in the DSL block,
      # regardless of type. This is important for git commands where argument order
      # matters, such as when using `--` to separate options from pathspecs.
      #
      # @param positionals [Array] positional argument values
      # @param opts [Hash] the keyword options to build arguments from
      # @return [Array<String>] the command-line arguments
      # @raise [ArgumentError] if unsupported options are provided or validation fails
      #
      def build(*positionals, **opts)
        validate_unsupported_options!(opts)
        validate_conflicting_aliases!(opts)
        normalized_opts = normalize_aliases(opts)
        validate_required_options!(normalized_opts)
        validate_option_values!(normalized_opts)
        validate_conflicts!(normalized_opts)
        build_ordered_arguments(positionals, normalized_opts)
      end

      private

      # Determine the internal option type based on inline and positional modifiers
      #
      # @param inline [Boolean] whether to use inline format (--flag=value)
      # @param positional [Boolean] whether to output as positional argument
      # @return [Symbol] the internal option type
      #
      def determine_value_option_type(inline, positional)
        if positional
          :value_to_positional
        elsif inline
          :inline_value
        else
          :value
        end
      end

      # Validate value modifier combinations
      #
      # @param names [Symbol, Array<Symbol>] the option name(s)
      # @param inline [Boolean] whether inline: true was specified
      # @param positional [Boolean] whether positional: true was specified
      # @param separator [String, nil] separator string if specified
      # @raise [ArgumentError] if invalid modifier combination is used
      #
      def validate_value_modifiers!(names, inline, positional, separator)
        primary = Array(names).first
        raise ArgumentError, "inline: and positional: cannot both be true for :#{primary}" if inline && positional

        return unless separator && !positional

        raise ArgumentError, "separator: is only valid with positional: true for :#{primary}"
      end

      # Determine the internal option type for flag_or_value based on negatable and inline modifiers
      #
      # @param negatable [Boolean] whether to negate false values
      # @param inline [Boolean] whether to use inline format (--flag=value)
      # @return [Symbol] the internal option type
      #
      def determine_flag_or_value_option_type(negatable, inline)
        if negatable && inline
          :negatable_flag_or_inline_value
        elsif negatable
          :negatable_flag_or_value
        elsif inline
          :flag_or_inline_value
        else
          :flag_or_value
        end
      end

      # Register an option with optional aliases
      #
      # @param names [Symbol, Array<Symbol>] the option name(s), first is primary
      # @param definition [Hash] the option definition
      # @return [void]
      #
      def register_option(names, **definition)
        keys = Array(names)
        primary = keys.first
        definition[:aliases] = keys
        validate_args_parameter!(definition, primary)
        apply_type_validator!(definition, primary)
        @option_definitions[primary] = definition
        keys.each { |key| @alias_map[key] = primary }
        @ordered_definitions << { kind: :option, name: primary }
      end

      def apply_type_validator!(definition, option_name)
        return unless definition[:expected_type]

        raise ArgumentError, "cannot specify both type: and validator: for :#{option_name}" if definition[:validator]

        definition[:validator] = create_type_validator(option_name, definition[:expected_type])
      end

      def validate_args_parameter!(definition, option_name)
        return unless definition[:args].is_a?(Array)
        return if %i[flag negatable_flag].include?(definition[:type])

        type = definition[:type]
        raise ArgumentError,
              "arrays for args: parameter are only supported for flag types, not :#{type} (option :#{option_name})"
      end

      # Build arguments by iterating over definitions in their defined order
      #
      # @param positionals [Array] positional argument values
      # @param normalized_opts [Hash] normalized keyword options
      # @return [Array<String>] the command-line arguments
      #
      def build_ordered_arguments(positionals, normalized_opts)
        args = []
        allocated_positionals = allocate_and_validate_positionals(positionals)

        @ordered_definitions.each do |entry|
          build_entry(args, entry, normalized_opts, allocated_positionals)
        end

        args
      end

      # Build a single definition entry and append to args
      #
      # @param args [Array<String>] the argument array to append to
      # @param entry [Hash] the definition entry with :kind and name/flag
      # @param normalized_opts [Hash] normalized keyword options
      # @param allocated_positionals [Hash] the allocated positional values
      # @return [void]
      #
      def build_entry(args, entry, normalized_opts, allocated_positionals)
        case entry[:kind]
        when :static
          args << entry[:flag]
        when :option
          build_option(args, entry[:name], @option_definitions[entry[:name]], normalized_opts[entry[:name]])
        when :positional
          build_single_positional(args, entry[:name], allocated_positionals)
        end
      end

      # Allocate positionals and perform validation, returning the allocation hash
      #
      # @param positionals [Array] positional argument values
      # @return [Hash] allocation of positional names to values
      #
      def allocate_and_validate_positionals(positionals)
        positionals = normalize_positionals(positionals)
        allocation, consumed_count = allocate_positionals(positionals)

        @positional_definitions.each do |definition|
          value = allocation[definition[:name]]
          validate_required_positional(value, definition)
          validate_no_nil_values!(value, definition)
        end

        check_unexpected_positionals(positionals, consumed_count)
        allocation
      end

      # Build a single positional argument
      #
      # @param args [Array<String>] the argument array to append to
      # @param name [Symbol] the positional argument name
      # @param allocation [Hash] the allocated positional values
      # @return [void]
      #
      def build_single_positional(args, name, allocation)
        definition = @positional_definitions.find { |d| d[:name] == name }
        value = allocation[name]
        append_positional_to_args(args, value, definition)
      end

      def validate_single_variadic!(name)
        existing_variadic = @positional_definitions.find { |d| d[:variadic] }
        return unless existing_variadic

        raise ArgumentError,
              "only one variadic positional is allowed; :#{existing_variadic[:name]} is already variadic, " \
              "cannot add :#{name} as variadic"
      end

      BUILDERS = {
        flag: lambda do |args, arg_spec, value, _|
          return unless value

          arg_spec.is_a?(Array) ? args.concat(arg_spec) : args << arg_spec
        end,
        negatable_flag: lambda do |args, arg_spec, value, _|
          unless [true, false].include?(value)
            raise ArgumentError,
                  "negatable_flag expects a boolean value, got #{value.inspect} (#{value.class})"
          end

          if arg_spec.is_a?(Array)
            arg_spec.each { |spec| args << (value ? spec : spec.sub(/\A--/, '--no-')) }
          else
            args << (value ? arg_spec : arg_spec.sub(/\A--/, '--no-'))
          end
        end,
        value: lambda do |args, arg_spec, value, definition|
          if definition[:multi_valued]
            Array(value).each { |v| args << arg_spec << v.to_s }
          else
            args << arg_spec << value.to_s
          end
        end,
        inline_value: lambda do |args, arg_spec, value, definition|
          if definition[:multi_valued]
            Array(value).each { |v| args << "#{arg_spec}=#{v}" }
          else
            args << "#{arg_spec}=#{value}"
          end
        end,
        flag_or_inline_value: lambda do |args, arg_spec, value, _|
          unless value.is_a?(TrueClass) || value.is_a?(FalseClass) || value.is_a?(String)
            raise ArgumentError,
                  "Invalid value for flag_or_inline_value: #{value.inspect} (#{value.class}); " \
                  'expected true, false, or a String'
          end
          return if value == false

          args << (value == true ? arg_spec : "#{arg_spec}=#{value}")
        end,
        negatable_flag_or_inline_value: lambda do |args, arg_spec, value, _|
          unless value.is_a?(TrueClass) || value.is_a?(FalseClass) || value.is_a?(String)
            raise ArgumentError,
                  "Invalid value for negatable_flag_or_inline_value: #{value.inspect} (#{value.class}); " \
                  'expected true, false, or a String'
          end
          args << case value
                  when true then arg_spec
                  when false then arg_spec.sub(/\A--/, '--no-')
                  else "#{arg_spec}=#{value}"
                  end
        end,
        flag_or_value: lambda do |args, arg_spec, value, _|
          unless value.is_a?(TrueClass) || value.is_a?(FalseClass) || value.is_a?(String)
            raise ArgumentError,
                  "Invalid value for flag_or_value: #{value.inspect} (#{value.class}); " \
                  'expected true, false, or a String'
          end
          return if value == false

          if value == true
            args << arg_spec
          else
            args << arg_spec << value.to_s
          end
        end,
        negatable_flag_or_value: lambda do |args, arg_spec, value, _|
          unless value.is_a?(TrueClass) || value.is_a?(FalseClass) || value.is_a?(String)
            raise ArgumentError,
                  "Invalid value for negatable_flag_or_value: #{value.inspect} (#{value.class}); " \
                  'expected true, false, or a String'
          end
          case value
          when true
            args << arg_spec
          when false
            args << arg_spec.sub(/\A--/, '--no-')
          else
            args << arg_spec << value.to_s
          end
        end,
        value_to_positional: lambda do |args, _, value, definition|
          # Validate array usage when multi_valued is false
          if value.is_a?(Array) && !definition[:multi_valued]
            raise ArgumentError,
                  "value_to_positional :#{definition[:aliases].first} requires multi_valued: true to accept an array"
          end

          # Validate no nil values in array
          if definition[:multi_valued] && value.is_a?(Array) && value.any?(&:nil?)
            raise ArgumentError,
                  "nil values are not allowed in value_to_positional :#{definition[:aliases].first}"
          end

          # Add separator if present
          args << definition[:separator] if definition[:separator]

          # Add values as positional arguments
          if definition[:multi_valued]
            Array(value).each { |v| args << v.to_s }
          else
            args << value.to_s
          end
        end,
        key_value: :build_key_value,
        inline_key_value: :build_inline_key_value,
        custom: lambda do |args, _, value, definition|
          result = definition[:builder]&.call(value)
          result.is_a?(Array) ? args.concat(result) : (args << result if result)
        end,
        metadata: ->(*) {}
      }.freeze
      private_constant :BUILDERS

      def build_option(args, name, definition, value)
        return if should_skip_option?(value, definition)

        arg_spec = definition[:args] || "--#{name.to_s.tr('_', '-')}"
        builder = BUILDERS[definition[:type]]
        if builder.is_a?(Symbol)
          send(builder, args, arg_spec, value, definition)
        else
          builder&.call(args, arg_spec, value, definition)
        end
      end

      def build_key_value(args, arg_spec, value, definition)
        sep = definition[:key_separator] || '='
        option_name = definition[:aliases].first
        normalize_key_value_pairs(value).each do |pair|
          validate_key_value_pair_size!(pair, option_name)
          k, v = pair
          validate_key_value_key!(k, sep, option_name)
          validate_key_value_value!(v, option_name)
          args << arg_spec << (v.nil? ? k.to_s : "#{k}#{sep}#{v}")
        end
      end

      def build_inline_key_value(args, arg_spec, value, definition)
        sep = definition[:key_separator] || '='
        option_name = definition[:aliases].first
        normalize_key_value_pairs(value).each do |pair|
          validate_key_value_pair_size!(pair, option_name)
          k, v = pair
          validate_key_value_key!(k, sep, option_name)
          validate_key_value_value!(v, option_name)
          args << "#{arg_spec}=#{v.nil? ? k.to_s : "#{k}#{sep}#{v}"}"
        end
      end

      def should_skip_option?(value, definition)
        return true if value.nil?
        return true if value == false && %i[flag_or_inline_value flag_or_value].include?(definition[:type])
        return skip_value_to_positional_array?(value, definition) if value.is_a?(Array)

        value.respond_to?(:empty?) && value.empty? && !definition[:allow_empty]
      end

      # For value_to_positional, empty arrays always skip regardless of allow_empty
      # (allow_empty only applies to empty strings, not empty arrays)
      def skip_value_to_positional_array?(value, definition)
        return value.empty? if definition[:type] == :value_to_positional

        value.empty? && !definition[:allow_empty]
      end

      # Normalize key-value input to an array of [key, value] pairs
      #
      # Accepts:
      # - Hash: { 'key' => 'value' } or { 'key' => ['v1', 'v2'] }
      # - Array of arrays: [['key', 'value'], ['key2', 'value2']]
      # - Single array pair: ['key', 'value']
      #
      # @param value [Hash, Array] the input value
      # @return [Array<Array>] array of [key, value] pairs
      #
      def normalize_key_value_pairs(value)
        case value
        when Hash then normalize_hash_to_pairs(value)
        when Array then normalize_array_to_pairs(value)
        else
          raise ArgumentError,
                "key_value option must be a Hash or Array, got #{value.class}"
        end
      end

      def normalize_hash_to_pairs(hash)
        hash.flat_map do |k, v|
          v.is_a?(Array) ? v.map { |val| [k, val] } : [[k, v]]
        end
      end

      def normalize_array_to_pairs(array)
        # Check if it's a single [key, value] pair or array of pairs
        if array.size == 2 && !array.first.is_a?(Array)
          [array]
        elsif array.any? { |e| !e.is_a?(Array) }
          # Flat array with non-pair elements (e.g., ['a', 'b', 'c'])
          raise ArgumentError, 'key_value array input must be a [key, value] pair or array of pairs'
        else
          array
        end
      end

      # Validate that a key-value pair array has at most 2 elements
      #
      # @param pair [Array] the pair to validate
      # @param option_name [Symbol] the option name for error messages
      # @raise [ArgumentError] if pair has more than 2 elements
      #
      def validate_key_value_pair_size!(pair, option_name)
        return unless pair.is_a?(Array) && pair.size > 2

        raise ArgumentError,
              "key_value :#{option_name} pair #{pair.inspect} has too many elements (expected [key, value])"
      end

      # Validate a key for key_value options
      #
      # @param key [Object] the key to validate
      # @param separator [String] the key-value separator
      # @param option_name [Symbol] the option name for error messages
      # @raise [ArgumentError] if key is nil, empty, or contains the separator
      #
      def validate_key_value_key!(key, separator, option_name)
        key_str = key.to_s
        raise ArgumentError, "key_value :#{option_name} requires a non-empty key" if key.nil? || key_str.empty?

        return unless key_str.include?(separator)

        raise ArgumentError,
              "key_value :#{option_name} key #{key_str.inspect} cannot contain the separator #{separator.inspect}"
      end

      # Validate a value for key_value options
      #
      # @param value [Object] the value to validate
      # @param option_name [Symbol] the option name for error messages
      # @raise [ArgumentError] if value is a Hash or Array (non-scalar)
      #
      def validate_key_value_value!(value, option_name)
        return if value.nil?
        return unless value.is_a?(Hash) || value.is_a?(Array)

        raise ArgumentError,
              "key_value :#{option_name} value must be a scalar (String, Symbol, Numeric, nil), " \
              "got #{value.class}: #{value.inspect}"
      end

      def normalize_positionals(positionals)
        # Flatten if first element is an array (allows both splat and array syntax)
        positionals = positionals.first if positionals.size == 1 && positionals.first.is_a?(Array)
        Array(positionals)
      end

      # Allocate positional arguments to definitions following Ruby semantics
      # Returns [allocation_hash, consumed_count] where consumed_count is the
      # number of non-nil positionals that were consumed by definitions.
      def allocate_positionals(positionals)
        PositionalAllocator.new(@positional_definitions).allocate(positionals)
      end

      def append_positional_to_args(args, value, definition)
        return if positional_value_empty?(value, definition)

        args << definition[:separator] if definition[:separator]
        append_positional_value(args, value, definition[:variadic])
      end

      def positional_value_empty?(value, definition)
        return true if value.nil?

        definition[:variadic] && value.respond_to?(:empty?) && value.empty?
      end

      def append_positional_value(args, value, variadic)
        if variadic
          args.concat(Array(value).map(&:to_s))
        else
          args << value.to_s
        end
      end

      def check_unexpected_positionals(positionals, consumed_count)
        provided_count = positionals.compact.size

        return if provided_count <= consumed_count

        unexpected_count = provided_count - consumed_count
        unexpected = positionals.compact.last(unexpected_count)
        raise ArgumentError, "Unexpected positional arguments: #{unexpected.join(', ')}"
      end

      def validate_required_positional(value, definition)
        return unless definition[:required]
        return if definition[:allow_nil] && value.nil?
        return unless value_empty?(value)

        raise ArgumentError, "at least one value is required for #{definition[:name]}" if definition[:variadic]

        raise ArgumentError, "#{definition[:name]} is required"
      end

      def validate_no_nil_values!(value, definition)
        return unless definition[:variadic]
        return if value.nil? # Allow nil as "not provided"

        # For variadic positionals, check if array contains any nil values
        values = Array(value)
        return unless values.any?(&:nil?)

        raise ArgumentError, "nil values are not allowed in variadic positional argument: #{definition[:name]}"
      end

      # Check if a positional value is empty (not provided)
      #
      # Only nil means "not provided" for positionals. Empty strings and empty
      # arrays are valid values that should be passed through.
      #
      # @param value [Object] the value to check
      # @return [Boolean] true if the value is nil
      #
      def value_empty?(value)
        value.nil?
      end

      def validate_unsupported_options!(opts)
        unsupported = opts.keys - @alias_map.keys
        return if unsupported.empty?

        raise ArgumentError, "Unsupported options: #{unsupported.map(&:inspect).join(', ')}"
      end

      def validate_conflicting_aliases!(opts)
        @option_definitions.each_value do |definition|
          aliases = definition[:aliases]
          next unless aliases.size > 1

          provided = aliases & opts.keys
          next unless provided.size > 1

          raise ArgumentError, "Conflicting options: #{provided.map(&:inspect).join(' and ')}"
        end
      end

      def normalize_aliases(opts)
        opts.transform_keys { |key| @alias_map[key] || key }
      end

      def validate_required_options!(opts)
        missing, nil_not_allowed = collect_required_option_errors(opts)
        raise_missing_options_error(missing) if missing.any?
        raise_nil_options_error(nil_not_allowed) if nil_not_allowed.any?
      end

      def collect_required_option_errors(opts)
        missing = []
        nil_not_allowed = []
        @option_definitions.each do |name, definition|
          next unless definition[:required]

          missing << name unless opts.key?(name)
          nil_not_allowed << name if opts.key?(name) && opts[name].nil? && definition[:allow_nil] == false
        end
        [missing, nil_not_allowed]
      end

      def raise_missing_options_error(missing)
        raise ArgumentError, "Required options not provided: #{missing.map(&:inspect).join(', ')}"
      end

      def raise_nil_options_error(nil_not_allowed)
        raise ArgumentError, "Required options cannot be nil: #{nil_not_allowed.map(&:inspect).join(', ')}"
      end

      def validate_option_values!(opts)
        @option_definitions.each do |name, definition|
          validator = definition[:validator]
          next unless validator
          next unless opts.key?(name)

          value = opts[name]
          result = validator.call(value)
          next if result == true

          # If validator returns a string, use it as the error message
          # Otherwise, generate a generic error message
          error_msg = result.is_a?(String) ? result : "Invalid value for option: #{name}"
          raise ArgumentError, error_msg
        end
      end

      def create_type_validator(option_name, expected_type)
        types = Array(expected_type)

        lambda do |value|
          return true if value.nil? # nil values are universally skipped by should_skip_option?
          return true if types.any? { |t| value.is_a?(t) }

          # Generate a helpful error message
          type_names = types.map(&:name).join(' or ')
          actual_type = value.class.name
          "The :#{option_name} option must be a #{type_names}, but was a #{actual_type}"
        end
      end

      def validate_conflicts!(opts)
        @conflicts.each do |conflict_group|
          provided = conflict_group.select { |name| opts.key?(name) && opts[name] }
          next if provided.size <= 1

          formatted = provided.map { |name| ":#{name}" }.join(' and ')
          raise ArgumentError, "cannot specify #{formatted}"
        end
      end
    end

    # Allocates positional argument values to definitions following Ruby semantics.
    #
    # This class handles the complex logic of mapping positional values to their
    # definitions, supporting required, optional, and variadic positionals.
    #
    # @api private
    class PositionalAllocator
      # @param definitions [Array<Hash>] positional argument definitions
      def initialize(definitions)
        @definitions = definitions
      end

      # Allocate values to definitions
      # @param values [Array] the positional argument values
      # @return [Array(Hash, Integer)] [allocation_hash, consumed_count]
      def allocate(values)
        allocation = {}
        variadic_index = @definitions.find_index { |d| d[:variadic] }

        consumed = if variadic_index.nil?
                     allocate_without_variadic(values, allocation)
                   else
                     allocate_with_variadic(values, allocation, variadic_index)
                   end

        [allocation, consumed]
      end

      private

      # Allocate when there's no variadic positional, following Ruby semantics:
      # - Required positionals at the END are reserved first
      # - Leading positionals get remaining values left-to-right
      # - Optional positionals are skipped when there aren't enough values
      def allocate_without_variadic(values, allocation)
        trailing = count_trailing_required
        leading_defs = @definitions[0...(@definitions.size - trailing)]
        trailing_defs = @definitions[(@definitions.size - trailing)..]

        values_for_leading = [values.size - trailing, 0].max
        leading_values = values[0...values_for_leading]
        trailing_values = values[values_for_leading..]

        consumed = allocate_leading(allocation, leading_defs, leading_values)
        consumed + allocate_trailing(allocation, trailing_defs, trailing_values)
      end

      def count_trailing_required
        count = 0
        @definitions.reverse_each do |d|
          break unless required?(d)

          count += 1
        end
        count
      end

      def required?(definition)
        definition[:required] && definition[:default].nil?
      end

      # Allocate leading positionals (those before any trailing required)
      # Required positionals consume values; optional ones only consume if extras available
      def allocate_leading(allocation, definitions, values)
        return 0 if definitions.empty?

        state = LeadingAllocationState.new(definitions, values, method(:required?))
        state.allocate(allocation)
      end

      def allocate_trailing(allocation, definitions, values)
        consumed = 0
        definitions.each_with_index do |definition, index|
          allocation[definition[:name]] = index < values.size ? values[index] : definition[:default]
          consumed += 1 if index < values.size
        end
        consumed
      end

      def allocate_with_variadic(values, allocation, variadic_index)
        parts = split_around_variadic(variadic_index)
        slices = calculate_variadic_slices(values, parts)

        pre_consumed = allocate_pre_variadic_smart(allocation, parts[:pre], slices[:pre_values])
        variadic_consumed = allocate_variadic(
          allocation, parts[:variadic], values, slices[:var_start], slices[:var_end]
        )
        post_consumed = allocate_post_variadic(allocation, parts[:post], values, slices[:post_start])

        pre_consumed + variadic_consumed + post_consumed
      end

      def calculate_variadic_slices(values, parts)
        post_required_count = count_required(parts[:post])
        pre_available = [values.size - post_required_count, 0].max
        pre_end = [pre_available, parts[:pre].size].min
        post_start = [values.size - parts[:post].size, pre_end].max

        {
          pre_values: values[0...pre_end],
          var_start: pre_end,
          var_end: post_start,
          post_start: post_start
        }
      end

      def count_required(definitions)
        definitions.count { |d| required?(d) }
      end

      def split_around_variadic(variadic_index)
        {
          pre: @definitions[0...variadic_index],
          variadic: @definitions[variadic_index],
          post: @definitions[(variadic_index + 1)..]
        }
      end

      # Allocate pre-variadic positionals with Ruby-like semantics
      # (required get values first, optional only if extra values available)
      def allocate_pre_variadic_smart(allocation, definitions, values)
        return 0 if definitions.empty?

        state = LeadingAllocationState.new(definitions, values, method(:required?))
        state.allocate(allocation)
      end

      def allocate_variadic(allocation, definition, values, start_idx, end_idx)
        variadic_values = values[start_idx...end_idx] || []
        allocation[definition[:name]] =
          if variadic_values.empty? || variadic_values.all?(&:nil?)
            definition[:default]
          else
            variadic_values
          end
        variadic_values.compact.size
      end

      def allocate_post_variadic(allocation, definitions, values, post_start)
        consumed = 0
        definitions.each_with_index do |definition, offset|
          pos_index = post_start + offset
          value = pos_index < values.size ? values[pos_index] : nil
          allocation[definition[:name]] = value.nil? ? definition[:default] : value
          consumed += 1 if pos_index < values.size && !values[pos_index].nil?
        end
        consumed
      end

      # Encapsulates state for allocating leading positionals
      # @api private
      class LeadingAllocationState
        def initialize(definitions, values, required_check)
          @definitions = definitions
          @values = values
          @required_check = required_check
          @required_count = definitions.count { |d| required_check.call(d) }
          @extra_for_optionals = [values.size - @required_count, 0].max
          @val_idx = 0
          @opt_idx = 0
          @consumed = 0
        end

        def allocate(allocation)
          @definitions.each { |definition| allocate_one(allocation, definition) }
          @consumed
        end

        private

        def allocate_one(allocation, definition)
          if @required_check.call(definition)
            allocate_required(allocation, definition)
          else
            allocate_optional(allocation, definition)
          end
        end

        def allocate_required(allocation, definition)
          allocation[definition[:name]] = value_or_default(definition)
          @consumed += 1 if @val_idx < @values.size
          @val_idx += 1
        end

        def allocate_optional(allocation, definition)
          if @opt_idx < @extra_for_optionals
            allocation[definition[:name]] = value_or_default(definition)
            @consumed += 1 if @val_idx < @values.size
            @val_idx += 1
          else
            allocation[definition[:name]] = definition[:default]
          end
          @opt_idx += 1
        end

        def value_or_default(definition)
          @val_idx < @values.size ? @values[@val_idx] : definition[:default]
        end
      end
    end
    # rubocop:enable Metrics/ParameterLists
  end
end
