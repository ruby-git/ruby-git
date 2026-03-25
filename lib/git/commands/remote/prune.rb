# frozen_string_literal: true

require 'git/commands/base'

module Git
  module Commands
    module Remote
      # Implements the `git remote prune` command
      #
      # Deletes stale remote-tracking refs that no longer exist on the named remote.
      #
      # @see Git::Commands::Remote
      # @see https://git-scm.com/docs/git-remote git-remote
      #
      # @api private
      class Prune < Git::Commands::Base
        arguments do
          literal 'remote'
          literal 'prune'
          flag_option %i[dry_run n]

          end_of_options

          operand :name, repeatable: true, required: true
        end

        # @!method call(*, **)
        #
        #   @overload call(*name, **options)
        #
        #     Execute the `git remote prune` command
        #
        #     @param name [Array<String>] One or more remote names to prune
        #
        #     @param options [Hash] command options
        #
        #     @option options [Boolean] :dry_run (nil) Report what would be pruned without deleting refs
        #
        #       Alias: :n
        #
        #     @return [Git::CommandLineResult] the result of calling `git remote prune`
        #
        #     @raise [ArgumentError] if no remote names are provided
        #
        #     @raise [Git::FailedError] if git exits with a non-zero exit status
      end
    end
  end
end
