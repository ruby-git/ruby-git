# frozen_string_literal: true

require 'git/commands/base'

module Git
  module Commands
    module Maintenance
      # Initialize and start background maintenance on the current repository
      #
      # @example Start background maintenance with default scheduler
      #   Git::Commands::Maintenance::Start.new(execution_context).call
      #
      # @example Start with a specific scheduler
      #   Git::Commands::Maintenance::Start.new(execution_context).call(scheduler: 'crontab')
      #
      # @note `arguments` block audited against https://git-scm.com/docs/git-maintenance/2.54.0
      #
      # @see Git::Commands::Maintenance Git::Commands::Maintenance for the full sub-command list
      #
      # @see https://git-scm.com/docs/git-maintenance git-maintenance documentation
      #
      # @api private
      #
      class Start < Git::Commands::Base
        requires_git_version '2.30.0'

        arguments do
          literal 'maintenance'
          literal 'start'

          value_option :scheduler, inline: true
          execution_option :env
        end

        # @!method call(*, **)
        #
        #   @overload call(**options)
        #
        #     Initialize config values and start background maintenance
        #
        #     This performs the same config updates as `register`, then updates
        #     the background scheduler to run `git maintenance run --scheduled`
        #     on an hourly basis.
        #
        #     @param options [Hash] command options
        #
        #     @option options [String] :scheduler (nil) specify the scheduler to use
        #
        #       Must be one of 'auto', 'crontab', 'systemd-timer', 'launchctl', or 'schtasks'.
        #       When 'auto', the appropriate platform-specific scheduler is used.
        #       Default is 'auto'.
        #
        #     @option options [Hash] :env (nil) environment variables to set for the git
        #       process; merged with the default environment; not passed to the git CLI
        #
        #     @return [Git::CommandLineResult] the result of calling `git maintenance start`
        #
        #     @raise [ArgumentError] if unsupported options are provided
        #
        #     @raise [Git::FailedError] if git exits with a non-zero exit status
        #
        #     @raise [Git::VersionError] if git version is below 2.30.0
      end
    end
  end
end
