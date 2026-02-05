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
    # - Operands (positional arguments: required, optional, repeatable)
    # - Validation (type checking, required options, conflicts)
    # - Argument building (converting Ruby values to CLI argument arrays)
    #
    # @example Defining arguments for a command
    #   ARGS = Git::Commands::Arguments.define do
    #     flag_option :force
    #     value_option :branch
    #     operand :repository, required: true
    #   end
    #
    # @example Binding and building command-line arguments
    #   ARGS.bind('https://github.com/user/repo', force: true, branch: 'main').to_ary
    #   # => ['--force', '--branch', 'main', 'https://github.com/user/repo']
    #
    # == Design
    #
    # The class uses a two-phase approach:
    #
    # 1. **Definition phase**: DSL methods ({#flag_option}, {#value_option}, {#operand}, etc.)
    #    record argument definitions in internal data structures.
    #
    # 2. **Bind phase**: {#bind} transforms Ruby values into a {Bound} object
    #    containing accessor methods and CLI arguments in definition order.
    #
    # Key internal components:
    #
    # - +@ordered_definitions+: Array tracking all definitions in definition order
    # - +@option_definitions+: Hash mapping option names to their definitions
    # - +@operand_definitions+: Array of operand (positional argument) definitions
    # - +@alias_map+: Maps option aliases to their primary names
    # - +BUILDERS+: Hash of lambdas that convert values to CLI arguments by type
    # - {OperandAllocator}: Handles Ruby-like operand allocation
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
    #     operand :ref
    #     literal '--'
    #     operand :path
    #   end
    #   args.bind('HEAD', 'file.txt').to_ary  # => ['HEAD', '--', 'file.txt']
    #
    # == Short Option Detection
    #
    # Option names are automatically formatted using POSIX conventions:
    #
    # - **Single-character names** use single-dash prefix: `:f` → `-f`
    # - **Multi-character names** use double-dash prefix: `:force` → `--force`
    #
    # For inline values (`inline: true`), the separator also follows POSIX conventions:
    #
    # - **Short options** use no separator: `-n3`
    # - **Long options** use `=` separator: `--name=value`
    #
    # Negated flags always use double-dash format (e.g., `-f` → `--no-f` when false).
    #
    # The `args:` parameter can override this automatic detection when needed.
    #
    # @example Short option detection
    #   flag_option :f                          # true → '-f'
    #   flag_option :force                      # true → '--force'
    #   value_option :n, inline: true           # 3 → '-n3'
    #   value_option :name, inline: true        # 'test' → '--name=test'
    #   flag_option :f, negatable: true         # false → '--no-f'
    #   flag_or_value_option :n, inline: true   # true → '-n', '5' → '-n5'
    #
    # @example Explicit override with args:
    #   flag_option :f, args: '--force'         # true → '--force' (override short detection)
    #
    # == Option Types
    #
    # The DSL supports several option types with orthogonal modifiers:
    #
    # === Primary Option Types
    # - {#flag_option} - Boolean flag (--flag when true, with `negatable: true` for --no-flag)
    # - {#value_option} - Valued option (--flag value, with `inline: true` for --flag=value,
    #   or `as_operand: true` for operands)
    # - {#flag_or_value_option} - Flag or value (--flag when true, --flag value when string,
    #   with `inline: true` and/or `negatable: true` modifiers)
    # - {#key_value_option} - Key-value option that can be repeated (--trailer key=value)
    # - {#literal} - Literal string always included in output
    # - {#custom_option} - Custom option with builder block
    # - {#metadata} - Validation-only option (not included in command output)
    #
    # {#value_option} supports a `repeatable: true` parameter that allows the option to accept
    # an array of values. This repeats the flag for each value (or outputs each as an
    # operand when using `as_operand: true`):
    #
    # @example Repeatable options
    #   value_option :config, repeatable: true
    #   # config: ['a=b', 'c=d'] => ['--config', 'a=b', '--config', 'c=d']
    #
    #   value_option :sort, inline: true, repeatable: true
    #   # sort: ['refname', '-committerdate'] => ['--sort=refname', '--sort=-committerdate']
    #
    #   value_option :pathspecs, as_operand: true, separator: '--', repeatable: true
    #   # pathspecs: ['file1.txt', 'file2.txt'] => ['--', 'file1.txt', 'file2.txt']

    # @note For {#value_option}, `inline: true` and `as_operand: true` are mutually exclusive and
    #   will raise ArgumentError if used together. The `separator:` option is only valid
    #   with `as_operand: true` and raises ArgumentError otherwise.
    #
    # == Common Option Parameters
    #
    # Most option types support parameters that affect **input validation**
    # (checking the provided values before building):
    #
    # - +required:+ - When true, the option key must be present in the provided opts.
    #   Raises ArgumentError if the key is missing.
    #   Supported by: {#flag_option}, {#value_option}, {#flag_or_value_option}, {#custom_option}.
    # - +allow_nil:+ - When false (with required: true), the value cannot be nil.
    #   Raises ArgumentError if a nil value is provided. Defaults to true.
    #   Supported by: same as +required:+.
    # - +type:+ - Validates the value is an instance of the specified class(es).
    #   Raises ArgumentError if type doesn't match.
    #   Supported by: {#flag_option}, {#value_option}, {#flag_or_value_option}.
    #
    # Note: {#literal} and {#metadata} do not support these validation parameters.
    #
    # These parameters affect **output generation** (what CLI arguments are produced):
    #
    # - +args:+ - Custom flag string(s) to output instead of deriving from name.
    # - +allow_empty:+ - ({#value_option} only) Include flag even for empty strings.
    # - +repeatable:+ - ({#value_option} only) Repeat flag for each array element.
    #
    # @example Required option with non-nil value
    #   value_option :upstream, inline: true, required: true, allow_nil: false
    #   # build()                    => ArgumentError: Required options not provided: :upstream
    #   # build(upstream: nil)       => ArgumentError: Required options cannot be nil: :upstream
    #   # build(upstream: 'origin')  => ['--upstream=origin']
    #
    # @example Required option allowing nil (default)
    #   value_option :branch, inline: true, required: true
    #   # build()                => ArgumentError: Required options not provided: :branch
    #   # build(branch: nil)     => []  (key present, nil value produces no output)
    #   # build(branch: 'main')  => ['--branch=main']
    #
    # == Operands (Positional Arguments)
    #
    # Operands are mapped using Ruby-like semantics:
    #
    # 1. Post-repeatable required operands are reserved first (from the end)
    # 2. Pre-repeatable operands are filled with remaining values (required first, then optional)
    # 3. Optional operands (with defaults) get values only if extras are available
    # 4. Repeatable operand gets whatever is left in the middle
    #
    # This matches Ruby's parameter binding behavior, including patterns like
    # `def foo(a = default, *rest, b)` where the required `b` is filled before optional `a`.
    #
    # @example Simple operand (like `def foo(repo)`)
    #   operand :repository, required: true
    #
    # @example Repeatable operand (like `def foo(*paths)`)
    #   operand :paths, repeatable: true
    #
    # @example git mv pattern (like `def mv(*sources, destination)`)
    #   operand :sources, repeatable: true, required: true
    #   operand :destination, required: true
    #   # build('src1', 'src2', 'dest') => ['src1', 'src2', 'dest']
    #
    # == Nil Handling for Operands
    #
    # Nil values have special meaning for operands:
    #
    # - For non-repeatable operands: nil means "not provided" and is skipped
    # - For repeatable operands: nil within the values is an error
    # - Empty strings are valid and passed through to git
    #
    # @example Skipping optional operand with nil
    #   # operand :commit; operand :paths, repeatable: true
    #   build(nil, 'file1', 'file2')  # => ['file1', 'file2']
    #
    # == Type Validation
    #
    # The `type:` parameter provides declarative type validation for option values.
    # When validation fails, an ArgumentError is raised with a descriptive message.
    #
    # @example Single type validation
    #   value_option :date, type: String, inline: true
    #   # Valid: date: "2024-01-01"
    #   # Invalid: date: 12345
    #   #   => ArgumentError: The :date option must be a String, but was a Integer
    #
    # @example Multiple type validation (allows any of the specified types)
    #   value_option :timeout, type: [Integer, Float], inline: true
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
        @operand_definitions = []
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
      # @example Basic flag option
      #   flag_option :force
      #   # true  => --force
      #   # false => (nothing)
      #
      # @example Negatable flag option
      #   flag_option :full, negatable: true
      #   # true  => --full
      #   # false => --no-full
      #
      # @example With type validation
      #   flag_option :force, type: [TrueClass, FalseClass]
      #
      # @example With required and allow_nil: false
      #   flag_option :force, required: true, allow_nil: false
      #   # Raises ArgumentError if nil or not provided
      #
      def flag_option(names, args: nil, type: nil, validator: nil, negatable: false, required: false, allow_nil: true)
        option_type = negatable ? :negatable_flag : :flag
        register_option(names, type: option_type, args: args, expected_type: type, validator: validator,
                               required: required, allow_nil: allow_nil)
      end

      alias flag flag_option

      # Define a valued option (--flag value as separate arguments)
      #
      # @param names [Symbol, Array<Symbol>] the option name(s), first is primary
      # @param args [String, nil] custom flag string (arrays not supported for value types)
      # @param type [Class, Array<Class>, nil] expected type(s) for validation. Raises ArgumentError with
      #   descriptive message if value doesn't match. Cannot be combined with validator:.
      # @param inline [Boolean] when true, outputs --flag=value as single argument instead of
      #   --flag value as separate arguments (default: false). Cannot be combined with as_operand:.
      # @param as_operand [Boolean] when true, outputs value as operand (positional argument) without flag
      #   (default: false). Cannot be combined with inline:.
      # @param positional [Boolean] DEPRECATED: Use as_operand: instead. Alias for as_operand:.
      # @param separator [String, nil] separator string to insert before values when as_operand: true
      #   (e.g., '--' for pathspec separator). Only valid with as_operand: true.
      # @param allow_empty [Boolean] whether to include the flag even when value is an empty string.
      #   When false (default), empty strings are skipped entirely. When true, the flag and empty
      #   value are included in the output.
      # @param repeatable [Boolean] whether to allow multiple values. When true, accepts an array
      #   of values and repeats the flag for each (e.g., --flag v1 --flag v2). A single value or nil
      #   is also accepted.
      # @param multi_valued [Boolean] DEPRECATED: Use repeatable: instead. Alias for repeatable:.
      # @param required [Boolean] when true, the option key must be present in the provided options hash.
      #   Raises ArgumentError if the key is missing. Defaults to false.
      # @param allow_nil [Boolean] when false (with required: true), the value cannot be nil.
      #   Raises ArgumentError if a nil value is provided. Defaults to true.
      # @return [void]
      #
      # @example Basic value option
      #   value_option :branch
      #   # branch: 'main' => ['--branch', 'main']
      #
      # @example Inline value option
      #   value_option :format, inline: true
      #   # format: 'short' => ['--format=short']
      #
      # @example Operand value (outputs as positional argument)
      #   value_option :paths, as_operand: true, repeatable: true, separator: '--'
      #   # paths: ['file.txt'] => ['--', 'file.txt']
      #
      # @example With type validation
      #   value_option :branch, type: String
      #
      # @example With allow_empty
      #   value_option :message, allow_empty: true
      #   # message: ""     => ['--message', '']
      #   # message: "text" => ['--message', 'text']
      #
      #   value_option :message  # allow_empty defaults to false
      #   # message: ""     => [] (skipped)
      #   # message: "text" => ['--message', 'text']
      #
      # @example With repeatable
      #   value_option :config, repeatable: true
      #   # config: 'a=b'          => ['--config', 'a=b']
      #   # config: ['a=b', 'c=d'] => ['--config', 'a=b', '--config', 'c=d']
      #   # config: nil            => []
      #
      # @example With required
      #   value_option :message, required: true
      #   # Must be provided: build(message: 'text') or build(message: nil)
      #   # Raises ArgumentError if not provided: build()
      #
      # @example With required and allow_nil: false
      #   value_option :message, required: true, allow_nil: false
      #   # Must be provided with non-nil value: build(message: 'text')
      #   # Raises ArgumentError if nil: build(message: nil)
      #   # Raises ArgumentError if not provided: build()
      #
      def value_option(names, args: nil, type: nil, inline: false, as_operand: false, positional: nil, separator: nil,
                       allow_empty: false, repeatable: false, multi_valued: nil, required: false, allow_nil: true)
        # Support both as_operand: and positional: (deprecated) for backward compatibility
        effective_as_operand = as_operand || positional || false
        # Support both repeatable: and multi_valued: (deprecated) for backward compatibility
        effective_repeatable = repeatable || multi_valued || false
        validate_value_modifiers!(names, inline, effective_as_operand, separator)

        option_type = determine_value_option_type(inline, effective_as_operand)
        register_option(names, type: option_type, args: args, expected_type: type, separator: separator,
                               allow_empty: allow_empty, repeatable: effective_repeatable, required: required,
                               allow_nil: allow_nil)
      end

      alias value value_option

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
      # @example Basic flag or value option (new capability - not possible with old DSL)
      #   flag_or_value_option :contains
      #   # true       => --contains
      #   # false      => (nothing)
      #   # "abc123"   => --contains abc123 (separate arguments)
      #   # nil        => (nothing)
      #
      # @example With inline: true
      #   flag_or_value_option :gpg_sign, inline: true
      #   # true       => --gpg-sign
      #   # false      => (nothing)
      #   # "KEY"      => --gpg-sign=KEY (inline)
      #   # nil        => (nothing)
      #
      # @example With negatable: true (flag or value with negation)
      #   flag_or_value_option :verify, negatable: true
      #   # true       => --verify
      #   # false      => --no-verify
      #   # "KEYID"    => --verify KEYID (separate arguments)
      #   # nil        => (nothing)
      #
      # @example With negatable: true and inline: true
      #   flag_or_value_option :sign, negatable: true, inline: true
      #   # true       => --sign
      #   # false      => --no-sign
      #   # "KEY"      => --sign=KEY (inline)
      #   # nil        => (nothing)
      #
      def flag_or_value_option(names, args: nil, type: nil, negatable: false, inline: false,
                               required: false, allow_nil: true)
        option_type = determine_flag_or_value_option_type(negatable, inline)
        register_option(names, type: option_type, args: args, expected_type: type,
                               required: required, allow_nil: allow_nil)
      end

      alias flag_or_value flag_or_value_option

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
      # @example Basic key-value option (like --trailer)
      #   key_value_option :trailers, args: '--trailer'
      #   # trailers: { 'Signed-off-by' => 'John' }
      #   #   => ['--trailer', 'Signed-off-by=John']
      #
      # @example Hash with array values (multiple values for same key)
      #   key_value_option :trailers, args: '--trailer'
      #   # trailers: { 'Signed-off-by' => ['John', 'Jane'] }
      #   #   => ['--trailer', 'Signed-off-by=John', '--trailer', 'Signed-off-by=Jane']
      #
      # @example Array of arrays (full ordering control)
      #   key_value_option :trailers, args: '--trailer'
      #   # trailers: [['Signed-off-by', 'John'], ['Acked-by', 'Bob']]
      #   #   => ['--trailer', 'Signed-off-by=John', '--trailer', 'Acked-by=Bob']
      #
      # @example Key without value (nil value omits separator)
      #   key_value_option :trailers, args: '--trailer'
      #   # trailers: [['Acked-by', nil]]
      #   #   => ['--trailer', 'Acked-by']
      #
      # @example Nil in array values produces key-only entries
      #   key_value_option :trailers, args: '--trailer'
      #   # trailers: { 'Key' => ['Value1', nil, 'Value2'] }
      #   #   => ['--trailer', 'Key=Value1', '--trailer', 'Key', '--trailer', 'Key=Value2']
      #
      # @example With custom separator
      #   key_value_option :trailers, args: '--trailer', key_separator: ': '
      #   # trailers: { 'Signed-off-by' => 'John' }
      #   #   => ['--trailer', 'Signed-off-by: John']
      #
      # @example Empty values produce no output
      #   key_value_option :trailers, args: '--trailer', required: true
      #   # trailers: {}  => []  (no error, empty output)
      #   # trailers: []  => []  (no error, empty output)
      #   # trailers: nil => []  (no error, empty output)
      #
      def key_value_option(names, args: nil, key_separator: '=', inline: false, required: false, allow_nil: true)
        option_type = inline ? :inline_key_value : :key_value
        register_option(names, type: option_type, args: args, key_separator: key_separator,
                               required: required, allow_nil: allow_nil)
      end

      alias key_value key_value_option

      # Define a literal string that is always included in the output
      #
      # Literals are output at their definition position (not grouped at the start).
      # This allows precise control over argument ordering, which is important for
      # git commands where argument position matters.
      #
      # @param flag_string [String] the literal string (e.g., '--', '--no-progress')
      # @return [void]
      #
      # @example Literal for subcommand mode
      #   literal '--delete'
      #   flag_option :force
      #   operand :branches, repeatable: true
      #   # build('feature', force: true) => ['--delete', '--force', 'feature']
      #
      # @example Literal separator between options and pathspecs
      #   flag_option :force
      #   operand :tree_ish
      #   literal '--'
      #   operand :paths, repeatable: true
      #   # build('HEAD', 'file.txt', force: true) => ['--force', 'HEAD', '--', 'file.txt']
      #
      def literal(flag_string)
        @static_flags << flag_string
        @ordered_definitions << { kind: :static, flag: flag_string }
      end

      alias static literal

      # Define a custom option with a custom builder block
      #
      # @param names [Symbol, Array<Symbol>] the option name(s), first is primary
      # @param required [Boolean] whether the option must be provided (key must exist in opts)
      # @param allow_nil [Boolean] whether nil is allowed when required is true. Defaults to true.
      #   When false with required: true, raises ArgumentError if value is nil.
      # @yield [value] block that receives the option value and returns the argument string
      # @return [void]
      #
      def custom_option(names, required: false, allow_nil: true, &block)
        register_option(names, type: :custom, builder: block, required: required, allow_nil: allow_nil)
      end

      alias custom custom_option

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

      # Define an operand (positional argument in CLI terminology)
      #
      # Operands are mapped to values following Ruby method signature
      # semantics. Required operands before a variadic are filled left-to-right,
      # required operands after a variadic are filled from the end, and the
      # variadic gets whatever remains in the middle.
      #
      # @param name [Symbol] the operand name (used in error messages)
      # @param required [Boolean] whether the operand is required. For repeatable
      #   operands, this means at least one value must be provided.
      # @param repeatable [Boolean] whether the operand accepts multiple values
      #   (can appear multiple times on the command line). Only one repeatable operand is
      #   allowed per definition; attempting to define a second will raise an
      #   ArgumentError.
      # @param variadic [Boolean] DEPRECATED: Use repeatable: instead. Alias for repeatable:.
      # @param default [Object] the default value if not provided. For repeatable
      #   operands, this should be an array (e.g., `default: ['.']`).
      # @param separator [String, nil] separator string to insert before this
      #   operand in the output (e.g., '--' for the common pathspec separator)
      # @param allow_nil [Boolean] whether nil is a valid value for a required
      #   operand. When true, nil consumes the operand slot but is omitted
      #   from output. This is useful for commands like `git checkout` where
      #   the tree-ish is required to consume a slot but may be nil to restore
      #   from the index. Defaults to false.
      # @return [void]
      #
      # @example Required operand (like `def clone(repository)`)
      #   operand :repository, required: true
      #   # build('https://github.com/user/repo')
      #   #   => ['https://github.com/user/repo']
      #
      # @example Optional operand with default (like `def log(commit = 'HEAD')`)
      #   operand :commit, default: 'HEAD'
      #   # build()        => ['HEAD']
      #   # build('main')  => ['main']
      #
      # @example Repeatable operand (like multiple file arguments)
      #   operand :paths, repeatable: true
      #   # build('file1', 'file2', 'file3')
      #   #   => ['file1', 'file2', 'file3']
      #
      # @example Required repeatable with at least one value
      #   operand :paths, repeatable: true, required: true
      #   # build()         => raises ArgumentError
      #   # build('file1')  => ['file1']
      #
      # @example git mv pattern (sources... destination)
      #   operand :sources, repeatable: true, required: true
      #   operand :destination, required: true
      #   # build('src1', 'src2', 'dest')
      #   #   => ['src1', 'src2', 'dest']
      #   # build('src', 'dest')
      #   #   => ['src', 'dest']
      #
      # @example Optional before repeatable with required after
      #   operand :a, default: 'default_a'
      #   operand :middle, repeatable: true
      #   operand :b, required: true
      #   # build('x')           => ['default_a', 'x']  (a=default, middle=[], b='x')
      #   # build('x', 'y')      => ['x', 'y']          (a='x', middle=[], b='y')
      #   # build('x', 'm', 'y') => ['x', 'm', 'y']     (a='x', middle=['m'], b='y')
      #
      # @example Operand with separator (pathspec after --)
      #   flag_option :force
      #   operand :paths, repeatable: true, separator: '--'
      #   # build('file1', 'file2', force: true)
      #   #   => ['--force', '--', 'file1', 'file2']
      #
      # @example Complex pattern (commit1, optional commit2, repeatable paths)
      #   operand :commit1, required: true
      #   operand :commit2
      #   operand :paths, repeatable: true, separator: '--'
      #   # build('HEAD~1')
      #   #   => ['HEAD~1']
      #   # build('HEAD~1', 'HEAD')
      #   #   => ['HEAD~1', 'HEAD']
      #   # build('HEAD~1', 'HEAD', 'file.rb')
      #   #   => ['HEAD~1', 'HEAD', '--', 'file.rb']
      #
      # @example Required operand that allows nil (like `git checkout [tree-ish] -- paths`)
      #   operand :tree_ish, required: true, allow_nil: true
      #   operand :paths, repeatable: true, separator: '--'
      #   # build('HEAD', 'file.rb')
      #   #   => ['HEAD', '--', 'file.rb']
      #   # build(nil, 'file.rb')
      #   #   => ['--', 'file.rb']  (nil consumes slot but is omitted from output)
      #
      def operand(name, required: false, repeatable: false, variadic: nil,
                  default: nil, separator: nil, allow_nil: false)
        effective_repeatable = repeatable || variadic || false
        validate_single_repeatable!(name) if effective_repeatable
        add_operand_definition(name, required, effective_repeatable, default, separator, allow_nil)
      end

      alias positional operand

      # Bind positionals and options, returning a Bound object with accessor methods
      #
      # Unlike the internal build method which returns a raw Array, this method
      # returns a {Bound} object that:
      # - Provides accessor methods for all defined options and positional arguments
      # - Automatically normalizes option aliases to their canonical names
      # - Supports splatting via `to_ary` for seamless use with `command(*bound)`
      #
      # @param positionals [Array] positional argument values
      # @param opts [Hash] the keyword options
      # @return [Bound] a frozen object with accessor methods for all arguments
      # @raise [ArgumentError] if unsupported options are provided or validation fails
      #
      # @example Simple splatting (same behavior as build)
      #   def call(*, **)
      #     @execution_context.command(*ARGS.bind(*, **))
      #   end
      #
      # @example Inspecting options before command execution
      #   def call(*, **)
      #     bound_args = ARGS.bind(*, **)
      #     bound_args.force          # => true (if provided)
      #     bound_args.remotes        # => true (normalized from :r or :remotes)
      #     bound_args.branch_names   # => ['branch1', 'branch2']
      #     @execution_context.command(*bound_args)
      #   end
      #
      # @example Hash-style access for reserved names
      #   bound_args[:hash]  # Required for reserved names like :hash, :class
      #
      def bind(*positionals, **opts)
        validate_unsupported_options!(opts)
        validate_conflicting_aliases!(opts)
        normalized_opts = normalize_aliases(opts)
        validate_required_options!(normalized_opts)
        validate_option_values!(normalized_opts)
        validate_conflicts!(normalized_opts)

        args_array = build_ordered_arguments(positionals, normalized_opts)
        allocated_positionals = allocate_and_validate_positionals(positionals)

        # Build options hash with normalized values (including defaults for flags)
        options_hash = build_options_hash(normalized_opts)

        Bound.new(args_array, options_hash, allocated_positionals)
      end

      private

      # Build a hash of all option values for the Bound object
      #
      # @param normalized_opts [Hash] the normalized options
      # @return [Hash{Symbol => Object}] option values with defaults applied
      def build_options_hash(normalized_opts)
        result = {}
        @option_definitions.each_key do |name|
          result[name] = normalized_opts.key?(name) ? normalized_opts[name] : default_option_value(name)
        end
        result
      end

      # Get the default value for an option when not provided
      #
      # @param name [Symbol] the option name
      # @return [Object] the default value (false for flags, nil for values)
      def default_option_value(name)
        definition = @option_definitions[name]
        case definition[:type]
        when :flag, :negatable_flag
          false
        end
      end

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

        if definition[:type] == :negatable_flag
          raise ArgumentError,
                "arrays for args: parameter cannot be combined with negatable: true (option :#{option_name})"
        end

        return if definition[:type] == :flag

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
        when :operand
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

        @operand_definitions.each do |definition|
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
        definition = @operand_definitions.find { |d| d[:name] == name }
        value = allocation[name]
        append_positional_to_args(args, value, definition)
      end

      def validate_single_repeatable!(name)
        existing_repeatable = @operand_definitions.find { |d| d[:repeatable] }
        return unless existing_repeatable

        raise ArgumentError,
              "only one repeatable operand is allowed; :#{existing_repeatable[:name]} is already repeatable, " \
              "cannot add :#{name} as repeatable"
      end

      def add_operand_definition(name, required, repeatable, default, separator, allow_nil)
        @operand_definitions << {
          name: name, required: required, repeatable: repeatable,
          default: default, separator: separator, allow_nil: allow_nil
        }
        @ordered_definitions << { kind: :operand, name: name }
      end

      BUILDERS = {
        flag: lambda do |args, arg_spec, value, _|
          return unless value

          arg_spec.is_a?(Array) ? args.concat(arg_spec) : args << arg_spec
        end,
        negatable_flag: :build_negatable_flag,
        value: lambda do |args, arg_spec, value, definition|
          if definition[:repeatable]
            Array(value).each { |v| args << arg_spec << v.to_s }
          else
            args << arg_spec << value.to_s
          end
        end,
        inline_value: :build_inline_value,
        flag_or_inline_value: :build_flag_or_inline_value,
        negatable_flag_or_inline_value: :build_negatable_flag_or_inline_value,
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
        negatable_flag_or_value: :build_negatable_flag_or_value,
        value_to_positional: lambda do |args, _, value, definition|
          # Validate array usage when repeatable is false
          if value.is_a?(Array) && !definition[:repeatable]
            raise ArgumentError,
                  "value_to_positional :#{definition[:aliases].first} requires repeatable: true to accept an array"
          end

          # Validate no nil values in array
          if definition[:repeatable] && value.is_a?(Array) && value.any?(&:nil?)
            raise ArgumentError,
                  "nil values are not allowed in value_to_positional :#{definition[:aliases].first}"
          end

          # Add separator if present
          args << definition[:separator] if definition[:separator]

          # Add values as positional arguments
          if definition[:repeatable]
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

        arg_spec = definition[:args] || default_arg_spec(name)
        builder = BUILDERS[definition[:type]]
        if builder.is_a?(Symbol)
          send(builder, args, arg_spec, value, definition)
        else
          builder&.call(args, arg_spec, value, definition)
        end
      end

      # Generate the default argument specification based on option name length
      #
      # POSIX convention: single-character options use single dash (-f),
      # multi-character options use double dash (--force)
      #
      # @param name [Symbol] the option name
      # @return [String] the argument specification (e.g., '-f' or '--force')
      #
      def default_arg_spec(name)
        name_str = name.to_s.tr('_', '-')
        name_str.length == 1 ? "-#{name_str}" : "--#{name_str}"
      end

      # Check if an argument specification is for a short (single-character) option
      #
      # @param arg_spec [String] the argument specification
      # @return [Boolean] true if this is a short option (single dash, single char)
      #
      def short_option?(arg_spec)
        arg_spec.is_a?(String) && arg_spec.match?(/\A-[^-]\z/)
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

      # Build inline value option with POSIX-compliant formatting
      #
      # Short options (single-char) use no separator: -n3
      # Long options (multi-char) use = separator: --name=value
      #
      def build_inline_value(args, arg_spec, value, definition)
        sep = inline_value_separator(arg_spec)
        if definition[:repeatable]
          Array(value).each { |v| args << "#{arg_spec}#{sep}#{v}" }
        else
          args << "#{arg_spec}#{sep}#{value}"
        end
      end

      # Build flag or inline value option with POSIX-compliant formatting
      #
      def build_flag_or_inline_value(args, arg_spec, value, _definition)
        validate_flag_or_value_type!(value, 'flag_or_inline_value')
        return if value == false

        args << (value == true ? arg_spec : "#{arg_spec}#{inline_value_separator(arg_spec)}#{value}")
      end

      # Build negatable flag or inline value option with POSIX-compliant formatting
      #
      def build_negatable_flag_or_inline_value(args, arg_spec, value, _definition)
        validate_flag_or_value_type!(value, 'negatable_flag_or_inline_value')
        args << case value
                when true then arg_spec
                when false then negate_flag(arg_spec)
                else "#{arg_spec}#{inline_value_separator(arg_spec)}#{value}"
                end
      end

      # Build negatable flag or value option with proper negation format for short options
      #
      def build_negatable_flag_or_value(args, arg_spec, value, _definition)
        validate_flag_or_value_type!(value, 'negatable_flag_or_value')
        case value
        when true
          args << arg_spec
        when false
          args << negate_flag(arg_spec)
        else
          args << arg_spec << value.to_s
        end
      end

      # Validate that a value is a valid flag_or_value type (true, false, or String)
      #
      def validate_flag_or_value_type!(value, option_type)
        return if value.is_a?(TrueClass) || value.is_a?(FalseClass) || value.is_a?(String)

        raise ArgumentError,
              "Invalid value for #{option_type}: #{value.inspect} (#{value.class}); " \
              'expected true, false, or a String'
      end

      # Determine the separator to use for inline values based on option type
      #
      # POSIX convention:
      # - Short options (single dash, single char like -n): no separator (-n3)
      # - Long options (double dash like --name): = separator (--name=value)
      #
      # @param arg_spec [String] the argument specification
      # @return [String] empty string ('') for short options, '=' for long options;
      #   never returns nil, safe to concatenate directly
      #
      def inline_value_separator(arg_spec)
        short_option?(arg_spec) ? '' : '='
      end

      # Build negatable flag with proper negation format
      #
      # For negation, always use double-dash format (--no-x) even for short options,
      # as this is the POSIX convention.
      #
      def build_negatable_flag(args, arg_spec, value, _definition)
        unless [true, false].include?(value)
          raise ArgumentError,
                "negatable_flag expects a boolean value, got #{value.inspect} (#{value.class})"
        end

        args << (value ? arg_spec : negate_flag(arg_spec))
      end

      # Negate a flag by adding --no- prefix
      #
      # For short options (-f), expands to --no-f
      # For long options (--force), transforms to --no-force
      #
      # @param arg_spec [String] the argument specification
      # @return [String] the negated flag
      #
      def negate_flag(arg_spec)
        if short_option?(arg_spec)
          # -f => --no-f
          "--no-#{arg_spec[1]}"
        else
          # --force => --no-force
          arg_spec.sub(/\A--/, '--no-')
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
        OperandAllocator.new(@operand_definitions).allocate(positionals)
      end

      def append_positional_to_args(args, value, definition)
        return if positional_value_empty?(value, definition)

        args << definition[:separator] if definition[:separator]
        append_positional_value(args, value, definition[:repeatable])
      end

      def positional_value_empty?(value, definition)
        return true if value.nil?

        definition[:repeatable] && value.respond_to?(:empty?) && value.empty?
      end

      def append_positional_value(args, value, repeatable)
        if repeatable
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

        raise ArgumentError, "at least one value is required for #{definition[:name]}" if definition[:repeatable]

        raise ArgumentError, "#{definition[:name]} is required"
      end

      def validate_no_nil_values!(value, definition)
        return unless definition[:repeatable]
        return if value.nil? # Allow nil as "not provided"

        # For repeatable positionals, check if array contains any nil values
        values = Array(value)
        return unless values.any?(&:nil?)

        raise ArgumentError, "nil values are not allowed in repeatable positional argument: #{definition[:name]}"
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

      # Bound arguments object returned by {Arguments#bind}
      #
      # Provides accessor methods for all defined options and positional arguments,
      # with automatic normalization of aliases to their canonical names.
      #
      # @api private
      #
      # @example Accessing bound arguments
      #   bound = ARGS.bind('branch1', 'branch2', force: true, r: true)
      #   bound.force          # => true
      #   bound.remotes        # => true (normalized from :r alias)
      #   bound.branch_names   # => ['branch1', 'branch2']
      #
      # @example Splatting for command execution
      #   @execution_context.command(*bound)  # Uses to_ary
      #
      # @example Hash-style access for reserved names
      #   bound[:hash]  # Required for reserved names like :hash, :class, etc.
      #
      class Bound
        # Names that cannot have accessor methods defined (would override Object methods)
        RESERVED_NAMES = (Object.instance_methods + [:to_ary]).freeze

        # @param args_array [Array<String>] the CLI argument array (frozen)
        # @param options [Hash{Symbol => Object}] normalized options hash (frozen)
        # @param positionals [Hash{Symbol => Object}] positional arguments hash (frozen)
        def initialize(args_array, options, positionals)
          @args_array = args_array.freeze
          @options = options.freeze
          @positionals = positionals.freeze

          # Define accessor methods (skip reserved names)
          @options.each_key { |name| define_accessor(name, @options) }
          @positionals.each_key { |name| define_accessor(name, @positionals) }

          freeze
        end

        # Returns the CLI arguments array for splatting
        #
        # This enables direct splatting: `command(*bound_args)`
        #
        # @return [Array<String>] the CLI arguments
        def to_ary
          @args_array
        end

        # Returns the CLI arguments array for splatting
        #
        # Ruby's splat operator in array literals uses `to_a` for expansion.
        # This enables: `['git', 'branch', *bound_args]`
        #
        # @return [Array<String>] the CLI arguments
        def to_a
          @args_array
        end

        # Hash-style access to option and positional values
        #
        # Use this for reserved names (like :hash, :class) that cannot have
        # accessor methods defined.
        #
        # @param key [Symbol] the option or positional name
        # @return [Object, nil] the value, or nil if not found
        def [](key)
          return @options[key] if @options.key?(key)
          return @positionals[key] if @positionals.key?(key)

          nil
        end

        private

        # Define an accessor method for the given name
        #
        # @param name [Symbol] the option or positional name
        # @param source [Hash] the hash to read from (@options or @positionals)
        def define_accessor(name, source)
          return if RESERVED_NAMES.include?(name)

          define_singleton_method(name) { source[name] }
        end
      end
    end

    # Allocates operand (positional argument) values to definitions following Ruby semantics.
    #
    # This class handles the complex logic of mapping positional values to their
    # definitions, supporting required, optional, and repeatable operands.
    #
    # @api private
    class OperandAllocator
      # @param definitions [Array<Hash>] operand definitions
      def initialize(definitions)
        @definitions = definitions
      end

      # Allocate values to definitions
      # @param values [Array] the positional argument values
      # @return [Array(Hash, Integer)] [allocation_hash, consumed_count]
      def allocate(values)
        allocation = {}
        repeatable_index = @definitions.find_index { |d| d[:repeatable] }

        consumed = if repeatable_index.nil?
                     allocate_without_repeatable(values, allocation)
                   else
                     allocate_with_repeatable(values, allocation, repeatable_index)
                   end

        [allocation, consumed]
      end

      private

      # Allocate when there's no repeatable positional, following Ruby semantics:
      # - Required positionals at the END are reserved first
      # - Leading positionals get remaining values left-to-right
      # - Optional positionals are skipped when there aren't enough values
      def allocate_without_repeatable(values, allocation)
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

      def allocate_with_repeatable(values, allocation, repeatable_index)
        parts = split_around_repeatable(repeatable_index)
        slices = calculate_repeatable_slices(values, parts)

        pre_consumed = allocate_pre_repeatable_smart(allocation, parts[:pre], slices[:pre_values])
        repeatable_consumed = allocate_repeatable(
          allocation, parts[:repeatable], values, slices[:var_start], slices[:var_end]
        )
        post_consumed = allocate_post_repeatable(allocation, parts[:post], values, slices[:post_start])

        pre_consumed + repeatable_consumed + post_consumed
      end

      def calculate_repeatable_slices(values, parts)
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

      def split_around_repeatable(repeatable_index)
        {
          pre: @definitions[0...repeatable_index],
          repeatable: @definitions[repeatable_index],
          post: @definitions[(repeatable_index + 1)..]
        }
      end

      # Allocate pre-repeatable positionals with Ruby-like semantics
      # (required get values first, optional only if extra values available)
      def allocate_pre_repeatable_smart(allocation, definitions, values)
        return 0 if definitions.empty?

        state = LeadingAllocationState.new(definitions, values, method(:required?))
        state.allocate(allocation)
      end

      def allocate_repeatable(allocation, definition, values, start_idx, end_idx)
        repeatable_values = values[start_idx...end_idx] || []
        allocation[definition[:name]] =
          if repeatable_values.empty? || repeatable_values.all?(&:nil?)
            definition[:default]
          else
            repeatable_values
          end
        repeatable_values.compact.size
      end

      def allocate_post_repeatable(allocation, definitions, values, post_start)
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

    # Backward compatibility alias for OperandAllocator
    # @api private
    PositionalAllocator = OperandAllocator
    # rubocop:enable Metrics/ParameterLists
  end
end
