# frozen_string_literal: true

module Git
  module Commands
    # rubocop:disable Metrics/ParameterLists

    # This class provides a DSL for mapping Ruby method arguments to git command-line
    # arguments.
    #
    # ## Overview
    #
    # This class provides a DSL for defining how arguments passed to {#bind} should
    # be mapped to git CLI argument arrays. The process follows four phases:
    #
    # 1. **Definition** of expected CLI arguments and their constraints
    # 2. **Binding** of method arguments to the definition
    # 3. **Validation** of values against argument constraints
    # 4. **Building** of the CLI argument array
    #
    # See {Git::Commands::Init} for a usage example.
    #
    # Example: Defining arguments for a command
    #
    # ```ruby
    # # 1. Definition of expected CLI arguments and their constraints
    # args_def = Arguments.define do
    #   flag_option :force
    #   value_option :branch
    #   operand :repository, required: true
    # end
    #
    # # 2. Binding of method arguments to the definition
    # # 3. Validation of values against argument constraints
    # args = args_def.bind('https://github.com/user/repo', force: true, branch: 'main')
    #
    # # 4. Building of the CLI argument array
    # args.to_a # => ['--force', '--branch', 'main', 'https://github.com/user/repo']
    #
    # # Bonus: accessing bound values
    # args.force?      # => true
    # args.branch      # => 'main'
    # args.repository  # => 'https://github.com/user/repo'
    # ```
    #
    # ## Terminology
    #
    # This class bridges CLI and Ruby interfaces. While both use the term "arguments"
    # for values passed to commands/methods, they differ in terminology for specific
    # argument types:
    #
    # | CLI (POSIX)            | Ruby Interface         | Description                                         |
    # |------------------------|------------------------|-----------------------------------------------------|
    # | argument specification | DSL definition         | Declared command inputs and constraints             |
    # | arguments              | arguments              | Values passed when calling a command/method         |
    # | operands               | positional arguments   | Arguments identified by position                    |
    # | options                | keyword arguments      | Arguments identified by name (`--force` / `force:`) |
    #
    # The following sections explain each interface in detail.
    #
    # ### CLI Interface (POSIX)
    #
    # An **argument specification** declares what command inputs are accepted and
    # their constraints.
    #
    # Example:
    #
    # ```text
    # git branch (--set-upstream-to=<upstream>|-u <upstream>) [<branch-name>]
    # ```
    #
    # When a command is invoked, **arguments** are the values passed to it:
    # - **Arguments**: Values passed when calling the command (everything after the
    #   command name)
    # - **Operands**: Arguments identified by position
    # - **Options**: Arguments identified by name (prefixed with `-` or `--`)
    #
    # Example:
    #
    # ```shell
    # git branch --set-upstream-to=origin/main main
    # ```
    #
    # - Operands: `main`
    # - Options: `--set-upstream-to=origin/main`
    #
    # ### Ruby Interface
    #
    # A **DSL definition** declares what arguments the {#bind} method accepts and how
    # they map to CLI arguments.
    #
    # Example:
    #
    # ```ruby
    # Arguments.define do
    #   literal 'branch'
    #   value_option %i[set_upstream_to u], inline: true  # primary name with short alias :u
    #   operand :branch_name
    # end
    # ```
    #
    # When {#bind} is called, **arguments** are the values passed to it:
    # - **Arguments**: Values passed to {#bind}
    # - **Positional arguments**: Arguments identified by position
    # - **Keyword arguments**: Arguments identified by name
    #
    # Example:
    #
    # ```ruby
    # args_def.bind('main', set_upstream_to: 'origin/main')
    # ```
    #
    # - Positional argument: `'main'`
    # - Keyword argument: `set_upstream_to: 'origin/main'`
    #
    # Calling {Bound#to_a} on the bound result produces the CLI argument array:
    #
    # ```ruby
    # args_def.bind('main', set_upstream_to: 'origin/main').to_a
    # # => ['branch', '--set-upstream-to=origin/main', 'main']
    # ```
    #
    # ## Design
    #
    # The class operates in two stages:
    #
    # 1. **Definition stage**: DSL methods ({#flag_option}, {#value_option}, {#operand}, etc.)
    #    record argument definitions in internal data structures.
    #
    # 2. **Bind stage**: {#bind} binds Ruby values and validates them against constraints,
    #    returning a {Bound} object.
    #
    # The returned {Bound} object provides accessor methods for the bound values and handles
    # the building phase, converting bound values to CLI arguments via {Bound#to_a}.
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
    # ## Argument Ordering
    #
    # Arguments are rendered in the exact order they are defined in the DSL block,
    # regardless of type (options, operands, or static flags). This is important
    # for git commands where argument order matters, such as when using `--` to
    # separate options from pathspecs.
    #
    # @example Ordering example
    #   args_def = Arguments.define do
    #     operand :ref
    #     literal '--'
    #     operand :path
    #   end
    #   args_def.bind('HEAD', 'file.txt').to_a  # => ['HEAD', '--', 'file.txt']
    #
    # ## Short Option Detection
    #
    # Option names are automatically formatted using POSIX conventions:
    #
    # - **Single-character names** use single-dash prefix: `:f` → `-f`
    # - **Multi-character names** use double-dash prefix: `:force` → `--force`
    #
    # For inline values (`inline: true`), the separator also follows POSIX
    # conventions:
    #
    # - **Short options** use no separator: `-n3`
    # - **Long options** use `=` separator: `--name=value`
    #
    # Negated flags always use double-dash format (e.g., `-f` → `--no-f` when false).
    #
    # The `as:` parameter can override this automatic detection when needed.
    #
    # @example Short option detection
    #   args_def = Arguments.define do
    #     flag_option :f                          # true → '-f'
    #     flag_option :force                      # true → '--force'
    #     value_option :n, inline: true           # 3 → '-n3'
    #     value_option :name, inline: true        # 'test' → '--name=test'
    #   end
    #
    #   args_def.bind(f: true, force: true, n: 3, name: 'test').to_a
    #   # => ['-f', '--force', '-n3', '--name=test']
    #
    # @example Explicit override with `as:`
    #   args_def = Arguments.define do
    #     flag_option :f, as: '--force'
    #   end
    #   args_def.bind(f: true).to_a  # => ['--force']
    #
    # ## Option Types
    #
    # The DSL supports several option types with modifiers:
    #
    # ### Primary Option Types
    # - {#flag_option} - Boolean flag (--flag when true, with `negatable: true` for --no-flag)
    # - {#value_option} - Valued option (--flag value, with `inline: true` for --flag=value,
    #   or `as_operand: true` for operands)
    # - {#flag_or_value_option} - Flag or value (--flag when true, --flag value when string,
    #   with `inline: true` and/or `negatable: true` modifiers)
    # - {#key_value_option} - Key-value option that can be repeated (--trailer key=value)
    # - {#literal} - Literal string always included in output
    # - {#custom_option} - Custom option with builder block
    # - {#execution_option} - Execution option (not included in CLI output, forwarded to command execution)
    #
    # {#value_option} supports a `repeatable: true` parameter that allows the option to accept
    # an array of values. This repeats the flag for each value (or outputs each as an
    # operand when using `as_operand: true`):
    #
    # Repeatable options:
    #
    #   value_option :config, repeatable: true
    #   # config: ['a=b', 'c=d'] => ['--config', 'a=b', '--config', 'c=d']
    #
    #   value_option :sort, inline: true, repeatable: true
    #   # sort: ['refname', '-committerdate'] => ['--sort=refname', '--sort=-committerdate']
    #
    #   value_option :pathspecs, as_operand: true, separator: '--', repeatable: true
    #   # pathspecs: ['file1.txt', 'file2.txt'] => ['--', 'file1.txt', 'file2.txt']
    #
    # ## Common Option Parameters
    #
    # Most option types support parameters that affect **input validation** (checked
    # during {#bind}):
    #
    # - **required:** - When true, the option key must be present in the provided
    #   opts. Raises ArgumentError if the key is missing. Defaults to false.
    #   Supported by: {#flag_option}, {#value_option}, {#flag_or_value_option}, {#custom_option}, {#operand}.
    # - **allow_nil:** - When false (with required: true), the value cannot be nil.
    #   Raises ArgumentError if a nil value is provided. Defaults to true for
    #   options, false for operands. Supported by: same as **required:**.
    # - **type:** - Validates the value is an instance of the specified class(es).
    #   Accepts a single class or an array of classes. Raises ArgumentError if type
    #   doesn't match. This parameter only performs type checking during validation;
    #   conversion of values to CLI argument strings happens later during the build
    #   phase (for example, via #to_s in {Bound#to_a}). Defaults to nil (no validation).
    #   Supported by: {#flag_option}, {#value_option}, {#flag_or_value_option}.
    #
    # Note: {#literal} and {#execution_option} do not support these validation parameters.
    #
    # These parameters affect **output generation** (what CLI arguments are
    # produced):
    #
    # - **as:** - Override the CLI argument(s) derived from the option name
    #   Can be a String or an Array. Default is nil (derives from name).
    # - **allow_empty:** - ({#value_option} only) When true, output the option
    #   even if the value is an empty string. Default is false (empty strings skipped).
    # - **repeatable:** - ({#value_option} and {#operand} only) Output an option or
    #   operand for each array element. Default is false.
    #
    # @example Required option with non-nil value
    #   args_def = Arguments.define do
    #     value_option :upstream, inline: true, required: true, allow_nil: false
    #   end
    #   args_def.bind() #=> raise ArgumentError, "Required options not provided: :upstream"
    #   args_def.bind(upstream: nil) #=> raise ArgumentError, "Required options cannot be nil: :upstream"
    #   args_def.bind(upstream: 'origin').to_a  # => ['--upstream=origin']
    #
    # @example Required option allowing nil (default)
    #   args_def = Arguments.define do
    #     value_option :branch, inline: true, required: true
    #   end
    #   args_def.bind() #=> raise ArgumentError, "Required options not provided: :branch"
    #   args_def.bind(branch: nil).to_a  # => []
    #   args_def.bind(branch: 'main').to_a  # => ['--branch=main']
    #
    # ## Operands (Positional Arguments)
    #
    # Operands are mapped using Ruby-like semantics:
    #
    # 1. Post-repeatable required operands are reserved first (from the end)
    # 2. Pre-repeatable operands are filled with remaining values (required first, then optional)
    # 3. Optional operands (with defaults) get values only if extras are available
    # 4. Repeatable operand gets whatever is left in the middle
    #
    # This matches Ruby's parameter binding behavior, including patterns like `def
    # foo(a = default, *rest, b)` where the required `b` is filled before optional
    # `a`.
    #
    # @example Simple operand (like `git clone <repository>`)
    #   args_def = Arguments.define do
    #     literal 'clone'
    #     operand :repository, required: true
    #   end
    #   args_def.bind('https://github.com/user/repo').to_a
    #   # => ['clone', 'https://github.com/user/repo']
    #
    # @example Repeatable operand (like `git add <paths>...`)
    #   args_def = Arguments.define do
    #     literal 'add'
    #     operand :paths, repeatable: true
    #   end
    #   args_def.bind('file1', 'file2', 'file3').to_a
    #   # => ['add', 'file1', 'file2', 'file3']
    #
    # @example git mv pattern (like `git mv <sources>... <destination>`)
    #   args_def = Arguments.define do
    #     literal 'mv'
    #     operand :sources, repeatable: true, required: true
    #     operand :destination, required: true
    #   end
    #   args_def.bind('src1', 'src2', 'dest').to_a  # => ['mv', 'src1', 'src2', 'dest']
    #
    # ## Nil Handling for Operands
    #
    # When nil values are allowed (see `required:` and `allow_nil:` above), they have
    # special output behavior:
    #
    # - For non-repeating operands: nil values consume an operand slot during
    #   binding but are omitted from the resulting command-line arguments array
    # - For repeatable operands: nil values within the array raise an error
    #
    # @example Nil value omitted from output
    #   args = Arguments.define do
    #     operand :tree_ish, required: true, allow_nil: true
    #     operand :paths, repeatable: true
    #   end.bind(nil, 'file1', 'file2')
    #   args.to_a     # => ['file1', 'file2']
    #   args.tree_ish # => nil
    #   args.paths    # => ['file1', 'file2']
    #
    # ## Option-like Operand Rejection
    #
    # Operands that appear **before** a `--` separator boundary in the argument
    # definition are automatically validated to ensure their values don't start
    # with `-`. This prevents user-supplied strings like `'-s'` from being
    # misinterpreted as git flags when passed as positional arguments.
    #
    # The `--` boundary can come from:
    # - A `literal '--'` definition
    # - An operand with `separator: '--'`
    # - A `value_option` with `as_operand: true, separator: '--'`
    #
    # Operands **after** the `--` boundary are not validated (they represent
    # paths/filenames which may legitimately start with `-`). If no `--`
    # boundary exists in the definition, **all** operands are validated.
    #
    # @example Operands before and after '--' separator
    #   args_def = Arguments.define do
    #     operand :commit1
    #     operand :commit2
    #     operand :paths, repeatable: true, separator: '--'
    #   end
    #   args_def.bind('-s') #=> raise ArgumentError, "operand :commit1 value '-s' looks like a command-line option"
    #   args_def.bind('HEAD', 'HEAD~1', '-file.txt').to_a
    #   # => ['HEAD', 'HEAD~1', '--', '-file.txt']
    #
    # @example All operands validated when no '--' boundary exists
    #   args_def = Arguments.define do
    #     operand :path1, required: true
    #     operand :path2, required: true
    #   end
    #   args_def.bind('-s', 'file.txt')
    #   #=> raise ArgumentError, "operand :path1 value '-s' looks like a command-line option"
    #
    # ## Options After Separator
    #
    # Options that produce CLI flags (e.g. `flag_option`, `value_option`,
    # `key_value_option`, `custom_option`) cannot be defined after a `--`
    # separator boundary. Git treats everything after `--` as operands, so
    # flags emitted there would be misinterpreted.
    #
    # Only `value_option` with `as_operand: true` and `execution_option` are allowed
    # after the boundary because they do not produce flag-prefixed output.
    #
    # For example, this will raise +ArgumentError+ during definition:
    #
    #     Arguments.define do
    #       literal '--'
    #       flag_option :verbose
    #     end #=> raises ArgumentError
    #
    # @example Allowed: value_option as_operand after '--'
    #   Arguments.define do
    #     literal '--'
    #     value_option :paths, as_operand: true, repeatable: true
    #   end
    #
    # ## Type Validation
    #
    # The `type:` parameter provides declarative type validation for option values.
    # When validation fails, an ArgumentError is raised with a descriptive message.
    #
    # @example Single type validation
    #   args_def = Arguments.define do
    #     value_option :date, type: String, inline: true
    #   end
    #   args_def.bind(date: "2024-01-01").to_a  # => ['--date=2024-01-01']
    #   args_def.bind(date: 12345) #=> raise ArgumentError, "The :date option must be a String, but was a Integer"
    #
    # @example Multiple type validation (allows any of the specified types)
    #   args_def = Arguments.define do
    #     value_option :timeout, type: [Integer, Float], inline: true
    #   end
    #   args_def.bind(timeout: 30).to_a    # => ['--timeout=30']
    #   args_def.bind(timeout: 30.5).to_a  # => ['--timeout=30.5']
    #   args_def.bind(timeout: "30")
    #   #=> raise ArgumentError, "The :timeout option must be a Integer or Float, but was a String"
    #
    # The `type:` parameter cannot be combined with a custom `validator:` parameter.
    # Attempting to use both will raise an ArgumentError during definition.
    #
    # ## Conflict Detection
    #
    # Use {#conflicts} to declare mutually exclusive arguments. Names may refer to
    # **options** (flag, value, flag-or-value, etc.) or **operands** (positional
    # arguments) interchangeably. When {#bind} is called, if more than one argument
    # in a conflict group is "present", an ArgumentError is raised.
    #
    # An argument is considered **present** when its value is not `nil`, `false`,
    # `[]`, or `''`.
    #
    # @example Option vs option conflict
    #   args_def = Arguments.define do
    #     flag_option :force
    #     flag_option :force_force
    #     conflicts :force, :force_force
    #   end
    #   args_def.bind(force: true, force_force: true) #=> raise ArgumentError, "cannot specify :force and :force_force"
    #
    # @example Mixed option and operand conflict
    #   args_def = Arguments.define do
    #     flag_option %i[merge m], as: '--merge'
    #     operand :tree_ish, required: true, allow_nil: true
    #     conflicts :merge, :tree_ish
    #   end
    #   args_def.bind('main', merge: true)  #=> raise ArgumentError, "cannot specify :merge and :tree_ish"
    #   args_def.bind(nil, merge: true).to_a  # => ['--merge']
    #
    # ## At-Least-One Presence Validation
    #
    # Use {#requires_one_of} to declare groups of arguments where at least one must be
    # present. Names may refer to **options** (flag, value, flag-or-value, etc.) or
    # **operands** (positional arguments) interchangeably. When {#bind} is called, if
    # none of the arguments in a group is present, an ArgumentError is raised.
    #
    # @example Requiring at least one path source (options only)
    #   args_def = Arguments.define do
    #     value_option :pathspec_from_file, inline: true
    #     value_option :pathspec, as_operand: true, repeatable: true, separator: '--'
    #     requires_one_of :pathspec, :pathspec_from_file
    #   end
    #   args_def.bind
    #     #=> raise ArgumentError, 'at least one of :pathspec, :pathspec_from_file must be provided'
    #   args_def.bind(pathspec: ['file.txt']).to_a  # => ['--', 'file.txt']
    #
    # @example Mixed option and operand group
    #   args_def = Arguments.define do
    #     flag_option :all
    #     operand :paths, repeatable: true
    #     requires_one_of :all, :paths
    #   end
    #   args_def.bind
    #     #=> raise ArgumentError, 'at least one of :all, :paths must be provided'
    #   args_def.bind('file.txt').to_a  # => ['file.txt']
    #
    # ## Conditional Argument Requirements
    #
    # Use {#requires} and the `when:` form of {#requires_one_of} to declare that an
    # argument (or at least one of a group) must be present **only when** a specific
    # trigger argument is present. These constraints are evaluated during {#bind}: if
    # the trigger is absent the check is skipped entirely.
    #
    # An ArgumentError is raised at definition time if either the required name(s) or
    # the trigger name are not known arguments, catching typos early.
    #
    # @example Single conditional requirement
    #   args_def = Arguments.define do
    #     flag_option :pathspec_file_nul
    #     value_option :pathspec_from_file, inline: true
    #     requires :pathspec_from_file, when: :pathspec_file_nul
    #   end
    #   args_def.bind(pathspec_file_nul: true, pathspec_from_file: 'paths.txt').to_a
    #   # => ['--pathspec-file-nul', '--pathspec-from-file=paths.txt']
    #   args_def.bind(pathspec_file_nul: true)
    #   #=> raise ArgumentError, ':pathspec_file_nul requires :pathspec_from_file'
    #   args_def.bind  # trigger absent — no error
    #
    # @example Conditional at-least-one-of group
    #   args_def = Arguments.define do
    #     flag_option :annotate
    #     value_option :message, inline: true
    #     value_option :file, inline: true
    #     requires_one_of :message, :file, when: :annotate
    #   end
    #   args_def.bind(annotate: true, message: 'v1.0').to_a  # => ['--annotate', '--message=v1.0']
    #   args_def.bind(annotate: true)
    #   #=> raise ArgumentError, ':annotate requires at least one of :message, :file'
    #   args_def.bind  # trigger absent — no error
    #
    # ## Value Constraints
    #
    # In addition to presence-based validation ({#conflicts}, {#requires_one_of},
    # and {#requires}), you can restrict the *set of acceptable values* for any
    # value-type option using {#allowed_values}. If a bound value falls outside
    # the configured set, {#bind} raises ArgumentError with a descriptive message.
    #
    # This is typically used to model git options that accept only a fixed list of
    # modes or strategies, and supersedes ad-hoc `validator:` lambdas for simple
    # set-membership checks.
    #
    # @example Restricting option values
    #   args_def = Arguments.define do
    #     value_option :strategy, inline: true
    #     allowed_values :strategy, in: %w[ours theirs]
    #   end
    #   args_def.bind(strategy: 'ours').to_a      # => ['--strategy=ours']
    #   args_def.bind(strategy: 'theirs').to_a # => ['--strategy=theirs']
    #   args_def.bind(strategy: 'rebase')
    #   # => raise ArgumentError, 'Invalid value for :strategy: expected one of ["ours", "theirs"], got "rebase"'
    #
    # @api private
    #
    class Arguments
      # Define a new Arguments instance using the DSL
      #
      # @yield The block where arguments are defined using DSL methods
      #
      # @return [Arguments] The configured Arguments instance
      #
      # @example Basic flag
      #   args_def = Arguments.define do
      #     flag_option :verbose
      #   end
      #   args_def.bind(verbose: true).to_a  # => ['--verbose']
      #
      def self.define(&block)
        args = new
        args.instance_eval(&block) if block
        args
      end

      def initialize
        @option_definitions = {}
        @alias_map = {} # Maps alias keys to primary keys
        @operand_definitions = []
        @conflicts = [] # Array of conflicting option pairs/groups
        @requires_one_of = [] # Array of "at least one must be present" groups
        @ordered_definitions = [] # Tracks all definitions in definition order
        @past_separator = false # Tracks whether a '--' boundary has been defined
      end

      # Define a boolean flag option (--flag when true)
      #
      # @param names [Symbol, Array<Symbol>] the option name(s), first is primary
      #
      # @param as [String, Array<String>, nil] custom argument(s) to output (e.g., '-r' or ['--amend', '--no-edit'])
      #
      # @param type [Class, Array<Class>, nil] expected type(s) for validation. Raises ArgumentError with
      #   descriptive message if value doesn't match. Cannot be combined with validator:.
      #
      # @param validator [Proc, nil] optional validator block (cannot be combined with type:)
      #
      # @param negatable [Boolean] when true, outputs --no-flag when value is false (default: false)
      #
      # @param required [Boolean] whether the option must be provided (key must exist in opts)
      #
      # @param allow_nil [Boolean] whether nil is allowed when required is true. Defaults to true.
      #   When false with required: true, raises ArgumentError if value is nil.
      #
      # @return [void]
      #
      # @raise [ArgumentError] if inline: and as_operand: are both true
      #
      # @raise [ArgumentError] if separator: is provided without as_operand: true
      #
      # @raise [ArgumentError] if defined after a '--' separator boundary
      #
      # @example Basic flag
      #   args_def = Arguments.define do
      #     flag_option :force
      #   end
      #   args_def.bind(force: true).to_a   # => ['--force']
      #   args_def.bind(force: false).to_a  # => []
      #
      # @example Negatable flag
      #   args_def = Arguments.define do
      #     flag_option :full, negatable: true
      #   end
      #   args_def.bind(full: true).to_a   # => ['--full']
      #   args_def.bind(full: false).to_a  # => ['--no-full']
      #
      # @example With type validation
      #   args_def = Arguments.define do
      #     flag_option :force, type: [TrueClass, FalseClass]
      #   end
      #   args_def.bind(force: true).to_a  # => ['--force']
      #
      # @example With required and allow_nil: false
      #   args_def = Arguments.define do
      #     flag_option :force, required: true, allow_nil: false
      #   end
      #   args_def.bind() #=> raise ArgumentError, "Required options not provided: :force"
      #   args_def.bind(force: nil) #=> raise ArgumentError, "Required options cannot be nil: :force"
      #
      def flag_option(names, as: nil, type: nil, validator: nil, negatable: false, required: false, allow_nil: true)
        option_type = negatable ? :negatable_flag : :flag
        register_option(names, type: option_type, as: as, expected_type: type, validator: validator,
                               required: required, allow_nil: allow_nil)
      end

      # Define a valued option (--flag value as separate arguments)
      #
      # This option type supports three output modes controlled by `inline:` and `as_operand:`:
      #
      # - **Default**: `--flag value` (flag and value as separate arguments)
      # - **Inline**: `--flag=value` (single argument with `inline: true`)
      # - **Operand**: `value` (no flag, just the value with `as_operand: true`)
      #
      # @param names [Symbol, Array<Symbol>] the option name(s), first is primary
      #
      # @param as [String, nil] custom option string (arrays not supported for value types)
      #
      # @param type [Class, Array<Class>, nil] expected type(s) for validation. Raises ArgumentError with
      #   descriptive message if value doesn't match. Cannot be combined with validator:.
      #
      # @param inline [Boolean] when true, outputs --flag=value as single argument instead of
      #   --flag value as separate arguments (default: false). Cannot be combined with as_operand:.
      #
      # @param as_operand [Boolean] when true, outputs value as operand without flag
      #   (default: false). Cannot be combined with inline:.
      #
      # @param separator [String, nil] separator string to insert before values when as_operand: true
      #   (e.g., '--' for pathspec separator). Only valid with as_operand: true.
      #
      # @param allow_empty [Boolean] whether to include the option even when value is an empty string.
      #   When false (default), empty strings are skipped entirely. When true, the option and empty
      #   value are included in the output.
      #
      # @param repeatable [Boolean] whether to allow multiple values. When true, accepts an array
      #   of values and repeats the option for each value. A single value or nil is also accepted.
      #   Behavior varies by output mode (see examples below).
      #
      # @param required [Boolean] when true, the option key must be present in the provided options hash.
      #   Raises ArgumentError if the key is missing. Defaults to false.
      #
      # @param allow_nil [Boolean] when false (with required: true), the value cannot be nil.
      #   Raises ArgumentError if a nil value is provided. Defaults to true.
      #
      # @return [void]
      #
      # @raise [ArgumentError] if inline: and as_operand: are both true
      #
      # @raise [ArgumentError] if separator: is provided without as_operand: true
      #
      # @raise [ArgumentError] if defined after a '--' separator boundary
      #   (unless as_operand: true)
      #
      # @example Basic value (default mode)
      #   args_def = Arguments.define do
      #     value_option :branch
      #   end
      #   args_def.bind(branch: 'main').to_a  # => ['--branch', 'main']
      #
      # @example Inline value
      #   args_def = Arguments.define do
      #     value_option :format, inline: true
      #   end
      #   args_def.bind(format: 'short').to_a  # => ['--format=short']
      #
      # @example Operand value (no flag output)
      #   args_def = Arguments.define do
      #     value_option :ref, as_operand: true
      #   end
      #   args_def.bind(ref: 'HEAD').to_a  # => ['HEAD']
      #
      # @example Operand with separator
      #   args_def = Arguments.define do
      #     value_option :paths, as_operand: true, separator: '--'
      #   end
      #   args_def.bind(paths: 'file.txt').to_a  # => ['--', 'file.txt']
      #
      # @example Multi-valued (default mode) - repeats option for each value
      #   args_def = Arguments.define do
      #     value_option :config, repeatable: true
      #   end
      #   args_def.bind(config: 'a=b').to_a  # => ['--config', 'a=b']
      #   args_def.bind(config: ['a=b', 'c=d']).to_a  # => ['--config', 'a=b', '--config', 'c=d']
      #   args_def.bind(config: nil).to_a  # => []
      #
      # @example Multi-valued with inline - repeats inline option for each value
      #   args_def = Arguments.define do
      #     value_option :sort, inline: true, repeatable: true
      #   end
      #   args_def.bind(sort: ['refname', '-committerdate']).to_a
      #   # => ['--sort=refname', '--sort=-committerdate']
      #
      # @example Multi-valued with operand - outputs values without flags
      #   args_def = Arguments.define do
      #     value_option :pathspecs, as_operand: true, separator: '--', repeatable: true
      #   end
      #   args_def.bind(pathspecs: ['file1.txt', 'file2.txt']).to_a
      #   # => ['--', 'file1.txt', 'file2.txt']
      #
      # @example With type validation
      #   args_def = Arguments.define do
      #     value_option :branch, type: String
      #   end
      #   args_def.bind(branch: 'main').to_a  # => ['--branch', 'main']
      #
      # @example With allow_empty
      #   args_def = Arguments.define do
      #     value_option :message, allow_empty: true
      #   end
      #   args_def.bind(message: "").to_a     # => ['--message', '']
      #   args_def.bind(message: "text").to_a  # => ['--message', 'text']
      #
      #   args_def2 = Arguments.define do
      #     value_option :message  # allow_empty defaults to false
      #   end
      #   args_def2.bind(message: "").to_a     # => []
      #   args_def2.bind(message: "text").to_a  # => ['--message', 'text']
      #
      # @example With required
      #   args_def = Arguments.define do
      #     value_option :message, required: true
      #   end
      #   args_def.bind(message: 'text').to_a  # => ['--message', 'text']
      #   args_def.bind(message: nil).to_a  # => []
      #   args_def.bind() #=> raise ArgumentError, "Required options not provided: :message"
      #
      # @example With required and allow_nil: false
      #   args_def = Arguments.define do
      #     value_option :message, required: true, allow_nil: false
      #   end
      #   args_def.bind(message: 'text').to_a  # => ['--message', 'text']
      #   args_def.bind(message: nil) #=> raise ArgumentError, "Required options cannot be nil: :message"
      #   args_def.bind() #=> raise ArgumentError, "Required options not provided: :message"
      #
      def value_option(names, as: nil, type: nil, inline: false, as_operand: false, separator: nil,
                       allow_empty: false, repeatable: false, required: false, allow_nil: true)
        validate_value_modifiers!(names, inline, as_operand, separator)

        option_type = determine_value_option_type(inline, as_operand)
        register_option(names, type: option_type, as: as, expected_type: type, separator: separator,
                               allow_empty: allow_empty, repeatable: repeatable, required: required,
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
      #
      # @param as [String, nil] custom option string
      #
      # @param type [Class, Array<Class>, nil] expected type(s) for validation
      #
      # @param negatable [Boolean] when true, outputs --no-flag for false values (default: false)
      #
      # @param inline [Boolean] when true, outputs --flag=value instead of --flag value (default: false)
      #
      # @param required [Boolean] whether the option must be provided (key must exist in opts)
      #
      # @param allow_nil [Boolean] whether nil is allowed when required is true. Defaults to true.
      #
      # @return [void]
      #
      # @raise [ArgumentError] if value is not true, false, or a String
      #
      # @raise [ArgumentError] if defined after a '--' separator boundary
      #
      # @example Basic flag or value (new capability - not possible with old DSL)
      #   args_def = Arguments.define do
      #     flag_or_value_option :contains
      #   end
      #   args_def.bind(contains: true).to_a       # => ['--contains']
      #   args_def.bind(contains: false).to_a      # => []
      #   args_def.bind(contains: "abc123").to_a   # => ['--contains', 'abc123']
      #   args_def.bind(contains: nil).to_a        # => []
      #
      # @example With inline: true
      #   args_def = Arguments.define do
      #     flag_or_value_option :gpg_sign, inline: true
      #   end
      #   args_def.bind(gpg_sign: true).to_a    # => ['--gpg-sign']
      #   args_def.bind(gpg_sign: false).to_a   # => []
      #   args_def.bind(gpg_sign: "KEY").to_a   # => ['--gpg-sign=KEY']
      #   args_def.bind(gpg_sign: nil).to_a     # => []
      #
      # @example With negatable: true (flag or value with negation)
      #   args_def = Arguments.define do
      #     flag_or_value_option :verify, negatable: true
      #   end
      #   args_def.bind(verify: true).to_a      # => ['--verify']
      #   args_def.bind(verify: false).to_a     # => ['--no-verify']
      #   args_def.bind(verify: "KEYID").to_a   # => ['--verify', 'KEYID']
      #   args_def.bind(verify: nil).to_a       # => []
      #
      # @example With negatable: true and inline: true
      #   args_def = Arguments.define do
      #     flag_or_value_option :sign, negatable: true, inline: true
      #   end
      #   args_def.bind(sign: true).to_a    # => ['--sign']
      #   args_def.bind(sign: false).to_a   # => ['--no-sign']
      #   args_def.bind(sign: "KEY").to_a   # => ['--sign=KEY']
      #   args_def.bind(sign: nil).to_a     # => []
      #
      def flag_or_value_option(names, as: nil, type: nil, negatable: false, inline: false,
                               required: false, allow_nil: true)
        option_type = determine_flag_or_value_option_type(negatable, inline)
        register_option(names, type: option_type, as: as, expected_type: type,
                               required: required, allow_nil: allow_nil)
      end

      # Define a key-value option that can be specified multiple times
      #
      # This is useful for git options like --trailer that take key=value pairs
      # and can be repeated. Accepts Hash or Array of arrays for flexible input.
      #
      # @param names [Symbol, Array<Symbol>] the option name(s), first is primary
      #
      # @param as [String, nil] custom option string (e.g., '--trailer')
      #
      # @param key_separator [String] separator between key and value (default: '=')
      #
      # @param inline [Boolean] when true, outputs --flag=key=value instead of --flag key=value
      #
      # @param required [Boolean] whether the option must be provided (key must exist in opts).
      #   Note: empty hash/array is considered "present" and produces no output without error.
      #
      # @param allow_nil [Boolean] whether nil is allowed when required is true
      #
      # @return [void]
      #
      # @raise [ArgumentError] if array input is not a [key, value] pair or array of pairs
      #
      # @raise [ArgumentError] if a sub-array has more than 2 elements
      #
      # @raise [ArgumentError] if a key is nil, empty, or contains the separator
      #
      # @raise [ArgumentError] if a value is a Hash or Array (non-scalar)
      #
      # @raise [ArgumentError] if defined after a '--' separator boundary
      #
      # @example Basic key-value (like --trailer)
      #   args_def = Arguments.define do
      #     key_value_option :trailers, as: '--trailer'
      #   end
      #   args_def.bind(trailers: { 'Signed-off-by' => 'John' }).to_a
      #   # => ['--trailer', 'Signed-off-by=John']
      #
      # @example Hash with array values (multiple values for same key)
      #   args_def = Arguments.define do
      #     key_value_option :trailers, as: '--trailer'
      #   end
      #   args_def.bind(trailers: { 'Signed-off-by' => ['John', 'Jane'] }).to_a
      #   # => ['--trailer', 'Signed-off-by=John', '--trailer', 'Signed-off-by=Jane']
      #
      # @example Array of arrays (full ordering control)
      #   args_def = Arguments.define do
      #     key_value_option :trailers, as: '--trailer'
      #   end
      #   args_def.bind(trailers: [['Signed-off-by', 'John'], ['Acked-by', 'Bob']]).to_a
      #   # => ['--trailer', 'Signed-off-by=John', '--trailer', 'Acked-by=Bob']
      #
      # @example Key without value (nil value omits separator)
      #   args_def = Arguments.define do
      #     key_value_option :trailers, as: '--trailer'
      #   end
      #   args_def.bind(trailers: [['Acked-by', nil]]).to_a
      #   # => ['--trailer', 'Acked-by']
      #
      # @example Nil in array values produces key-only entries
      #   args_def = Arguments.define do
      #     key_value_option :trailers, as: '--trailer'
      #   end
      #   args_def.bind(trailers: { 'Key' => ['Value1', nil, 'Value2'] }).to_a
      #   # => ['--trailer', 'Key=Value1', '--trailer', 'Key', '--trailer', 'Key=Value2']
      #
      # @example With custom separator
      #   args_def = Arguments.define do
      #     key_value_option :trailers, as: '--trailer', key_separator: ': '
      #   end
      #   args_def.bind(trailers: { 'Signed-off-by' => 'John' }).to_a
      #   # => ['--trailer', 'Signed-off-by: John']
      #
      # @example Empty values produce no output
      #   args_def = Arguments.define do
      #     key_value_option :trailers, as: '--trailer', required: true
      #   end
      #   args_def.bind(trailers: {}).to_a   # => []
      #   args_def.bind(trailers: []).to_a   # => []
      #   args_def.bind(trailers: nil).to_a  # => []
      #
      def key_value_option(names, as: nil, key_separator: '=', inline: false, required: false, allow_nil: true)
        option_type = inline ? :inline_key_value : :key_value
        register_option(names, type: option_type, as: as, key_separator: key_separator,
                               required: required, allow_nil: allow_nil)
      end

      # Define a literal string that is always included in the output
      #
      # Literals are output at their definition position (not grouped at the start).
      # This allows precise control over argument ordering, which is important for
      # git commands where argument position matters.
      #
      # @param flag_string [String] the static flag string (e.g., '--', '--no-progress')
      #
      # @return [void]
      #
      # @example Static flag for subcommand mode
      #   args_def = Arguments.define do
      #     literal '--delete'
      #     flag_option :force
      #     operand :branches, repeatable: true
      #   end
      #   args_def.bind('feature', force: true).to_a  # => ['--delete', '--force', 'feature']
      #
      # @example Static separator between options and pathspecs
      #   args_def = Arguments.define do
      #     flag_option :force
      #     operand :tree_ish
      #     literal '--'
      #     operand :paths, repeatable: true
      #   end
      #   args_def.bind('HEAD', 'file.txt', force: true).to_a
      #   # => ['--force', 'HEAD', '--', 'file.txt']
      #
      def literal(flag_string)
        @ordered_definitions << { kind: :static, flag: flag_string }
        @past_separator = true if flag_string == '--'
      end

      # Define a custom option with a custom builder block
      #
      # @param names [Symbol, Array<Symbol>] the option name(s), first is primary
      #
      # @param required [Boolean] whether the option must be provided (key must exist in opts)
      #
      # @param allow_nil [Boolean] whether nil is allowed when required is true. Defaults to true.
      #   When false with required: true, raises ArgumentError if value is nil.
      #
      # @yield [value] block that receives the option value and returns the argument string
      #
      # @return [void]
      #
      # @raise [ArgumentError] if defined after a '--' separator boundary
      #
      def custom_option(names, required: false, allow_nil: true, &block)
        register_option(names, type: :custom, builder: block, required: required, allow_nil: allow_nil)
      end

      # Define an execution option (not included in CLI output, forwarded to command execution)
      #
      # @param names [Symbol, Array<Symbol>] the option name(s), first is primary
      #
      # @return [void]
      #
      def execution_option(names)
        register_option(names, type: :execution_option)
      end

      # Declare that arguments conflict with each other (mutually exclusive)
      #
      # Each call to {#conflicts} defines a separate group of mutually exclusive
      # arguments. Names may refer to **options** (flag, value, flag-or-value, etc.)
      # or **operands** (positional arguments). When {#bind} is called, if more than
      # one argument in the same conflict group is "present", an ArgumentError is
      # raised.
      #
      # **Presence semantics** — an argument is considered present when its value is
      # not any of: `nil`, `false`, `[]`, `''`. All other values (including `true`,
      # non-empty strings, and non-empty arrays) are considered present.
      #
      # An ArgumentError is raised at definition time if any name given to
      # +conflicts+ is not a known option or operand, catching typos early.
      #
      # The error message has the general form:
      #
      #   "cannot specify :name1 and :name2"
      #
      # @param names [Array<Symbol>] the option/operand names that conflict within
      #   this group
      #
      # @return [void]
      #
      # @raise [ArgumentError] if any name is not a known option or operand
      #
      # @raise [ArgumentError] if more than one argument in the same conflict group
      #   is present when building arguments
      #
      # @example Option-only conflict group
      #   args_def = Arguments.define do
      #     flag_option :gpg_sign
      #     flag_option :no_gpg_sign
      #     flag_option :force
      #     flag_option :no_force
      #     conflicts :gpg_sign, :no_gpg_sign
      #     conflicts :force, :no_force
      #   end
      #   args_def.bind(gpg_sign: true).to_a  # => ['--gpg-sign']
      #
      # @example Mixed option and operand conflict
      #   args_def = Arguments.define do
      #     flag_option %i[merge m], as: '--merge'
      #     operand :tree_ish, required: true, allow_nil: true
      #     operand :paths, repeatable: true, separator: '--'
      #     conflicts :merge, :tree_ish
      #   end
      #   args_def.bind(nil, 'file.txt', merge: true).to_a  # => ['--merge', '--', 'file.txt']
      #   args_def.bind('main', 'file.txt', merge: true)
      #     # => raise ArgumentError, 'cannot specify :merge and :tree_ish'
      #
      def conflicts(*names)
        names.each do |name|
          sym = name.to_sym
          next if known_argument?(sym)

          raise ArgumentError, "unknown argument :#{sym} in conflicts declaration"
        end
        @conflicts << names.map(&:to_sym)
      end

      # Declare that at least one of the named arguments must be present when binding
      #
      # Each call to {#requires_one_of} defines an independent "at least one" group.
      # When {#bind} is called, if none of the arguments in the group is present,
      # an ArgumentError is raised.
      #
      # **Conditional form** — when `when:` is given, the check is only performed if
      # the named trigger argument is present. If the trigger is absent the group is
      # skipped entirely.
      #
      # **Presence semantics** — an argument is considered present when its value is
      # not any of: `nil`, `false`, `[]`, `''`. All other values (including `true`,
      # non-empty strings, and non-empty arrays) are considered present.
      #
      # Names may refer to **options** (flag, value, flag-or-value, etc.) or
      # **operands** (positional arguments) interchangeably. Alias resolution happens
      # before the check, so supplying an alias for one of the named options counts
      # as that option being present.
      #
      # An ArgumentError is raised at definition time if any name (including the
      # `when:` trigger) is not a known option or operand, catching typos early.
      #
      # The error message has the general form (unconditional):
      #
      #   "at least one of :name1, :name2 must be provided"
      #
      # The error message has the general form (conditional, `when:` given):
      #
      #   ":trigger requires at least one of :name1, :name2"
      #
      # @param names [Array<Symbol>] the option/operand names where at least one
      #   must be present
      #
      # @option kwargs [Symbol] :when optional trigger argument; when given, the check is
      #   only performed if the trigger argument is present
      #
      # @return [void]
      #
      # @raise [ArgumentError] if no names are given
      #
      # @raise [ArgumentError] if any name (or the `when:` trigger) is not a known
      #   option or operand
      #
      # @raise [ArgumentError] if none of the arguments in the group is present
      #   when binding arguments (and the trigger, if any, is present)
      #
      # @example At-least-one of two keyword options (unconditional)
      #   args_def = Arguments.define do
      #     value_option :pathspec_from_file, inline: true
      #     value_option :pathspec, as_operand: true, repeatable: true, separator: '--'
      #     requires_one_of :pathspec, :pathspec_from_file
      #   end
      #   args_def.bind(pathspec: ['file.txt']).to_a  # => ['--', 'file.txt']
      #   args_def.bind(pathspec_from_file: 'paths.txt').to_a
      #   # => ['--pathspec-from-file=paths.txt']
      #   args_def.bind
      #     # => raise ArgumentError, 'at least one of :pathspec, :pathspec_from_file must be provided'
      #
      # @example Mixed option and operand group (unconditional)
      #   args_def = Arguments.define do
      #     flag_option :all
      #     operand :paths, repeatable: true
      #     requires_one_of :all, :paths
      #   end
      #   args_def.bind('file.txt').to_a     # passes — :paths is present
      #   args_def.bind(all: true).to_a      # passes — :all is present
      #   args_def.bind
      #     # => raise ArgumentError, 'at least one of :all, :paths must be provided'
      #
      # @example Multiple independent groups (unconditional)
      #   args_def = Arguments.define do
      #     flag_option :commit
      #     flag_option :all
      #     value_option :pathspec_from_file, inline: true
      #     value_option :pathspec, as_operand: true, repeatable: true, separator: '--'
      #     requires_one_of :commit, :all
      #     requires_one_of :pathspec, :pathspec_from_file
      #   end
      #
      # @example Conditional at-least-one-of group (`when:` form)
      #   args_def = Arguments.define do
      #     flag_option :annotate
      #     value_option :message, inline: true
      #     value_option :file, inline: true
      #     requires_one_of :message, :file, when: :annotate
      #   end
      #   args_def.bind(annotate: true, message: 'v1.0').to_a  # passes
      #   args_def.bind(annotate: true)
      #     # => raise ArgumentError, ':annotate requires at least one of :message, :file'
      #   args_def.bind  # trigger absent — no error
      #
      def requires_one_of(*names, **kwargs)
        condition = kwargs.delete(:when)
        raise ArgumentError, "requires_one_of: unknown keyword arguments: #{kwargs.keys.inspect}" unless kwargs.empty?
        raise ArgumentError, 'requires_one_of must be given at least one argument name' if names.empty?

        canonical_group = canonicalize_requires_names(names)
        canonical_condition = resolve_requires_condition(condition)
        @requires_one_of << { names: canonical_group, condition: canonical_condition, single: false }
      end

      # Declare that *name* must be present whenever the trigger argument *when:* is present
      #
      # When {#bind} is called, if the trigger argument is present and *name* is absent,
      # an ArgumentError is raised. If the trigger is absent, the check is skipped.
      #
      # **Presence semantics** — an argument is considered present when its value is
      # not any of: `nil`, `false`, `[]`, `''`. All other values (including `true`,
      # non-empty strings, and non-empty arrays) are considered present.
      #
      # An ArgumentError is raised at definition time if either *name* or the `when:`
      # trigger is not a known option or operand, catching typos early.
      #
      # The error message has the form:
      #
      #   ":trigger requires :name"
      #
      # @param name [Symbol] the option/operand name that must be present
      #
      # @option kwargs [Symbol] :when the trigger argument; when present, *name* must also be present
      #
      # @return [void]
      #
      # @raise [ArgumentError] if `when:` is not provided
      #
      # @raise [ArgumentError] if *name* or the `when:` trigger is not a known option
      #   or operand
      #
      # @raise [ArgumentError] if the trigger is present and *name* is absent when
      #   binding arguments
      #
      # @example Require pathspec_from_file when pathspec_file_nul is present
      #   args_def = Arguments.define do
      #     flag_option :pathspec_file_nul
      #     value_option :pathspec_from_file, inline: true
      #     requires :pathspec_from_file, when: :pathspec_file_nul
      #   end
      #   args_def.bind(pathspec_file_nul: true, pathspec_from_file: 'paths.txt').to_a
      #   # => ['--pathspec-file-nul', '--pathspec-from-file=paths.txt']
      #   args_def.bind(pathspec_file_nul: true)
      #   # => raise ArgumentError, ':pathspec_file_nul requires :pathspec_from_file'
      #   args_def.bind  # trigger absent — no error
      #
      # @example Require dry_run when ignore_missing is present
      #   args_def = Arguments.define do
      #     flag_option :dry_run
      #     flag_option :ignore_missing
      #     requires :dry_run, when: :ignore_missing
      #   end
      #   args_def.bind(ignore_missing: true)
      #   # => raise ArgumentError, ':ignore_missing requires :dry_run'
      #
      def requires(name, **kwargs)
        condition = kwargs.delete(:when)
        raise ArgumentError, 'requires: `when:` keyword is required' unless condition
        raise ArgumentError, "requires: unknown keyword arguments: #{kwargs.keys.inspect}" unless kwargs.empty?

        sym = name.to_sym
        validate_requires_name!(sym)
        canonical_trigger = resolve_requires_condition(condition)
        @requires_one_of << { names: [@alias_map[sym] || sym], condition: canonical_trigger, single: true }
      end

      # rubocop:disable Layout/LineLength

      # Restrict a value option to a fixed set of accepted strings
      #
      # Declares that the named option must only receive values from the given list
      # when a value is provided. Validation runs during {#bind}, after type checking.
      # `nil` and absent values are always skipped. Empty strings are skipped when
      # `allow_empty: true` is set on the option. For `repeatable: true` options
      # each element of the array is validated individually.
      #
      # @param name [Symbol] the option name (primary or alias); must refer to a
      #   previously defined {#value_option} or {#flag_or_value_option}
      #
      # @param in [Array<String>] the accepted string values
      #
      # @return [void]
      #
      # @raise [ArgumentError] if +name+ is not a known option at definition time
      #
      # @raise [ArgumentError] if +name+ refers to a non-value option (e.g., a flag)
      #
      # @raise [ArgumentError] during {#bind} if the bound value is not in the
      #   accepted set, with a message of the form:
      #   `"Invalid value for :name: expected one of [...], got \"actual\""`
      #
      # @example Constrain chmod to '+x' or '-x'
      #   args_def = Arguments.define do
      #     value_option :chmod, inline: true
      #     allowed_values :chmod, in: ['+x', '-x']
      #   end
      #   args_def.bind(chmod: '+x').to_a   # => ['--chmod=+x']
      #   args_def.bind(chmod: 'rx')
      #     # => raise ArgumentError, 'Invalid value for :chmod: expected one of ["+x", "-x"], got "rx"'
      #   args_def.bind.to_a              # => []  # (absent — no error)
      #
      # @example Constrain cleanup to an enumerated set
      #   args_def = Arguments.define do
      #     value_option :cleanup, inline: true
      #     allowed_values :cleanup, in: %w[verbatim whitespace strip]
      #   end
      #   args_def.bind(cleanup: 'verbatim').to_a  # => ['--cleanup=verbatim']
      #   args_def.bind(cleanup: 'compact')
      #     # => raise ArgumentError, 'Invalid value for :cleanup: expected one of ["verbatim", "whitespace", "strip"], got "compact"'
      #
      # @example Repeatable option — each element is validated
      #   args_def = Arguments.define do
      #     value_option :strategy, inline: true, repeatable: true
      #     allowed_values :strategy, in: %w[ours theirs]
      #   end
      #   args_def.bind(strategy: %w[ours theirs]).to_a
      #     # => ['--strategy=ours', '--strategy=theirs']
      #   args_def.bind(strategy: %w[ours other])
      #     # => raise ArgumentError, 'Invalid value for :strategy: expected one of ["ours", "theirs"], got "other"'
      #
      def allowed_values(name, in:)
        sym = name.to_sym
        defn = validate_allowed_values_definition!(sym)
        defn[:allowed_values] = coerce_allowed_values_set!(sym, binding.local_variable_get(:in))
      end

      # rubocop:enable Layout/LineLength

      # Define an operand (positional argument in Ruby terminology)
      #
      # Operands are mapped to values following Ruby method signature
      # semantics. Required operands before a repeatable are filled left-to-right,
      # required operands after a repeatable are filled from the end, and the
      # repeatable gets whatever remains in the middle.
      #
      # @param name [Symbol] the operand name (used in error messages)
      #
      # @param required [Boolean] whether the argument is required. For repeatable
      #   operands, this means at least one value must be provided.
      #
      # @param repeatable [Boolean] whether the argument accepts multiple values
      #   (like Ruby's splat operator *args). Only one repeatable operand is
      #   allowed per definition; attempting to define a second will raise an
      #   ArgumentError.
      #
      # @param default [Object] the default value if not provided. For repeatable
      #   operands, this should be an array (e.g., `default: ['.']`).
      #
      # @param separator [String, nil] separator string to insert before this
      #   operand in the output (e.g., '--' for the common pathspec separator)
      #
      # @param allow_nil [Boolean] whether nil is a valid value for a required
      #   operand. When true, nil consumes the operand slot but is omitted
      #   from output. This is useful for commands like `git checkout` where
      #   the tree-ish is required to consume a slot but may be nil to restore
      #   from the index. Defaults to false.
      #
      # @return [void]
      #
      # @example Required operand (like `def clone(repository)`)
      #   args_def = Arguments.define do
      #     operand :repository, required: true
      #   end
      #   args_def.bind('https://github.com/user/repo').to_a
      #   # => ['https://github.com/user/repo']
      #
      # @example Optional operand with default (like `def log(commit = 'HEAD')`)
      #   args_def = Arguments.define do
      #     operand :commit, default: 'HEAD'
      #   end
      #   args_def.bind().to_a        # => ['HEAD']
      #   args_def.bind('main').to_a  # => ['main']
      #
      # @example Repeatable operand (like `def add(*paths)`)
      #   args_def = Arguments.define do
      #     operand :paths, repeatable: true
      #   end
      #   args_def.bind('file1', 'file2', 'file3').to_a
      #   # => ['file1', 'file2', 'file3']
      #
      # @example Required repeatable with at least one value (like `def rm(*paths)` with validation)
      #   args_def = Arguments.define do
      #     operand :paths, repeatable: true, required: true
      #   end
      #   args_def.bind() #=> raise ArgumentError, "at least one value is required for paths"
      #   args_def.bind('file1').to_a  # => ['file1']
      #
      # @example git mv pattern (like `def mv(*sources, destination)`)
      #   args_def = Arguments.define do
      #     operand :sources, repeatable: true, required: true
      #     operand :destination, required: true
      #   end
      #   args_def.bind('src1', 'src2', 'dest').to_a  # => ['src1', 'src2', 'dest']
      #   args_def.bind('src', 'dest').to_a           # => ['src', 'dest']
      #
      # @example Optional before variadic with required after (like `def foo(a = 'default', *middle, b)`)
      #   args_def = Arguments.define do
      #     operand :a, default: 'default_a'
      #     operand :middle, repeatable: true
      #     operand :b, required: true
      #   end
      #   args_def.bind('x').to_a           # => ['default_a', 'x']
      #   args_def.bind('x', 'y').to_a      # => ['x', 'y']
      #   args_def.bind('x', 'm', 'y').to_a # => ['x', 'm', 'y']
      #
      # @example Operand with separator (pathspec after --)
      #   args_def = Arguments.define do
      #     flag_option :force
      #     operand :paths, repeatable: true, separator: '--'
      #   end
      #   args_def.bind('file1', 'file2', force: true).to_a
      #   # => ['--force', '--', 'file1', 'file2']
      #
      # @example Complex pattern (like `def diff(commit1, commit2 = nil, *paths)`)
      #   args_def = Arguments.define do
      #     operand :commit1, required: true
      #     operand :commit2
      #     operand :paths, repeatable: true, separator: '--'
      #   end
      #   args_def.bind('HEAD~1').to_a  # => ['HEAD~1']
      #   args_def.bind('HEAD~1', 'HEAD').to_a  # => ['HEAD~1', 'HEAD']
      #   args_def.bind('HEAD~1', 'HEAD', 'file.rb').to_a
      #   # => ['HEAD~1', 'HEAD', '--', 'file.rb']
      #
      # @example Required operand that allows nil (like `git checkout [tree-ish] -- paths`)
      #   args_def = Arguments.define do
      #     operand :tree_ish, required: true, allow_nil: true
      #     operand :paths, repeatable: true, separator: '--'
      #   end
      #   args_def.bind(nil, 'file1.txt', 'file2.txt').to_a
      #   # => ['--', 'file1.txt', 'file2.txt']
      #   args_def.bind('HEAD', 'file.rb').to_a
      #   # => ['HEAD', '--', 'file.rb']
      #   args_def.bind(nil, 'file.rb').to_a
      #   # => ['--', 'file.rb']
      #
      # @raise [ArgumentError] if the operand appears before a '--' boundary (or no
      #   boundary exists) and the bound value starts with '-'
      #
      def operand(name, required: false, repeatable: false, default: nil, separator: nil, allow_nil: false)
        validate_single_repeatable!(name) if repeatable
        add_operand_definition(name, required, repeatable, default, separator, allow_nil)
      end

      # Bind positionals and options, returning a Bound object with accessor methods
      #
      # Unlike the internal build method which returns a raw Array, this method
      # returns a {Bound} object that:
      # - Provides accessor methods for all defined options and positional arguments
      # - Automatically normalizes option aliases to their canonical names
      # - Supports splatting via `to_ary` for seamless use with `command(*bound)`
      #
      # @param positionals [Array] positional argument values
      #
      # @param opts [Hash] the keyword options
      #
      # @return [Bound] a frozen object with accessor methods for all arguments
      #
      # @raise [ArgumentError] if unsupported options are provided or validation fails
      #
      # @raise [ArgumentError] if an operand value before a '--' boundary starts with '-'
      #
      # @example Simple splatting (same behavior as build)
      #   def call(*, **)
      #     @execution_context.command(*ARGS.bind(*, **))
      #   end
      #
      # @example Inspecting options before command execution
      #   args_def = Arguments.define do
      #     flag_option :force
      #     flag_option :remotes, as: ['-r', '--remotes']
      #     operand :branch_names, repeatable: true
      #   end
      #   bound_args = args_def.bind('branch1', 'branch2', force: true, remotes: true)
      #   bound_args.force?         # => true
      #   bound_args.remotes?       # => true
      #   bound_args.branch_names   # => ['branch1', 'branch2']
      #
      # @example Hash-style access for reserved names
      #   args_def = Arguments.define do
      #     value_option :hash
      #   end
      #   bound_args = args_def.bind(hash: 'abc123')
      #   bound_args[:hash]  # => 'abc123'
      #
      def bind(*positionals, **opts)
        normalized_opts = validate_and_normalize_options!(opts)
        allocated_positionals = allocate_and_validate_positionals(positionals)
        validate_no_option_like_operands!(allocated_positionals, normalized_opts)
        validate_conflicts!(normalized_opts, allocated_positionals)
        validate_requires_one_of!(normalized_opts, allocated_positionals)

        args_array = build_ordered_arguments(allocated_positionals, normalized_opts)
        options_hash = build_options_hash(normalized_opts)
        execution_option_names = option_names_by_type(:execution_option)
        flag_names = option_names_by_type(:flag, :negatable_flag)

        Bound.new(args_array, options_hash, allocated_positionals, execution_option_names, flag_names)
      end

      # Option types allowed after a '--' separator boundary (they do not produce CLI flags)
      OPTION_TYPES_AFTER_SEPARATOR = %i[value_as_operand execution_option].freeze

      # Option types that accept a string value — eligible for `allowed_values` constraints
      VALUE_OPTION_TYPES_FOR_ALLOWED_VALUES = %i[
        value inline_value value_as_operand
        flag_or_value flag_or_inline_value
        negatable_flag_or_value negatable_flag_or_inline_value
      ].freeze

      # The subset of VALUE_OPTION_TYPES_FOR_ALLOWED_VALUES whose boolean values
      # carry semantic meaning (true = emit flag, false = suppress flag) and must
      # skip allowed_values validation rather than being compared against the set.
      FLAG_OR_VALUE_OPTION_TYPES = %i[
        flag_or_value flag_or_inline_value
        negatable_flag_or_value negatable_flag_or_inline_value
      ].freeze

      private

      # Collect option names whose definition type is one of the given types
      #
      # @param types [Array<Symbol>] the option types to match
      #
      # @return [Array<Symbol>]
      #
      def option_names_by_type(*types)
        @option_definitions.each_with_object([]) do |(name, definition), names|
          names << name if types.include?(definition[:type])
        end
      end

      # Validate and normalize keyword options
      #
      # @param opts [Hash] raw keyword options
      # @return [Hash] normalized options with aliases resolved
      # @raise [ArgumentError] if options are unsupported, conflicting, or invalid
      #
      def validate_and_normalize_options!(opts)
        validate_unsupported_options!(opts)
        validate_conflicting_aliases!(opts)
        normalized_opts = normalize_aliases(opts)
        validate_required_options!(normalized_opts)
        validate_option_values!(normalized_opts)
        normalized_opts
      end

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

      # Determine the internal option type based on inline and as_operand modifiers
      #
      # @param inline [Boolean] whether to use inline format (--flag=value)
      # @param as_operand [Boolean] whether to output as operand (positional argument)
      # @return [Symbol] the internal option type
      #
      def determine_value_option_type(inline, as_operand)
        if as_operand
          :value_as_operand
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
      # @param as_operand [Boolean] whether as_operand: true was specified
      # @param separator [String, nil] separator string if specified
      # @raise [ArgumentError] if invalid modifier combination is used
      #
      def validate_value_modifiers!(names, inline, as_operand, separator)
        primary = Array(names).first
        raise ArgumentError, "inline: and as_operand: cannot both be true for :#{primary}" if inline && as_operand

        return unless separator && !as_operand

        raise ArgumentError, "separator: is only valid with as_operand: true for :#{primary}"
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
        validate_option_after_separator!(definition[:type], primary)
        validate_as_parameter!(definition, primary)
        apply_type_validator!(definition, primary)
        @option_definitions[primary] = definition
        keys.each { |key| @alias_map[key] = primary }
        @ordered_definitions << { kind: :option, name: primary }
        @past_separator = true if definition[:separator] == '--'
      end

      # Validate that flag-producing options are not defined after a '--' boundary
      #
      # @param type [Symbol] the option type
      # @param option_name [Symbol] the primary option name
      # @raise [ArgumentError] if a flag-producing option is defined after '--'
      #
      def validate_option_after_separator!(type, option_name)
        return unless @past_separator
        return if OPTION_TYPES_AFTER_SEPARATOR.include?(type)

        raise ArgumentError,
              "option :#{option_name} cannot be defined after a '--' separator " \
              'boundary because its flags would be treated as operands by git'
      end

      def apply_type_validator!(definition, option_name)
        return unless definition[:expected_type]

        if definition[:validator]
          raise ArgumentError,
                "cannot specify both type: and validator: for :#{option_name}"
        end

        definition[:validator] = create_type_validator(option_name, definition[:expected_type])
      end

      def validate_as_parameter!(definition, option_name)
        return unless definition[:as].is_a?(Array)

        if definition[:type] == :negatable_flag
          raise ArgumentError,
                "arrays for as: parameter cannot be combined with negatable: true (option :#{option_name})"
        end

        return if definition[:type] == :flag

        type = definition[:type]
        raise ArgumentError,
              "arrays for as: parameter are only supported for flag types, not :#{type} (option :#{option_name})"
      end

      # Build arguments by iterating over definitions in their defined order
      #
      # @param allocated_positionals [Hash] the allocated positional values
      # @param normalized_opts [Hash] normalized keyword options
      # @return [Array<String>] the command-line arguments
      #
      def build_ordered_arguments(allocated_positionals, normalized_opts)
        args = []

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
        @past_separator = true if separator == '--'
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
        value_as_operand: lambda do |args, _, value, definition|
          # Validate array usage when repeatable is false
          if value.is_a?(Array) && !definition[:repeatable]
            raise ArgumentError,
                  "value_as_operand :#{definition[:aliases].first} requires repeatable: true to accept an array"
          end

          # Validate no nil values in array
          if definition[:repeatable] && value.is_a?(Array) && value.any?(&:nil?)
            raise ArgumentError,
                  "nil values are not allowed in value_as_operand :#{definition[:aliases].first}"
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
        execution_option: ->(*) {}
      }.freeze
      private_constant :BUILDERS

      def build_option(args, name, definition, value)
        return if should_skip_option?(value, definition)

        arg_spec = definition[:as] || default_arg_spec(name)
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
        return skip_value_as_operand_array?(value, definition) if value.is_a?(Array)

        value.respond_to?(:empty?) && value.empty? && !definition[:allow_empty]
      end

      # For value_as_operand, empty arrays always skip regardless of allow_empty
      # (allow_empty only applies to empty strings, not empty arrays)
      def skip_value_as_operand_array?(value, definition)
        return value.empty? if definition[:type] == :value_as_operand

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

      # Reject operand values that look like command-line options
      #
      # Operands appearing before a '--' separator boundary (or all operands
      # if no separator exists) are validated to ensure they don't start with
      # a hyphen, which could be misinterpreted as a git option.
      #
      # A separator boundary defined via `separator: '--'` on an operand or
      # value_option is only considered active when the associated value will
      # cause the separator to be emitted. If the value is nil or empty (meaning
      # the separator will be omitted at runtime), operands past that definition
      # are still validated.
      #
      # @param allocation [Hash{Symbol => Object}] the allocated operand values
      # @param normalized_opts [Hash] the normalized keyword options
      # @raise [ArgumentError] if any pre-separator operand value starts with '-'
      #
      def validate_no_option_like_operands!(allocation, normalized_opts)
        pre_separator_operands = operand_names_before_separator(allocation, normalized_opts)
        pre_separator_operands.each do |name|
          value = allocation[name]
          check_operand_not_option_like(name, value)
        end
      end

      # Determine which operands appear before any '--' separator boundary
      #
      # Walks the ordered definitions and collects operand names until hitting
      # a literal '--' or an operand/option with separator: '--' whose value
      # will cause the separator to be emitted. If the separator-defining entry
      # has a nil or empty value, the boundary is not active and the walk
      # continues past it.
      #
      # @param allocation [Hash{Symbol => Object}] the allocated operand values
      # @param normalized_opts [Hash] the normalized keyword options
      # @return [Array<Symbol>] operand names that need option-like validation
      #
      def operand_names_before_separator(allocation, normalized_opts)
        names = []
        @ordered_definitions.each do |defn|
          break if separator_boundary_active?(defn, allocation, normalized_opts)

          names << defn[:name] if defn[:kind] == :operand
        end
        names
      end

      # Check if a definition represents an active '--' separator boundary
      #
      # A `literal '--'` is always active. An operand or option with
      # `separator: '--'` is only active when its bound value will cause
      # the separator to be emitted (i.e., the value is not nil/empty).
      #
      # @param defn [Hash] a definition entry from @ordered_definitions
      # @param allocation [Hash{Symbol => Object}] the allocated operand values
      # @param normalized_opts [Hash] the normalized keyword options
      # @return [Boolean] true if this definition is an active '--' boundary
      #
      def separator_boundary_active?(defn, allocation, normalized_opts)
        return true if defn[:kind] == :static && defn[:flag] == '--'
        return true if defn[:kind] == :operand && operand_separator_active?(defn[:name], allocation)
        return true if defn[:kind] == :option && option_separator_active?(defn[:name], normalized_opts)

        false
      end

      # Check if an operand with separator: '--' will emit its separator
      #
      # @param name [Symbol] the operand name
      # @param allocation [Hash{Symbol => Object}] the allocated operand values
      # @return [Boolean] true if the operand has separator: '--' and its value is present
      #
      def operand_separator_active?(name, allocation)
        operand_def = @operand_definitions.find { |d| d[:name] == name }
        return false unless operand_def&.dig(:separator) == '--'

        !positional_value_empty?(allocation[name], operand_def)
      end

      # Check if an option with separator: '--' will emit its separator
      #
      # @param name [Symbol] the option name
      # @param normalized_opts [Hash] the normalized keyword options
      # @return [Boolean] true if the option has separator: '--' and its value is present
      #
      def option_separator_active?(name, normalized_opts)
        option_def = @option_definitions[name]
        return false unless option_def&.dig(:separator) == '--'

        !should_skip_option?(normalized_opts[name], option_def)
      end

      # Check that a single operand value does not look like a command-line option
      #
      # @param name [Symbol] the operand name
      # @param value [Object] the operand value
      # @raise [ArgumentError] if the value starts with '-'
      #
      def check_operand_not_option_like(name, value)
        case value
        when String
          raise_option_like_error(name, value) if value.start_with?('-')
        when Array
          raise_option_like_array_error(name, value)
        end
      end

      # @raise [ArgumentError] if the string value starts with '-'
      def raise_option_like_error(name, value)
        raise ArgumentError, "operand :#{name} value '#{value}' looks like a command-line option"
      end

      # @raise [ArgumentError] if any array element starts with '-'
      def raise_option_like_array_error(name, values)
        invalid = values.select { |v| v.is_a?(String) && v.start_with?('-') }
        return if invalid.empty?

        raise ArgumentError,
              "operand :#{name} contains option-like values: #{invalid.map { |v| "'#{v}'" }.join(', ')}"
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
          next unless opts.key?(name)

          validate_single_option!(name, opts[name], definition)
        end
      end

      def validate_single_option!(name, value, definition)
        run_validator!(name, value, definition[:validator]) if definition[:validator]
        check_allowed_values!(name, value, definition) if definition[:allowed_values]
      end

      def run_validator!(name, value, validator)
        result = validator.call(value)
        return if result == true

        error_msg = result.is_a?(String) ? result : "Invalid value for option: #{name}"
        raise ArgumentError, error_msg
      end

      def check_allowed_values!(name, value, definition)
        allowed = definition[:allowed_values]
        type = definition[:type]
        if definition[:repeatable]
          check_repeatable_allowed_values!(name, value, allowed, definition[:allow_empty], type)
        else
          check_single_allowed_value!(name, value, allowed, definition[:allow_empty], type)
        end
      end

      def coerce_allowed_values_set!(sym, values)
        unless values.respond_to?(:map)
          raise ArgumentError,
                "allowed_values :#{sym} expects an Enumerable for `in:`, got #{values.class}"
        end
        arr = values.map(&:to_s)
        raise ArgumentError, "allowed_values :#{sym} must specify at least one allowed value" if arr.empty?

        arr.freeze
      end

      def validate_allowed_values_definition!(sym)
        primary = @alias_map[sym]
        defn = primary && @option_definitions[primary]
        unless defn
          raise ArgumentError, ":#{sym} is not a value option" if @operand_definitions.any? { |d| d[:name] == sym }

          raise ArgumentError, "unknown argument :#{sym} in allowed_values declaration"
        end
        unless VALUE_OPTION_TYPES_FOR_ALLOWED_VALUES.include?(defn[:type])
          raise ArgumentError, ":#{sym} is not a value option"
        end

        defn
      end

      def check_repeatable_allowed_values!(name, values, allowed, allow_empty, type)
        Array(values).each do |v|
          next if skip_allowed_values_check?(v, allow_empty, type)

          unless allowed.include?(v.to_s)
            raise ArgumentError,
                  "Invalid value for :#{name}: expected one of #{allowed.inspect}, got #{v.inspect}"
          end
        end
      end

      def check_single_allowed_value!(name, value, allowed, allow_empty, type)
        return if skip_allowed_values_check?(value, allow_empty, type)

        return if allowed.include?(value.to_s)

        raise ArgumentError,
              "Invalid value for :#{name}: expected one of #{allowed.inspect}, got #{value.inspect}"
      end

      def skip_allowed_values_check?(value, allow_empty, type)
        return true if value.nil?
        # Only skip boolean values for flag_or_value option types where true/false carry
        # semantic meaning (true = emit flag, false = suppress flag). For plain value
        # options, a boolean is an invalid value and should fail the allowed_values check.
        return true if [true, false].include?(value) && FLAG_OR_VALUE_OPTION_TYPES.include?(type)
        return true if value.to_s.empty? && allow_empty

        false
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

      def validate_conflicts!(opts, allocated_positionals = {})
        @conflicts.each do |conflict_group|
          provided = conflict_group.select do |name|
            value = opts.key?(name) ? opts[name] : allocated_positionals[name]
            argument_present?(value)
          end
          next if provided.size <= 1

          formatted = provided.map { |name| ":#{name}" }.join(' and ')
          raise ArgumentError, "cannot specify #{formatted}"
        end
      end

      # Validate conditional and unconditional requires_one_of groups
      #
      # Each entry in @requires_one_of is a Hash with keys:
      #   :names     — Array of canonical argument names that must collectively satisfy
      #                the at-least-one constraint
      #   :condition — canonical trigger name (Symbol), or nil for unconditional groups
      #   :single    — true when declared via `requires` (affects error message wording)
      #
      # @param opts [Hash] normalized keyword options (aliases already resolved)
      # @param allocated_positionals [Hash] the allocated positional values
      # @raise [ArgumentError] if none of the arguments in any applicable group is present
      #
      def validate_requires_one_of!(opts, allocated_positionals = {})
        @requires_one_of.each do |entry|
          validate_requires_one_of_entry!(entry, opts, allocated_positionals)
        end
      end

      # Validate a single requires_one_of entry
      #
      # @param entry [Hash] the group entry with :names, :condition, :single keys
      # @param opts [Hash] normalized keyword options
      # @param allocated_positionals [Hash] the allocated positional values
      #
      def validate_requires_one_of_entry!(entry, opts, allocated_positionals)
        condition = entry[:condition]

        if condition
          trigger_value = opts.key?(condition) ? opts[condition] : allocated_positionals[condition]
          return unless argument_present?(trigger_value)
        end

        names = entry[:names]
        return if names.any? { |n| argument_present?(opts.key?(n) ? opts[n] : allocated_positionals[n]) }

        raise ArgumentError, requires_one_of_error_message(names, condition, entry[:single])
      end

      # Build the error message for a failed requires_one_of check
      #
      # @param names [Array<Symbol>] the required argument names
      # @param condition [Symbol, nil] the trigger argument name, or nil for unconditional
      # @param single [Boolean] true when declared via `requires` (single required arg)
      # @return [String] the error message
      #
      def requires_one_of_error_message(names, condition, single)
        formatted = names.map { |name| ":#{name}" }.join(', ')
        return "at least one of #{formatted} must be provided" unless condition
        return ":#{condition} requires #{formatted}" if single

        ":#{condition} requires at least one of #{formatted}"
      end

      # Validate a single name used in a requires_one_of declaration
      #
      # @param sym [Symbol] the name to validate
      # @raise [ArgumentError] if sym is not a known option or operand
      #
      def validate_requires_one_of_name!(sym)
        raise ArgumentError, "unknown argument :#{sym} in requires_one_of declaration" unless known_argument?(sym)
      end

      # Validate a single name used in a requires or conditional requires_one_of declaration
      #
      # @param sym [Symbol] the name to validate
      # @raise [ArgumentError] if sym is not a known option or operand
      #
      def validate_requires_name!(sym)
        raise ArgumentError, "unknown argument :#{sym} in requires declaration" unless known_argument?(sym)
      end

      # Canonicalize an array of argument names for a requires_one_of group
      #
      # Validates each name, resolves aliases to their primary name, and deduplicates.
      # For options, canonical name comes from alias_map; for positional-only operands
      # the name is used directly.
      #
      # @param names [Array<Symbol, String>] raw argument names
      # @return [Array<Symbol>] canonical, deduplicated names
      #
      def canonicalize_requires_names(names)
        names.map do |name|
          sym = name.to_sym
          validate_requires_one_of_name!(sym)
          @alias_map[sym] || sym
        end.uniq
      end

      # Validate and canonicalize the `when:` condition for requires/requires_one_of
      #
      # @param condition [Symbol, nil] the raw trigger argument name
      # @return [Symbol, nil] canonical trigger name, or nil when condition is nil
      #
      def resolve_requires_condition(condition)
        return nil unless condition

        trigger_sym = condition.to_sym
        validate_requires_name!(trigger_sym)
        @alias_map[trigger_sym] || trigger_sym
      end

      # Return true if the given name refers to a defined option or operand
      #
      # @param name [Symbol] the argument name to look up
      # @return [Boolean]
      def known_argument?(name)
        @alias_map.key?(name) || @operand_definitions.any? { |d| d[:name] == name }
      end

      # Return true if a conflict-group value should be considered "present"
      #
      # A value is absent (not present) when it is nil, false, an empty array,
      # or an empty string. All other values are present.
      #
      # @param value [Object] the argument value to test
      # @return [Boolean]
      def argument_present?(value)
        return false if value.nil?
        return false if value == false
        return false if value == []
        return false if value == ''

        true
      end

      # Bound arguments object returned by {Arguments#bind}
      #
      # Provides accessor methods for all defined options and positional arguments,
      # with automatic normalization of aliases to their canonical names.
      #
      # For every `flag_option`, both a plain accessor (e.g. `bound.force`) and a
      # `?`-suffixed predicate alias (e.g. `bound.force?`) are generated, following
      # Ruby convention for boolean predicates. Plain accessors are kept for backward
      # compatibility. `value_option` fields only receive plain accessors.
      #
      # **Reserved-name exception:** if the `?`-suffixed name conflicts with a name
      # in {RESERVED_NAMES} (e.g. `nil?`, `frozen?`), the predicate alias is *not*
      # generated to avoid overriding built-in `Object` methods. Use hash-style
      # access (`bound[:nil]`) when the flag name is reserved.
      #
      # @api private
      #
      # @example Accessing bound arguments
      #   args_def = Arguments.define do
      #     flag_option :force
      #     flag_option :remotes, as: ['-r', '--remotes']
      #     operand :branch_names, repeatable: true
      #   end
      #   bound = args_def.bind('branch1', 'branch2', force: true, remotes: true)
      #   bound.force          # => true
      #   bound.force?         # => true   # ? alias for flag_option
      #   bound.remotes        # => true
      #   bound.remotes?       # => true   # ? alias for flag_option
      #   bound.branch_names   # => ['branch1', 'branch2']
      #
      # @example Splatting for command execution
      #   args_def = Arguments.define do
      #     flag_option :force
      #     operand :file
      #   end
      #   bound = args_def.bind('test.txt', force: true)
      #   bound.to_a  # => ['--force', 'test.txt']
      #
      # @example Hash-style access for reserved names
      #   args_def = Arguments.define do
      #     value_option :hash
      #   end
      #   bound = args_def.bind(hash: 'abc123')
      #   bound[:hash]  # => 'abc123'
      #
      class Bound
        # Names that cannot have accessor methods defined (would override Object methods)
        RESERVED_NAMES = (Object.instance_methods + [:to_ary]).freeze

        # Canonical frozen empty hash returned by {#execution_options} when no
        # non-nil execution options are present.
        #
        # @return [Hash{Symbol => Object}]
        EMPTY_EXECUTION_OPTIONS = {}.freeze

        # Execution options and values for command execution.
        #
        # Includes only options declared via {Arguments#execution_option} and
        # excludes options with nil values.
        #
        # @return [Hash{Symbol => Object}] frozen hash of execution option values
        # @!attribute [r] execution_options
        attr_reader :execution_options

        # @param args_array [Array<String>] the CLI argument array (frozen)
        # @param options [Hash{Symbol => Object}] normalized options hash (frozen)
        # @param positionals [Hash{Symbol => Object}] positional arguments hash (frozen)
        # @param execution_option_names [Array<Symbol>] option names declared via {Arguments#execution_option}
        # @param flag_names [Array<Symbol>] option names declared via {Arguments#flag_option}
        #
        def initialize(args_array, options, positionals, execution_option_names = [], flag_names = [])
          @args_array = args_array.freeze
          @options = options.freeze
          @positionals = positionals.freeze
          @execution_options = build_execution_options(execution_option_names)

          # Define accessor methods (skip reserved names)
          @options.each_key { |name| define_accessor(name, @options) }
          @positionals.each_key { |name| define_accessor(name, @positionals) }
          define_flag_predicate_accessors(flag_names)

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

        def build_execution_options(execution_option_names)
          result = execution_option_names.each_with_object({}) do |name, values|
            value = @options[name]
            values[name] = value unless value.nil?
          end

          result.empty? ? EMPTY_EXECUTION_OPTIONS : result.freeze
        end

        # Define an accessor method for the given name
        #
        # For `flag_option` names, a `?`-suffixed predicate alias is also defined
        # by {#initialize} after all plain accessors have been set up.
        #
        # @param name [Symbol] the option or positional name
        # @param source [Hash] the hash to read from (@options or @positionals)
        #
        def define_accessor(name, source)
          return if RESERVED_NAMES.include?(name)

          define_singleton_method(name) { source[name] }
        end

        # Define `?`-suffixed predicate aliases for each flag option
        #
        # Skips any name whose `?` form appears in {RESERVED_NAMES} and skips
        # names that are not present in the options hash.
        #
        # @param flag_names [Array<Symbol>] flag option names
        #
        def define_flag_predicate_accessors(flag_names)
          flag_names.each do |name|
            predicate_name = :"#{name}?"
            next if RESERVED_NAMES.include?(predicate_name)
            next unless @options.key?(name)

            define_singleton_method(predicate_name) { @options[name] }
          end
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
    # rubocop:enable Metrics/ParameterLists
  end
end
