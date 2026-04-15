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
    # @see https://git-scm.com/docs/git-fetch git-fetch documentation
    #
    # @api private
    #
    # @example Fetch from the default remote
    #   fetch = Git::Commands::Fetch.new(execution_context)
    #   fetch.call
    #
    # @example Fetch from a named remote
    #   fetch = Git::Commands::Fetch.new(execution_context)
    #   fetch.call('origin')
    #
    # @example Fetch a specific refspec from a remote
    #   fetch = Git::Commands::Fetch.new(execution_context)
    #   fetch.call('origin', 'refs/heads/main')
    #
    # @example Fetch all remotes with pruning
    #   fetch = Git::Commands::Fetch.new(execution_context)
    #   fetch.call(all: true, prune: true)
    #
    # @example Fetch with stderr merged into stdout (for capturing fetch output)
    #   fetch = Git::Commands::Fetch.new(execution_context)
    #   fetch.call('origin', merge: true)
    #
    class Fetch < Git::Commands::Base
      arguments do
        literal 'fetch'

        # Remotes and fetching scope
        flag_option :all, negatable: true
        flag_option %i[append a]
        flag_option :atomic

        # Shallow clone controls
        value_option :depth
        value_option :deepen
        value_option :shallow_since, inline: true
        value_option :shallow_exclude,
                     inline: true, repeatable: true
        flag_option :unshallow
        flag_option :update_shallow

        # Output and behavior
        flag_option :dry_run
        flag_option :write_fetch_head, negatable: true
        flag_option :refetch
        flag_option :prefetch

        # Safety and update control
        flag_option %i[force f]
        flag_option %i[keep k]
        flag_option :multiple

        # Pruning
        flag_option %i[prune p]
        flag_option %i[prune_tags P]

        # Tag handling
        flag_option %i[tags t], negatable: true

        # Submodules
        flag_or_value_option :recurse_submodules,
                             inline: true, negatable: true

        # Parallelism
        value_option %i[jobs j]

        # Tracking
        flag_option :set_upstream
        flag_option %i[update_head_ok u]

        # Output verbosity
        flag_option %i[quiet q]
        flag_option %i[verbose v]
        flag_option :progress

        # Protocol and connectivity
        value_option %i[server_option o],
                     inline: true, repeatable: true
        flag_option :show_forced_updates, negatable: true
        flag_option :ipv4
        flag_option :ipv6

        # Execution-only options (not emitted as CLI flags)
        execution_option :timeout
        execution_option :merge

        end_of_options
        operand :repository
        operand :refspecs, repeatable: true
      end

      # @!method call(*, **)
      #
      #   Execute the git fetch command
      #
      #   @overload call(repository = nil, *refspecs, **options)
      #
      #     @param repository [String, nil] (nil) The remote name or URL to fetch from
      #
      #       When nil, git uses the default remote configured for the current branch.
      #
      #     @param refspecs [Array<String>] One or more refspecs to fetch
      #
      #       Each may be a branch name, a refspec pattern such as `+refs/heads/*:refs/remotes/origin/*`,
      #       or a commit SHA.
      #
      #     @param options [Hash] command options
      #
      #     @option options [Boolean, nil] :all (nil) Fetch all remotes
      #
      #       Pass `false` to emit `--no-all`.
      #
      #     @option options [Boolean] :append (nil) Append ref names and object names of fetched
      #       refs to the existing contents of `.git/FETCH_HEAD`
      #
      #       Alias: :a
      #
      #     @option options [Boolean] :atomic (nil) Use an atomic transaction to update local refs
      #
      #     @option options [String] :depth (nil) Limit fetching to the specified number of commits
      #       from the tip of each remote branch history
      #
      #     @option options [String] :deepen (nil) Deepen or shorten history by the specified number
      #       of commits from the current shallow boundary
      #
      #     @option options [String] :shallow_since (nil) Deepen or shorten the history to include
      #       all reachable commits after the given date
      #
      #     @option options [String, Array<String>] :shallow_exclude (nil) Exclude commits reachable
      #       from the specified remote branch or tag
      #
      #       Repeatable.
      #
      #     @option options [Boolean] :unshallow (nil) Convert a shallow repository to a complete one,
      #       or fetch as much as possible from a shallow source
      #
      #     @option options [Boolean] :update_shallow (nil) Accept refs that would normally require
      #       updating `.git/shallow`
      #
      #     @option options [Boolean] :dry_run (nil) Show what would be done without making changes
      #
      #     @option options [Boolean, nil] :write_fetch_head (nil) Control whether to write the
      #       fetched remote refs to `.git/FETCH_HEAD`
      #
      #       Pass `false` to emit `--no-write-fetch-head`.
      #
      #     @option options [Boolean] :refetch (nil) Fetch all objects as a fresh clone would,
      #       bypassing negotiation
      #
      #     @option options [Boolean] :prefetch (nil) Modify the configured refspec to place all
      #       refs into the `refs/prefetch/` namespace
      #
      #     @option options [Boolean] :force (nil) Override the fast-forward check when using
      #       explicit refspecs
      #
      #       Alias: :f
      #
      #     @option options [Boolean] :keep (nil) Keep the downloaded pack
      #
      #       Alias: :k
      #
      #     @option options [Boolean] :multiple (nil) Allow several repository and group arguments
      #       to be specified
      #
      #       When using this option, pass additional repository or group names as extra positional
      #       arguments; they are bound to the `:refspecs` slot in the DSL but are passed through
      #       to git correctly.
      #
      #     @option options [Boolean] :prune (nil) Before fetching, remove any remote-tracking
      #       references that no longer exist on the remote
      #
      #       Alias: :p
      #
      #     @option options [Boolean] :prune_tags (nil) Before fetching, remove any local tags that
      #       no longer exist on the remote (requires `--prune`)
      #
      #       Alias: :P
      #
      #     @option options [Boolean, nil] :tags (nil) Fetch all tags from the remote
      #
      #       Pass `false` to emit `--no-tags` and disable automatic tag following.
      #
      #       Alias: :t
      #
      #     @option options [Boolean, String, nil] :recurse_submodules (nil) Control whether new
      #       commits of submodules should be fetched
      #
      #       When `true`, uses `--recurse-submodules`. When a string (e.g. `'yes'`, `'on-demand'`,
      #       `'no'`), passes that value. When `false`, emits `--no-recurse-submodules`.
      #
      #     @option options [String] :jobs (nil) Number of submodules or parallel fetches
      #
      #       Alias: :j
      #
      #     @option options [Boolean] :set_upstream (nil) Add upstream tracking reference if the
      #       remote is fetched successfully
      #
      #     @option options [Boolean] :update_head_ok (nil) Allow updating the HEAD that corresponds
      #       to the current branch
      #
      #       Used internally by `git pull`.
      #
      #       Alias: :u
      #
      #     @option options [Boolean] :quiet (nil) Suppress all output
      #
      #       Alias: :q
      #
      #     @option options [Boolean] :verbose (nil) Be verbose
      #
      #       Alias: :v
      #
      #     @option options [Boolean] :progress (nil) Force progress status on standard error even
      #       when the stream is not attached to a terminal
      #
      #     @option options [String, Array<String>] :server_option (nil) Transmit the given string
      #       to the server when communicating using protocol version 2
      #
      #       Repeatable.
      #
      #       Alias: :o
      #
      #     @option options [Boolean, nil] :show_forced_updates (nil) Check for force-updated branches
      #       during fetch
      #
      #       Pass `false` to emit `--no-show-forced-updates`.
      #
      #     @option options [Boolean] :ipv4 (nil) Use IPv4 addresses only
      #
      #     @option options [Boolean] :ipv6 (nil) Use IPv6 addresses only
      #
      #     @option options [Numeric, nil] :timeout (nil) Maximum seconds to wait for the command
      #       to complete
      #
      #       If nil, uses the global timeout from {Git::Config}.
      #
      #     @option options [Boolean] :merge (nil) Merge stderr into stdout in the returned result
      #
      #       Pass `true` to capture git fetch output (which is written to stderr by default).
      #
      #     @return [Git::CommandLineResult] the result of calling `git fetch`
      #
      #     @raise [ArgumentError] if unsupported options are provided
      #
      #     @raise [Git::FailedError] if the command returns a non-zero exit status
    end
  end
end
