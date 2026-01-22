# frozen_string_literal: true

module Git
  module Commands
    # Git::Commands::Arguments provides a DSL for defining command-line arguments
    # (both options and positional arguments) for Git commands.
    #
    # @api private
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
    # == Option Types
    #
    # The DSL supports several option types:
    #
    # - {#flag} - Boolean flag (--flag when true)
    # - {#negatable_flag} - Boolean flag with negation (--flag or --no-flag)
    # - {#value} - Valued option (--flag value as separate arguments)
    # - {#inline_value} - Inline valued option (--flag=value as single argument)
    # - {#flag_or_inline_value} - Flag or inline value (--flag or --flag=value)
    # - {#negatable_flag_or_inline_value} - Negatable flag or inline value
    # - {#static} - Static flag always included
    # - {#custom} - Custom option with builder block
    # - {#metadata} - Validation-only option (not included in command output)
    #
    # Both {#value} and {#inline_value} support a `multi_valued: true` parameter
    # that allows the option to accept an array of values, repeating the flag for each:
    #
    # @example Multi-valued options
    #   value :config, multi_valued: true
    #   # config: ['a=b', 'c=d'] => ['--config', 'a=b', '--config', 'c=d']
    #
    #   inline_value :sort, multi_valued: true
    #   # sort: ['refname', '-committerdate'] => ['--sort=refname', '--sort=-committerdate']
    #
    # == Positional Arguments
    #
    # Positional arguments are mapped using Ruby-like semantics for a supported
    # subset of method signature layouts:
    #
    # 1. Required positionals before variadic are filled first (left to right)
    # 2. Required positionals after variadic are filled from the end
    # 3. Optional positionals (with defaults) are filled with remaining args
    # 4. Variadic positional gets whatever is left in the middle
    #
    # @note Not all valid Ruby parameter layouts are supported. In particular,
    #   combinations that place optional positionals before a variadic positional
    #   together with post-variadic positionals (e.g., `def foo(a = 1, *rest, tail)`)
    #   are not handled correctly and should be avoided in command definitions.
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
    #   inline_value :date, type: String
    #   # Valid: date: "2024-01-01"
    #   # Invalid: date: 12345
    #   #   => ArgumentError: The :date option must be a String, but was a Integer
    #
    # @example Multiple type validation (allows any of the specified types)
    #   inline_value :timeout, type: [Integer, Float]
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
      end

      # Define a boolean flag option (--flag when true)
      #
      # @param names [Symbol, Array<Symbol>] the option name(s), first is primary
      # @param args [String, Array<String>, nil] custom argument(s) to output (e.g., '-r' or ['--amend', '--no-edit'])
      # @param type [Class, Array<Class>, nil] expected type(s) for validation. Raises ArgumentError with
      #   descriptive message if value doesn't match. Cannot be combined with validator:.
      # @return [void]
      #
      # @example With type validation
      #   flag :force, type: [TrueClass, FalseClass]
      #
      def flag(names, args: nil, type: nil)
        register_option(names, type: :flag, args: args, expected_type: type)
      end

      # Define a negatable boolean flag option (--flag when true, --no-flag when false)
      #
      # @param names [Symbol, Array<Symbol>] the option name(s), first is primary
      # @param args [String, Array<String>, nil] custom argument(s) to output (arrays only for flag types)
      # @param type [Class, Array<Class>, nil] expected type(s) for validation. Raises ArgumentError with
      #   descriptive message if value doesn't match. Cannot be combined with validator:.
      # @param validator [Proc, nil] optional validator block (cannot be combined with type:)
      # @return [void]
      #
      def negatable_flag(names, args: nil, type: nil, validator: nil)
        register_option(names, type: :negatable_flag, args: args, expected_type: type, validator: validator)
      end

      # Define a valued option (--flag value as separate arguments)
      #
      # @param names [Symbol, Array<Symbol>] the option name(s), first is primary
      # @param args [String, nil] custom flag string (arrays not supported for value types)
      # @param type [Class, Array<Class>, nil] expected type(s) for validation. Raises ArgumentError with
      #   descriptive message if value doesn't match. Cannot be combined with validator:.
      # @param allow_empty [Boolean] whether to include the flag even when value is an empty string.
      #   When false (default), empty strings are skipped entirely. When true, the flag and empty
      #   value are included in the output.
      # @param multi_valued [Boolean] whether to allow multiple values. When true, accepts an array
      #   of values and repeats the flag for each (e.g., --flag v1 --flag v2). A single value or nil
      #   is also accepted.
      # @return [void]
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
      def value(names, args: nil, type: nil, allow_empty: false, multi_valued: false)
        register_option(names, type: :value, args: args, expected_type: type, allow_empty: allow_empty,
                               multi_valued: multi_valued)
      end

      # Define an inline valued option (--flag=value as single argument)
      #
      # @param names [Symbol, Array<Symbol>] the option name(s), first is primary
      # @param args [String, nil] custom flag string (arrays not supported for value types)
      # @param type [Class, Array<Class>, nil] expected type(s) for validation. Raises ArgumentError with
      #   descriptive message if value doesn't match. Cannot be combined with validator:.
      # @param allow_empty [Boolean] whether to include the flag even when value is an empty string.
      #   When false (default), empty strings are skipped entirely. When true, the flag with empty
      #   value is included in the output (e.g., --message=).
      # @param multi_valued [Boolean] whether to allow multiple values. When true, accepts an array
      #   of values and repeats the flag for each (e.g., --flag=v1 --flag=v2). A single value or nil
      #   is also accepted.
      # @return [void]
      #
      # @example With type validation
      #   inline_value :date, type: String
      #   inline_value :timeout, type: [Integer, Float]
      #
      # @example With allow_empty
      #   inline_value :message, allow_empty: true
      #   # message: ""     => ['--message=']
      #   # message: "text" => ['--message=text']
      #
      #   inline_value :message  # allow_empty defaults to false
      #   # message: ""     => [] (skipped)
      #   # message: "text" => ['--message=text']
      #
      # @example With multi_valued
      #   inline_value :sort, multi_valued: true
      #   # sort: 'refname'                  => ['--sort=refname']
      #   # sort: ['refname', 'committerdate'] => ['--sort=refname', '--sort=committerdate']
      #   # sort: nil                         => []
      #
      def inline_value(names, args: nil, type: nil, allow_empty: false, multi_valued: false)
        register_option(names, type: :inline_value, args: args, expected_type: type, allow_empty: allow_empty,
                               multi_valued: multi_valued)
      end

      # Define a flag or inline value option (--flag when true, --flag=value when string)
      #
      # When the value is true, outputs just the flag (e.g., --gpg-sign)
      # When the value is a string, outputs flag with inline value (e.g., --gpg-sign=<key-id>)
      # When the value is nil/false, outputs nothing
      #
      # @param names [Symbol, Array<Symbol>] the option name(s), first is primary
      # @param args [String, nil] custom flag string (arrays not supported for value types)
      # @param type [Class, Array<Class>, nil] expected type(s) for validation. Raises ArgumentError with
      #   descriptive message if value doesn't match. Cannot be combined with validator:.
      # @return [void]
      #
      # @example
      #   flag_or_inline_value :gpg_sign
      #   # true  => --gpg-sign
      #   # "KEY" => --gpg-sign=KEY
      #   # nil   => (nothing)
      #
      def flag_or_inline_value(names, args: nil, type: nil)
        register_option(names, type: :flag_or_inline_value, args: args, expected_type: type)
      end

      # Define a negatable flag or inline value option
      #
      # When the value is true, outputs just the flag (e.g., --gpg-sign)
      # When the value is false, outputs negated flag (e.g., --no-gpg-sign)
      # When the value is a string, outputs flag with inline value (e.g., --gpg-sign=<key-id>)
      # When the value is nil, outputs nothing
      #
      # @param names [Symbol, Array<Symbol>] the option name(s), first is primary
      # @param args [String, nil] custom flag string (arrays not supported for value types)
      # @param type [Class, Array<Class>, nil] expected type(s) for validation. Raises ArgumentError with
      #   descriptive message if value doesn't match. Cannot be combined with validator:.
      # @return [void]
      #
      # @example
      #   negatable_flag_or_inline_value :gpg_sign
      #   # true  => --gpg-sign
      #   # false => --no-gpg-sign
      #   # "KEY" => --gpg-sign=KEY
      #   # nil   => (nothing)
      #
      def negatable_flag_or_inline_value(names, args: nil, type: nil)
        register_option(names, type: :negatable_flag_or_inline_value, args: args, expected_type: type)
      end

      # Define a static flag that is always included
      #
      # @param flag_string [String] the static flag string (e.g., '--no-progress')
      # @return [void]
      #
      def static(flag_string)
        @static_flags << flag_string
      end

      # Define a custom option with a custom builder block
      #
      # @param names [Symbol, Array<Symbol>] the option name(s), first is primary
      # @yield [value] block that receives the option value and returns the argument string
      # @return [void]
      #
      def custom(names, &block)
        register_option(names, type: :custom, builder: block)
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
      #
      # @note Optional positionals before a variadic combined with required
      #   positionals after the variadic (e.g., `def foo(a = 1, *rest, b)`) is
      #   not supported. Use required positionals before the variadic instead.
      # @param separator [String, nil] separator string to insert before this
      #   positional in the output (e.g., '--' for the common pathspec separator)
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
      def positional(name, required: false, variadic: false, default: nil, separator: nil)
        validate_single_variadic!(name) if variadic

        @positional_definitions << {
          name: name,
          required: required,
          variadic: variadic,
          default: default,
          separator: separator
        }
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

      # Build command-line arguments from the given positionals and options
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
        validate_option_values!(normalized_opts)
        validate_conflicts!(normalized_opts)
        args = @static_flags.dup
        build_options(args, normalized_opts)
        build_positionals(args, positionals)
        args
      end

      def build_options(args, normalized_opts)
        @option_definitions.each do |name, definition|
          build_option(args, name, definition, normalized_opts[name])
        end
      end

      private

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
        BUILDERS[definition[:type]]&.call(args, arg_spec, value, definition)
      end

      def should_skip_option?(value, definition)
        return true if value.nil?
        return true if value == false && definition[:type] == :flag_or_inline_value

        value.respond_to?(:empty?) && value.empty? && !definition[:allow_empty]
      end

      # Build positional arguments following Ruby method signature semantics
      #
      # Ruby allocation rules:
      # 1. Required positionals before variadic are filled first (left to right)
      # 2. Required positionals after variadic are filled from the end
      # 3. Optional positionals are filled with remaining args
      # 4. Variadic positional gets whatever is left in the middle
      #
      # Example: def foo(a, b, *middle, c, d)
      #   foo(1, 2, 3, 4)    => a=1, b=2, middle=[], c=3, d=4
      #   foo(1, 2, 3, 4, 5) => a=1, b=2, middle=[3], c=4, d=5
      #
      def build_positionals(args, positionals)
        positionals = normalize_positionals(positionals)
        allocation, consumed_count = allocate_positionals(positionals)

        @positional_definitions.each do |definition|
          value = allocation[definition[:name]]
          validate_required_positional(value, definition)
          validate_no_nil_values!(value, definition)
          append_positional_to_args(args, value, definition)
        end

        # Check for unexpected positionals
        check_unexpected_positionals(positionals, consumed_count)
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
        variadic_index = find_variadic_index
        allocation = {}

        consumed_count = if variadic_index.nil?
                           allocate_without_variadic(positionals, allocation)
                         else
                           allocate_with_variadic(positionals, allocation, variadic_index)
                         end

        [allocation, consumed_count]
      end

      def find_variadic_index
        @positional_definitions.find_index { |d| d[:variadic] }
      end

      def allocate_without_variadic(positionals, allocation)
        consumed = 0
        @positional_definitions.each_with_index do |definition, index|
          value = positionals[index]
          allocation[definition[:name]] = value.nil? ? definition[:default] : value
          consumed += 1 if index < positionals.size && !positionals[index].nil?
        end
        consumed
      end

      def allocate_with_variadic(positionals, allocation, variadic_index)
        pre_defs, variadic_def, post_defs = split_definitions_around_variadic(variadic_index)
        reserved_for_post = calculate_post_variadic_reservation(positionals.size, pre_defs.size, post_defs.size)

        pre_consumed = allocate_pre_variadic(positionals, allocation, pre_defs)
        post_start = positionals.size - reserved_for_post
        post_consumed = allocate_post_variadic(positionals, allocation, post_defs, post_start)
        variadic_consumed = allocate_variadic(positionals, allocation, variadic_def, pre_defs.size, post_start)

        pre_consumed + variadic_consumed + post_consumed
      end

      def split_definitions_around_variadic(variadic_index)
        [
          @positional_definitions[0...variadic_index],
          @positional_definitions[variadic_index],
          @positional_definitions[(variadic_index + 1)..]
        ]
      end

      def calculate_post_variadic_reservation(positionals_size, pre_count, post_count)
        available = [positionals_size - pre_count, 0].max
        [available, post_count].min
      end

      def allocate_pre_variadic(positionals, allocation, pre_defs)
        consumed = 0
        pre_defs.each_with_index do |definition, index|
          value = positionals[index]
          allocation[definition[:name]] = value.nil? ? definition[:default] : value
          consumed += 1 if index < positionals.size && !positionals[index].nil?
        end
        consumed
      end

      def allocate_post_variadic(positionals, allocation, post_defs, post_start)
        consumed = 0
        post_defs.each_with_index do |definition, offset|
          pos_index = post_start + offset
          value = pos_index < positionals.size ? positionals[pos_index] : nil
          allocation[definition[:name]] = value.nil? ? definition[:default] : value
          consumed += 1 if pos_index < positionals.size && !positionals[pos_index].nil?
        end
        consumed
      end

      def allocate_variadic(positionals, allocation, variadic_def, variadic_start, variadic_end)
        variadic_values = positionals[variadic_start...variadic_end] || []
        allocation[variadic_def[:name]] =
          if variadic_values.empty? || variadic_values.all?(&:nil?)
            variadic_def[:default]
          else
            variadic_values
          end
        variadic_values.compact.size
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
  end
end
