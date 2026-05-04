# frozen_string_literal: true

require 'git/commands/base'

module Git
  module Commands
    module Am
      # Implements `git am` to apply a series of patches from a mailbox
      #
      # Splits mail messages in a mailbox into commit log messages, authorship
      # information, and patches, and applies them to the current branch.
      #
      # @example Apply patches from a mailbox file
      #   am = Git::Commands::Am::Apply.new(execution_context)
      #   am.call('patches.mbox', chdir: repo.workdir)
      #
      # @example Apply patches with sign-off
      #   am.call('patches.mbox', signoff: true, chdir: repo.workdir)
      #
      # @example Apply with 3-way merge fallback
      #   am.call('patches.mbox', three_way: true, chdir: repo.workdir)
      #
      # @note `arguments` block audited against https://git-scm.com/docs/git-am/2.53.0
      #
      # @see https://git-scm.com/docs/git-am git-am
      #
      # @api private
      #
      class Apply < Git::Commands::Base
        arguments do
          literal 'am'

          # Commit message / mailinfo options
          flag_option %i[signoff s]
          flag_option %i[keep k]
          flag_option :keep_non_patch
          flag_option :keep_cr, negatable: true
          flag_option %i[scissors c], negatable: true
          value_option :quoted_cr
          value_option :empty
          flag_option %i[message_id m], negatable: true

          # Output
          flag_option %i[quiet q]

          # Encoding
          flag_option %i[utf8 u], negatable: true

          # Application strategy
          flag_option :three_way, as: '--3way', negatable: true
          flag_option :rerere_autoupdate, negatable: true

          # Whitespace and patch application options (passed to git-apply)
          flag_option :ignore_space_change
          flag_option :ignore_whitespace
          value_option :whitespace
          value_option :C, inline: true
          value_option :p, inline: true
          value_option :directory
          value_option :exclude, repeatable: true
          value_option :include, repeatable: true
          flag_option :reject

          # Patch format
          value_option :patch_format

          # Interactive mode
          flag_option %i[interactive i]

          # Hook verification
          flag_option :verify, negatable: true

          # Date handling
          flag_option :committer_date_is_author_date
          flag_option :ignore_date

          # GPG signing
          flag_or_value_option %i[gpg_sign S], inline: true, negatable: true

          # Execution
          execution_option :chdir

          end_of_options
          operand :mbox, repeatable: true
        end

        # @!method call(*, **)
        #
        #   @overload call(*mbox, **options)
        #
        #     Apply patches from one or more mailbox files to the current branch.
        #
        #     @param mbox [Array<String>] zero or more mailbox file paths or Maildir
        #       directories
        #
        #       If omitted, reads from standard input.
        #
        #     @param options [Hash] command options
        #
        #     @option options [Boolean] :signoff (nil) add Signed-off-by trailer
        #
        #       Alias: `:s`
        #
        #     @option options [Boolean] :keep (nil) pass -k flag to git-mailinfo,
        #       preserving the Subject line intact
        #
        #       Alias: `:k`
        #
        #     @option options [Boolean] :keep_non_patch (nil) pass -b flag to
        #       git-mailinfo
        #
        #     @option options [Boolean] :keep_cr (false) retain CR at end of lines (`--keep-cr`)
        #
        #     @option options [Boolean] :no_keep_cr (false) strip CR at end of lines (`--no-keep-cr`)
        #
        #     @option options [Boolean] :scissors (false) remove everything in the
        #       body before a scissors line (`--scissors`)
        #
        #       Alias: `:c`
        #
        #     @option options [Boolean] :no_scissors (false) disable scissors mode (`--no-scissors`)
        #
        #     @option options [String] :quoted_cr (nil) how to handle CR in quoted
        #       text passed to git-mailinfo
        #
        #       Valid actions: `'nowarn'`, `'warn'`, `'error'`.
        #
        #     @option options [String] :empty (nil) how to handle an e-mail message
        #       lacking a patch
        #
        #       Valid values: `'stop'` (fail, default), `'drop'` (skip the message),
        #       `'keep'` (create an empty commit).
        #
        #     @option options [Boolean] :message_id (false) pass -m flag to
        #       git-mailinfo, adding the Message-ID header to the commit message (`--message-id`)
        #
        #       Alias: `:m`
        #
        #     @option options [Boolean] :no_message_id (false) do not add the Message-ID header (`--no-message-id`)
        #
        #     @option options [Boolean] :quiet (nil) be quiet; only print error
        #       messages
        #
        #       Alias: `:q`
        #
        #     @option options [Boolean] :utf8 (false) re-code the commit log message
        #       in UTF-8 (`--utf8`)
        #
        #       Alias: `:u`
        #
        #     @option options [Boolean] :no_utf8 (false) do not re-code the commit log message (`--no-utf8`)
        #
        #     @option options [Boolean] :three_way (false) attempt 3-way merge when
        #       context does not match (`--3way`)
        #
        #     @option options [Boolean] :no_three_way (false) disable 3-way merge fallback (`--no-3way`)
        #
        #     @option options [Boolean] :rerere_autoupdate (false) allow rerere to
        #       update the index with auto-resolved conflicts (`--rerere-autoupdate`)
        #
        #     @option options [Boolean] :no_rerere_autoupdate (false) prevent rerere from
        #       auto-updating the index (`--no-rerere-autoupdate`)
        #
        #     @option options [Boolean] :ignore_space_change (nil) ignore whitespace
        #       changes when applying (passed to git-apply)
        #
        #     @option options [Boolean] :ignore_whitespace (nil) ignore whitespace
        #       when applying (passed to git-apply)
        #
        #     @option options [String] :whitespace (nil) whitespace error handling
        #       (e.g., `'nowarn'`, `'warn'`, `'fix'`, `'error'`)
        #
        #       Passed to git-apply.
        #
        #     @option options [Integer] :C (nil) ensure at least `<n>` lines of
        #       surrounding context match when applying (`-C<n>`)
        #
        #       Passed to git-apply.
        #
        #     @option options [Integer] :p (nil) strip `<n>` leading path components
        #       from file names (`-p<n>`)
        #
        #       Passed to git-apply.
        #
        #     @option options [String] :directory (nil) prepend `<dir>` to all
        #       filenames
        #
        #       Passed to git-apply.
        #
        #     @option options [Array<String>] :exclude (nil) skip files matching the
        #       given path pattern
        #
        #       May be repeated. Passed to git-apply.
        #
        #     @option options [Array<String>] :include (nil) apply only to files
        #       matching the given path pattern
        #
        #       May be repeated. Passed to git-apply.
        #
        #     @option options [Boolean] :reject (nil) leave rejected hunks in
        #       `*.rej` files instead of aborting
        #
        #       Passed to git-apply.
        #
        #     @option options [String] :patch_format (nil) override patch format
        #       detection
        #
        #       Valid formats: `'mbox'`, `'mboxrd'`, `'stgit'`, `'stgit-series'`,
        #       `'hg'`.
        #
        #     @option options [Boolean] :interactive (false) run interactively,
        #       prompting before each patch is applied
        #
        #       Alias: `:i`
        #
        #     @option options [Boolean] :verify (false) run pre-applypatch and
        #       applypatch-msg hooks (`--verify`)
        #
        #       Hooks are run by default when this option is omitted.
        #
        #     @option options [Boolean] :no_verify (false) bypass pre-applypatch and
        #       applypatch-msg hooks (`--no-verify`)
        #
        #     @option options [Boolean] :committer_date_is_author_date (nil) use the
        #       author date as the committer date
        #
        #     @option options [Boolean] :ignore_date (nil) use the committer date as
        #       the author date
        #
        #     @option options [Boolean, String] :gpg_sign (false) sign commits using
        #       GPG (`--gpg-sign`)
        #
        #       Pass a key-ID string to select the signing key; pass `true` to use
        #       the committer identity. Alias: `:S`
        #
        #     @option options [Boolean] :no_gpg_sign (false) countermand commit.gpgSign
        #       configuration (`--no-gpg-sign`)
        #
        #     @option options [String] :chdir (nil) change to this directory before
        #       running git
        #
        #       Not passed to the git CLI.
        #
        #     @return [Git::CommandLineResult] the result of calling `git am`
        #
        #     @raise [ArgumentError] if unsupported options are provided
        #
        #     @raise [Git::FailedError] if git exits with a non-zero exit status
      end
    end
  end
end
