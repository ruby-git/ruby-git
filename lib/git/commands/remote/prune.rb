# frozen_string_literal: true

require 'git/commands/base'

module Git
  module Commands
    module Remote
      # `git remote prune` command
      #
      # Deletes stale remote-tracking refs that no longer exist on the named remote.
      #
      # @example Dry-run to preview which refs would be pruned
      #   prune = Git::Commands::Remote::Prune.new(execution_context)
      #   prune.call('origin', dry_run: true)
      #
      # @example Prune stale tracking refs for a remote
      #   prune = Git::Commands::Remote::Prune.new(execution_context)
      #   prune.call('origin')
      #
      # @note `arguments` block audited against https://git-scm.com/docs/git-remote/2.53.0
      #
      # @see Git::Commands::Remote
      #
      # @see https://git-scm.com/docs/git-remote git-remote
      #
      # @api private
      #
      class Prune < Git::Commands::Base
        arguments do
          literal 'remote'
          literal 'prune'
          flag_option %i[dry_run n] # --dry-run (alias: :n)

          end_of_options

          operand :name, repeatable: true, required: true
        end

        # @!method call(*, **)
        #
        #   @overload call(*name, **options)
        #
        #     Prune stale remote-tracking refs for one or more remotes
        #
        #     @param name [Array<String>] one or more remote names to prune
        #
        #     @param options [Hash] command options
        #
        #     @option options [Boolean] :dry_run (nil) report what would be pruned without deleting refs
        #
        #       Alias: :n
        #
        #     @return [Git::CommandLineResult] the result of calling `git remote prune`
        #
        #     @raise [ArgumentError] if unsupported options are provided
        #
        #     @raise [Git::FailedError] if git exits with a non-zero exit status
      end
    end
  end
end
