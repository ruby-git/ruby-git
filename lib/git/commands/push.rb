# frozen_string_literal: true

require 'git/commands/base'

module Git
  module Commands
    # Encapsulates the `git push` command
    #
    # Updates remote refs using local refs, while sending objects necessary to
    # complete the given refs.
    #
    # @see https://git-scm.com/docs/git-push git-push documentation
    #
    # @api private
    #
    # @example Push to the default remote
    #   push = Git::Commands::Push.new(execution_context)
    #   push.call
    #
    # @example Push to a named remote
    #   push = Git::Commands::Push.new(execution_context)
    #   push.call('origin')
    #
    # @example Push a specific branch to a remote
    #   push = Git::Commands::Push.new(execution_context)
    #   push.call('origin', 'main')
    #
    # @example Force push to a remote branch
    #   push = Git::Commands::Push.new(execution_context)
    #   push.call('origin', 'main', force: true)
    #
    # @example Push with a server-side option
    #   push = Git::Commands::Push.new(execution_context)
    #   push.call('origin', push_option: 'ci.skip')
    #
    # @example Push all tags to a remote
    #   push = Git::Commands::Push.new(execution_context)
    #   push.call('origin', tags: true)
    #
    class Push < Git::Commands::Base
      arguments do
        literal 'push'

        # Push scope (SYNOPSIS order: [--all | --branches | --mirror | --tags])
        flag_option %i[all branches]
        flag_option :mirror
        flag_option :tags
        flag_option :follow_tags, negatable: true
        flag_option :atomic, negatable: true

        # Transfer options
        flag_option %i[dry_run n]
        flag_option :porcelain
        value_option %i[receive_pack exec], inline: true
        value_option :repo, inline: true

        # Safety
        flag_option %i[force f]
        flag_option %i[delete d]
        flag_option :prune

        # Output verbosity
        flag_option %i[quiet q]
        flag_option %i[verbose v]

        # Tracking
        flag_option %i[set_upstream u]

        # Push options (server-side)
        value_option %i[push_option o], repeatable: true, inline: true

        # GPG signing
        flag_or_value_option :signed,
                             negatable: true, inline: true

        # Force safety
        flag_or_value_option :force_with_lease,
                             negatable: true, inline: true
        flag_option :force_if_includes, negatable: true

        # Hooks
        flag_option :verify, negatable: true

        # Submodules
        flag_or_value_option :recurse_submodules,
                             negatable: true, inline: true, type: [String, FalseClass]

        # Transfer
        flag_option :thin, negatable: true
        flag_option :progress

        # Protocol and connectivity
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
      #   Execute the `git push` command
      #
      #   @overload call(repository = nil, *refspecs, **options)
      #
      #     @param repository [String, nil] The remote name or URL to push to
      #
      #       When nil, git uses the default remote configured for the current branch.
      #
      #     @param refspecs [Array<String>] Zero or more refspecs specifying which refs to push
      #
      #       Each may be a branch name or a full refspec pattern such as
      #       `refs/heads/main:refs/heads/main`. When no refspecs are given, git uses
      #       the push configuration for the current branch.
      #
      #     @param options [Hash] command options
      #
      #     @option options [Boolean] :all (nil) Push all branches
      #
      #       Alias: :branches
      #
      #     @option options [Boolean] :mirror (nil) Push all refs under `refs/` to the remote
      #
      #     @option options [Boolean] :tags (nil) Push all refs under `refs/tags/`
      #
      #     @option options [Boolean] :follow_tags (nil) Push annotated tags reachable from pushed commits
      #
      #       Pass `false` to emit `--no-follow-tags`.
      #
      #     @option options [Boolean] :atomic (nil) Use an atomic transaction to update remote refs
      #
      #       Pass `false` to emit `--no-atomic`.
      #
      #     @option options [Boolean] :dry_run (nil) Do not send updates, only report what would be pushed
      #
      #       Alias: :n
      #
      #     @option options [Boolean] :porcelain (nil) Produce machine-readable output
      #
      #     @option options [String] :receive_pack (nil) Path to the git-receive-pack program on the remote end
      #
      #       Alias: :exec
      #
      #     @option options [String] :repo (nil) Use this repository instead of the
      #       positional repository argument
      #
      #       Equivalent to the positional `<repository>` argument. If both are given, the
      #       positional argument takes precedence.
      #
      #     @option options [Boolean] :force (nil) Force updates, overriding the fast-forward check
      #
      #       Alias: :f
      #
      #     @option options [Boolean] :delete (nil) Delete all listed refs from the remote repository
      #
      #       Alias: :d
      #
      #     @option options [Boolean] :prune (nil) Remove remote branches that have no local counterpart
      #
      #     @option options [Boolean] :quiet (nil) Suppress all output
      #
      #       Alias: :q
      #
      #     @option options [Boolean] :verbose (nil) Run verbosely
      #
      #       Alias: :v
      #
      #     @option options [Boolean] :set_upstream (nil) Set upstream tracking for each successfully pushed branch
      #
      #       Alias: :u
      #
      #     @option options [String, Array<String>] :push_option (nil) Transmit one or more server-side options
      #
      #       Repeatable. Each occurrence emits a separate `--push-option=<value>` flag.
      #
      #       Alias: :o
      #
      #     @option options [Boolean, String] :signed (nil) GPG-sign the push certificate
      #
      #       When `true`, emits `--signed`. When a String (`'true'`, `'false'`, `'if-asked'`), passes
      #       that value. When `false`, emits `--no-signed`.
      #
      #     @option options [Boolean, String] :force_with_lease (nil) Refuse force pushes unless the remote
      #       ref matches the expected value
      #
      #       When `true`, emits `--force-with-lease`. When a String (e.g. `'main:abc123'`), emits
      #       `--force-with-lease=<string>`. When `false`, emits `--no-force-with-lease`.
      #
      #     @option options [Boolean] :force_if_includes (nil) Force pushes only if commits being
      #       pushed are already in the remote-tracking branch
      #
      #       Pass `false` to emit `--no-force-if-includes`.
      #
      #     @option options [Boolean] :verify (nil) Control pre-push hook execution
      #
      #       Pass `false` to emit `--no-verify`, bypassing the pre-push hook.
      #
      #     @option options [String, FalseClass] :recurse_submodules (nil) Control whether submodule
      #       commits are pushed
      #
      #       Pass a String (`'check'`, `'on-demand'`, `'only'`, `'no'`) to emit
      #       `--recurse-submodules=<value>`. When `false`, emits `--no-recurse-submodules`.
      #       Note: passing `true` is not valid; git requires an explicit value for this option.
      #
      #     @option options [Boolean] :thin (nil) Send a "thin" pack to reduce network traffic
      #
      #       Pass `false` to emit `--no-thin`.
      #
      #     @option options [Boolean] :progress (nil) Force progress reporting even when stderr is not a terminal
      #
      #     @option options [Boolean] :ipv4 (nil) Use IPv4 addresses only
      #
      #       Alias: :"4"
      #
      #     @option options [Boolean] :ipv6 (nil) Use IPv6 addresses only
      #
      #       Alias: :"6"
      #
      #     @option options [Integer] :timeout (nil) Maximum seconds to wait for the command to complete
      #
      #     @return [Git::CommandLineResult] the result of calling `git push`
      #
      #     @raise [Git::FailedError] if git exits with a non-zero exit status
      #
    end
  end
end
