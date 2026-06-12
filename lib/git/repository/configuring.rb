# frozen_string_literal: true

require 'git/commands/config_option_syntax'
require 'git/repository/shared_private'

module Git
  class Repository
    # Facade methods for reading and writing git configuration
    #
    # Provides the {#config} and {#global_config} methods, which dispatch to read a
    # single entry, list all entries, or write a value depending on the arguments
    # supplied. {#config} uses git's default config scope (reads from the full
    # resolution chain; set operations write to the repository's `.git/config`);
    # {#global_config} targets the git global config scope (`git config --global`).
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
      #   @param value [#to_s] the value to assign; must not be `nil` (a `nil`
      #     value is treated as "no value" and routes to the get overload).
      #     Any non-nil object is converted to a String via `#to_s` before
      #     being passed to git
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
        if !name.nil? && !value.nil?
          Private.config_set(@execution_context, name, value, **options)
        elsif name
          Private.config_get(@execution_context, name)
        else
          Private.config_list(@execution_context)
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
        if !name.nil? && !value.nil?
          Private.global_config_set(@execution_context, name, value)
        elsif !name.nil?
          Private.global_config_get(@execution_context, name)
        else
          Private.global_config_list(@execution_context)
        end
      end

      # @deprecated Use {#global_config} instead.
      def global_config_get(name)
        Git::Deprecation.warn(
          'Git::Repository#global_config_get is deprecated and will be removed in a future version. ' \
          'Use global_config(name) instead.'
        )
        global_config(name)
      end

      # @deprecated Use {#global_config} instead.
      def global_config_list
        Git::Deprecation.warn(
          'Git::Repository#global_config_list is deprecated and will be removed in a future version. ' \
          'Use global_config instead.'
        )
        global_config
      end

      # @deprecated Use {#global_config} instead.
      def global_config_set(name, value)
        Git::Deprecation.warn(
          'Git::Repository#global_config_set is deprecated and will be removed in a future version. ' \
          'Use global_config(name, value) instead.'
        )
        global_config(name, value)
      end

      # Return a single git configuration entry
      #
      # @deprecated Use {#config} with a name argument instead.
      #
      # @example Get the committer name from config
      #   repo.config_get('user.name') #=> "Alice"
      #
      # @param name [String] the dotted config key to look up (e.g. `"user.name"`)
      #
      # @return [String] the value of the config entry
      #
      # @raise [Git::FailedError] if git exits with a non-zero exit status
      #
      # @see #config
      #
      def config_get(name)
        Git::Deprecation.warn(
          'Git::Repository#config_get is deprecated and will be removed in a future version. ' \
          'Use config(name) instead.'
        )
        config(name)
      end

      # Return all git configuration entries as a Hash
      #
      # @deprecated Use {#config} with no arguments instead.
      #
      # @example List all config entries
      #   repo.config_list #=> { "user.name" => "Alice", "core.bare" => "false" }
      #
      # @return [Hash{String => String}] all visible config entries, keyed by their
      #   full dotted key names (e.g. `"user.name"`)
      #
      # @raise [Git::FailedError] if git exits with a non-zero exit status
      #
      # @see #config
      #
      def config_list
        Git::Deprecation.warn(
          'Git::Repository#config_list is deprecated and will be removed in a future version. ' \
          'Use config instead.'
        )
        config
      end

      # Write a git configuration entry
      #
      # @deprecated Use {#config} with name and value arguments instead.
      #
      # @example Set the committer name in local config
      #   repo.config_set('user.name', 'Alice')
      #
      # @param name [String] the dotted config key to write (e.g. `"user.name"`)
      #
      # @param value [#to_s] the value to assign; must not be `nil` (a `nil`
      #   value is treated as "no value" and routes to the get overload).
      #   Any non-nil object is converted to a String via `#to_s` before
      #   being passed to git
      #
      # @param opts [Hash] options for the set operation
      #
      # @option opts [String, nil] :file (nil) path to a custom config file to
      #   write to instead of the repository's default `.git/config`
      #
      # @return [Git::CommandLineResult] the raw result of `git config <name> <value>`
      #
      # @raise [ArgumentError] if unsupported options are provided
      #
      # @raise [Git::FailedError] if git exits with a non-zero exit status
      #
      # @see #config
      #
      def config_set(name, value, opts = {})
        Git::Deprecation.warn(
          'Git::Repository#config_set is deprecated and will be removed in a future version. ' \
          'Use config(name, value, options) instead.'
        )
        config(name, value, opts)
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
