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
    #   commit.call(amend: true, no_verify: true)  # emits --no-verify
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
        flag_option %i[all a]

        # Message source and editing
        flag_option %i[edit e], negatable: true
        flag_option :amend
        value_option %i[reuse_message C], inline: true
        value_option :fixup, inline: true
        value_option :squash, inline: true
        value_option %i[message m], inline: true, allow_empty: true
        value_option %i[file F], inline: true
        value_option %i[template t], inline: true

        # Author / date
        flag_option :reset_author
        value_option :author, inline: true
        value_option :date, inline: true, type: String

        # Message cleanup and trailers
        value_option :cleanup, inline: true
        value_option :trailer, repeatable: true

        # Hooks
        flag_option %i[verify n], negatable: true

        # Behavior
        flag_option :allow_empty
        flag_option :allow_empty_message
        flag_option :no_post_rewrite
        flag_option %i[include i]
        flag_option %i[only o]

        # Output / dry-run
        flag_option :dry_run
        flag_option :short
        flag_option :branch
        flag_option :porcelain
        flag_option :long
        flag_option %i[null z]
        flag_option %i[verbose v], max_times: 2
        flag_option %i[quiet q]
        flag_option :status, negatable: true

        # Verbose diff options
        value_option %i[unified U], inline: true, type: Integer
        value_option :inter_hunk_context, inline: true, type: Integer

        # Signoff
        flag_option %i[signoff s], negatable: true

        # GPG signing
        flag_or_value_option %i[gpg_sign S], negatable: true, inline: true

        # Untracked files
        flag_or_value_option %i[untracked_files u], inline: true

        # Pathspec from file
        value_option :pathspec_from_file, inline: true
        flag_option :pathspec_file_nul

        # Path selection
        end_of_options
        operand :pathspec, repeatable: true
      end

      # @overload call(*pathspec, **options)
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
      #     @option options [Boolean, nil] :all (nil) automatically stage modified and deleted
      #       files before committing
      #
      #       Alias: `:a`
      #
      #     @option options [Boolean, nil] :edit (nil) open an editor for the commit message (`--edit`)
      #
      #       Alias: `:e`
      #
      #     @option options [Boolean, nil] :no_edit (nil) suppress the editor (`--no-edit`)
      #
      #     @option options [Boolean, nil] :amend (nil) replace the tip of the current branch
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
      #     @option options [Boolean, nil] :reset_author (nil) when used with `:reuse_message`
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
      #     @option options [Boolean, nil] :verify (nil) run pre-commit and commit-msg hooks (`--verify`)
      #
      #       Alias: `:n`
      #
      #     @option options [Boolean, nil] :no_verify (nil) bypass pre-commit and commit-msg hooks (`--no-verify`)
      #
      #     @option options [Boolean, nil] :allow_empty (nil) allow committing with no changes
      #
      #     @option options [Boolean, nil] :allow_empty_message (nil) allow committing with an
      #       empty message
      #
      #     @option options [Boolean, nil] :no_post_rewrite (nil) bypass the post-rewrite hook
      #
      #     @option options [Boolean, nil] :include (nil) stage the listed paths before
      #       committing in addition to already-staged contents
      #
      #       Alias: `:i`
      #
      #     @option options [Boolean, nil] :only (nil) commit only the listed paths from the
      #       working tree, ignoring staged changes for other paths
      #
      #       Alias: `:o`
      #
      #     @option options [Boolean, nil] :dry_run (nil) do not create a commit; show what
      #       would be committed
      #
      #     @option options [Boolean, nil] :short (nil) show short-format dry-run output;
      #       implies `:dry_run`
      #
      #     @option options [Boolean, nil] :branch (nil) show branch and tracking info in
      #       short-format dry-run output
      #
      #     @option options [Boolean, nil] :porcelain (nil) show porcelain-format dry-run
      #       output; implies `:dry_run`
      #
      #     @option options [Boolean, nil] :long (nil) show long-format dry-run output;
      #       implies `:dry_run`
      #
      #     @option options [Boolean, nil] :null (nil) terminate dry-run output entries with
      #       NUL instead of LF
      #
      #       Alias: `:z`
      #
      #     @option options [Boolean, Integer, nil] :verbose (nil) show unified diff between
      #       HEAD and what would be committed at the bottom of the commit message template
      #
      #       Pass `2` to also show the unified diff between staged and working-tree changes.
      #
      #       Alias: `:v`
      #
      #     @option options [Boolean, nil] :quiet (nil) suppress commit summary message
      #
      #       Alias: `:q`
      #
      #     @option options [Boolean, nil] :status (nil) include `git status` output in the
      #       commit message template (`--status`)
      #
      #     @option options [Boolean, nil] :no_status (nil) omit `git status` output from the
      #       commit message template (`--no-status`)
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
      #       the commit message (`--signoff`)
      #
      #       Alias: `:s`
      #
      #     @option options [Boolean, nil] :no_signoff (nil) suppress the `Signed-off-by` trailer (`--no-signoff`)
      #
      #     @option options [Boolean, String, nil] :gpg_sign (nil) GPG-sign the commit (`--gpg-sign`)
      #
      #       When `true`, uses the default key. When a `String`, uses the specified key ID.
      #
      #       Alias: `:S`
      #
      #     @option options [Boolean, nil] :no_gpg_sign (nil) disable GPG signing, overriding
      #       `commit.gpgSign` config (`--no-gpg-sign`)
      #
      #     @option options [Boolean, String, nil] :untracked_files (nil) show untracked files
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
      #     @option options [Boolean, nil] :pathspec_file_nul (nil) pathspec elements in
      #       `:pathspec_from_file` are NUL-separated instead of newline-separated
      #
      #     @return [Git::CommandLine::Result] the result of calling `git commit`
      #
      #     @raise [ArgumentError] if unsupported options are provided
      #
      #     @raise [Git::FailedError] if git exits with a non-zero exit status
      #
      #   @api public
      #
      def call(*, **)
        super
      end
    end
  end
end
