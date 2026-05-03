# frozen_string_literal: true

module Git
  # Takes a hash of user options and a declarative map and produces
  # an array of command-line arguments. Also validates that only
  # supported options are provided based on the map.
  #
  # @api private
  class ArgsBuilder
    # This hash maps an option type to a lambda that knows how to build the
    # corresponding command-line argument. This is a scalable dispatch table.
    ARG_BUILDERS = {
      boolean: ->(config, value) { value ? config[:flag] : [] },

      valued_equals: ->(config, value) { "#{config[:flag]}=#{value}" if value },

      valued_space: ->(config, value) { [config[:flag], value.to_s] if value },

      repeatable_valued_space: lambda do |config, value|
        Array(value).flat_map { |v| [config[:flag], v.to_s] }
      end,

      custom: ->(config, value) { config[:builder].call(value) },

      validate_only: ->(_config, _value) { [] } # Does not build any args
    }.freeze

    # Main entrypoint to validate options and build arguments
    def self.build(opts, option_map)
      validate!(opts, option_map)
      new(opts, option_map).build
    end

    # Public validation method that can be called independently
    def self.validate!(opts, option_map)
      validate_unsupported_keys!(opts, option_map)
      validate_configured_options!(opts, option_map)
    end

    def initialize(opts, option_map)
      @opts = opts
      @option_map = option_map
    end

    def build
      @option_map.flat_map do |config|
        type = config[:type]
        next config[:flag] if type == :static

        key = config[:keys].find { |k| @opts.key?(k) }
        next [] unless key

        build_arg_for_option(config, @opts[key])
      end.compact
    end

    private

    def build_arg_for_option(config, value)
      builder = ARG_BUILDERS[config[:type]]
      builder&.call(config, value) || []
    end

    private_class_method def self.validate_unsupported_keys!(opts, option_map)
      all_valid_keys = option_map.flat_map { |config| config[:keys] }.compact
      unsupported_keys = opts.keys - all_valid_keys

      return if unsupported_keys.empty?

      raise ArgumentError, "Unsupported options: #{unsupported_keys.map(&:inspect).join(', ')}"
    end

    private_class_method def self.validate_configured_options!(opts, option_map)
      option_map.each do |config|
        next unless config[:keys] # Skip static flags

        check_for_missing_required_option!(opts, config)
        validate_option_value!(opts, config)
      end
    end

    private_class_method def self.check_for_missing_required_option!(opts, config)
      return unless config[:required]

      key_provided = config[:keys].any? { |k| opts.key?(k) }
      return if key_provided

      raise ArgumentError, "Missing required option: #{config[:keys].first}"
    end

    private_class_method def self.validate_option_value!(opts, config)
      validator = config[:validator]
      return unless validator

      user_key = config[:keys].find { |k| opts.key?(k) }
      return unless user_key # Don't validate if the user didn't provide the option

      return if validator.call(opts[user_key])

      raise ArgumentError, "Invalid value for option: #{user_key}"
    end
  end
end
