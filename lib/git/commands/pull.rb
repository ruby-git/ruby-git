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
    # @see https://git-scm.com/docs/git-pull git-pull documentation
    #
    # @api private
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
    #   pull.call('origin', edit: false)
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
        flag_option :edit, negatable: true
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
      #     @option options [Boolean] :quiet (nil) Suppress all output
      #
      #       Alias: :q
      #
      #     @option options [Boolean] :verbose (nil) Enable verbose output during fetch and merge
      #
      #       Alias: :v
      #
      #     @option options [Boolean, String] :recurse_submodules (nil) Control submodule
      #       commit fetching
      #
      #       `true` for `--recurse-submodules`, `false` for `--no-recurse-submodules`,
      #       or a string such as `'yes'`, `'on-demand'`, `'no'` for
      #       `--recurse-submodules=<value>`.
      #
      #     @option options [Boolean] :commit (nil) Perform the merge and commit the result
      #
      #       `true` for `--commit`, `false` for `--no-commit`.
      #
      #     @option options [Boolean] :edit (nil) Open an editor for the merge commit message.
      #       When false, adds --no-edit to suppress the editor. When true, adds --edit.
      #       When nil, defers to git's default behavior.
      #
      #     @option options [String] :cleanup (nil) Merge-message cleanup mode
      #
      #       Determines how the merge message is cleaned up before committing.
      #       For example, `'strip'`, `'whitespace'`, `'verbatim'`, `'scissors'`, `'default'`.
      #
      #     @option options [Boolean] :ff_only (nil) Require fast-forward merge or up-to-date HEAD
      #
      #       Refuses to merge unless the current HEAD is already up to date or the
      #       merge can be resolved as a fast-forward.
      #
      #     @option options [Boolean] :ff (nil) Control whether fast-forward is allowed
      #
      #       `true` for `--ff`, `false` for `--no-ff`.
      #
      #     @option options [Boolean, String] :gpg_sign (nil) GPG-sign the resulting merge commit
      #
      #       `true` for `--gpg-sign`, a String key ID for `--gpg-sign=<keyid>`, `false` for
      #       `--no-gpg-sign`. Alias: :S
      #
      #     @option options [Boolean, Integer] :log (nil) Include one-line descriptions from
      #       the actual commits being merged in log message
      #
      #       `true` for `--log`, `false` for `--no-log`, or an integer for `--log=<n>`.
      #
      #     @option options [Boolean] :signoff (nil) Add a `Signed-off-by` trailer to the
      #       resulting merge commit message
      #
      #       `true` for `--signoff`, `false` for `--no-signoff`.
      #
      #     @option options [Boolean] :stat (nil) Show a diffstat at the end of the merge
      #
      #     @option options [Boolean] :no_stat (nil) Do not show a diffstat at the end of the merge
      #
      #       Alias: :n
      #
      #     @option options [Boolean] :compact_summary (nil) Show a compact summary after the merge
      #
      #     @option options [Boolean] :squash (nil) Squash pulled commits into a single commit
      #
      #       `true` for `--squash`, `false` for `--no-squash`.
      #
      #     @option options [Boolean] :verify (nil) Run pre-merge and commit-msg hooks
      #
      #       `true` for `--verify`, `false` for `--no-verify`.
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
      #     @option options [Boolean] :verify_signatures (nil) Verify that the tip commit of
      #       the side branch being merged is signed with a valid key
      #
      #       `true` for `--verify-signatures`, `false` for `--no-verify-signatures`.
      #
      #     @option options [Boolean] :summary (nil) Control whether to show a summary after
      #       the merge
      #
      #       `true` for `--summary`, `false` for `--no-summary`.
      #
      #     @option options [Boolean] :autostash (nil) Automatically create a temporary stash entry
      #       before the operation begins
      #
      #       `true` for `--autostash`, `false` for `--no-autostash`.
      #
      #     @option options [Boolean] :allow_unrelated_histories (nil) Allow pulling from a
      #       repository that shares no common history with the current repository
      #
      #     @option options [Boolean, String] :rebase (nil) Rebase the current branch on
      #       top of the upstream branch after fetching
      #
      #       `true` for `--rebase`, `false` for `--no-rebase`, or a string such as `'merges'`
      #       or `'interactive'` for `--rebase=<value>`. Alias: :r
      #
      #     @option options [Boolean] :all (nil) Control whether to fetch all remotes
      #
      #       `true` for `--all`, `false` for `--no-all`.
      #
      #     @option options [Boolean] :append (nil) Append ref names and object names fetched to
      #       the existing contents of `.git/FETCH_HEAD`
      #
      #       Alias: :a
      #
      #     @option options [Boolean] :atomic (nil) Use an atomic transaction to update local refs
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
      #     @option options [Boolean] :unshallow (nil) Convert a shallow repository to a complete one
      #
      #       If the source is shallow, fetches as much as possible.
      #
      #     @option options [Boolean] :update_shallow (nil) Accept refs that update `.git/shallow`
      #
      #     @option options [String, Array<String>] :negotiation_tip (nil) Report only commits
      #       reachable from the given tips during negotiation
      #
      #       Repeatable.
      #
      #     @option options [Boolean] :negotiate_only (nil) Do not fetch; only print ancestries
      #       between the local repository and the remote
      #
      #     @option options [Boolean] :dry_run (nil) Show what would be done without making changes
      #
      #     @option options [Boolean] :porcelain (nil) Give the output in a stable, easy-to-parse
      #       format for scripts
      #
      #     @option options [Boolean] :force (nil) Override the check for a non-fast-forward update
      #
      #       Alias: :f
      #
      #     @option options [Boolean] :keep (nil) Keep the downloaded pack
      #
      #       Alias: :k
      #
      #     @option options [Boolean] :prefetch (nil) Modify the configured refspec to place
      #       all refs into the `refs/prefetch/` namespace
      #
      #     @option options [Boolean] :prune (nil) Remove remote-tracking references that no longer
      #       exist on the remote before fetching
      #
      #       Alias: :p
      #
      #     @option options [Boolean] :tags (nil) Control tag fetching behavior
      #
      #       `true` for `--tags` (fetch all tags), `false` for `--no-tags` (disable
      #       automatic tag following). Alias: :t
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
      #     @option options [Boolean] :set_upstream (nil) Add upstream (tracking) reference for
      #       the current branch
      #
      #     @option options [String] :upload_pack (nil) Path to `git-upload-pack` on the remote
      #
      #     @option options [Boolean] :progress (nil) Control progress reporting
      #
      #       `true` for `--progress` (force progress even if stderr is not a terminal),
      #       `false` for `--no-progress` (suppress progress output).
      #
      #     @option options [String, Array<String>] :server_option (nil) Transmit the given
      #       string to the server when communicating using protocol version 2
      #
      #       Repeatable. Alias: :o
      #
      #     @option options [Boolean] :show_forced_updates (nil) Control display of forced updates
      #
      #       `true` for `--show-forced-updates`, `false` for `--no-show-forced-updates`.
      #
      #     @option options [Boolean] :ipv4 (nil) Use IPv4 addresses only, ignoring IPv6 addresses
      #
      #       Alias: :'4'
      #
      #     @option options [Boolean] :ipv6 (nil) Use IPv6 addresses only, ignoring IPv4 addresses
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
