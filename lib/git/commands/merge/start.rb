# frozen_string_literal: true

require 'git/commands/base'

module Git
  module Commands
    module Merge
      # Implements `git merge` to incorporate changes from named commits
      #
      # Joins two or more development histories together by incorporating
      # changes from the named commits into the current branch.
      #
      # @example Simple merge
      #   merge = Git::Commands::Merge::Start.new(execution_context)
      #   merge.call('feature')
      #
      # @example Merge with no fast-forward
      #   merge.call('feature', ff: false, m: 'Merge feature branch')
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
      # @note `arguments` block audited against https://git-scm.com/docs/git-merge/2.53.0
      #
      # @see Git::Commands::Merge
      #
      # @see https://git-scm.com/docs/git-merge git-merge
      #
      # @api private
      #
      class Start < Git::Commands::Base
        arguments do
          literal 'merge'

          # Commit behavior
          flag_option :commit, negatable: true
          flag_option %i[edit e], negatable: true

          # Commit message cleanup
          value_option :cleanup, inline: true

          # Fast-forward behavior
          flag_option :ff, negatable: true
          flag_option :ff_only

          # Signing
          flag_or_value_option %i[gpg_sign S], negatable: true, inline: true

          # Log message
          flag_or_value_option :log, negatable: true, inline: true

          # Trailers
          flag_option :signoff, negatable: true

          # Stat display
          flag_option :stat, negatable: true
          flag_option :compact_summary

          # Squash
          flag_option :squash

          # Verification
          flag_option :verify, negatable: true

          # Strategy options
          value_option %i[strategy s], inline: true
          value_option %i[strategy_option X], inline: true, repeatable: true

          # Signature verification
          flag_option :verify_signatures, negatable: true

          # Verbosity and progress
          flag_option %i[quiet q]
          flag_option %i[verbose v]
          flag_option :progress, negatable: true

          # Stash and history
          flag_option :autostash, negatable: true
          flag_option :allow_unrelated_histories, negatable: true

          # Message options
          value_option :m
          value_option :into_name
          value_option %i[file F], inline: true

          # Conflict resolution
          flag_option :rerere_autoupdate, negatable: true
          flag_option :overwrite_ignore, negatable: true

          end_of_options

          # Positional: commits to merge (variadic, required)
          operand :commit, repeatable: true, required: true
        end

        # @!method call(*, **)
        #
        #   @overload call(*commit, **options)
        #
        #     Execute the git merge command
        #
        #     @param commit [Array<String>] one or more branch names, commit SHAs,
        #       or refs to merge into the current branch; multiple commits create
        #       an octopus merge
        #
        #     @param options [Hash] command options
        #
        #     @option options [Boolean] :commit (nil) perform merge and commit the result
        #
        #       `true` → `--commit`, `false` → `--no-commit`
        #
        #     @option options [Boolean] :edit (nil) open an editor for the merge commit message
        #
        #       `true` → `--edit`, `false` → `--no-edit`. Alias: `:e`
        #
        #     @option options [String] :cleanup (nil) how the merge message will be cleaned
        #       up before committing
        #
        #       Accepted values include `strip`, `whitespace`, `verbatim`,
        #       `scissors`, and `default`. Emits `--cleanup=<mode>`.
        #
        #     @option options [Boolean] :ff (nil) fast-forward behavior
        #
        #       `true` → `--ff`, `false` → `--no-ff`
        #
        #     @option options [Boolean] :ff_only (false) refuse to merge unless
        #       fast-forward is possible; emits `--ff-only`
        #
        #     @option options [Boolean, String] :gpg_sign (nil) GPG-sign the resulting
        #       merge commit
        #
        #       `true` → `--gpg-sign`, a String key ID → `--gpg-sign=<keyid>`,
        #       `false` → `--no-gpg-sign`. Alias: `:S`
        #
        #     @option options [Boolean, Integer] :log (nil) populate the merge message
        #       with one-line commit descriptions
        #
        #       `true` → `--log`, `false` → `--no-log`,
        #       an Integer `n` → `--log=<n>` to limit entries
        #
        #     @option options [Boolean] :signoff (nil) add a Signed-off-by trailer
        #       to the commit message
        #
        #       `true` → `--signoff`, `false` → `--no-signoff`
        #
        #     @option options [Boolean] :stat (nil) show a diffstat at the end of the merge
        #
        #       `true` → `--stat`, `false` → `--no-stat`
        #
        #     @option options [Boolean] :compact_summary (false) show a compact summary
        #       at the end of the merge; emits `--compact-summary`
        #
        #     @option options [Boolean] :squash (false) produce working tree and index
        #       state as if a real merge happened, but do not commit; emits `--squash`
        #
        #     @option options [Boolean] :verify (nil) run pre-merge and commit-msg hooks
        #
        #       `true` → `--verify`, `false` → `--no-verify`
        #
        #     @option options [String] :strategy (nil) merge strategy to use
        #       (e.g., `'ort'`, `'recursive'`, `'resolve'`, `'octopus'`, `'ours'`, `'subtree'`)
        #
        #       Emits `--strategy=<strategy>`. Alias: `:s`
        #
        #     @option options [String, Array<String>] :strategy_option (nil) pass
        #       option(s) to the merge strategy (e.g., `'ours'`, `'theirs'`, `'patience'`)
        #
        #       Can be a single value or an array for multiple `--strategy-option` flags.
        #       Emits `--strategy-option=<option>`. Alias: `:X`
        #
        #     @option options [Boolean] :verify_signatures (nil) verify commit signatures
        #       on the tip of the side branch
        #
        #       `true` → `--verify-signatures`, `false` → `--no-verify-signatures`
        #
        #     @option options [Boolean] :quiet (false) operate quietly; emits `--quiet`
        #
        #       Alias: `:q`
        #
        #     @option options [Boolean] :verbose (false) be verbose; emits `--verbose`
        #
        #       Alias: `:v`
        #
        #     @option options [Boolean] :progress (nil) turn progress reporting on or off
        #
        #       `true` → `--progress`, `false` → `--no-progress`
        #
        #     @option options [Boolean] :autostash (nil) automatically stash and unstash
        #       the working tree before and after the operation
        #
        #       `true` → `--autostash`, `false` → `--no-autostash`
        #
        #     @option options [Boolean] :allow_unrelated_histories (nil) allow merging
        #       histories that do not share a common ancestor
        #
        #       `true` → `--allow-unrelated-histories`,
        #       `false` → `--no-allow-unrelated-histories`
        #
        #     @option options [String] :m (nil) commit message for the merge commit;
        #       emits `-m <msg>`
        #
        #     @option options [String] :into_name (nil) prepare the default merge message
        #       as if merging to the named branch; emits `--into-name <branch>`
        #
        #     @option options [String] :file (nil) read the commit message from the given
        #       file; emits `--file=<file>`. Alias: `:F`
        #
        #     @option options [Boolean] :rerere_autoupdate (nil) allow rerere to update
        #       the index with the auto-resolved conflict result
        #
        #       `true` → `--rerere-autoupdate`, `false` → `--no-rerere-autoupdate`
        #
        #     @option options [Boolean] :overwrite_ignore (nil) silently overwrite ignored
        #       files from the merge result
        #
        #       `true` → `--overwrite-ignore`, `false` → `--no-overwrite-ignore`
        #
        #     @return [Git::CommandLineResult] the result of calling `git merge`
        #
        #     @raise [ArgumentError] if unsupported options are provided
        #
        #     @raise [Git::FailedError] if git exits with a non-zero exit status
      end
    end
  end
end
