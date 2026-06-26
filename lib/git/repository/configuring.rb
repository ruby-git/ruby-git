# frozen_string_literal: true

require 'git/commands/config_option_syntax'
require 'git/repository/shared_private'

module Git
  class Repository
    # Legacy facade methods for reading and writing git configuration
    #
    # Provides the {#config} and {#global_config} dispatch methods for 4.x
    # compatibility. These methods return raw `String` / `Hash` values instead of
    # {Git::ConfigEntryInfo} objects and are retained so that internal callers such
    # as `Git::Status` continue to work unchanged.
    #
    # The structured `config_*` methods (e.g. `config_get`, `config_list`) are
    # provided by {Git::Configuring}, which is included directly into
    # {Git::Repository}.
    #
    # Included by {Git::Repository}.
    #
    # @api public
    #
    module Configuring
      # Option keys accepted by {#config} when writing a value
      CONFIG_SET_ALLOWED_OPTS = %i[file].freeze
      private_constant :CONFIG_SET_ALLOWED_OPTS

      # Option keys accepted by {#config} when reading a single value or listing
      CONFIG_READ_ALLOWED_OPTS = %i[file].freeze
      private_constant :CONFIG_READ_ALLOWED_OPTS

      CONFIG_DEPRECATION_WARNING = 'Git::Repository#config is deprecated and will be removed in v6.0.0. ' \
                                   'Use config_get(name), config_set(name, value), or config_list instead.'
      private_constant :CONFIG_DEPRECATION_WARNING

      GLOBAL_CONFIG_DEPRECATION_WARNING =
        'Git::Repository#global_config is deprecated and will be removed in v6.0.0. ' \
        'Use config_get(name, global: true), config_set(name, value, global: true), ' \
        'or config_list(global: true) instead.'
      private_constant :GLOBAL_CONFIG_DEPRECATION_WARNING

      # Read or write a git configuration entry
      #
      # Dispatches to one of three modes depending on the arguments supplied:
      #
      # * **List** — `config()` returns all visible config entries as a `Hash`.
      # * **Get** — `config(name)` returns the value for a single key as a `String`.
      # * **Set** — `config(name, value)` writes a value and returns the raw
      #   command result.
      #
      # @overload config(options = {})
      #
      #   @example List all config entries
      #     repo.config #=> { "user.name" => "Alice", "core.bare" => "false" }
      #
      #   @example List all entries from a custom config file
      #     repo.config(file: '/path/to/.gitconfig')
      #     #=> { "user.name" => "Alice", "core.bare" => "false" }
      #
      #   @param options [Hash] options for the list operation
      #
      #   @option options [String, nil] :file (nil) path to a custom config file
      #     to read from instead of the default resolution chain
      #
      #   @return [Hash{String => String}] all visible config entries, keyed by
      #     their full dotted key names (e.g. `"user.name"`)
      #
      #   @raise [ArgumentError] if unsupported options are provided
      #
      # @overload config(name, options = {})
      #
      #   @example Read the committer name from config
      #     repo.config('user.name') #=> "Alice"
      #
      #   @example Read a value from a custom config file
      #     repo.config('user.name', file: '/path/to/.gitconfig') #=> "Alice"
      #
      #   @param name [String] the dotted config key to look up (e.g.
      #     `"user.name"`)
      #
      #   @param options [Hash] options for the get operation
      #
      #   @option options [String, nil] :file (nil) path to a custom config file
      #     to read from instead of the default resolution chain
      #
      #   @return [String] the value of the config entry
      #
      #   @raise [ArgumentError] if unsupported options are provided
      #
      # @overload config(name, value, options = {})
      #
      #   @example Set the committer name in local config
      #     repo.config('user.name', 'Alice')
      #
      #   @example Write a value to a custom config file
      #     repo.config('user.name', 'Alice', file: '/path/to/custom/config')
      #
      #   @param name [String] the dotted config key to write (e.g.
      #     `"user.name"`)
      #
      #   @param value [#to_s] the value to assign; must not be `nil` (a `nil`
      #     value is treated as "no value" and routes to the get overload).
      #     Must not be a `Hash` (a Hash is treated as the `options` argument;
      #     call `value.to_s` explicitly before passing if a stringified Hash
      #     is genuinely needed). Any other non-nil object is converted to a
      #     String via `#to_s` before being passed to git
      #
      #   @param options [Hash] options for the set operation
      #
      #   @option options [String, nil] :file (nil) path to a custom config file
      #     to write to instead of the repository's default `.git/config`
      #
      #   @return [Git::CommandLineResult] the raw result of
      #     `git config <name> <value>`
      #
      #   @raise [ArgumentError] if unsupported options are provided
      #
      # @raise [Git::FailedError] if git exits with a non-zero exit status
      #
      def config(name = nil, value = nil, options = {})
        Git::Deprecation.warn(CONFIG_DEPRECATION_WARNING)
        name, value, options = Private.normalize_config_args(name, value, options)

        if !name.nil? && !value.nil?
          Private.config_set(@execution_context, name, value, **options)
        elsif name
          Private.config_get(@execution_context, name, **options)
        else
          Private.config_list(@execution_context, **options)
        end
      end

      # Read or write a global git configuration entry
      #
      # Dispatches to one of three modes depending on the arguments supplied,
      # targeting the git global config scope (`git config --global`):
      #
      # * **List** — `global_config()` returns all global config entries as a `Hash`.
      # * **Get** — `global_config(name)` returns the value for a single key as a `String`.
      # * **Set** — `global_config(name, value)` writes a value and returns the raw
      #   command result.
      #
      # @overload global_config
      #
      #   @example List all global config entries
      #     repo.global_config #=> { "user.name" => "Alice", "core.autocrlf" => "false" }
      #
      #   @return [Hash{String => String}] all global config entries, keyed by their
      #     full dotted key names (e.g. `"user.name"`)
      #
      #   @raise [Git::FailedError] if git exits with a non-zero exit status
      #
      # @overload global_config(name)
      #
      #   @example Read the global committer name
      #     repo.global_config('user.name') #=> "Alice"
      #
      #   @param name [String] the dotted config key to look up (e.g. `"user.name"`)
      #
      #   @return [String] the value of the global config entry
      #
      #   @raise [Git::FailedError] if git exits with a non-zero exit status
      #
      # @overload global_config(name, value)
      #
      #   @example Set the global committer name
      #     repo.global_config('user.name', 'Alice')
      #
      #   @param name [String] the dotted config key to write (e.g. `"user.name"`)
      #
      #   @param value [#to_s] the value to assign; any object is accepted and
      #     converted to a String via `#to_s` before being passed to git
      #
      #   @return [Git::CommandLineResult] the raw result of
      #     `git config --global <name> <value>`
      #
      #   @raise [Git::FailedError] if git exits with a non-zero exit status
      #
      def global_config(name = nil, value = nil)
        Git::Deprecation.warn(GLOBAL_CONFIG_DEPRECATION_WARNING)
        if !name.nil? && !value.nil?
          Private.global_config_set(@execution_context, name, value)
        elsif !name.nil?
          Private.global_config_get(@execution_context, name)
        else
          Private.global_config_list(@execution_context)
        end
      end

      # Private helpers local to {Git::Repository::Configuring}
      #
      # @api private
      #
      module Private
        module_function

        # Normalize `config()` positional arguments
        #
        # In Ruby 3.x, calling `config(file: '/path')` passes the hash as the
        # first positional argument. This helper re-maps those patterns so that
        # `name`, `value`, and `options` are always in their canonical positions.
        #
        # Raises `ArgumentError` for call shapes that are ambiguous or clearly
        # wrong, such as passing extra positional arguments after an options Hash.
        #
        # @param name [String, Hash, nil] the raw first argument to {#config}
        #
        # @param value [Object, Hash, nil] the raw second argument to {#config}
        #
        # @param options [Hash] the raw third argument to {#config}
        #
        # @return [Array(String|nil, Object|nil, Hash)] normalized [name, value, options]
        #
        # @raise [ArgumentError] if extra positional arguments follow an options Hash
        #
        def normalize_config_args(name, value, options)
          if name.is_a?(Hash)
            raise ArgumentError, 'unexpected positional arguments after options hash' if !value.nil? || !options.empty?

            [nil, nil, name]
          elsif value.is_a?(Hash)
            raise ArgumentError, 'unexpected third argument when second argument is options hash' unless options.empty?

            [name, nil, value]
          else
            [name, value, options]
          end
        end

        # Set a config value by key name
        #
        # @overload config_set(execution_context, name, value, **options)
        #
        #   @param execution_context [Git::ExecutionContext] the execution context
        #
        #   @param name [String] the dotted config key to write (e.g. `"user.name"`)
        #
        #   @param value [String] the value to assign
        #
        #   @param options [Hash] keyword options forwarded to the command
        #
        #   @option options [String, nil] :file (nil) path to a custom config file
        #     to write to instead of the repository's default `.git/config`
        #
        #   @return [Git::CommandLineResult] the raw result of
        #     `git config <name> <value>`
        #
        # @raise [ArgumentError] if unsupported options are provided
        #
        # @raise [Git::FailedError] if git exits with a non-zero exit status
        #
        def config_set(execution_context, name, value, **)
          SharedPrivate.assert_valid_opts!(CONFIG_SET_ALLOWED_OPTS, **)
          Git::Commands::ConfigOptionSyntax::Set.new(execution_context).call(name, value, **)
        end

        # Retrieve a config value by key name
        #
        # @param execution_context [Git::ExecutionContext] the execution context
        #
        # @param name [String] the dotted config key to look up (e.g. `"user.name"`)
        #
        # @param options [Hash] keyword options
        #
        # @option options [String, nil] :file (nil) path to a custom config file to read from
        #
        # @return [String] the value of the config entry
        #
        # @raise [ArgumentError] if unsupported options are provided
        #
        # @raise [Git::FailedError] if git exits with a non-zero exit status
        #
        def config_get(execution_context, name, **options)
          SharedPrivate.assert_valid_opts!(CONFIG_READ_ALLOWED_OPTS, **options)
          opts = options[:file] ? { file: options[:file] } : {}
          result = Git::Commands::ConfigOptionSyntax::Get.new(execution_context).call(name, **opts)
          raise Git::FailedError, result if result.status.exitstatus != 0

          result.stdout
        end

        # Retrieve all config entries as a hash
        #
        # @param execution_context [Git::ExecutionContext] the execution context
        #
        # @param options [Hash] keyword options
        #
        # @option options [String, nil] :file (nil) path to a custom config file to read from
        #
        # @return [Hash{String => String}] all config entries, keyed by their full
        #   dotted key names (e.g. `"user.name"`)
        #
        # @raise [ArgumentError] if unsupported options are provided
        #
        # @raise [Git::FailedError] if git exits with a non-zero exit status
        #
        def config_list(execution_context, **options)
          SharedPrivate.assert_valid_opts!(CONFIG_READ_ALLOWED_OPTS, **options)
          opts = options[:file] ? { file: options[:file] } : {}
          lines = Git::Commands::ConfigOptionSyntax::List.new(execution_context).call(**opts).stdout.split("\n")
          lines.each_with_object({}) do |line, hsh|
            key, value = line.split('=', 2)
            hsh[key] = value || ''
          end
        end

        # Retrieve a global config value by key name
        #
        # @param execution_context [Git::ExecutionContext] the execution context
        #
        # @param name [String] the dotted config key to look up (e.g. `"user.name"`)
        #
        # @return [String] the value of the global config entry
        #
        # @raise [Git::FailedError] if git exits with a non-zero exit status
        #
        def global_config_get(execution_context, name)
          result = Git::Commands::ConfigOptionSyntax::Get.new(execution_context).call(name, global: true)
          raise Git::FailedError, result if result.status.exitstatus != 0

          result.stdout
        end

        # Retrieve all global config entries as a hash
        #
        # @param execution_context [Git::ExecutionContext] the execution context
        #
        # @return [Hash{String => String}] all global config entries, keyed by their full
        #   dotted key names (e.g. `"user.name"`)
        #
        # @raise [Git::FailedError] if git exits with a non-zero exit status
        #
        def global_config_list(execution_context)
          lines = Git::Commands::ConfigOptionSyntax::List.new(execution_context).call(global: true).stdout.split("\n")
          lines.each_with_object({}) do |line, hsh|
            key, value = line.split('=', 2)
            hsh[key] = value || ''
          end
        end

        # Set a global config value by key name
        #
        # @param execution_context [Git::ExecutionContext] the execution context
        #
        # @param name [String] the dotted config key to write (e.g. `"user.name"`)
        #
        # @param value [#to_s] the value to assign; any object is accepted and
        #   converted to a String via `#to_s` before being passed to git
        #
        # @return [Git::CommandLineResult] the raw result of
        #   `git config --global <name> <value>`
        #
        # @raise [Git::FailedError] if git exits with a non-zero exit status
        #
        def global_config_set(execution_context, name, value)
          Git::Commands::ConfigOptionSyntax::Set.new(execution_context).call(name, value, global: true)
        end
      end

      private_constant :Private
    end
  end
end
