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
    # | ---------------------- | ---------------------- | --------------------------------------------------- |
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
    # Use {#end_of_options} to emit `--` only when at least one following operand
    # produces output, or {#literal} with `'--'` when `--` must always be present.
    #
    # @example Ordering example (end_of_options emits '--' only when path is present)
    #   args_def = Arguments.define do
    #     operand :ref
    #     end_of_options
    #     operand :path
    #   end
    #   args_def.bind('HEAD', 'file.txt').to_a  # => ['HEAD', '--', 'file.txt']
    #   args_def.bind('HEAD').to_a              # => ['HEAD']  # (no trailing --)
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
    # ```ruby
    # value_option :config, repeatable: true
    # # config: ['a=b', 'c=d'] => ['--config', 'a=b', '--config', 'c=d']
    #
    # value_option :sort, inline: true, repeatable: true
    # # sort: ['refname', '-committerdate'] => ['--sort=refname', '--sort=-committerdate']
    #
    # end_of_options
    # value_option :pathspecs, as_operand: true, repeatable: true
    # # pathspecs: ['file1.txt', 'file2.txt'] => ['--', 'file1.txt', 'file2.txt']
    # ```
    #
    # ## Common Option Parameters
    #
    # Most option types support parameters that affect **input validation** (checked
    # during {#bind}):
    #
    # - **required:** - When true, the option key must be present in the provided
    #   opts. Raises ArgumentError if the key is missing. Defaults to false.
    #
    #   Supported by: {#flag_option}, {#value_option}, {#flag_or_value_option},
    #   {#key_value_option}, {#custom_option}, {#operand}.
    #
    # - **allow_nil:** - When false (with required: true), the value cannot be nil.
    #   Raises ArgumentError if a nil value is provided. Defaults to true for
    #   options, false for operands.
    #
    #   Supported by: same as **required:**.
    #
    # - **type:** - Validates the value is an instance of the specified class(es).
    #   Accepts a single class or an array of classes. Raises ArgumentError if type
    #   doesn't match. This parameter only performs type checking during validation;
    #   the conversion of values to CLI argument strings is handled separately during
    #   the build phase — see the *String Conversion* section below. Defaults to nil (no
    #   validation).
    #
    #   Supported by: {#flag_option}, {#value_option}, {#flag_or_value_option}.
    #
    # Note: {#literal} and {#execution_option} do not support these validation parameters.
    #
    # These parameters affect **output generation** (what CLI arguments are
    # produced):
    #
    # - **as:** - Override the CLI argument(s) derived from the option name
    #   Can be a String or an Array. Default is nil (derives from name).
    #
    # - **allow_empty:** - ({#value_option} only) When true, output the option
    #   even if the value is an empty string. Default is false (empty strings skipped).
    #
    # - **repeatable:** - ({#value_option}, {#flag_or_value_option}, and {#operand}
    #   only) Output an option or operand for each array element. Default is false.
    #
    # - **skip_cli:** - ({#operand} only) Bind, validate, and expose an operand
    #   accessor without emitting that operand in {Bound#to_a}. Default is false.
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
    # - An `end_of_options` declaration
    #
    # Operands **after** the `--` boundary are not validated (they represent
    # paths/filenames which may legitimately start with `-`). If no `--`
    # boundary exists in the definition, **all** operands are validated.
    #
    # @example Operands before and after '--' end_of_options boundary
    #   args_def = Arguments.define do
    #     operand :commit1
    #     operand :commit2
    #     end_of_options
    #     operand :paths, repeatable: true
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
    # ## String Conversion
    #
    # During the build phase, value-bearing option types (`value_option`,
    # `flag_or_value_option`, `key_value_option`) and `operand` definitions convert
    # their bound values to CLI argument strings by calling `#to_s`. This means any
    # object with a meaningful `#to_s` implementation — `Integer`, `Float`,
    # `Pathname`, etc. — can be passed as a value without the DSL needing to know
    # about the type.
    #
    # Note: `flag_option` values control *presence or absence* of a flag and are not
    # stringified. `custom_option` builders receive the raw value and are responsible
    # for producing CLI strings themselves.
    #
    # The `type:` parameter does not affect this conversion; it only validates the
    # Ruby class of the value *before* stringification.
    #
    # @example Numeric values are stringified automatically
    #   args_def = Arguments.define do
    #     value_option :depth, inline: true
    #     value_option :jobs,  inline: true
    #   end
    #   args_def.bind(depth: 5, jobs: 4).to_a  # => ['--depth=5', '--jobs=4']
    #
    # @example Pathname is also accepted (no type: needed)
    #   args_def = Arguments.define do
    #     operand :path, required: true
    #   end
    #   args_def.bind(Pathname.new('/tmp/foo')).to_a  # => ['/tmp/foo']
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
    # ## Forbidden Value Combinations
    #
    # {#conflicts} is presence-based — it cannot distinguish between semantically
    # equivalent and contradictory combinations of negatable flags. Use
    # {#forbid_values} to declare specific **exact-value tuples** that are invalid.
    #
    # A `forbid_values` declaration matches only when **every** listed name has a
    # bound value equal to the declared value (Ruby `==`). Only matching tuples raise
    # ArgumentError; all other value combinations are permitted. Names may be options
    # or operands; aliases are canonicalized before comparison.
    #
    # This is most useful for negatable flags where some value-pairings are
    # contradictory but others are semantically equivalent and should remain valid.
    #
    # The error message has the form:
    #
    #   "cannot specify :name1=value1 with :name2=value2"
    #
    # @example Reject contradictory pairs without blocking equivalent ones
    #   args_def = Arguments.define do
    #     flag_option :all,            negatable: true
    #     flag_option :ignore_removal, negatable: true
    #     forbid_values all: true,    ignore_removal: true         # --all --ignore-removal: contradictory
    #     forbid_values no_all: true, no_ignore_removal: true     # --no-all --no-ignore-removal: contradictory
    #   end
    #   args_def.bind(all: true,    ignore_removal: true)
    #     #=> raise ArgumentError, 'cannot specify :all=true with :ignore_removal=true'
    #   args_def.bind(all: true,    no_ignore_removal: true).to_a  # => ['--all', '--no-ignore-removal']
    #   args_def.bind(no_all: true, ignore_removal: true).to_a     # => ['--no-all', '--ignore-removal']
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
    #     end_of_options
    #     value_option :pathspec, as_operand: true, repeatable: true
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
    # and {#requires}) and value-combination constraints ({#forbid_values}), you can
    # restrict the *set of acceptable values* for any value-type option using
    # {#allowed_values}. If a bound value falls outside the configured set, {#bind}
    # raises ArgumentError with a descriptive message.
    #
    # This is typically used to model git options that accept only a fixed list of
    # modes or strategies.
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
      # @yield [] block evaluated in the context of the new Arguments instance via
      #   +instance_eval+, so DSL methods ({#flag_option}, {#operand}, etc.) are called
      #   directly without an explicit receiver
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
        @forbidden_values = [] # Array of forbidden exact-value tuples
        @requires_one_of = [] # Array of "at least one must be present" groups
        @ordered_definitions = [] # Tracks all definitions in definition order
        @past_separator = false # Tracks whether a '--' boundary has been defined
        @end_of_options_declared = false # Guards against duplicate end_of_options calls
        @negatable_companions = Set.new # Synthesized :no_<name> companion entries
      end

      # Define a boolean flag option (--flag when true)
      #
      # @param names [Symbol, Array<Symbol>] the option name(s), first is primary
      #
      # @param as [String, Array<String>, nil] custom argument(s) to output (e.g., '-r' or ['--amend', '--no-edit'])
      #
      # @param negatable [Boolean] when true, registers a companion `no_<name>` key that emits
      #   `--no-<flag>` when set to `true`. Both keys use standard boolean semantics: `true`
      #   emits the flag, `false` or absent emits nothing. A conflict is automatically registered
      #   between the two keys so that `name: true, no_name: true` raises at bind time.
      #   The primary key must be snake_case (e.g. `:verify`, `:three_way`). When `as:` is
      #   given, it must be a long-form (`--flag`) String; Arrays and short-form flags (e.g.
      #   `-S`) are not compatible with `negatable: true` because the synthesized companion is
      #   always `--no-<flag>`.
      #
      # @param required [Boolean] whether the option must be provided (the key must be present
      #   in opts). When combined with +negatable: true+, a `requires_one_of [name, no_name]`
      #   group is automatically registered so that either the primary or companion key satisfies
      #   the requirement (e.g. `bind(no_verify: true)` satisfies `required: true` for `:verify`).
      #   Note that under the companion-key model, `bind(verify: false)` does **not** satisfy
      #   the requirement because `false` is treated as absent.
      #
      # @param allow_nil [Boolean] whether nil is allowed when required is true. Defaults to true.
      #   When false with required: true, raises ArgumentError if value is nil.
      #   Cannot be combined with +negatable: true+ and +required: true+ — raises ArgumentError
      #   at definition time (nil is already caught by the auto +requires_one_of+ group).
      #
      # @param max_times [Integer, nil] maximum number of times the flag may be repeated (default: nil).
      #   When set, the caller may pass a positive Integer up to this limit to emit the flag
      #   multiple times (e.g. `force: 2` emits `--force --force`). Must be an Integer >= 2;
      #   0 and 1 raise ArgumentError at definition time. When nil (the default), only boolean
      #   values are accepted.
      #
      # @return [void]
      #
      # @raise [ArgumentError] if defined after an `end_of_options` or `literal '--'` boundary
      #
      # @raise [ArgumentError] if max_times is not nil and not an Integer >= 2
      #
      # @raise [ArgumentError] if negatable: true and the primary key is not snake_case
      #
      # @raise [ArgumentError] if negatable: true and the generated `no_<name>` key collides
      #   with an already-registered key
      #
      # @raise [ArgumentError] if negatable: true and as: is an Array
      #
      # @raise [ArgumentError] if negatable: true and as: is not a long-form (`--flag`) String
      #
      # @raise [ArgumentError] if negatable: true and required: true and allow_nil: false
      #
      # @example Basic flag
      #   args_def = Arguments.define do
      #     flag_option :force
      #   end
      #   args_def.bind(force: true).to_a   # => ['--force']
      #   args_def.bind(force: false).to_a  # => []
      #
      # @example Negatable flag (companion-key model)
      #   args_def = Arguments.define do
      #     flag_option :full, negatable: true
      #   end
      #   args_def.bind(full: true).to_a      # => ['--full']
      #   args_def.bind(no_full: true).to_a   # => ['--no-full']
      #   args_def.bind(full: false).to_a     # => []
      #
      # @example Negatable flag with required: true (either companion key satisfies the requirement)
      #   args_def = Arguments.define do
      #     flag_option :verify, negatable: true, required: true
      #   end
      #   args_def.bind(verify: true).to_a    # => ['--verify']
      #   args_def.bind(no_verify: true).to_a # => ['--no-verify']
      #   args_def.bind(verify: false)
      #   #=> raise ArgumentError, "at least one of :verify, :no_verify must be provided"
      #   args_def.bind
      #   #=> raise ArgumentError, "at least one of :verify, :no_verify must be provided"
      #
      # @example Repeatable flag with max_times
      #   args_def = Arguments.define do
      #     flag_option :force, max_times: 2
      #   end
      #   args_def.bind(force: true).to_a  # => ['--force']
      #   args_def.bind(force: 1).to_a     # => ['--force']
      #   args_def.bind(force: 2).to_a     # => ['--force', '--force']
      #
      # @example Negatable flag with max_times
      #   args_def = Arguments.define do
      #     flag_option :force, negatable: true, max_times: 2
      #   end
      #   args_def.bind(no_force: true).to_a  # => ['--no-force']
      #   args_def.bind(force: 2).to_a        # => ['--force', '--force']
      #
      # @example With required and allow_nil: false
      #   args_def = Arguments.define do
      #     flag_option :force, required: true, allow_nil: false
      #   end
      #   args_def.bind() #=> raise ArgumentError, "Required options not provided: :force"
      #   args_def.bind(force: nil) #=> raise ArgumentError, "Required options cannot be nil: :force"
      #
      def flag_option(names, as: nil, negatable: false, required: false, allow_nil: true, max_times: nil)
        primary = Array(names).first
        validate_max_times!(primary, max_times)

        if negatable
          register_negatable_flag_pair(names, as: as, required: required,
                                              allow_nil: allow_nil, max_times: max_times)
        else
          register_option(names, type: :flag, as: as, expected_type: nil, validator: nil,
                                 required: required, allow_nil: allow_nil, max_times: max_times)
        end
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
      #   descriptive message if value doesn't match.
      #
      # @param inline [Boolean] when true, outputs --flag=value as single argument instead of
      #   --flag value as separate arguments (default: false). Cannot be combined with as_operand:.
      #
      # @param as_operand [Boolean] when true, outputs value as operand without flag
      #   (default: false). Cannot be combined with inline:.
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
      # @raise [ArgumentError] if defined after an `end_of_options` or `literal '--'` boundary
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
      # @example Operand with end_of_options boundary
      #   args_def = Arguments.define do
      #     end_of_options
      #     value_option :paths, as_operand: true
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
      #     end_of_options
      #     value_option :pathspecs, as_operand: true, repeatable: true
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
      def value_option(names, as: nil, type: nil, inline: false, as_operand: false,
                       allow_empty: false, repeatable: false, required: false, allow_nil: true)
        validate_value_modifiers!(names, inline, as_operand)

        option_type = determine_value_option_type(inline, as_operand)
        register_option(names, type: option_type, as: as, expected_type: type,
                               allow_empty: allow_empty, repeatable: repeatable, required: required,
                               allow_nil: allow_nil)
      end

      # Define a flag or value option
      #
      # This is a flexible option type that outputs:
      # - Just the flag (--flag) when value is true
      # - Nothing when value is false
      # - Flag with value when value is any non-boolean, non-nil object (stringified via #to_s;
      #   e.g., --flag value or --flag=value if inline: true)
      # - Nothing when value is nil
      #
      # @param names [Symbol, Array<Symbol>] the option name(s), first is primary
      #
      # @param as [String, nil] custom option string
      #
      # @param type [Class, Array<Class>, nil] expected type(s) for validation
      #
      # @param negatable [Boolean] when true, registers a companion `no_<name>` key that emits
      #   `--no-<flag>` when set to `true`. The positive key retains flag-or-value semantics;
      #   the negative key is boolean-only (accepts only `true`/`false`/`nil`). A conflict is
      #   automatically registered so that `name: true, no_name: true` raises at bind time.
      #   The primary key must be snake_case. When `as:` is given, it must be a long-form
      #   (`--flag`) String; Arrays and short-form flags (e.g. `-S`) are not compatible with
      #   `negatable: true` because the synthesized companion is always `--no-<flag>`.
      #
      # @param inline [Boolean] when true, outputs --flag=value instead of --flag value (default: false)
      #
      # @param repeatable [Boolean] when true, accepts an Array of values and repeats the option
      #   for each element. Each element must be +true+, +false+, or a non-nil object (which is
      #   stringified via +#to_s+); nil elements raise ArgumentError at bind time.
      #   A single (non-Array) value is also accepted. Default false.
      #
      # @param required [Boolean] whether the option must be provided (the key must be present
      #   in opts). When combined with +negatable: true+, a `requires_one_of [name, no_name]`
      #   group is automatically registered so that either side satisfies the requirement. Note
      #   that `bind(name: false)` does **not** satisfy the requirement because `false` is
      #   treated as absent under the companion-key model.
      #
      # @param allow_nil [Boolean] whether nil is allowed when required is true. Defaults to true.
      #   Cannot be combined with +negatable: true+ and +required: true+ — raises ArgumentError
      #   at definition time (nil is already caught by the auto +requires_one_of+ group).
      #
      # @return [void]
      #
      # @raise [ArgumentError] at bind time if +repeatable: true+ is used and any
      #   Array element is nil
      #
      # @raise [ArgumentError] if defined after an `end_of_options` or `literal '--'` boundary
      #
      # @raise [ArgumentError] if negatable: true and the primary key is not snake_case
      #
      # @raise [ArgumentError] if negatable: true and the generated `no_<name>` key collides
      #   with an already-registered key
      #
      # @raise [ArgumentError] if negatable: true and as: is an Array
      #
      # @raise [ArgumentError] if negatable: true and as: is not a long-form (`--flag`) String
      #
      # @raise [ArgumentError] if negatable: true and required: true and allow_nil: false
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
      # @example With negatable: true (companion-key model)
      #   args_def = Arguments.define do
      #     flag_or_value_option :verify, negatable: true
      #   end
      #   args_def.bind(verify: true).to_a       # => ['--verify']
      #   args_def.bind(verify: false).to_a      # => []
      #   args_def.bind(no_verify: true).to_a    # => ['--no-verify']
      #   args_def.bind(verify: "KEYID").to_a    # => ['--verify', 'KEYID']
      #   args_def.bind(verify: nil).to_a        # => []
      #
      # @example With negatable: true and inline: true
      #   args_def = Arguments.define do
      #     flag_or_value_option :sign, negatable: true, inline: true
      #   end
      #   args_def.bind(sign: true).to_a      # => ['--sign']
      #   args_def.bind(sign: false).to_a     # => []
      #   args_def.bind(no_sign: true).to_a   # => ['--no-sign']
      #   args_def.bind(sign: "KEY").to_a     # => ['--sign=KEY']
      #   args_def.bind(sign: nil).to_a       # => []
      #
      # @example With inline: true and repeatable: true
      #   args_def = Arguments.define do
      #     flag_or_value_option :recurse_submodules, inline: true, repeatable: true
      #   end
      #   args_def.bind(recurse_submodules: true).to_a       # => ['--recurse-submodules']
      #   args_def.bind(recurse_submodules: 'lib/').to_a     # => ['--recurse-submodules=lib/']
      #   args_def.bind(recurse_submodules: ['lib/', 'ext/']).to_a
      #   # => ['--recurse-submodules=lib/', '--recurse-submodules=ext/']
      #   args_def.bind(recurse_submodules: [nil])
      #   # => raise_error ArgumentError, /Invalid value for flag_or_inline_value/
      #
      def flag_or_value_option(names, as: nil, type: nil, negatable: false, inline: false,
                               repeatable: false, required: false, allow_nil: true)
        if negatable
          register_negatable_flag_or_value_pair(names, as: as, type: type, inline: inline,
                                                       repeatable: repeatable, required: required,
                                                       allow_nil: allow_nil)
        else
          option_type = inline ? :flag_or_inline_value : :flag_or_value
          register_option(names, type: option_type, as: as, expected_type: type,
                                 repeatable: repeatable, required: required, allow_nil: allow_nil)
        end
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
      # @raise [ArgumentError] at bind time if array input is not a [key, value] pair or array of pairs
      #
      # @raise [ArgumentError] at bind time if a sub-array has more than 2 elements
      #
      # @raise [ArgumentError] at bind time if a key is nil, empty, or contains the separator
      #
      # @raise [ArgumentError] at bind time if a value is a Hash or Array (non-scalar)
      #
      # @raise [ArgumentError] if defined after an `end_of_options` or `literal '--'` boundary
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

      # Conditionally emit an options terminator only when at least one following
      # argument produces output
      #
      # This is the canonical form for declaring the options/operands boundary in a
      # command definition. Unlike {#literal} with `'--'` which always emits the
      # separator, `end_of_options` emits its terminator string only when at least one
      # argument defined after it will be emitted as part of the CLI (for example
      # operands or `value_option ... as_operand: true`). This avoids a trailing bare
      # terminator when no pathspecs or other post-separator arguments are provided.
      #
      # `end_of_options` also acts as an always-active validation boundary: operands
      # defined before it are always validated for option-like values (starting with
      # `-`), regardless of whether the terminator will ultimately be emitted.
      #
      # @param as [String] the CLI token to emit as the options terminator
      #   (default `'--'`). Some commands use a different terminator; for example,
      #   `git rev-parse` uses `'--end-of-options'`.
      #
      # @return [void]
      #
      # @raise [ArgumentError] if called more than once per definition block
      #
      # @raise [ArgumentError] if a flag-producing option is defined after this call
      #
      # @example Basic usage (git checkout tree-ish -- pathspecs)
      #   args_def = Arguments.define do
      #     flag_option :force
      #     operand :tree_ish, required: true, allow_nil: true
      #     end_of_options
      #     operand :pathspecs, repeatable: true
      #   end
      #   args_def.bind('HEAD', 'file.txt').to_a   # => ['HEAD', '--', 'file.txt']
      #   args_def.bind('HEAD').to_a               # => ['HEAD'] # (no --, nothing after it)
      #   args_def.bind(nil, 'file.txt').to_a      # => ['--', 'file.txt']
      #   args_def.bind(nil).to_a                  # => []
      #
      # @example Custom terminator (git rev-parse --end-of-options)
      #   args_def = Arguments.define do
      #     flag_option :verify
      #     end_of_options as: '--end-of-options'
      #     operand :args, repeatable: true
      #   end
      #   args_def.bind('HEAD').to_a               # => ['--end-of-options', 'HEAD']
      #   args_def.bind.to_a                       # => []
      #
      def end_of_options(as: '--')
        raise ArgumentError, 'end_of_options cannot be declared twice' if @end_of_options_declared

        @ordered_definitions << { kind: :end_of_options }
        @end_of_options_declared = true
        @end_of_options_as = as
        @past_separator = true
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
      # @yield [value] block that receives the option value and returns the CLI argument(s)
      #
      # @yieldparam value [Object] the bound value for this option
      #
      # @yieldreturn [String, Array<String>, nil] the CLI argument(s) to emit;
      #   nil or an empty array emits nothing
      #
      # @return [void]
      #
      # @raise [ArgumentError] if defined after an `end_of_options` or `literal '--'` boundary
      #
      # @example Custom transformation (e.g., formatting a Date value)
      #   args_def = Arguments.define do
      #     custom_option :since do |val|
      #       val ? "--since=#{val.strftime('%Y-%m-%d')}" : nil
      #     end
      #   end
      #   args_def.bind(since: Date.new(2024, 1, 1)).to_a  # => ['--since=2024-01-01']
      #   args_def.bind.to_a                               # => []
      #
      def custom_option(names, required: false, allow_nil: true, &block)
        register_option(names, type: :custom, builder: block, required: required, allow_nil: allow_nil)
      end

      # Define an execution option (not included in CLI output, forwarded to command execution)
      #
      # Execution options are omitted from the CLI argument array produced by {Bound#to_a}, but
      # their values are still accessible on the {Bound} object. This is useful for options that
      # control Ruby-side execution context (e.g., working directory) rather than git flags.
      #
      # @param names [Symbol, Array<Symbol>] the option name(s), first is primary
      #
      # @return [void]
      #
      # @example Chdir option forwarded to execution context, not emitted as a CLI flag
      #   args_def = Arguments.define do
      #     flag_option :verbose
      #     execution_option :chdir
      #   end
      #   bound = args_def.bind(verbose: true, chdir: '/tmp')
      #   bound.to_a        # => ['--verbose']  # :chdir is not included
      #   bound[:chdir]     # => '/tmp'          # still accessible on the Bound object
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
      # **Presence semantics** — an argument is present when its value is not `nil`,
      # `[]`, or `''`. `false` is always treated as absent for all option types.
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
      #     end_of_options
      #     operand :paths, repeatable: true
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

      # Declare that an exact combination of argument values is forbidden
      #
      # Each call to {#forbid_values} defines one forbidden tuple. A tuple matches
      # when **every** listed name is present (has a bound value after alias
      # normalization) **and** each value equals the declared value exactly (Ruby
      # `==`). When a tuple matches, {#bind} raises ArgumentError.
      #
      # This fills the gap left by {#conflicts}, which only checks *presence*.
      # `forbid_values` is useful for negatable flags whose combinations can be
      # semantically equivalent or contradictory depending on the actual boolean
      # values — presence-based exclusion would be too coarse.
      #
      # Names may refer to **options** (flag, value, flag-or-value, etc.) or
      # **operands** (positional arguments). Alias names are accepted and
      # canonicalized to their primary names.
      #
      # An ArgumentError is raised at **definition time** if any name is not a
      # known option or operand.
      #
      # The error message has the form:
      #
      #   "cannot specify :name1=value1 with :name2=value2"
      #
      # @param pairs [Hash] keyword pairs mapping argument name to forbidden value
      #
      # @return [void]
      #
      # @raise [ArgumentError] if any name in +pairs+ is not a known option or
      #   operand
      #
      # @raise [ArgumentError] during {#bind} if all names are present and all
      #   values exactly match the declared tuple
      #
      # @example Reject only the contradictory negatable flag combinations
      #   args_def = Arguments.define do
      #     flag_option :all,            negatable: true
      #     flag_option :ignore_removal, negatable: true
      #     # --all --ignore-removal: contradictory (add ALL vs ignore removals)
      #     forbid_values all: true,    ignore_removal: true
      #     # --no-all --no-ignore-removal: contradictory (ignore removals vs include removals)
      #     forbid_values no_all: true, no_ignore_removal: true
      #   end
      #   # Contradictory tuples raise:
      #   args_def.bind(all: true, ignore_removal: true)
      #     # => raise ArgumentError, 'cannot specify :all=true with :ignore_removal=true'
      #   args_def.bind(no_all: true, no_ignore_removal: true)
      #     # => raise ArgumentError, 'cannot specify :no_all=true with :no_ignore_removal=true'
      #   # Semantically compatible pairs are allowed:
      #   args_def.bind(all: true,    no_ignore_removal: true).to_a  # => ['--all', '--no-ignore-removal']
      #   args_def.bind(no_all: true, ignore_removal: true).to_a     # => ['--no-all', '--ignore-removal']
      #
      def forbid_values(**pairs)
        raise ArgumentError, 'forbid_values must be given at least one name-value pair' if pairs.empty?

        pairs.each_key do |name|
          sym = name.to_sym
          next if known_argument?(sym)

          raise ArgumentError, "unknown argument :#{sym} in forbid_values declaration"
        end
        canonical = pairs.transform_keys { |k| @alias_map[k] || k }
        @forbidden_values << canonical
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
      # **Presence semantics** — two slightly different rules apply:
      #
      # - *`when:` trigger* — the trigger is considered present when its value is
      #   not `nil`, `false`, `[]`, or `''`. A flag set to `false` means absent,
      #   so the trigger does **not** fire.
      # - *Satisfied-by check* — a group member is considered present when its
      #   value is not `nil`, `false`, `[]`, or `''`. `false` is treated as absent
      #   for all option types under the companion-key model.
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
      #     end_of_options
      #     value_option :pathspec, as_operand: true, repeatable: true
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
      #     end_of_options
      #     value_option :pathspec, as_operand: true, repeatable: true
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

      # Declare that exactly one of the named arguments must be present when binding
      #
      # This is a convenience composite that combines {#requires_one_of} (at least one
      # must be present) and {#conflicts} (at most one may be present). Use it when a
      # group of arguments is mutually exclusive *and* the caller must supply precisely
      # one of them.
      #
      # The call:
      #
      #   requires_exactly_one_of :a, :b, :c
      #
      # is exactly equivalent to:
      #
      #   requires_one_of :a, :b, :c
      #   conflicts       :a, :b, :c
      #
      # **Presence semantics** — inherits the rules from the constituent methods.
      # See {#requires_one_of} and {#conflicts} for the full details.
      #
      # An ArgumentError is raised at definition time if any name is not a known
      # option or operand, catching typos early.
      #
      # Error messages reuse the formats from the constituent methods:
      #
      #   "at least one of :a, :b, :c must be provided"   # zero present
      #   "cannot specify :a and :b"                       # two or more present
      #
      # @param names [Array<Symbol>] the option/operand names where exactly one
      #   must be present
      #
      # @return [void]
      #
      # @raise [ArgumentError] if any name is not a known option or operand
      #
      # @raise [ArgumentError] at bind time if none of the arguments in the group is present
      #
      # @raise [ArgumentError] at bind time if more than one argument in the group is present
      #
      # @example Mode flags where exactly one must be supplied
      #   args_def = Arguments.define do
      #     flag_option :mode_a
      #     flag_option :mode_b
      #     flag_option :mode_c
      #     requires_exactly_one_of :mode_a, :mode_b, :mode_c
      #   end
      #   args_def.bind(mode_a: true).to_a  # => ['--mode-a']
      #   args_def.bind
      #     # => raise ArgumentError, 'at least one of :mode_a, :mode_b, :mode_c must be provided'
      #   args_def.bind(mode_a: true, mode_c: true)
      #     # => raise ArgumentError, 'cannot specify :mode_a and :mode_c'
      #
      def requires_exactly_one_of(*names)
        requires_one_of(*names)
        conflicts(*names)
      end

      # Declare that *name* must be present whenever the trigger argument *when:* is present
      #
      # When {#bind} is called, if the trigger argument is present and *name* is absent,
      # an ArgumentError is raised. If the trigger is absent, the check is skipped.
      #
      # **Presence semantics** — two slightly different rules apply:
      #
      # - *`when:` trigger* — the trigger is considered present when its value is
      #   not `nil`, `false`, `[]`, or `''`. A value of `false` is treated as
      #   absent. If you need an explicit negative form for a negatable flag, use
      #   its `no_<name>` companion key instead.
      # - *Required argument* — *name* is considered present when its value is
      #   not `nil`, `false`, `[]`, or `''`.
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
      # @param in [#each] accepted values enumerable. Each value is coerced with
      #   +to_s+ and compared as a string.
      #
      # For \\{#flag_or_value_option} variants (including +negatable: true+),
      # boolean values (+true+ / +false+) are skipped by this check because they
      # control flag-emission behavior rather than representing candidate string
      # values.
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
      # @param allow_nil [Boolean] whether nil is a valid value for a required
      #   operand. When true, nil consumes the operand slot but is omitted
      #   from output. This is useful for commands like `git checkout` where
      #   the tree-ish is required to consume a slot but may be nil to restore
      #   from the index. Defaults to false.
      #
      # @param skip_cli [Boolean] whether this operand participates in binding,
      #   validation, and accessors but is omitted from CLI argv emission.
      #   Defaults to false.
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
      # @example Operand after end_of_options boundary (pathspec after --)
      #   args_def = Arguments.define do
      #     flag_option :force
      #     end_of_options
      #     operand :paths, repeatable: true
      #   end
      #   args_def.bind('file1', 'file2', force: true).to_a
      #   # => ['--force', '--', 'file1', 'file2']
      #
      # @example Complex pattern (like `def diff(commit1, commit2 = nil, *paths)`)
      #   args_def = Arguments.define do
      #     operand :commit1, required: true
      #     operand :commit2
      #     end_of_options
      #     operand :paths, repeatable: true
      #   end
      #   args_def.bind('HEAD~1').to_a  # => ['HEAD~1']
      #   args_def.bind('HEAD~1', 'HEAD').to_a  # => ['HEAD~1', 'HEAD']
      #   args_def.bind('HEAD~1', 'HEAD', 'file.rb').to_a
      #   # => ['HEAD~1', 'HEAD', '--', 'file.rb']
      #
      # @example Required operand that allows nil (like `git checkout [tree-ish] -- paths`)
      #   args_def = Arguments.define do
      #     operand :tree_ish, required: true, allow_nil: true
      #     end_of_options
      #     operand :paths, repeatable: true
      #   end
      #   args_def.bind(nil, 'file1.txt', 'file2.txt').to_a
      #   # => ['--', 'file1.txt', 'file2.txt']
      #   args_def.bind('HEAD', 'file.rb').to_a
      #   # => ['HEAD', '--', 'file.rb']
      #   args_def.bind(nil, 'file.rb').to_a
      #   # => ['--', 'file.rb']
      #
      # @raise [ArgumentError] during {#bind} if the operand appears before a '--'
      #   boundary (or no boundary exists) and the bound value starts with '-'
      #
      #
      def operand(name, required: false, repeatable: false, default: nil, allow_nil: false,
                  skip_cli: false)
        validate_single_repeatable!(name) if repeatable
        add_operand_definition(name, required, repeatable, default, allow_nil, skip_cli)
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
      #     @execution_context.command_capturing(*ARGS.bind(*, **))
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
        validate_bind_inputs!(normalized_opts, allocated_positionals)

        args_array = build_ordered_arguments(allocated_positionals, normalized_opts)
        options_hash = build_options_hash(normalized_opts)
        execution_option_names = option_names_by_type(:execution_option)
        flag_names = option_names_by_type(:flag)

        Bound.new(args_array, options_hash, allocated_positionals, execution_option_names, flag_names)
      end

      # Option types allowed after a '--' separator boundary (they do not produce CLI flags)
      OPTION_TYPES_AFTER_SEPARATOR = %i[value_as_operand execution_option].freeze

      # Sentinel object placed in the build array by an :end_of_options definition.
      # It is later replaced by the stored `as:` value (default `'--'`) if any element
      # follows it, or stripped if it is last.
      # Uses Object identity comparison (== is not overridden) so it can never collide
      # with the literal string '--' or any other real argument value.
      END_OF_OPTIONS_MARKER = Object.new.freeze
      private_constant :END_OF_OPTIONS_MARKER

      # Option types that accept a string value — eligible for `allowed_values` constraints
      VALUE_OPTION_TYPES_FOR_ALLOWED_VALUES = %i[
        value inline_value value_as_operand
        flag_or_value flag_or_inline_value
      ].freeze

      # The subset of VALUE_OPTION_TYPES_FOR_ALLOWED_VALUES whose boolean values
      # carry semantic meaning (true = emit flag, false = suppress flag) and must
      # skip allowed_values validation rather than being compared against the set.
      FLAG_OR_VALUE_OPTION_TYPES = %i[
        flag_or_value flag_or_inline_value
      ].freeze

      private

      # Run all cross-field validations on bound inputs
      #
      # @param normalized_opts [Hash] normalized keyword options
      # @param allocated_positionals [Hash] allocated positional arguments
      # @return [void]
      #
      def validate_bind_inputs!(normalized_opts, allocated_positionals)
        validate_no_option_like_operands!(allocated_positionals)
        validate_conflicts!(normalized_opts, allocated_positionals)
        validate_forbidden_values!(normalized_opts, allocated_positionals)
        validate_requires_one_of!(normalized_opts, allocated_positionals)
      end

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
        when :flag
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
      # @raise [ArgumentError] if invalid modifier combination is used
      #
      def validate_value_modifiers!(names, inline, as_operand)
        primary = Array(names).first
        raise ArgumentError, "inline: and as_operand: cannot both be true for :#{primary}" if inline && as_operand
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
        validate_no_duplicate_aliases!(keys)
        validate_no_companion_collision!(keys)
        validate_option_after_separator!(definition[:type], primary)
        validate_as_parameter!(definition, primary)
        apply_type_validator!(definition, primary)
        store_option(primary, keys, definition)
      end

      def store_option(primary, keys, definition)
        @option_definitions[primary] = definition
        keys.each { |key| @alias_map[key] = primary }
        @ordered_definitions << { kind: :option, name: primary }
      end

      # Raise if any of +keys+ collides with a previously synthesized +no_<name>+
      # companion entry. This catches the case where a user declares
      # +flag_option :foo, negatable: true+ followed by +flag_option :no_foo+.
      def validate_no_companion_collision!(keys)
        keys.each do |key|
          next unless @negatable_companions.include?(key)

          raise ArgumentError,
                "option key :#{key} is already registered as a negatable companion"
        end
      end

      # Raise if the +keys+ array contains duplicate entries.
      #
      # Duplicate aliases in a single declaration (e.g. +flag_option %i[foo foo]+)
      # are a programming mistake and would silently overwrite each other in
      # +@alias_map+. Catching them at definition time makes the error obvious.
      def validate_no_duplicate_aliases!(keys)
        seen = Set.new
        keys.each do |key|
          raise ArgumentError, "duplicate alias key :#{key} in option definition" unless seen.add?(key)
        end
      end

      def validate_max_times!(option_name, max_times)
        return if max_times.nil?

        return if max_times.is_a?(Integer) && max_times >= 2

        raise ArgumentError, "max_times for :#{option_name} must be an Integer >= 2"
      end

      # Register two companion :flag entries for a negatable flag option
      #
      # Registers a positive entry for +names+ and a boolean-only negative entry for
      # <tt>:no_<primary></tt>. An automatic conflict is added so that both being
      # true at bind time raises ArgumentError.
      def register_negatable_flag_pair(names, as:, required:, allow_nil:, max_times:)
        primary = Array(names).first
        validate_negatable_allow_nil!(primary, required: required, allow_nil: allow_nil)
        prepare_negatable!(primary, names, as)

        register_option(names, type: :flag, as: as, expected_type: nil, validator: nil,
                               required: false, allow_nil: allow_nil, max_times: max_times)
        register_negative_companion(primary, as: as, required: required)
      end

      # Register a positive flag-or-value entry and a boolean-only negative companion
      # entry for a negatable flag-or-value option
      def register_negatable_flag_or_value_pair(names, as:, type:, inline:, repeatable:, required:, allow_nil:)
        primary = Array(names).first
        validate_negatable_allow_nil!(primary, required: required, allow_nil: allow_nil)
        prepare_negatable!(primary, names, as)

        positive_type = inline ? :flag_or_inline_value : :flag_or_value
        register_option(names, type: positive_type, as: as, expected_type: type,
                               repeatable: repeatable, required: false, allow_nil: allow_nil)
        register_negative_companion(primary, as: as, required: required)
      end

      # Run shared validations for a negatable option before registering either side
      def prepare_negatable!(primary, names, as)
        validate_negatable_primary_key!(primary)
        validate_negatable_as_not_array!(primary, as)
        validate_negatable_as_long_form!(primary, as)
        no_name = :"no_#{primary}"
        validate_no_negatable_collision!(no_name)
        validate_no_companion_in_alias_list!(no_name, Array(names))
      end

      # Register the synthesized +no_<primary>+ flag entry, the auto-conflict, and
      # (when +required: true+) the auto requires_one_of group
      def register_negative_companion(primary, as:, required:)
        no_name = :"no_#{primary}"
        positive_flag = as || default_arg_spec(primary)
        negative_flag = negate_flag(positive_flag)

        register_option(no_name, type: :flag, as: negative_flag, expected_type: nil, validator: nil,
                                 required: false, allow_nil: true)
        @negatable_companions << no_name
        @conflicts << [primary, no_name]
        @requires_one_of << { names: [primary, no_name], condition: nil, single: false } if required
      end

      # Raise if `allow_nil: false` is combined with `negatable: true` and `required: true`
      #
      # When `negatable: true` and `required: true`, the "required" constraint is enforced
      # by an auto `requires_one_of` group (either the primary or its `no_<name>` companion
      # must be present). Because the primary option is internally registered with
      # `required: false`, the `allow_nil: false` nil-check never runs, making the
      # combination silently misleading. Fail at definition time instead.
      #
      # @param key [Symbol] the primary option name (for the error message)
      #
      # @param required [Boolean] whether the option is required
      #
      # @param allow_nil [Boolean] whether nil is allowed
      #
      # @raise [ArgumentError] if `required: true` and `allow_nil: false` are combined
      #   with `negatable: true`
      #
      def validate_negatable_allow_nil!(key, required:, allow_nil:)
        return unless required && allow_nil == false

        raise ArgumentError,
              "allow_nil: false cannot be used with negatable: true and required: true on :#{key} " \
              '(nil is caught by the auto requires_one_of group, not allow_nil)'
      end

      # @raise [ArgumentError] if key is not snake_case
      #
      def validate_negatable_primary_key!(key)
        return if key.to_s.match?(/\A[a-z][a-z0-9_]*\z/)

        raise ArgumentError,
              "negatable: true requires a snake_case primary key, got :#{key} " \
              "(would generate :no_#{key} which is not a meaningful negative form)"
      end

      # Raise if as: is an Array when negatable: true
      #
      # Arrays for as: are not compatible with negatable: true regardless of the
      # underlying option type — the synthesized +--no-<flag>+ form has no sensible
      # mapping when the positive form expands to multiple CLI tokens.
      def validate_negatable_as_not_array!(primary, as)
        return unless as.is_a?(Array)

        raise ArgumentError,
              "arrays for as: parameter cannot be combined with negatable: true (option :#{primary})"
      end

      # Raise if as: is given as a short-form flag (e.g. +-S+) when negatable: true.
      # Negation requires a long-form flag because the synthesized companion is
      # always +--no-<flag>+; deriving it from a short flag would yield a
      # nonexistent git form like +--no-S+.
      def validate_negatable_as_long_form!(primary, as)
        return if as.nil?
        return if as.is_a?(String) && as.start_with?('--')

        raise ArgumentError,
              "negatable: true requires a long-form (--flag) value for as: on :#{primary}, got #{as.inspect}"
      end

      # Raise if the generated no_ companion key is already registered
      #
      def validate_no_negatable_collision!(no_name)
        return unless @alias_map.key?(no_name)

        raise ArgumentError,
              "negatable: true would register :#{no_name} but that key is already registered"
      end

      # Raise if the synthesized companion key appears in the same declaration's alias list.
      #
      # This catches e.g. +flag_option %i[foo no_foo], negatable: true+ where :no_foo
      # is listed as an alias and would be silently overwritten when the companion is
      # registered, corrupting @alias_map and @option_definitions.
      def validate_no_companion_in_alias_list!(no_name, keys)
        return unless keys.include?(no_name)

        raise ArgumentError,
              "negatable: true would register :#{no_name} as a companion, but :#{no_name} " \
              'is already listed as an alias in the same declaration'
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
          if entry[:kind] == :end_of_options
            args << END_OF_OPTIONS_MARKER
          else
            build_entry(args, entry, normalized_opts, allocated_positionals)
          end
        end

        resolve_end_of_options_marker(args)
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
        # :nocov: this case should be unreachable
        else
          raise ArgumentError, "unknown entry kind: #{entry[:kind].inspect}"
        end
        # :nocov:
      end

      # Replace the END_OF_OPTIONS_MARKER with the stored `as:` value if any element
      # follows it, or strip it
      #
      # @param args [Array] the built argument array (may contain END_OF_OPTIONS_MARKER)
      # @return [Array<String>] the argument array with the marker resolved
      #
      def resolve_end_of_options_marker(args)
        idx = args.index(END_OF_OPTIONS_MARKER)
        return args unless idx

        if idx == args.size - 1
          args.delete_at(idx) # nothing follows — strip
        else
          args[idx] = @end_of_options_as # something follows — make it real
        end
        args
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
        return if definition[:skip_cli]

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

      def add_operand_definition(name, required, repeatable, default, allow_nil, skip_cli)
        @operand_definitions << {
          name: name, required: required, repeatable: repeatable,
          default: default, allow_nil: allow_nil, skip_cli: skip_cli
        }
        @ordered_definitions << { kind: :operand, name: name }
      end

      BUILDERS = {
        flag: :build_flag,
        value: lambda do |args, arg_spec, value, definition|
          if definition[:repeatable]
            Array(value).each { |v| args << arg_spec << v.to_s }
          else
            args << arg_spec << value.to_s
          end
        end,
        inline_value: :build_inline_value,
        flag_or_inline_value: :build_flag_or_inline_value,
        flag_or_value: :build_flag_or_value,
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
          builder.call(args, arg_spec, value, definition)
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
      def build_flag_or_inline_value(args, arg_spec, value, definition)
        each_flag_or_value_value(value, definition, 'flag_or_inline_value') do |v|
          next if v == false

          args << (v == true ? arg_spec : "#{arg_spec}#{inline_value_separator(arg_spec)}#{v}")
        end
      end

      # Build flag or value option
      #
      def build_flag_or_value(args, arg_spec, value, definition)
        each_flag_or_value_value(value, definition, 'flag_or_value') do |v|
          next if v == false

          if v == true
            args << arg_spec
          else
            args << arg_spec << v.to_s
          end
        end
      end

      def each_flag_or_value_value(value, definition, option_type)
        values = definition[:repeatable] ? Array(value) : [value]
        values.each do |v|
          validate_flag_or_value_type!(v, option_type)
          yield v
        end
      end

      # Validate that a flag_or_value element is not nil.
      #
      # Boolean values (true/false) control flag presence/absence. Any other non-nil
      # object is accepted and converted to a CLI argument string via +#to_s+.
      # Nil is rejected only within repeatable arrays — non-repeatable nil values are
      # filtered out earlier by +should_skip_option?+ and never reach here.
      #
      def validate_flag_or_value_type!(value, option_type)
        return unless value.nil?

        raise ArgumentError,
              "Invalid value for #{option_type}: nil is not allowed as an array element; " \
              'expected true, false, or a non-nil object that responds to #to_s'
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

      def build_flag(args, arg_spec, value, definition)
        count = normalize_flag_value!(value, definition)
        append_repeated_flag(args, arg_spec, count)
      end

      def append_repeated_flag(args, arg_spec, count)
        return if count <= 0

        count.times do
          arg_spec.is_a?(Array) ? args.concat(arg_spec) : args << arg_spec
        end
      end

      def normalize_flag_value!(value, definition)
        return 1 if value == true
        return 0 if value.nil? || value == false

        option_name = definition[:aliases].first
        max_times = definition[:max_times]

        raise_flag_type_boolean_error!(value, definition) if max_times.nil?

        return normalize_flag_integer_value!(value, option_name, max_times) if value.is_a?(Integer)

        raise ArgumentError, "Invalid value for :#{option_name}: expected true, false, or a positive Integer"
      end

      def raise_flag_type_boolean_error!(value, definition)
        raise_flag_boolean_error!(definition[:aliases].first, value)
      end

      def raise_flag_boolean_error!(option_name, value)
        raise ArgumentError,
              "flag_option :#{option_name} expects a boolean value, got #{value.inspect} (#{value.class})"
      end

      def normalize_flag_integer_value!(value, option_name, max_times)
        raise ArgumentError, "Invalid value for :#{option_name}: expected a positive Integer" if value <= 0

        raise_max_times_exceeded!(option_name, value, max_times) if value > max_times

        value
      end

      def raise_max_times_exceeded!(option_name, value, max_times)
        raise ArgumentError,
              "#{option_name}: #{value} exceeds max_times: #{max_times} for :#{option_name}"
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
      # if no boundary exists) are validated to ensure they don't start with
      # a hyphen, which could be misinterpreted as a git option.
      #
      # @param allocation [Hash{Symbol => Object}] the allocated operand values
      # @raise [ArgumentError] if any pre-separator operand value starts with '-'
      #
      def validate_no_option_like_operands!(allocation)
        pre_separator_operands = operand_names_before_separator
        pre_separator_operands.each do |name|
          value = allocation[name]
          check_operand_not_option_like(name, value)
        end
      end

      # Determine which operands appear before any '--' separator boundary
      #
      # Walks the ordered definitions and collects operand names until hitting
      # a `literal '--'` or an `end_of_options` declaration. All operands after
      # any such boundary are excluded from option-like validation.
      #
      # @return [Array<Symbol>] operand names that need option-like validation
      #
      def operand_names_before_separator
        names = []
        @ordered_definitions.each do |defn|
          break if separator_boundary_active?(defn)

          names << defn[:name] if defn[:kind] == :operand && !operand_skip_cli?(defn[:name])
        end
        names
      end

      # Check if an operand is configured with skip_cli: true
      #
      # @param name [Symbol] the operand name
      # @return [Boolean] true if operand has skip_cli enabled
      #
      def operand_skip_cli?(name)
        operand_def = @operand_definitions.find { |d| d[:name] == name }
        operand_def[:skip_cli] == true
      end

      # Check if a definition represents an active '--' separator boundary
      #
      # A `literal '--'` is always active. An `end_of_options` entry is also always active,
      # even when its runtime `--` may be suppressed by {#resolve_end_of_options_marker}.
      #
      # @param defn [Hash] a definition entry from @ordered_definitions
      # @return [Boolean] true if this definition is an active '--' boundary
      #
      def separator_boundary_active?(defn)
        return true if literal_separator_flag?(defn)
        return true if defn[:kind] == :end_of_options

        false
      end

      # Check if a definition is a literal '--' static flag
      #
      # @param defn [Hash] the entry definition
      # @return [Boolean]
      #
      def literal_separator_flag?(defn)
        defn[:kind] == :static && defn[:flag] == '--'
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
          provided = conflict_group.select { |name| conflict_present?(name, opts, allocated_positionals) }
          next if provided.size <= 1

          formatted = provided.map { |name| ":#{name}" }.join(' and ')
          raise ArgumentError, "cannot specify #{formatted}"
        end
      end

      # Return true if a named argument should be counted as present during conflict checking
      #
      # For registered keyword options only looks in opts; positional slots use
      # allocated_positionals. This prevents a positional operand that shares a
      # name with a keyword option from spuriously triggering keyword conflicts.
      def conflict_present?(name, opts, allocated_positionals)
        canonical_name = @alias_map[name] || name
        value = if @option_definitions.key?(canonical_name)
                  opts[canonical_name]
                else
                  allocated_positionals[canonical_name]
                end
        argument_present?(value)
      end

      # Validate that no bound values match a forbidden exact-value tuple
      #
      # @param opts [Hash] normalized keyword options (aliases already resolved)
      # @param allocated_positionals [Hash] the allocated positional values
      # @raise [ArgumentError] if all names in a forbidden tuple are present with
      #   their declared values
      #
      def validate_forbidden_values!(opts, allocated_positionals = {})
        @forbidden_values.each do |tuple|
          next unless forbidden_tuple_matches?(tuple, opts, allocated_positionals)

          formatted = tuple.map { |name, value| ":#{name}=#{value.inspect}" }.join(' with ')
          raise ArgumentError, "cannot specify #{formatted}"
        end
      end

      # Return true if every name in the tuple has a bound value equal to the
      # declared forbidden value.
      #
      # The check only fires when the key is actually present (bound) — an absent
      # key never triggers a forbidden-values match.
      #
      # @param tuple [Hash{Symbol => Object}] canonical name → forbidden value
      # @param opts [Hash] normalized keyword options
      # @param allocated_positionals [Hash] the allocated positional values
      # @return [Boolean]
      #
      def forbidden_tuple_matches?(tuple, opts, allocated_positionals)
        tuple.all? do |name, forbidden_value|
          if opts.key?(name)
            opts[name] == forbidden_value
          elsif allocated_positionals.key?(name)
            allocated_positionals[name] == forbidden_value
          else
            false
          end
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

        return if condition && !conflict_present?(condition, opts, allocated_positionals)

        names = entry[:names]
        return if names.any? { |n| conflict_present?(n, opts, allocated_positionals) }

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
      # or an empty string. All other values — including non-empty arrays — are
      # present, regardless of their contents. This keeps validation consistent
      # with CLI emission: repeatable options (value_option, inline_value, etc.)
      # emit tokens for non-empty arrays even when every element is '' or false.
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
        # This enables direct splatting: `command(*bound_args)`.
        #
        # Operands declared with `skip_cli: true` are intentionally excluded.
        #
        # @return [Array<String>] the CLI arguments
        def to_ary
          @args_array
        end

        # Returns the CLI arguments array for splatting
        #
        # Ruby's splat operator in array literals uses `to_a` for expansion.
        # This enables: `['git', 'branch', *bound_args]`.
        #
        # Operands declared with `skip_cli: true` are intentionally excluded.
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

            define_singleton_method(predicate_name) { flag_predicate?(@options[name]) }
          end
        end

        def flag_predicate?(value)
          return value.positive? if value.is_a?(Integer)

          value == true
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

        # Allocates leading positional values and returns consumed non-nil count
        #
        # @param allocation [Hash{Symbol => Object}] allocation hash to populate
        #
        # @return [Integer] number of non-nil positional values consumed
        #
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
            @consumed += 1
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
