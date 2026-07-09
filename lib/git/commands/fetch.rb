# frozen_string_literal: true

require 'git/commands/base'

module Git
  module Commands
    # Implements the `git fetch` command
    #
    # Downloads objects and refs from another repository. Fetches branches
    # and/or tags from one or more other repositories, along with the objects
    # necessary to complete their histories.
    #
    # @example Typical usage
    #   fetch = Git::Commands::Fetch.new(execution_context)
    #   fetch.call
    #   fetch.call('origin')
    #   fetch.call('origin', 'refs/heads/main')
    #   fetch.call(all: true, prune: true)
    #   fetch.call('origin', merge: true)
    #
    # @note `arguments` block audited against
    #   https://git-scm.com/docs/git-fetch/2.53.0
    #
    # @see https://git-scm.com/docs/git-fetch git-fetch
    #
    # @see Git::Commands
    #
    # @api private
    #
    class Fetch < Git::Commands::Base
      arguments do
        literal 'fetch'

        # Remote scope
        flag_option :all, negatable: true
        flag_option %i[append a]
        flag_option :atomic

        # Shallow clone controls
        value_option :depth, inline: true
        value_option :deepen, inline: true
        value_option :shallow_since, inline: true
        value_option :shallow_exclude,
                     inline: true, repeatable: true
        flag_option :unshallow
        flag_option :update_shallow

        # Negotiation
        value_option :negotiation_tip, inline: true, repeatable: true
        flag_option :negotiate_only

        # Output and dry-run
        flag_option :dry_run
        flag_option :porcelain
        flag_option :write_fetch_head, negatable: true

        # Safety and update control
        flag_option %i[force f]
        flag_option %i[keep k]
        flag_option :multiple

        # Maintenance
        flag_option :auto_maintenance, negatable: true
        flag_option :auto_gc, negatable: true
        flag_option :write_commit_graph, negatable: true

        # Prefetching
        flag_option :prefetch

        # Pruning
        flag_option %i[prune p]
        flag_option %i[prune_tags P]

        # Refetching and refmapping
        flag_option :refetch
        value_option :refmap, inline: true, repeatable: true

        # Tag handling
        flag_option %i[tags t], negatable: true

        # Submodules
        flag_or_value_option :recurse_submodules,
                             inline: true, negatable: true

        # Parallelism
        value_option %i[jobs j], inline: true

        # Tracking and internal plumbing
        flag_option :set_upstream
        value_option :submodule_prefix, inline: true
        value_option :recurse_submodules_default, inline: true
        flag_option %i[update_head_ok u]
        value_option :upload_pack

        # Output verbosity
        flag_option %i[quiet q]
        flag_option %i[verbose v]
        flag_option :progress

        # Protocol and connectivity
        value_option %i[server_option o],
                     inline: true, repeatable: true
        flag_option :show_forced_updates, negatable: true
        flag_option %i[ipv4 4]
        flag_option %i[ipv6 6]

        # Stdin
        flag_option :stdin

        # Execution-only options (not emitted as CLI flags)
        execution_option :timeout
        execution_option :merge

        end_of_options
        operand :repository
        operand :refspec, repeatable: true
      end

      # @overload call(repository = nil, *refspec, **options)
      #
      #     Execute the `git fetch` command
      #
      #     @param repository [String, nil] (nil) the remote name or URL to fetch from
      #
      #       When nil, git uses the default remote configured for the current branch.
      #
      #     @param refspec [Array<String>] one or more refspecs to fetch
      #
      #       Each may be a branch name, a refspec pattern such as
      #       `+refs/heads/*:refs/remotes/origin/*`, or a commit SHA.
      #
      #     @param options [Hash] command options
      #
      #     @option options [Boolean, nil] :all (nil) fetch all remotes (`--all`)
      #
      #     @option options [Boolean, nil] :no_all (nil) do not fetch all remotes (`--no-all`)
      #
      #     @option options [Boolean, nil] :append (nil) append ref names and object
      #       names of fetched refs to the existing contents of `.git/FETCH_HEAD`
      #
      #       Alias: :a
      #
      #     @option options [Boolean, nil] :atomic (nil) use an atomic transaction
      #       to update local refs
      #
      #     @option options [String] :depth (nil) limit fetching to the specified
      #       number of commits from the tip of each remote branch history
      #
      #     @option options [String] :deepen (nil) deepen or shorten history by
      #       the specified number of commits from the current shallow boundary
      #
      #     @option options [String] :shallow_since (nil) deepen or shorten the
      #       history to include all reachable commits after the given date
      #
      #     @option options [String, Array<String>] :shallow_exclude (nil) exclude
      #       commits reachable from the specified remote branch or tag
      #
      #       Repeatable.
      #
      #     @option options [Boolean, nil] :unshallow (nil) convert a shallow
      #       repository to a complete one, or fetch as much as possible from
      #       a shallow source
      #
      #     @option options [Boolean, nil] :update_shallow (nil) accept refs that
      #       would normally require updating `.git/shallow`
      #
      #     @option options [String, Array<String>] :negotiation_tip (nil) only
      #       report commits reachable from the given tips when negotiating
      #
      #       Repeatable. The argument may be a ref, a glob on ref names, or an
      #       abbreviated SHA-1.
      #
      #     @option options [Boolean, nil] :negotiate_only (nil) do not fetch
      #       anything from the server; print ancestors of `--negotiation-tip`
      #       arguments that we have in common
      #
      #     @option options [Boolean, nil] :dry_run (nil) show what would be done
      #       without making changes
      #
      #     @option options [Boolean, nil] :porcelain (nil) print the output to
      #       standard output in an easy-to-parse format for scripts
      #
      #     @option options [Boolean, nil] :write_fetch_head (nil) write the fetched
      #       remote refs to `.git/FETCH_HEAD` (`--write-fetch-head`)
      #
      #     @option options [Boolean, nil] :no_write_fetch_head (nil) do not write
      #       fetched remote refs to `.git/FETCH_HEAD` (`--no-write-fetch-head`)
      #
      #     @option options [Boolean, nil] :force (nil) override the fast-forward
      #       check when using explicit refspecs
      #
      #       Alias: :f
      #
      #     @option options [Boolean, nil] :keep (nil) keep the downloaded pack
      #
      #       Alias: :k
      #
      #     @option options [Boolean, nil] :multiple (nil) allow several repository
      #       and group arguments to be specified
      #
      #       When using this option, pass additional repository or group names
      #       as extra positional arguments; they are bound to the `:refspec`
      #       slot in the DSL but are passed through to git correctly.
      #
      #     @option options [Boolean, nil] :auto_maintenance (nil) run automatic
      #       repository maintenance after fetching (`--auto-maintenance`)
      #
      #     @option options [Boolean, nil] :no_auto_maintenance (nil) do not run
      #       automatic repository maintenance after fetching
      #       (`--no-auto-maintenance`)
      #
      #     @option options [Boolean, nil] :auto_gc (nil) run automatic garbage
      #       collection after fetching — deprecated alias for `:auto_maintenance`
      #       (`--auto-gc`)
      #
      #     @option options [Boolean, nil] :no_auto_gc (nil) do not run automatic
      #       garbage collection after fetching (`--no-auto-gc`)
      #
      #     @option options [Boolean, nil] :write_commit_graph (nil) write a
      #       commit-graph after fetching (`--write-commit-graph`)
      #
      #     @option options [Boolean, nil] :no_write_commit_graph (nil) do not write
      #       a commit-graph after fetching (`--no-write-commit-graph`)
      #
      #     @option options [Boolean, nil] :prefetch (nil) modify the configured
      #       refspec to place all refs into the `refs/prefetch/` namespace
      #
      #     @option options [Boolean, nil] :prune (nil) before fetching, remove any
      #       remote-tracking references that no longer exist on the remote
      #
      #       Alias: :p
      #
      #     @option options [Boolean, nil] :prune_tags (nil) before fetching, remove
      #       any local tags that no longer exist on the remote (requires
      #       `--prune`)
      #
      #       Alias: :P
      #
      #     @option options [Boolean, nil] :refetch (nil) fetch all objects as a
      #       fresh clone would, bypassing negotiation
      #
      #     @option options [String, Array<String>] :refmap (nil) use the
      #       specified refspec to map refs to remote-tracking branches instead
      #       of the configured `remote.*.fetch` values
      #
      #       Repeatable.
      #
      #     @option options [Boolean, nil] :tags (nil) fetch all tags from the
      #       remote (`--tags`)
      #
      #       Alias: :t
      #
      #     @option options [Boolean, nil] :no_tags (nil) disable automatic tag
      #       following (`--no-tags`)
      #
      #     @option options [Boolean, String, nil] :recurse_submodules (nil) control
      #       whether new commits of submodules should be fetched
      #
      #       When `true`, uses `--recurse-submodules`. When a string (e.g.
      #       `'yes'`, `'on-demand'`, `'no'`), passes that value.
      #
      #     @option options [Boolean, nil] :no_recurse_submodules (nil) do not
      #       recurse into submodules (`--no-recurse-submodules`)
      #
      #     @option options [String] :jobs (nil) number of submodules or parallel
      #       fetches
      #
      #       Alias: :j
      #
      #     @option options [Boolean, nil] :set_upstream (nil) add upstream tracking
      #       reference if the remote is fetched successfully
      #
      #     @option options [String] :submodule_prefix (nil) prepend the given
      #       path to informative messages such as "Fetching submodule foo"
      #
      #       Used internally when recursing over submodules.
      #
      #     @option options [String] :recurse_submodules_default (nil) provide a
      #       non-negative default value for `--recurse-submodules`
      #
      #       Used internally.
      #
      #     @option options [Boolean, nil] :update_head_ok (nil) allow updating the
      #       HEAD that corresponds to the current branch
      #
      #       Used internally by `git pull`.
      #
      #       Alias: :u
      #
      #     @option options [String] :upload_pack (nil) specify a non-default
      #       path for `git-upload-pack` on the remote side
      #
      #     @option options [Boolean, nil] :quiet (nil) suppress all output
      #
      #       Alias: :q
      #
      #     @option options [Boolean, nil] :verbose (nil) be verbose
      #
      #       Alias: :v
      #
      #     @option options [Boolean, nil] :progress (nil) force progress status on
      #       standard error even when the stream is not attached to a terminal
      #
      #     @option options [String, Array<String>] :server_option (nil) transmit
      #       the given string to the server when communicating using protocol
      #       version 2
      #
      #       Repeatable.
      #
      #       Alias: :o
      #
      #     @option options [Boolean, nil] :show_forced_updates (nil) check for
      #       force-updated branches during fetch (`--show-forced-updates`)
      #
      #     @option options [Boolean, nil] :no_show_forced_updates (nil) do not
      #       check for force-updated branches during fetch
      #       (`--no-show-forced-updates`)
      #
      #     @option options [Boolean, nil] :ipv4 (nil) use IPv4 addresses only
      #
      #       Alias: :"4"
      #
      #     @option options [Boolean, nil] :ipv6 (nil) use IPv6 addresses only
      #
      #       Alias: :"6"
      #
      #     @option options [Boolean, nil] :stdin (nil) read refspecs from stdin in
      #       addition to those provided as arguments
      #
      #     @option options [Numeric, nil] :timeout (nil) maximum seconds to wait
      #       for the command to complete
      #
      #       If nil, uses the global timeout from {Git::Config}.
      #
      #     @option options [Boolean, nil] :merge (nil) merge stderr into stdout in
      #       the returned result
      #
      #       Pass `true` to capture git fetch output (which is written to stderr
      #       by default).
      #
      #     @return [Git::CommandLine::Result] the result of calling `git fetch`
      #
      #     @raise [ArgumentError] if unsupported options are provided
      #
      #     @raise [Git::FailedError] if git exits with a non-zero exit status
      #
      #     @api public
      #
      def call(*, **)
        super
      end
    end
  end
end
