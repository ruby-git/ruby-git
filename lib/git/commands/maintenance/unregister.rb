# frozen_string_literal: true

require 'git/commands/base'

module Git
  module Commands
    module Maintenance
      # Remove the current repository from background maintenance
      #
      # @example Unregister the repository from maintenance
      #   Git::Commands::Maintenance::Unregister.new(execution_context).call
      #
      # @example Force unregister even if repository is not registered
      #   Git::Commands::Maintenance::Unregister.new(execution_context).call(force: true)
      #
      # @note `arguments` block audited against https://git-scm.com/docs/git-maintenance/2.54.0
      #
      # @see Git::Commands::Maintenance Git::Commands::Maintenance for the full sub-command list
      #
      # @see https://git-scm.com/docs/git-maintenance git-maintenance documentation
      #
      # @api private
      #
      class Unregister < Git::Commands::Base
        requires_git_version '2.30.0'

        arguments do
          literal 'maintenance'
          literal 'unregister'

          flag_or_value_option :config_file, negatable: true
          flag_option :force, negatable: true
          execution_option :env
        end

        # @!method call(*, **)
        #
        #   @overload call(**options)
        #
        #     Remove the current repository from background maintenance
        #
        #     This only removes the repository from the configured list.
        #     It does not stop the background maintenance processes from running.
        #
        #     Reports an error if the current repository is not already registered,
        #     unless `--force` is used.
        #
        #     @param options [Hash] command options
        #
        #     @option options [Boolean, String] :config_file (false) use a specified
        #       config file instead of the global config (`--config-file`)
        #
        #       When a String, the path is passed as `--config-file <file>`.
        #
        #     @option options [Boolean] :no_config_file (false) disable the config file
        #       (`--no-config-file`)
        #
        #     @option options [Boolean] :force (false) return success even if repository is not registered
        #       (`--force`)
        #
        #     @option options [Boolean] :no_force (false) fail if the repository is not registered
        #       (`--no-force`)
        #
        #     @option options [Hash] :env (nil) environment variables to set for the git
        #       process; merged with the default environment; not passed to the git CLI
        #
        #     @return [Git::CommandLineResult] the result of calling `git maintenance unregister`
        #
        #     @raise [ArgumentError] if unsupported options are provided
        #
        #     @raise [Git::FailedError] if git exits with a non-zero exit status
        #
        #     @raise [Git::VersionError] if git version is below 2.30.0
        #
        #     @api public
      end
    end
  end
end
