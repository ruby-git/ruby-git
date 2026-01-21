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
      def value(names, args: nil, type: nil, allow_empty: false)
        register_option(names, type: :value, args: args, expected_type: type, allow_empty: allow_empty)
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
      def inline_value(names, args: nil, type: nil, allow_empty: false)
        register_option(names, type: :inline_value, args: args, expected_type: type, allow_empty: allow_empty)
      end

      # Define a multi-value option (--flag value repeated for each value)
      #
      # @param names [Symbol, Array<Symbol>] the option name(s), first is primary
      # @param args [String, nil] custom flag string (arrays not supported for value types)
      # @param type [Class, Array<Class>, nil] expected type(s) for validation. Raises ArgumentError with
      #   descriptive message if value doesn't match. Cannot be combined with validator:.
      # @return [void]
      #
      def multi_value(names, args: nil, type: nil)
        register_option(names, type: :multi_value, args: args, expected_type: type)
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
      # @param name [Symbol] the positional argument name
      # @param required [Boolean] whether the argument is required (for variadic, requires at least one value)
      # @param variadic [Boolean] whether the argument accepts multiple values
      # @param default [Object] the default value if not provided
      # @param separator [String, nil] separator to insert before this positional (e.g., '--')
      # @return [void]
      #
      def positional(name, required: false, variadic: false, default: nil, separator: nil)
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
        value: ->(args, arg_spec, value, _) { args << arg_spec << value.to_s },
        inline_value: ->(args, arg_spec, value, _) { args << "#{arg_spec}=#{value}" },
        multi_value: ->(args, arg_spec, value, _) { Array(value).each { |v| args << arg_spec << v.to_s } },
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

      def build_positionals(args, positionals)
        positionals = normalize_positionals(positionals)
        positional_index = 0

        @positional_definitions.each do |definition|
          value = extract_positional_value(positionals, positional_index, definition)
          validate_required_positional(value, definition)
          validate_no_nil_values!(value, definition)
          positional_index = append_positional(args, value, definition, positional_index, positionals.size)
        end
      end

      def normalize_positionals(positionals)
        # Flatten if first element is an array (allows both splat and array syntax)
        positionals = positionals.first if positionals.size == 1 && positionals.first.is_a?(Array)
        Array(positionals)
      end

      def append_positional(args, value, definition, index, total)
        return index if value_empty?(value)

        args << definition[:separator] if definition[:separator]

        if definition[:variadic]
          args.concat(Array(value).map(&:to_s))
          total # consume all remaining
        else
          args << value.to_s
          index + 1
        end
      end

      def extract_positional_value(positionals, index, definition)
        if definition[:variadic]
          values = positionals[index..]
          values.empty? ? definition[:default] : values
        else
          positionals[index] || definition[:default]
        end
      end

      def validate_required_positional(value, definition)
        return unless definition[:required]
        return unless value_empty?(value)

        raise ArgumentError, "at least one value is required for #{definition[:name]}" if definition[:variadic]

        raise ArgumentError, "#{definition[:name]} is required"
      end

      def validate_no_nil_values!(value, definition)
        return unless definition[:variadic]
        return if value_empty?(value)

        values = Array(value)
        return unless values.any?(&:nil?)

        raise ArgumentError, "nil values are not allowed in variadic positional argument: #{definition[:name]}"
      end

      def value_empty?(value)
        value.nil? || (value.respond_to?(:empty?) && value.empty?)
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
