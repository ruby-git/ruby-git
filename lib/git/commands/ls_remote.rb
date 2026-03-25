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
    # @see https://git-scm.com/docs/git-ls-remote git-ls-remote documentation
    # @see Git::Commands
    #
    # @api private
    #
    # @example List all refs in a remote
    #   ls_remote = Git::Commands::LsRemote.new(execution_context)
    #   ls_remote.call('origin')
    #
    # @example List only branches and tags
    #   ls_remote = Git::Commands::LsRemote.new(execution_context)
    #   ls_remote.call('origin', heads: true, tags: true)
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
    class LsRemote < Git::Commands::Base
      arguments do
        literal 'ls-remote'

        flag_option %i[heads h]                                       # --heads; alias: :h
        flag_option %i[tags t]                                        # --tags; alias: :t
        flag_option :refs                                             # --refs

        # Connectivity
        value_option :upload_pack, inline: true # --upload-pack=<exec>

        flag_option %i[quiet q]                                       # --quiet; alias: :q
        flag_option :exit_code                                        # --exit-code
        flag_option :get_url                                          # --get-url
        value_option :sort, inline: true                              # --sort=<key>
        flag_option :symref                                           # --symref

        value_option %i[server_option o],                             # --server-option=<option>
                     inline: true, repeatable: true                   # alias: :o

        # Execution-only options (not emitted as CLI flags)
        execution_option :timeout

        end_of_options

        operand :repository # [<repository>]
        operand :pattern, repeatable: true # [<patterns>...]
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
      #       When omitted, all references (after filtering via `--heads`, `--tags`,
      #       `--refs`) are shown. When specified, only refs matching one or more
      #       patterns are displayed.
      #
      #     @param options [Hash] command options
      #
      #     @option options [Boolean] :heads (nil) Limit output to refs under `refs/heads/`
      #
      #       Alias: :h
      #
      #     @option options [Boolean] :tags (nil) Limit output to refs under `refs/tags/`
      #
      #       Alias: :t
      #
      #     @option options [Boolean] :refs (nil) Exclude peeled tags and pseudorefs
      #       like `HEAD` from the output
      #
      #     @option options [String] :upload_pack (nil) Full path to `git-upload-pack`
      #       on the remote host
      #
      #       Useful when accessing repositories via SSH where the daemon does not
      #       use the PATH configured by the user.
      #
      #     @option options [Boolean] :quiet (nil) Do not print the remote URL to stderr
      #
      #       Alias: :q
      #
      #     @option options [Boolean] :exit_code (nil) Exit with status `2` when no
      #       matching refs are found in the remote repository
      #
      #       Without this option, the command exits `0` whenever it successfully
      #       communicates with the remote, even if no refs match.
      #
      #     @option options [Boolean] :get_url (nil) Expand and print the remote URL
      #       (respecting `url.<base>.insteadOf` config) and exit without contacting
      #       the remote
      #
      #     @option options [String] :sort (nil) Sort output by the given key
      #
      #       Prefix `-` for descending order. Supports `"version:refname"` or
      #       `"v:refname"`. See `git for-each-ref` for sort key documentation.
      #
      #     @option options [Boolean] :symref (nil) Show the underlying ref pointed to by
      #       symbolic refs
      #
      #       The `upload-pack` protocol currently surfaces only the `HEAD` symref,
      #       so that is typically the only symref shown.
      #
      #     @option options [String, Array<String>] :server_option (nil) Transmit a
      #       string to the server when communicating using protocol version 2
      #
      #       The string must not contain NUL or LF characters. Repeatable by
      #       passing an Array. Alias: :o
      #
      #     @option options [Numeric] :timeout (nil) Execution timeout in seconds
      #
      #     @return [Git::CommandLineResult] the result of calling `git ls-remote`
      #
      #     @raise [Git::FailedError] if git returns an exit code > 2
    end
  end
end
