# frozen_string_literal: true

require 'git/commands/merge/start'
require 'git/repository/internal'

module Git
  class Repository
    # Facade methods for merge operations: merging branches into the current branch
    #
    # Included by {Git::Repository}.
    #
    # @api public
    #
    module Merging
      # Option keys accepted by {#merge}
      #
      # Derived from the 4.x option map for `Git::Lib#merge`.
      MERGE_ALLOWED_OPTS = %i[no_commit no_ff m message].freeze
      private_constant :MERGE_ALLOWED_OPTS

      # Merge one or more branches into the current branch
      #
      # The merge commit message may be given by the message positional argument, the
      # `:message` option, or the `:m` option; if more than one is provided, the
      # precedence is positional argument > `:message` > `:m`.
      #
      # @example Merge a single branch
      #   repo.merge('feature')
      #
      # @example Merge a branch with a no-fast-forward commit message
      #   repo.merge('feature', 'Merge feature into main', no_ff: true)
      #
      # @example Octopus merge of multiple branches
      #   repo.merge(%w[feature-a feature-b])
      #
      # @example Merge without committing
      #   repo.merge('feature', nil, no_commit: true)
      #
      # @param branch [String, Array<String>, #to_s] the branch or branches to merge
      #   into the current branch
      #
      #   when an Array is given, an octopus merge is performed; a {Git::Branch}
      #   object is coerced to a String via `#to_s`.
      #
      # @param message [String, nil] optional commit message for the merge commit
      #
      #   Translated to the `-m` flag internally. For fast-forward merges git ignores
      #   this value; use `no_ff: true` to ensure a merge commit is created and the
      #   message is recorded.
      #
      # @param opts [Hash] additional options forwarded to `git merge`
      #
      # @option opts [Boolean] :no_commit (false) stop before creating the merge commit
      #   (`--no-commit`)
      #
      # @option opts [Boolean] :no_ff (false) create a merge commit even when
      #   fast-forward is possible (`--no-ff`)
      #
      # @option opts [String] :message (nil) commit message
      #
      #   Prefer the `:m` option instead of this one. Translated to the `-m` flag.
      #   Identical to the positional `message` argument and the `:m` option.
      #
      # @option opts [String] :m (nil) commit message (`-m` flag)
      #
      # @return [String] git's stdout from the merge command
      #
      # @raise [ArgumentError] if unsupported options are provided
      #
      # @raise [Git::FailedError] if git exits with a non-zero exit status
      #
      def merge(branch, message = nil, opts = {})
        Git::Repository::Internal.assert_valid_opts!(MERGE_ALLOWED_OPTS, **opts)

        # Dup so callers who reuse the same opts hash are not affected
        opts = opts.dup

        # Merge positional message into opts so the rest of the logic is uniform
        opts[:message] = message if message

        # git merge uses -m, not --message; translate the key
        opts[:m] = opts.delete(:message) if opts.key?(:message)

        branches = Array(branch).map(&:to_s)
        Git::Commands::Merge::Start.new(@execution_context).call(*branches, no_edit: true, **opts).stdout
      end
    end
  end
end
