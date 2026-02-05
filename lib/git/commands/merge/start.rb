# frozen_string_literal: true

require 'git/commands/arguments'

module Git
  module Commands
    module Merge
      # Implements the `git merge` command for merging branches
      #
      # This command joins two or more development histories together by
      # incorporating changes from named commits into the current branch.
      #
      # @see https://git-scm.com/docs/git-merge git-merge
      #
      # @api private
      #
      # @example Simple merge
      #   merge = Git::Commands::Merge::Start.new(execution_context)
      #   merge.call('feature')
      #
      # @example Merge with no fast-forward
      #   merge.call('feature', ff: false, message: 'Merge feature branch')
      #
      # @example Squash merge
      #   merge.call('feature', squash: true)
      #
      # @example Merge with strategy option
      #   merge.call('feature', strategy: 'ort', strategy_option: 'theirs')
      #
      # @example Octopus merge (multiple branches)
      #   merge.call('branch1', 'branch2', 'branch3')
      #
      class Start
        # Arguments DSL for building command-line arguments
        #
        # NOTE: The order of definitions determines the order of arguments
        # in the final command line.
        #
        ARGS = Arguments.define do
          literal 'merge'
          # Always suppress editor (non-interactive use)
          literal '--no-edit'

          # Commit behavior
          flag_option :commit, negatable: true
          flag_option :squash, args: '--squash'

          # Fast-forward behavior
          flag_option :ff, negatable: true
          flag_option :ff_only, args: '--ff-only'

          # Message options
          value_option %i[message m], args: '-m'
          value_option %i[file F], args: '-F'
          value_option :into_name, inline: true, args: '--into-name'

          # Strategy options
          value_option %i[strategy s], args: '-s'
          value_option %i[strategy_option X], args: '-X', repeatable: true

          # Verification
          flag_option :verify, negatable: true
          flag_option :verify_signatures, negatable: true
          flag_option :gpg_sign, negatable: true

          # History
          flag_option :allow_unrelated_histories, negatable: true
          flag_option :rerere_autoupdate, negatable: true

          # Other
          flag_option :autostash, negatable: true
          flag_option :signoff, negatable: true
          flag_option :log, negatable: true

          # Positional: commits to merge (variadic, required)
          operand :commits, repeatable: true, required: true
        end.freeze

        # Initialize the Merge::Start command
        #
        # @param execution_context [Git::ExecutionContext, Git::Lib] the context for executing git commands
        #
        def initialize(execution_context)
          @execution_context = execution_context
        end

        # Execute the git merge command
        #
        # @overload call(*commits, **options)
        #
        #   @param commits [Array<String>] One or more branch names, commit SHAs,
        #     or refs to merge into the current branch. Multiple commits create
        #     an octopus merge.
        #
        #   @param options [Hash] command options
        #
        #   @option options [Boolean] :commit (nil) Perform merge and commit.
        #     true for --commit, false for --no-commit
        #
        #   @option options [Boolean] :squash (nil) Create a single commit on top
        #     of current branch with the effect of merging another branch
        #
        #   @option options [Boolean] :ff (nil) Fast-forward behavior.
        #     true for --ff, false for --no-ff
        #
        #   @option options [Boolean] :ff_only (nil) Refuse to merge unless
        #     fast-forward is possible
        #
        #   @option options [String] :message (nil) Commit message for merge commit.
        #     Alias: :m
        #
        #   @option options [String] :file (nil) Read commit message from file.
        #     Alias: :F
        #
        #   @option options [String] :into_name (nil) Prepare merge message as if
        #     merging into this branch name
        #
        #   @option options [String] :strategy (nil) Merge strategy to use
        #     (e.g., 'ort', 'recursive', 'resolve', 'octopus', 'ours', 'subtree').
        #     Alias: :s
        #
        #   @option options [String, Array<String>] :strategy_option (nil) Pass
        #     option(s) to the merge strategy (e.g., 'ours', 'theirs', 'patience').
        #     Can be a single value or array for multiple -X flags. Alias: :X
        #
        #   @option options [Boolean] :verify (nil) Run pre-merge and commit-msg
        #     hooks. true for --verify, false for --no-verify
        #
        #   @option options [Boolean] :verify_signatures (nil) Verify commit
        #     signatures. true for --verify-signatures, false for
        #     --no-verify-signatures
        #
        #   @option options [Boolean] :gpg_sign (nil) GPG-sign the merge commit.
        #     true for --gpg-sign, false for --no-gpg-sign
        #
        #   @option options [Boolean] :allow_unrelated_histories (nil) Allow
        #     merging histories without common ancestor. true for
        #     --allow-unrelated-histories, false for --no-allow-unrelated-histories
        #
        #   @option options [Boolean] :rerere_autoupdate (nil) Allow rerere to
        #     update index. true for --rerere-autoupdate, false for
        #     --no-rerere-autoupdate
        #
        #   @option options [Boolean] :autostash (nil) Automatically stash/unstash
        #     before/after merge. true for --autostash, false for --no-autostash
        #
        #   @option options [Boolean] :signoff (nil) Add Signed-off-by trailer.
        #     true for --signoff, false for --no-signoff
        #
        #   @option options [Boolean] :log (nil) Include one-line descriptions
        #     from commits in merge message. true for --log, false for --no-log
        #
        # @return [Git::CommandLineResult] the result of the command
        #
        # @raise [Git::FailedError] if the merge fails (e.g., conflicts)
        #
        def call(*, **)
          args = ARGS.bind(*, **)
          @execution_context.command(*args)
        end
      end
    end
  end
end
