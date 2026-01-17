# frozen_string_literal: true

module Git
  module Commands
    # Git::Commands::Options provides a DSL for defining command-line options
    # and positional arguments for Git commands.
    #
    # @example Defining options for a command
    #   OPTIONS = Git::Commands::Options.define do
    #     flag :force
    #     value :branch
    #     positional :repository, required: true
    #   end
    #
    # @example Building command-line arguments
    #   OPTIONS.build('https://github.com/user/repo', force: true, branch: 'main')
    #   # => ['--force', '--branch', 'main', 'https://github.com/user/repo']
    #
    class Options
      # Define a new Options instance using the DSL
      #
      # @yield The block where options are defined using DSL methods
      # @return [Options] The configured Options instance
      #
      # @example
      #   options = Git::Command::Options.define do
      #     flag :verbose
      #   end
      #
      def self.define(&block)
        options = new
        options.instance_eval(&block) if block
        options
      end

      def initialize
        @option_definitions = {}
        @alias_map = {} # Maps alias keys to primary keys
        @static_flags = []
        @positional_definitions = []
      end

      # Define a boolean flag option (--flag when true)
      #
      # @param names [Symbol, Array<Symbol>] the option name(s), first is primary
      # @param flag [String, nil] custom flag string (e.g., '-r' instead of '--recursive')
      # @return [void]
      #
      def flag(names, flag: nil)
        register_option(names, type: :flag, flag: flag)
      end

      # Define a negatable boolean flag option (--flag when true, --no-flag when false)
      #
      # @param names [Symbol, Array<Symbol>] the option name(s), first is primary
      # @param flag [String, nil] custom flag string
      # @param validator [Proc, nil] optional validator proc that receives the value and returns true if valid
      # @return [void]
      #
      def negatable_flag(names, flag: nil, validator: nil)
        register_option(names, type: :negatable_flag, flag: flag, validator: validator)
      end

      # Define a valued option (--flag value as separate arguments)
      #
      # @param names [Symbol, Array<Symbol>] the option name(s), first is primary
      # @param flag [String, nil] custom flag string
      # @return [void]
      #
      def value(names, flag: nil)
        register_option(names, type: :value, flag: flag)
      end

      # Define an inline valued option (--flag=value as single argument)
      #
      # @param names [Symbol, Array<Symbol>] the option name(s), first is primary
      # @param flag [String, nil] custom flag string
      # @return [void]
      #
      def inline_value(names, flag: nil)
        register_option(names, type: :inline_value, flag: flag)
      end

      # Define a multi-value option (--flag value repeated for each value)
      #
      # @param names [Symbol, Array<Symbol>] the option name(s), first is primary
      # @param flag [String, nil] custom flag string
      # @return [void]
      #
      def multi_value(names, flag: nil)
        register_option(names, type: :multi_value, flag: flag)
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

      # Define a positional argument
      #
      # @param name [Symbol] the positional argument name
      # @param required [Boolean] whether the argument is required
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
        @option_definitions[primary] = definition
        keys.each { |key| @alias_map[key] = primary }
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
        args = @static_flags.dup
        @option_definitions.each do |name, definition|
          build_option(args, name, definition, normalized_opts[name])
        end
        build_positionals(args, positionals)
        args
      end

      private

      BUILDERS = {
        flag: ->(args, flag_name, value, _) { args << flag_name if value },
        negatable_flag: lambda do |args, flag_name, value, _|
          args << (value ? flag_name : flag_name.sub(/\A--/, '--no-'))
        end,
        value: ->(args, flag_name, value, _) { args << flag_name << value.to_s },
        inline_value: ->(args, flag_name, value, _) { args << "#{flag_name}=#{value}" },
        multi_value: ->(args, flag_name, value, _) { Array(value).each { |v| args << flag_name << v.to_s } },
        custom: lambda do |args, _, value, definition|
          result = definition[:builder]&.call(value)
          result.is_a?(Array) ? args.concat(result) : (args << result if result)
        end,
        metadata: ->(*) {}
      }.freeze
      private_constant :BUILDERS

      def build_option(args, name, definition, value)
        return if value.nil? || (value.respond_to?(:empty?) && value.empty?)

        flag_name = definition[:flag] || "--#{name.to_s.tr('_', '-')}"
        BUILDERS[definition[:type]]&.call(args, flag_name, value, definition)
      end

      def build_positionals(args, positionals)
        positionals = normalize_positionals(positionals)
        positional_index = 0

        @positional_definitions.each do |definition|
          value = extract_positional_value(positionals, positional_index, definition)
          validate_required_positional(value, definition)
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

        raise ArgumentError, "#{definition[:name]} is required"
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
          next if validator.call(opts[name])

          raise ArgumentError, "Invalid value for option: #{name}"
        end
      end
    end
  end
end
