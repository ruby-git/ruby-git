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

      # @!method call(*, **)
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
      #     @option options [Boolean] :quiet (false) Suppress all output
      #
      #       Alias: :q
      #
      #     @option options [Boolean] :verbose (false) Enable verbose output during fetch and merge
      #
      #       Alias: :v
      #
      #     @option options [Boolean, String] :recurse_submodules (false) Control submodule
      #       commit fetching (`--recurse-submodules`)
      #
      #       Pass a string such as `'yes'`, `'on-demand'`, or `'no'` for
      #       `--recurse-submodules=<value>`.
      #
      #     @option options [Boolean] :no_recurse_submodules (false) Disable submodule
      #       commit fetching (`--no-recurse-submodules`)
      #
      #     @option options [Boolean] :commit (false) Perform the merge and commit the result
      #       (`--commit`)
      #
      #     @option options [Boolean] :no_commit (false) Merge but do not commit the result
      #       (`--no-commit`)
      #
      #     @option options [Boolean] :edit (false) Open an editor for the merge commit message
      #       (`--edit`)
      #
      #       Alias: :e
      #
      #     @option options [Boolean] :no_edit (false) Do not open an editor for the merge commit
      #       message (`--no-edit`)
      #
      #     @option options [String] :cleanup (nil) Merge-message cleanup mode
      #
      #       Determines how the merge message is cleaned up before committing.
      #       For example, `'strip'`, `'whitespace'`, `'verbatim'`, `'scissors'`, `'default'`.
      #
      #     @option options [Boolean] :ff_only (false) Require fast-forward merge or up-to-date HEAD
      #
      #       Refuses to merge unless the current HEAD is already up to date or the
      #       merge can be resolved as a fast-forward.
      #
      #     @option options [Boolean] :ff (false) Allow fast-forward merge (`--ff`)
      #
      #     @option options [Boolean] :no_ff (false) Disable fast-forward merge, always creating a
      #       merge commit (`--no-ff`)
      #
      #     @option options [Boolean, String] :gpg_sign (false) GPG-sign the resulting merge commit
      #       (`--gpg-sign`)
      #
      #       Pass a key-ID string to select the signing key. Alias: :S
      #
      #     @option options [Boolean] :no_gpg_sign (false) Countermand commit.gpgSign configuration
      #       (`--no-gpg-sign`)
      #
      #     @option options [Boolean, Integer] :log (false) Include one-line descriptions from
      #       the actual commits being merged in log message (`--log`)
      #
      #       Pass an integer for `--log=<n>`.
      #
      #     @option options [Boolean] :no_log (false) Disable inclusion of one-line descriptions
      #       from merged commits (`--no-log`)
      #
      #     @option options [Boolean] :signoff (false) Add a `Signed-off-by` trailer to the
      #       resulting merge commit message (`--signoff`)
      #
      #     @option options [Boolean] :no_signoff (false) Remove a `Signed-off-by` trailer from
      #       the merge commit message (`--no-signoff`)
      #
      #     @option options [Boolean] :stat (false) Show a diffstat at the end of the merge
      #
      #     @option options [Boolean] :no_stat (false) Do not show a diffstat at the end of the merge
      #
      #       Alias: :n
      #
      #     @option options [Boolean] :compact_summary (false) Show a compact summary after the merge
      #
      #     @option options [Boolean] :squash (false) Squash pulled commits into a single commit
      #       (`--squash`)
      #
      #     @option options [Boolean] :no_squash (false) Override `--squash` option (`--no-squash`)
      #
      #     @option options [Boolean] :verify (false) Run pre-merge and commit-msg hooks
      #       (`--verify`)
      #
      #     @option options [Boolean] :no_verify (false) Bypass pre-merge and commit-msg hooks
      #       (`--no-verify`)
      #
      #     @option options [String] :strategy (nil) Use the given merge strategy
      #
      #       For example, `'ort'`, `'recursive'`, `'resolve'`, `'octopus'`, `'ours'`, `'subtree'`.
      #       Alias: :s
      #
      #     @option options [String, Array<String>] :strategy_option (nil) Pass option(s) to
      #       the merge strategy
      #
      #       Can be a single value or array. For example, `'ours'`, `'theirs'`, `'patience'`.
      #       Alias: :X
      #
      #     @option options [Boolean] :verify_signatures (false) Verify that the tip commit of
      #       the side branch being merged is signed with a valid key (`--verify-signatures`)
      #
      #     @option options [Boolean] :no_verify_signatures (false) Do not verify the signature of
      #       the side branch tip commit (`--no-verify-signatures`)
      #
      #     @option options [Boolean] :summary (false) Show a summary after the merge (`--summary`)
      #
      #     @option options [Boolean] :no_summary (false) Do not show a summary after the merge
      #       (`--no-summary`)
      #
      #     @option options [Boolean] :autostash (false) Automatically create a temporary stash entry
      #       before the operation begins (`--autostash`)
      #
      #     @option options [Boolean] :no_autostash (false) Disable automatic stashing before the
      #       operation (`--no-autostash`)
      #
      #     @option options [Boolean] :allow_unrelated_histories (false) Allow pulling from a
      #       repository that shares no common history with the current repository
      #
      #     @option options [Boolean, String] :rebase (false) Rebase the current branch on
      #       top of the upstream branch after fetching (`--rebase`)
      #
      #       Pass a string such as `'merges'` or `'interactive'` for `--rebase=<value>`.
      #       Alias: :r
      #
      #     @option options [Boolean] :no_rebase (false) Override earlier `--rebase` option
      #       (`--no-rebase`)
      #
      #     @option options [Boolean] :all (false) Fetch all remotes (`--all`)
      #
      #     @option options [Boolean] :no_all (false) Do not fetch all remotes (`--no-all`)
      #
      #     @option options [Boolean] :append (false) Append ref names and object names fetched to
      #       the existing contents of `.git/FETCH_HEAD`
      #
      #       Alias: :a
      #
      #     @option options [Boolean] :atomic (false) Use an atomic transaction to update local refs
      #
      #     @option options [String] :depth (nil) Limit fetching to the given number of commits
      #
      #       Fetches only the specified number of commits from the tip of each
      #       remote branch history.
      #
      #     @option options [String] :deepen (nil) Deepen or shorten history of a shallow repository
      #
      #     @option options [String] :shallow_since (nil) Deepen or shorten history to include all
      #       reachable commits after the given date
      #
      #     @option options [String, Array<String>] :shallow_exclude (nil) Exclude commits reachable
      #       from the specified remote branch or tag
      #
      #       Repeatable.
      #
      #     @option options [Boolean] :unshallow (false) Convert a shallow repository to a complete one
      #
      #       If the source is shallow, fetches as much as possible.
      #
      #     @option options [Boolean] :update_shallow (false) Accept refs that update `.git/shallow`
      #
      #     @option options [String, Array<String>] :negotiation_tip (nil) Report only commits
      #       reachable from the given tips during negotiation
      #
      #       Repeatable.
      #
      #     @option options [Boolean] :negotiate_only (false) Do not fetch; only print ancestries
      #       between the local repository and the remote
      #
      #     @option options [Boolean] :dry_run (false) Show what would be done without making changes
      #
      #     @option options [Boolean] :porcelain (false) Give the output in a stable, easy-to-parse
      #       format for scripts
      #
      #     @option options [Boolean] :force (false) Override the check for a non-fast-forward update
      #
      #       Alias: :f
      #
      #     @option options [Boolean] :keep (false) Keep the downloaded pack
      #
      #       Alias: :k
      #
      #     @option options [Boolean] :prefetch (false) Modify the configured refspec to place
      #       all refs into the `refs/prefetch/` namespace
      #
      #     @option options [Boolean] :prune (false) Remove remote-tracking references that no longer
      #       exist on the remote before fetching
      #
      #       Alias: :p
      #
      #     @option options [Boolean] :tags (false) Fetch all tags from the remote (`--tags`)
      #
      #       Alias: :t
      #
      #     @option options [Boolean] :no_tags (false) Disable automatic tag following
      #       (`--no-tags`)
      #
      #     @option options [String, Array<String>] :refmap (nil) Override fetch refspecs for
      #       remote-tracking branch mapping
      #
      #       Repeatable.
      #
      #     @option options [String] :jobs (nil) Number of submodules fetched in parallel
      #
      #       Alias: :j
      #
      #     @option options [Boolean] :set_upstream (false) Add upstream (tracking) reference for
      #       the current branch
      #
      #     @option options [String] :upload_pack (nil) Path to `git-upload-pack` on the remote
      #
      #     @option options [Boolean] :progress (false) Force progress status display (`--progress`)
      #
      #     @option options [Boolean] :no_progress (false) Suppress progress status display
      #       (`--no-progress`)
      #
      #     @option options [String, Array<String>] :server_option (nil) Transmit the given
      #       string to the server when communicating using protocol version 2
      #
      #       Repeatable. Alias: :o
      #
      #     @option options [Boolean] :show_forced_updates (false) Check whether a local branch is
      #       force-updated during fetch (`--show-forced-updates`)
      #
      #     @option options [Boolean] :no_show_forced_updates (false) Disable checking for force
      #       updates (`--no-show-forced-updates`)
      #
      #     @option options [Boolean] :ipv4 (false) Use IPv4 addresses only, ignoring IPv6 addresses
      #
      #       Alias: :'4'
      #
      #     @option options [Boolean] :ipv6 (false) Use IPv6 addresses only, ignoring IPv4 addresses
      #
      #       Alias: :'6'
      #
      #     @option options [Numeric, nil] :timeout (nil) Timeout in seconds for the command
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
