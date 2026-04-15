# frozen_string_literal: true

require 'git/commands/base'

module Git
  module Commands
    # Implements the `git commit` command
    #
    # This command records changes to the repository by creating a new commit
    # with the staged changes.
    #
    # @example Typical usage
    #   commit = Git::Commands::Commit.new(execution_context)
    #   commit.call(message: 'Initial commit')
    #   commit.call(message: 'Add feature', all: true, author: 'Jane <jane@example.com>')
    #   commit.call(amend: true, verify: false)  # emits --no-verify
    #   commit.call('src/foo.rb', message: 'Update foo')
    #
    # @note `arguments` block audited against https://git-scm.com/docs/git-commit/2.53.0
    #
    # @see https://git-scm.com/docs/git-commit git-commit
    #
    # @see Git::Commands
    #
    # @api private
    #
    class Commit < Git::Commands::Base
      arguments do
        literal 'commit'

        # Stage selection
        flag_option %i[all a] # --all (alias: :a)

        # Message source and editing
        flag_option %i[edit e], negatable: true                          # --edit / --no-edit (alias: :e)
        flag_option :amend                                               # --amend
        value_option %i[reuse_message C], inline: true                   # --reuse-message=<commit> (alias: :C)
        value_option :fixup, inline: true                                # --fixup=[amend:|reword:]<commit>
        value_option :squash, inline: true                               # --squash=<commit>
        value_option %i[message m], inline: true, allow_empty: true      # --message=<msg> (alias: :m)
        value_option %i[file F], inline: true                            # --file=<file> (alias: :F)
        value_option %i[template t], inline: true                        # --template=<file> (alias: :t)

        # Author / date
        flag_option :reset_author                                        # --reset-author
        value_option :author, inline: true                               # --author=<author>
        value_option :date, inline: true, type: String                   # --date=<date>

        # Message cleanup and trailers
        value_option :cleanup, inline: true                              # --cleanup=<mode>
        value_option :trailer, repeatable: true                          # --trailer <token>[=<value>]

        # Hooks
        flag_option %i[verify n], negatable: true # --verify / --no-verify (alias: :n)

        # Behavior
        flag_option :allow_empty                                         # --allow-empty
        flag_option :allow_empty_message                                 # --allow-empty-message
        flag_option :no_post_rewrite                                     # --no-post-rewrite
        flag_option %i[include i]                                        # --include (alias: :i)
        flag_option %i[only o]                                           # --only (alias: :o)

        # Output / dry-run
        flag_option :dry_run                                             # --dry-run
        flag_option :short                                               # --short
        flag_option :branch                                              # --branch
        flag_option :porcelain                                           # --porcelain
        flag_option :long                                                # --long
        flag_option %i[null z]                                           # --null (alias: :z)
        flag_option %i[verbose v], max_times: 2                          # --verbose (alias: :v, up to 2×)
        flag_option %i[quiet q]                                          # --quiet (alias: :q)
        flag_option :status, negatable: true                             # --status / --no-status

        # Verbose diff options
        value_option %i[unified U], inline: true, type: Integer          # --unified=<n> (alias: :U)
        value_option :inter_hunk_context, inline: true, type: Integer    # --inter-hunk-context=<n>

        # Signoff
        flag_option %i[signoff s], negatable: true # --signoff / --no-signoff (alias: :s)

        # GPG signing
        flag_or_value_option %i[gpg_sign S], negatable: true, inline: true # --gpg-sign[=<keyid>] / --no-gpg-sign (:S)

        # Untracked files
        flag_or_value_option %i[untracked_files u], inline: true # --untracked-files[=<mode>] (alias: :u)

        # Pathspec from file
        value_option :pathspec_from_file, inline: true                   # --pathspec-from-file=<file>
        flag_option :pathspec_file_nul                                   # --pathspec-file-nul

        # Path selection
        end_of_options
        operand :pathspec, repeatable: true
      end

      # @!method call(*, **)
      #
      #   @overload call(*pathspec, **options)
      #
      #     Execute the `git commit` command.
      #
      #     @param pathspec [Array<String>] zero or more paths to commit
      #
      #       When given, only changes to the listed paths are committed, ignoring
      #       staged changes for other paths.
      #
      #     @param options [Hash] command options
      #
      #     @option options [Boolean] :all (false) automatically stage modified and deleted
      #       files before committing
      #
      #       Alias: `:a`
      #
      #     @option options [Boolean, nil] :edit (nil) open an editor for the commit message
      #
      #       When `false`, adds `--no-edit` to suppress the editor. When `true`, adds
      #       `--edit`. When `nil`, defers to git's default behavior.
      #
      #       Alias: `:e`
      #
      #     @option options [Boolean] :amend (false) replace the tip of the current branch
      #       with a new commit
      #
      #     @option options [String] :reuse_message (nil) reuse the log message and
      #       authorship from the given commit without invoking an editor
      #
      #       Alias: `:C`
      #
      #     @option options [String] :fixup (nil) create a fixup or amend commit targeting
      #       the given commit
      #
      #       Pass `<commit>` for a plain "fixup!" commit, `amend:<commit>` to also replace
      #       the log message, or `reword:<commit>` to replace only the log message.
      #
      #     @option options [String] :squash (nil) construct a "squash!" commit message for
      #       use with `git rebase --autosquash`
      #
      #     @option options [String] :message (nil) use the given string as the commit message
      #
      #       Alias: `:m`
      #
      #     @option options [String] :file (nil) read the commit message from the given file;
      #       use `-` to read from standard input
      #
      #       Alias: `:F`
      #
      #     @option options [String] :template (nil) start the editor with the contents of
      #       the given file as the commit message template
      #
      #       Alias: `:t`
      #
      #     @option options [Boolean] :reset_author (false) when used with `:reuse_message`
      #       or `:amend`, declare the committer as the new author
      #
      #     @option options [String] :author (nil) override the commit author
      #
      #     @option options [String] :date (nil) override the author date
      #
      #     @option options [String] :cleanup (nil) how to clean up the commit message before
      #       committing; one of `strip`, `whitespace`, `verbatim`, `scissors`, or `default`
      #
      #     @option options [String, Array<String>] :trailer (nil) add one or more
      #       `<token>[=<value>]` trailers to the commit message
      #
      #     @option options [Boolean, nil] :verify (nil) run pre-commit and commit-msg hooks
      #
      #       When `false`, adds `--no-verify` to bypass the hooks. When `true`, adds
      #       `--verify` to explicitly re-enable them. When `nil`, defers to git's default.
      #
      #       Alias: `:n`
      #
      #     @option options [Boolean] :allow_empty (false) allow committing with no changes
      #
      #     @option options [Boolean] :allow_empty_message (false) allow committing with an
      #       empty message
      #
      #     @option options [Boolean] :no_post_rewrite (false) bypass the post-rewrite hook
      #
      #     @option options [Boolean] :include (false) stage the listed paths before
      #       committing in addition to already-staged contents
      #
      #       Alias: `:i`
      #
      #     @option options [Boolean] :only (false) commit only the listed paths from the
      #       working tree, ignoring staged changes for other paths
      #
      #       Alias: `:o`
      #
      #     @option options [Boolean] :dry_run (false) do not create a commit; show what
      #       would be committed
      #
      #     @option options [Boolean] :short (false) show short-format dry-run output;
      #       implies `:dry_run`
      #
      #     @option options [Boolean] :branch (false) show branch and tracking info in
      #       short-format dry-run output
      #
      #     @option options [Boolean] :porcelain (false) show porcelain-format dry-run
      #       output; implies `:dry_run`
      #
      #     @option options [Boolean] :long (false) show long-format dry-run output;
      #       implies `:dry_run`
      #
      #     @option options [Boolean] :null (false) terminate dry-run output entries with
      #       NUL instead of LF
      #
      #       Alias: `:z`
      #
      #     @option options [Boolean, Integer] :verbose (false) show unified diff between
      #       HEAD and what would be committed at the bottom of the commit message template
      #
      #       Pass `2` to also show the unified diff between staged and working-tree changes.
      #
      #       Alias: `:v`
      #
      #     @option options [Boolean] :quiet (false) suppress commit summary message
      #
      #       Alias: `:q`
      #
      #     @option options [Boolean, nil] :status (nil) include `git status` output in the
      #       commit message template
      #
      #       When `false`, adds `--no-status`. When `true`, adds `--status`. When `nil`,
      #       defers to git's default (controlled by `commit.status` config).
      #
      #     @option options [Integer] :unified (nil) generate verbose diff with the given
      #       number of context lines
      #
      #       Alias: `:U`
      #
      #     @option options [Integer] :inter_hunk_context (nil) show context between diff
      #       hunks up to the given number of lines (for use with `:verbose`)
      #
      #     @option options [Boolean, nil] :signoff (nil) add a `Signed-off-by` trailer to
      #       the commit message
      #
      #       When `false`, adds `--no-signoff`. When `nil`, defers to git's default.
      #
      #       Alias: `:s`
      #
      #     @option options [Boolean, String, nil] :gpg_sign (nil) GPG-sign the commit
      #
      #       When `true`, uses the default key. When a `String`, uses the specified key ID.
      #       When `false`, adds `--no-gpg-sign` to override `commit.gpgSign` config.
      #       When `nil`, defers to git's default.
      #
      #       Alias: `:S`
      #
      #     @option options [Boolean, String] :untracked_files (nil) show untracked files
      #       in the dry-run status output
      #
      #       When `true`, uses git's default mode (`all`). Pass a `String` (`"no"`,
      #       `"normal"`, or `"all"`) to set the mode explicitly.
      #
      #       Alias: `:u`
      #
      #     @option options [String] :pathspec_from_file (nil) read pathspec from the given
      #       file instead of the command line
      #
      #     @option options [Boolean] :pathspec_file_nul (false) pathspec elements in
      #       `:pathspec_from_file` are NUL-separated instead of newline-separated
      #
      #     @return [Git::CommandLineResult] the result of calling `git commit`
      #
      #     @raise [ArgumentError] if unsupported options are provided
      #
      #     @raise [Git::FailedError] if git exits with a non-zero exit status
      #
      #   @api public
      #
    end
  end
end
