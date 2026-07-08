# frozen_string_literal: true

require 'git/commands/base'

module Git
  module Commands
    # Implements the `git push` command
    #
    # Updates remote refs using local refs, while sending objects necessary to
    # complete the given refs.
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
    # @note `arguments` block audited against https://git-scm.com/docs/git-push/2.53.0
    #
    # @see https://git-scm.com/docs/git-push git-push
    #
    # @see Git::Commands
    #
    # @api private
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
                             negatable: true, inline: true, type: String

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

      # @!method call(*, **options)
      #
      #   @param options [Hash] command options
      #
      #   @option options [Boolean, nil] :all (nil) command option key; see overload docs
      #     for the full option list
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
      #     @option options [Boolean, nil] :all (nil) push all branches
      #
      #       Alias: :branches
      #
      #     @option options [Boolean, nil] :mirror (nil) push all refs under `refs/` to the remote
      #
      #     @option options [Boolean, nil] :tags (nil) push all refs under `refs/tags/`
      #
      #     @option options [Boolean, nil] :follow_tags (nil) push reachable annotated tags (`--follow-tags`)
      #
      #     @option options [Boolean, nil] :no_follow_tags (nil) do not push reachable annotated tags
      #       (`--no-follow-tags`)
      #
      #     @option options [Boolean, nil] :atomic (nil) use an atomic transaction to update remote refs (`--atomic`)
      #
      #     @option options [Boolean, nil] :no_atomic (nil) disable atomic transaction for remote updates
      #       (`--no-atomic`)
      #
      #     @option options [Boolean, nil] :dry_run (nil) do not send updates, only report what would be pushed
      #
      #       Alias: :n
      #
      #     @option options [Boolean, nil] :porcelain (nil) produce machine-readable output
      #
      #     @option options [String] :receive_pack (nil) path to the git-receive-pack program on the remote end
      #
      #       Alias: :exec
      #
      #     @option options [String] :repo (nil) use this repository instead of the
      #       positional repository argument
      #
      #       Equivalent to the positional `<repository>` argument. If both are given, the
      #       positional argument takes precedence.
      #
      #     @option options [Boolean, nil] :force (nil) force updates, overriding the fast-forward check
      #
      #       Alias: :f
      #
      #     @option options [Boolean, nil] :delete (nil) delete all listed refs from the remote repository
      #
      #       Alias: :d
      #
      #     @option options [Boolean, nil] :prune (nil) remove remote branches that have no local counterpart
      #
      #     @option options [Boolean, nil] :quiet (nil) suppress all output
      #
      #       Alias: :q
      #
      #     @option options [Boolean, nil] :verbose (nil) run verbosely
      #
      #       Alias: :v
      #
      #     @option options [Boolean, nil] :set_upstream (nil) set upstream tracking for each successfully pushed branch
      #
      #       Alias: :u
      #
      #     @option options [String, Array<String>] :push_option (nil) transmit one or more server-side options
      #
      #       Repeatable. Each occurrence emits a separate `--push-option=<value>` flag.
      #
      #       Alias: :o
      #
      #     @option options [Boolean, String, nil] :signed (nil) GPG-sign the push certificate (`--signed`)
      #
      #       When a String (`'true'`, `'false'`, `'if-asked'`), emits `--signed=<value>`.
      #
      #     @option options [Boolean, nil] :no_signed (nil) disable GPG signing of the push certificate (`--no-signed`)
      #
      #     @option options [Boolean, String, nil] :force_with_lease (nil) refuse force pushes unless the
      #       remote ref matches the expected value (`--force-with-lease`)
      #
      #       When a String (e.g. `'main:abc123'`), emits `--force-with-lease=<string>`.
      #
      #     @option options [Boolean, nil] :no_force_with_lease (nil) disable force-with-lease (`--no-force-with-lease`)
      #
      #     @option options [Boolean, nil] :force_if_includes (nil) force pushes only if commits being
      #       pushed are already in the remote-tracking branch (`--force-if-includes`)
      #
      #     @option options [Boolean, nil] :no_force_if_includes (nil) disable force-if-includes
      #       (`--no-force-if-includes`)
      #
      #     @option options [Boolean, nil] :verify (nil) run the pre-push hook (`--verify`)
      #
      #     @option options [Boolean, nil] :no_verify (nil) bypass the pre-push hook (`--no-verify`)
      #
      #     @option options [String] :recurse_submodules (nil) control whether submodule
      #       commits are pushed
      #
      #       Pass a String (`'check'`, `'on-demand'`, `'only'`, `'no'`) to emit
      #       `--recurse-submodules=<value>`. Note: passing `true` is not valid; git requires
      #       an explicit value for this option.
      #
      #     @option options [Boolean, nil] :no_recurse_submodules (nil) disable submodule push
      #       (`--no-recurse-submodules`)
      #
      #     @option options [Boolean, nil] :thin (nil) send a "thin" pack to reduce network traffic (`--thin`)
      #
      #     @option options [Boolean, nil] :no_thin (nil) send a full pack instead of a thin pack (`--no-thin`)
      #
      #     @option options [Boolean, nil] :progress (nil) force progress reporting even when stderr is not a terminal
      #
      #     @option options [Boolean, nil] :ipv4 (nil) use IPv4 addresses only
      #
      #       Alias: :"4"
      #
      #     @option options [Boolean, nil] :ipv6 (nil) use IPv6 addresses only
      #
      #       Alias: :"6"
      #
      #     @option options [Integer] :timeout (nil) maximum seconds to wait for the command to complete
      #
      #     @return [Git::CommandLineResult] the result of calling `git push`
      #
      #     @raise [ArgumentError] if unsupported options are provided
      #
      #     @raise [Git::FailedError] if git exits with a non-zero exit status
      #
    end
  end
end
