# frozen_string_literal: true

require 'git/commands/base'

module Git
  module Commands
    # Implements the `git pull` command
    #
    # Incorporates changes from a remote repository into the current branch.
    # In its default mode, `git pull` is shorthand for `git fetch` followed
    # by `git merge FETCH_HEAD`.
    #
    # @example Pull from the default remote
    #   pull = Git::Commands::Pull.new(execution_context)
    #   pull.call
    #
    # @example Pull from a named remote
    #   pull = Git::Commands::Pull.new(execution_context)
    #   pull.call('origin')
    #
    # @example Pull a specific branch from a remote
    #   pull = Git::Commands::Pull.new(execution_context)
    #   pull.call('origin', 'main')
    #
    # @example Pull with rebase instead of merge
    #   pull = Git::Commands::Pull.new(execution_context)
    #   pull.call('origin', rebase: true)
    #
    # @example Pull with allow-unrelated-histories
    #   pull = Git::Commands::Pull.new(execution_context)
    #   pull.call('origin', 'feature', allow_unrelated_histories: true)
    #
    # @example Pull and suppress the merge-commit editor
    #   pull = Git::Commands::Pull.new(execution_context)
    #   pull.call('origin', no_edit: true)
    #
    # @note `arguments` block audited against
    #   https://git-scm.com/docs/git-pull/2.53.0
    #
    # @see https://git-scm.com/docs/git-pull git-pull
    #
    # @see Git::Commands
    #
    # @api private
    #
    class Pull < Git::Commands::Base
      arguments do
        literal 'pull'

        # General options
        flag_option %i[quiet q]
        flag_option %i[verbose v]
        flag_or_value_option :recurse_submodules,
                             negatable: true, inline: true

        # Merge options
        flag_option :commit, negatable: true
        flag_option %i[edit e], negatable: true
        value_option :cleanup, inline: true
        flag_option :ff_only
        flag_option :ff, negatable: true
        flag_or_value_option %i[gpg_sign S], negatable: true, inline: true
        flag_or_value_option :log, negatable: true, inline: true
        flag_option :signoff, negatable: true
        flag_option :stat
        flag_option %i[no_stat n]
        flag_option :compact_summary
        flag_option :squash, negatable: true
        flag_option :verify, negatable: true
        value_option %i[strategy s], inline: true
        value_option %i[strategy_option X], inline: true, repeatable: true
        flag_option :verify_signatures, negatable: true
        flag_option :summary, negatable: true
        flag_option :autostash, negatable: true
        flag_option :allow_unrelated_histories
        flag_or_value_option %i[rebase r], negatable: true, inline: true

        # Fetch options
        flag_option :all, negatable: true
        flag_option %i[append a]
        flag_option :atomic
        value_option :depth, inline: true
        value_option :deepen, inline: true
        value_option :shallow_since, inline: true
        value_option :shallow_exclude, inline: true, repeatable: true
        flag_option :unshallow
        flag_option :update_shallow
        value_option :negotiation_tip, inline: true, repeatable: true
        flag_option :negotiate_only
        flag_option :dry_run
        flag_option :porcelain
        flag_option %i[force f]
        flag_option %i[keep k]
        flag_option :prefetch
        flag_option %i[prune p]
        flag_option %i[tags t], negatable: true
        value_option :refmap, inline: true, repeatable: true
        value_option %i[jobs j], inline: true
        flag_option :set_upstream
        value_option :upload_pack
        flag_option :progress, negatable: true
        value_option %i[server_option o], inline: true, repeatable: true
        flag_option :show_forced_updates, negatable: true
        flag_option %i[ipv4 4]
        flag_option %i[ipv6 6]

        # Execution options (not emitted as CLI flags)
        execution_option :timeout

        end_of_options
        operand :repository
        operand :refspec, repeatable: true
      end

      # @!method call(*, **options)
      #
      #   @param options [Hash] command options
      #
      #   @option options [Boolean, nil] :quiet (nil) command option key; see overload
      #     docs for the full option list
      #
      #   Execute the `git pull` command
      #
      #   @overload call(repository = nil, *refspecs, **options)
      #
      #     @param repository [String, nil] The remote name or URL to pull from
      #
      #       When nil, git uses the default remote for the current branch.
      #
      #     @param refspecs [Array<String>] Zero or more refspecs specifying which refs to fetch
      #       and merge
      #
      #       Each may be a branch name or refspec pattern.
      #
      #     @param options [Hash] command options
      #
      #     @option options [Boolean, nil] :quiet (nil) suppress all output
      #
      #       Alias: :q
      #
      #     @option options [Boolean, nil] :verbose (nil) enable verbose output during fetch and merge
      #
      #       Alias: :v
      #
      #     @option options [Boolean, String, nil] :recurse_submodules (nil) control submodule
      #       commit fetching (`--recurse-submodules`)
      #
      #       Pass a string such as `'yes'`, `'on-demand'`, or `'no'` for
      #       `--recurse-submodules=<value>`.
      #
      #     @option options [Boolean, nil] :no_recurse_submodules (nil) disable submodule
      #       commit fetching (`--no-recurse-submodules`)
      #
      #     @option options [Boolean, nil] :commit (nil) perform the merge and commit the result
      #       (`--commit`)
      #
      #     @option options [Boolean, nil] :no_commit (nil) merge but do not commit the result
      #       (`--no-commit`)
      #
      #     @option options [Boolean, nil] :edit (nil) open an editor for the merge commit message
      #       (`--edit`)
      #
      #       Alias: :e
      #
      #     @option options [Boolean, nil] :no_edit (nil) do not open an editor for the merge commit
      #       message (`--no-edit`)
      #
      #     @option options [String] :cleanup (nil) merge-message cleanup mode
      #
      #       Determines how the merge message is cleaned up before committing.
      #       For example, `'strip'`, `'whitespace'`, `'verbatim'`, `'scissors'`, `'default'`.
      #
      #     @option options [Boolean, nil] :ff_only (nil) require fast-forward merge or up-to-date HEAD
      #
      #       Refuses to merge unless the current HEAD is already up to date or the
      #       merge can be resolved as a fast-forward.
      #
      #     @option options [Boolean, nil] :ff (nil) allow fast-forward merge (`--ff`)
      #
      #     @option options [Boolean, nil] :no_ff (nil) disable fast-forward merge, always creating a
      #       merge commit (`--no-ff`)
      #
      #     @option options [Boolean, String, nil] :gpg_sign (nil) GPG-sign the resulting merge commit
      #       (`--gpg-sign`)
      #
      #       Pass a key-ID string to select the signing key. Alias: :S
      #
      #     @option options [Boolean, nil] :no_gpg_sign (nil) countermand commit.gpgSign configuration
      #       (`--no-gpg-sign`)
      #
      #     @option options [Boolean, Integer, nil] :log (nil) include one-line descriptions from
      #       the actual commits being merged in log message (`--log`)
      #
      #       Pass an integer for `--log=<n>`.
      #
      #     @option options [Boolean, nil] :no_log (nil) disable inclusion of one-line descriptions
      #       from merged commits (`--no-log`)
      #
      #     @option options [Boolean, nil] :signoff (nil) add a `Signed-off-by` trailer to the
      #       resulting merge commit message (`--signoff`)
      #
      #     @option options [Boolean, nil] :no_signoff (nil) remove a `Signed-off-by` trailer from
      #       the merge commit message (`--no-signoff`)
      #
      #     @option options [Boolean, nil] :stat (nil) show a diffstat at the end of the merge
      #
      #     @option options [Boolean, nil] :no_stat (nil) do not show a diffstat at the end of the merge
      #
      #       Alias: :n
      #
      #     @option options [Boolean, nil] :compact_summary (nil) show a compact summary after the merge
      #
      #     @option options [Boolean, nil] :squash (nil) squash pulled commits into a single commit
      #       (`--squash`)
      #
      #     @option options [Boolean, nil] :no_squash (nil) override `--squash` option (`--no-squash`)
      #
      #     @option options [Boolean, nil] :verify (nil) run pre-merge and commit-msg hooks
      #       (`--verify`)
      #
      #     @option options [Boolean, nil] :no_verify (nil) bypass pre-merge and commit-msg hooks
      #       (`--no-verify`)
      #
      #     @option options [String] :strategy (nil) use the given merge strategy
      #
      #       For example, `'ort'`, `'recursive'`, `'resolve'`, `'octopus'`, `'ours'`, `'subtree'`.
      #       Alias: :s
      #
      #     @option options [String, Array<String>] :strategy_option (nil) pass option(s) to
      #       the merge strategy
      #
      #       Can be a single value or array. For example, `'ours'`, `'theirs'`, `'patience'`.
      #       Alias: :X
      #
      #     @option options [Boolean, nil] :verify_signatures (nil) verify that the tip commit of
      #       the side branch being merged is signed with a valid key (`--verify-signatures`)
      #
      #     @option options [Boolean, nil] :no_verify_signatures (nil) do not verify the signature of
      #       the side branch tip commit (`--no-verify-signatures`)
      #
      #     @option options [Boolean, nil] :summary (nil) show a summary after the merge (`--summary`)
      #
      #     @option options [Boolean, nil] :no_summary (nil) do not show a summary after the merge
      #       (`--no-summary`)
      #
      #     @option options [Boolean, nil] :autostash (nil) automatically create a temporary stash entry
      #       before the operation begins (`--autostash`)
      #
      #     @option options [Boolean, nil] :no_autostash (nil) disable automatic stashing before the
      #       operation (`--no-autostash`)
      #
      #     @option options [Boolean, nil] :allow_unrelated_histories (nil) allow pulling from a
      #       repository that shares no common history with the current repository
      #
      #     @option options [Boolean, String, nil] :rebase (nil) rebase the current branch on
      #       top of the upstream branch after fetching (`--rebase`)
      #
      #       Pass a string such as `'merges'` or `'interactive'` for `--rebase=<value>`.
      #       Alias: :r
      #
      #     @option options [Boolean, nil] :no_rebase (nil) override earlier `--rebase` option
      #       (`--no-rebase`)
      #
      #     @option options [Boolean, nil] :all (nil) fetch all remotes (`--all`)
      #
      #     @option options [Boolean, nil] :no_all (nil) do not fetch all remotes (`--no-all`)
      #
      #     @option options [Boolean, nil] :append (nil) append ref names and object names fetched to
      #       the existing contents of `.git/FETCH_HEAD`
      #
      #       Alias: :a
      #
      #     @option options [Boolean, nil] :atomic (nil) use an atomic transaction to update local refs
      #
      #     @option options [String] :depth (nil) limit fetching to the given number of commits
      #
      #       Fetches only the specified number of commits from the tip of each
      #       remote branch history.
      #
      #     @option options [String] :deepen (nil) deepen or shorten history of a shallow repository
      #
      #     @option options [String] :shallow_since (nil) deepen or shorten history to include all
      #       reachable commits after the given date
      #
      #     @option options [String, Array<String>] :shallow_exclude (nil) exclude commits reachable
      #       from the specified remote branch or tag
      #
      #       Repeatable.
      #
      #     @option options [Boolean, nil] :unshallow (nil) convert a shallow repository to a complete one
      #
      #       If the source is shallow, fetches as much as possible.
      #
      #     @option options [Boolean, nil] :update_shallow (nil) accept refs that update `.git/shallow`
      #
      #     @option options [String, Array<String>] :negotiation_tip (nil) report only commits
      #       reachable from the given tips during negotiation
      #
      #       Repeatable.
      #
      #     @option options [Boolean, nil] :negotiate_only (nil) do not fetch; only print ancestries
      #       between the local repository and the remote
      #
      #     @option options [Boolean, nil] :dry_run (nil) show what would be done without making changes
      #
      #     @option options [Boolean, nil] :porcelain (nil) give the output in a stable, easy-to-parse
      #       format for scripts
      #
      #     @option options [Boolean, nil] :force (nil) override the check for a non-fast-forward update
      #
      #       Alias: :f
      #
      #     @option options [Boolean, nil] :keep (nil) keep the downloaded pack
      #
      #       Alias: :k
      #
      #     @option options [Boolean, nil] :prefetch (nil) modify the configured refspec to place
      #       all refs into the `refs/prefetch/` namespace
      #
      #     @option options [Boolean, nil] :prune (nil) remove remote-tracking references that no longer
      #       exist on the remote before fetching
      #
      #       Alias: :p
      #
      #     @option options [Boolean, nil] :tags (nil) fetch all tags from the remote (`--tags`)
      #
      #       Alias: :t
      #
      #     @option options [Boolean, nil] :no_tags (nil) disable automatic tag following
      #       (`--no-tags`)
      #
      #     @option options [String, Array<String>] :refmap (nil) override fetch refspecs for
      #       remote-tracking branch mapping
      #
      #       Repeatable.
      #
      #     @option options [String] :jobs (nil) number of submodules fetched in parallel
      #
      #       Alias: :j
      #
      #     @option options [Boolean, nil] :set_upstream (nil) add upstream (tracking) reference for
      #       the current branch
      #
      #     @option options [String] :upload_pack (nil) path to `git-upload-pack` on the remote
      #
      #     @option options [Boolean, nil] :progress (nil) force progress status display (`--progress`)
      #
      #     @option options [Boolean, nil] :no_progress (nil) suppress progress status display
      #       (`--no-progress`)
      #
      #     @option options [String, Array<String>] :server_option (nil) transmit the given
      #       string to the server when communicating using protocol version 2
      #
      #       Repeatable. Alias: :o
      #
      #     @option options [Boolean, nil] :show_forced_updates (nil) check whether a local branch is
      #       force-updated during fetch (`--show-forced-updates`)
      #
      #     @option options [Boolean, nil] :no_show_forced_updates (nil) disable checking for force
      #       updates (`--no-show-forced-updates`)
      #
      #     @option options [Boolean, nil] :ipv4 (nil) use IPv4 addresses only, ignoring IPv6 addresses
      #
      #       Alias: :'4'
      #
      #     @option options [Boolean, nil] :ipv6 (nil) use IPv6 addresses only, ignoring IPv4 addresses
      #
      #       Alias: :'6'
      #
      #     @option options [Numeric, nil] :timeout (nil) timeout in seconds for the command
      #
      #       If nil, uses the global timeout from {Git::Config}.
      #
      #     @return [Git::CommandLineResult] the result of calling `git pull`
      #
      #     @raise [ArgumentError] if argument validation fails (e.g., unsupported options
      #       are provided or option values are invalid)
      #
      #     @raise [Git::FailedError] if git exits with a non-zero exit status
    end
  end
end
