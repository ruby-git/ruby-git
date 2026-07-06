# frozen_string_literal: true

require 'git/commands/base'

module Git
  module Commands
    # Implements the `git ls-remote` command
    #
    # Lists references available in a remote repository along with the
    # associated commit IDs. Can be used to detect changes in a remote
    # repository without cloning or fetching.
    #
    # @example List all refs in a remote
    #   ls_remote = Git::Commands::LsRemote.new(execution_context)
    #   ls_remote.call('origin')
    #
    # @example List only branches and tags
    #   ls_remote = Git::Commands::LsRemote.new(execution_context)
    #   ls_remote.call('origin', branches: true, tags: true)
    #
    # @example List only refs (no symbolic refs like HEAD)
    #   ls_remote = Git::Commands::LsRemote.new(execution_context)
    #   ls_remote.call('origin', refs: true)
    #
    # @example Filter by pattern
    #   ls_remote = Git::Commands::LsRemote.new(execution_context)
    #   ls_remote.call('origin', 'refs/heads/main')
    #
    # @example Detect the default branch of a remote
    #   ls_remote = Git::Commands::LsRemote.new(execution_context)
    #   ls_remote.call('origin', 'HEAD', symref: true)
    #
    # @note `arguments` block audited against https://git-scm.com/docs/git-ls-remote/2.53.0
    #
    # @see https://git-scm.com/docs/git-ls-remote git-ls-remote documentation
    #
    # @see Git::Commands
    #
    # @api private
    #
    class LsRemote < Git::Commands::Base
      arguments do
        literal 'ls-remote'

        flag_option %i[branches b]
        flag_option %i[heads h]
        flag_option %i[tags t]
        flag_option :refs

        # Connectivity
        value_option :upload_pack, inline: true

        flag_option %i[quiet q]
        flag_option :exit_code
        flag_option :get_url
        value_option :sort, inline: true
        flag_option :symref

        value_option %i[server_option o],
                     inline: true, repeatable: true

        # Execution-only options (not emitted as CLI flags)
        execution_option :timeout

        end_of_options

        operand :repository
        operand :pattern, repeatable: true
      end

      # Exit status 2 means no matching refs were found (used with --exit-code)
      allow_exit_status 0..2

      # @!method call(*, **)
      #
      #   @overload call(repository = nil, *patterns, **options)
      #
      #     Execute the `git ls-remote` command
      #
      #     @param repository [String, nil] The remote name or URL to query
      #
      #       When nil, git uses the remote inferred from the current branch's
      #       tracking configuration, or "origin" if no tracking remote is set.
      #
      #     @param patterns [Array<String>] One or more ref patterns to filter results
      #
      #       When omitted, all references (after filtering via `--branches`, `--tags`,
      #       `--refs`) are shown. When specified, only refs matching one or more
      #       patterns are displayed.
      #
      #     @param options [Hash] command options
      #
      #     @option options [Boolean, nil] :branches (nil) limit output to refs under `refs/heads/`
      #
      #       Alias: :b
      #
      #     @option options [Boolean, nil] :heads (nil) limit output to refs under `refs/heads/`
      #
      #       Deprecated: use `:branches` instead. Kept for backward compatibility with
      #       older git versions where `--heads` is the only supported flag.
      #
      #       Alias: :h
      #
      #     @option options [Boolean, nil] :tags (nil) limit output to refs under `refs/tags/`
      #
      #       Alias: :t
      #
      #     @option options [Boolean, nil] :refs (nil) exclude peeled tags and pseudorefs
      #       like `HEAD` from the output
      #
      #     @option options [String] :upload_pack (nil) full path to `git-upload-pack`
      #       on the remote host
      #
      #       Useful when accessing repositories via SSH where the daemon does not
      #       use the PATH configured by the user.
      #
      #     @option options [Boolean, nil] :quiet (nil) do not print the remote URL to stderr
      #
      #       Alias: :q
      #
      #     @option options [Boolean, nil] :exit_code (nil) exit with status `2` when no
      #       matching refs are found in the remote repository
      #
      #       Without this option, the command exits `0` whenever it successfully
      #       communicates with the remote, even if no refs match.
      #
      #     @option options [Boolean, nil] :get_url (nil) expand and print the remote URL
      #       (respecting `url.<base>.insteadOf` config) and exit without contacting
      #       the remote
      #
      #     @option options [String] :sort (nil) sort output by the given key
      #
      #       Prefix `-` for descending order. Supports `"version:refname"` or
      #       `"v:refname"`. See `git for-each-ref` for sort key documentation.
      #
      #     @option options [Boolean, nil] :symref (nil) show the underlying ref pointed to by
      #       symbolic refs
      #
      #       The `upload-pack` protocol currently surfaces only the `HEAD` symref,
      #       so that is typically the only symref shown.
      #
      #     @option options [String, Array<String>] :server_option (nil) transmit a
      #       string to the server when communicating using protocol version 2
      #
      #       The string must not contain NUL or LF characters. Repeatable by
      #       passing an Array. Alias: :o
      #
      #     @option options [Numeric] :timeout (nil) execution timeout in seconds
      #
      #     @return [Git::CommandLineResult] the result of calling `git ls-remote`
      #
      #     @raise [Git::FailedError] if git exits outside the allowed range (exit code > 2)
    end
  end
end
