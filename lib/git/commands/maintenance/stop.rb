# frozen_string_literal: true

require 'git/commands/base'

module Git
  module Commands
    module Maintenance
      # Halt the background maintenance schedule
      #
      # @example Stop background maintenance
      #   Git::Commands::Maintenance::Stop.new(execution_context).call
      #
      # @note `arguments` block audited against https://git-scm.com/docs/git-maintenance/2.54.0
      #
      # @see Git::Commands::Maintenance Git::Commands::Maintenance for the full sub-command list
      #
      # @see https://git-scm.com/docs/git-maintenance git-maintenance documentation
      #
      # @api private
      #
      class Stop < Git::Commands::Base
        requires_git_version '2.30.0'

        arguments do
          literal 'maintenance'
          literal 'stop'

          execution_option :env
        end

        # @!method call(*, **)
        #
        #   @overload call(**options)
        #
        #     Halt the background maintenance schedule
        #
        #     The current repository is not removed from the list of maintained
        #     repositories, in case the background maintenance is restarted later.
        #
        #     @param options [Hash] command options
        #
        #     @option options [Hash] :env (nil) environment variables to set for the git
        #       process; merged with the default environment; not passed to the git CLI
        #
        #     @return [Git::CommandLineResult] the result of calling `git maintenance stop`
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
