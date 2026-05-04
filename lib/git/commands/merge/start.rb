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
        #     @option options [Boolean] :commit (false) perform merge and commit the result (`--commit`)
        #
        #     @option options [Boolean] :no_commit (false) do not perform a merge commit (`--no-commit`)
        #
        #     @option options [Boolean] :edit (false) open an editor for the merge commit message (`--edit`)
        #
        #       Alias: `:e`
        #
        #     @option options [Boolean] :no_edit (false) skip the editor for the merge commit message (`--no-edit`)
        #
        #     @option options [String] :cleanup (nil) how the merge message will be cleaned
        #       up before committing
        #
        #       Accepted values include `strip`, `whitespace`, `verbatim`,
        #       `scissors`, and `default`. Emits `--cleanup=<mode>`.
        #
        #     @option options [Boolean] :ff (false) allow fast-forward merges (`--ff`)
        #
        #     @option options [Boolean] :no_ff (false) create a merge commit even when fast-forward is
        #       possible (`--no-ff`)
        #
        #     @option options [Boolean] :ff_only (false) refuse to merge unless
        #       fast-forward is possible; emits `--ff-only`
        #
        #     @option options [Boolean, String] :gpg_sign (false) GPG-sign the resulting
        #       merge commit (`--gpg-sign`)
        #
        #       Pass a key ID string to select the signing key; pass `true` to use the
        #       committer identity. Alias: `:S`
        #
        #     @option options [Boolean] :no_gpg_sign (false) countermand commit.gpgSign
        #       configuration (`--no-gpg-sign`)
        #
        #     @option options [Boolean, Integer] :log (false) populate the merge message
        #       with one-line commit descriptions (`--log`)
        #
        #       Pass an Integer `n` to limit to `n` entries (`--log=<n>`).
        #
        #     @option options [Boolean] :no_log (false) do not list one-line commit descriptions (`--no-log`)
        #
        #     @option options [Boolean] :signoff (false) add a Signed-off-by trailer to the commit message (`--signoff`)
        #
        #     @option options [Boolean] :no_signoff (false) remove a Signed-off-by trailer from the
        #       commit message (`--no-signoff`)
        #
        #     @option options [Boolean] :stat (false) show a diffstat at the end of the merge (`--stat`)
        #
        #     @option options [Boolean] :no_stat (false) suppress the diffstat at the end of the merge (`--no-stat`)
        #
        #     @option options [Boolean] :compact_summary (false) show a compact summary
        #       at the end of the merge; emits `--compact-summary`
        #
        #     @option options [Boolean] :squash (false) produce working tree and index
        #       state as if a real merge happened, but do not commit; emits `--squash`
        #
        #     @option options [Boolean] :verify (false) run pre-merge and commit-msg hooks (`--verify`)
        #
        #     @option options [Boolean] :no_verify (false) bypass pre-merge and commit-msg hooks (`--no-verify`)
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
        #     @option options [Boolean] :verify_signatures (false) verify commit signatures
        #       on the tip of the side branch (`--verify-signatures`)
        #
        #     @option options [Boolean] :no_verify_signatures (false) do not verify commit
        #       signatures (`--no-verify-signatures`)
        #
        #     @option options [Boolean] :quiet (false) operate quietly; emits `--quiet`
        #
        #       Alias: `:q`
        #
        #     @option options [Boolean] :verbose (false) be verbose; emits `--verbose`
        #
        #       Alias: `:v`
        #
        #     @option options [Boolean] :progress (false) force progress status reporting (`--progress`)
        #
        #     @option options [Boolean] :no_progress (false) suppress progress status reporting (`--no-progress`)
        #
        #     @option options [Boolean] :autostash (false) automatically stash and unstash
        #       the working tree before and after the operation (`--autostash`)
        #
        #     @option options [Boolean] :no_autostash (false) do not automatically stash and unstash
        #       the working tree (`--no-autostash`)
        #
        #     @option options [Boolean] :allow_unrelated_histories (false) allow merging
        #       histories that do not share a common ancestor (`--allow-unrelated-histories`)
        #
        #     @option options [Boolean] :no_allow_unrelated_histories (false) disallow merging
        #       unrelated histories (`--no-allow-unrelated-histories`)
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
        #     @option options [Boolean] :rerere_autoupdate (false) allow rerere to update
        #       the index with the auto-resolved conflict result (`--rerere-autoupdate`)
        #
        #     @option options [Boolean] :no_rerere_autoupdate (false) prevent rerere from
        #       auto-updating the index (`--no-rerere-autoupdate`)
        #
        #     @option options [Boolean] :overwrite_ignore (false) silently overwrite ignored
        #       files from the merge result (`--overwrite-ignore`)
        #
        #     @option options [Boolean] :no_overwrite_ignore (false) abort if the merge result
        #       would overwrite any ignored files (`--no-overwrite-ignore`)
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
