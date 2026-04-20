# frozen_string_literal: true

require 'git/commands/base'

module Git
  module Commands
    module Maintenance
      # Add the current repository to the maintenance config
      #
      # @example Register the repository for maintenance
      #   Git::Commands::Maintenance::Register.new(execution_context).call
      #
      # @example Register with a custom config file
      #   Git::Commands::Maintenance::Register.new(execution_context).call(config_file: '/path/to/config')
      #
      # @note `arguments` block audited against https://git-scm.com/docs/git-maintenance/2.54.0
      #
      # @see Git::Commands::Maintenance Git::Commands::Maintenance for the full sub-command list
      #
      # @see https://git-scm.com/docs/git-maintenance git-maintenance documentation
      #
      # @api private
      #
      class Register < Git::Commands::Base
        requires_git_version '2.30.0'

        arguments do
          literal 'maintenance'
          literal 'register'

          flag_or_value_option :config_file, negatable: true
          execution_option :env
        end

        # @!method call(*, **)
        #
        #   @overload call(**options)
        #
        #     Initialize config values so scheduled maintenance will start running
        #
        #     This adds the repository to the `maintenance.repo` config variable
        #     in the current user's global config (or the specified config file)
        #     and enables recommended configuration values for
        #     `maintenance.<task>.schedule`.
        #
        #     Also sets `maintenance.strategy` to 'incremental' if not previously set,
        #     and disables foreground maintenance by setting `maintenance.auto = false`
        #     in the current repository.
        #
        #     @param options [Hash] command options
        #
        #     @option options [Boolean, String] :config_file (nil) use a specified
        #       config file instead of the global config
        #
        #       When a String, the path is passed as `--config-file <file>`.
        #
        #       Pass `true` for `--config-file`, `false` for `--no-config-file`.
        #
        #     @option options [Hash] :env (nil) environment variables to set for the git
        #       process; merged with the default environment; not passed to the git CLI
        #
        #     @return [Git::CommandLineResult] the result of calling `git maintenance register`
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
