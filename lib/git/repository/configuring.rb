# frozen_string_literal: true

require 'git/commands/config_option_syntax'
require 'git/repository/shared_private'

module Git
  class Repository
    # Facade methods for reading and writing git configuration
    #
    # Provides the {#config} method, which dispatches to read a single entry,
    # list all entries, or write a value depending on the arguments supplied.
    #
    # Included by {Git::Repository}.
    #
    # @api public
    #
    module Configuring
      # Option keys accepted by {#config} when writing a value
      CONFIG_SET_ALLOWED_OPTS = %i[file].freeze
      private_constant :CONFIG_SET_ALLOWED_OPTS

      # Read or write a git configuration entry
      #
      # Dispatches to one of three modes depending on the arguments supplied:
      #
      # * **List** — `config()` returns all visible config entries as a `Hash`.
      # * **Get** — `config(name)` returns the value for a single key as a `String`.
      # * **Set** — `config(name, value)` writes a value and returns the raw
      #   command result.
      #
      # @overload config
      #
      #   @example List all config entries
      #     repo.config #=> { "user.name" => "Alice", "core.bare" => "false" }
      #
      #   @return [Hash{String => String}] all visible config entries, keyed by
      #     their full dotted key names (e.g. `"user.name"`)
      #
      # @overload config(name)
      #
      #   @example Read the committer name from config
      #     repo.config('user.name') #=> "Alice"
      #
      #   @param name [String] the dotted config key to look up (e.g.
      #     `"user.name"`)
      #
      #   @return [String] the value of the config entry
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
      #   @param value [String] the value to assign
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
        if name && value
          Private.config_set(@execution_context, name, value, **options)
        elsif name
          Private.config_get(@execution_context, name)
        else
          Private.config_list(@execution_context)
        end
      end

      # Private helpers local to {Git::Repository::Configuring}
      #
      # @api private
      #
      module Private
        module_function

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
        # @return [String] the value of the config entry
        #
        # @raise [Git::FailedError] if git exits with a non-zero exit status
        #
        def config_get(execution_context, name)
          result = Git::Commands::ConfigOptionSyntax::Get.new(execution_context).call(name)
          raise Git::FailedError, result if result.status.exitstatus != 0

          result.stdout
        end

        # Retrieve all config entries as a hash
        #
        # @param execution_context [Git::ExecutionContext] the execution context
        #
        # @return [Hash{String => String}] all config entries, keyed by their full
        #   dotted key names (e.g. `"user.name"`)
        #
        # @raise [Git::FailedError] if git exits with a non-zero exit status
        #
        def config_list(execution_context)
          lines = Git::Commands::ConfigOptionSyntax::List.new(execution_context).call.stdout.split("\n")
          lines.each_with_object({}) do |line, hsh|
            key, value = line.split('=', 2)
            hsh[key] = value || ''
          end
        end
      end

      private_constant :Private
    end
  end
end
