# frozen_string_literal: true

require 'git/commands/base'

module Git
  module Commands
    module Revert
      # Implements `git revert` to create commits that undo prior changes
      #
      # Given one or more existing commits, reverts the changes introduced by
      # those commits and records new commits that reverse them. This requires
      # the working tree to be clean.
      #
      # @example Revert the most recent commit
      #   revert = Git::Commands::Revert::Start.new(execution_context)
      #   revert.call('HEAD')
      #
      # @example Revert a specific commit without committing
      #   revert.call('abc123', no_commit: true)
      #
      # @example Revert a range of commits
      #   revert.call('HEAD~3..HEAD~1')
      #
      # @example Revert a merge commit specifying the mainline parent
      #   revert.call('abc123', mainline: 1)
      #
      # @note `arguments` block audited against https://git-scm.com/docs/git-revert/2.53.0
      #
      # @see Git::Commands::Revert
      #
      # @see https://git-scm.com/docs/git-revert git-revert
      #
      # @api private
      #
      class Start < Git::Commands::Base
        arguments do
          literal 'revert'

          # Edit commit message (SYNOPSIS: [--[no-]edit])
          flag_option %i[edit e], negatable: true

          # Commit behavior (SYNOPSIS: [-n])
          flag_option %i[no_commit n]

          # Parent selection for merge commits (SYNOPSIS: [-m <parent-number>])
          value_option %i[mainline m]

          # Authorship (SYNOPSIS: [-s])
          flag_option %i[signoff s], negatable: true

          # GPG signing (SYNOPSIS: [-S[<keyid>]])
          flag_or_value_option %i[gpg_sign S], negatable: true, inline: true

          # Commit message cleanup
          value_option :cleanup, inline: true

          # Merge strategy
          value_option :strategy, inline: true
          value_option %i[strategy_option X], inline: true, repeatable: true

          # Conflict resolution
          flag_option :rerere_autoupdate, negatable: true

          # Commit log message format
          flag_option :reference

          end_of_options

          # Commits to revert
          operand :commit, repeatable: true, required: true
        end

        # @!method call(*, **)
        #
        #   @overload call(*commit, **options)
        #
        #     Execute the git revert command
        #
        #     @param commit [Array<String>] one or more commit SHAs, refs, or
        #       rev ranges to revert
        #
        #     @param options [Hash] command options
        #
        #     @option options [Boolean] :edit (false) open the editor for the
        #       commit message (`--edit`)
        #
        #       Alias: `:e`
        #
        #     @option options [Boolean] :no_edit (false) suppress the editor for
        #       the commit message (`--no-edit`)
        #
        #     @option options [Boolean] :no_commit (false) apply changes to index
        #       and working tree without committing
        #
        #       Alias: `:n`
        #
        #     @option options [Integer, String] :mainline (nil) parent number (starting
        #       from 1) identifying the mainline when reverting a merge commit
        #
        #       Alias: `:m`
        #
        #     @option options [Boolean] :signoff (false) add a `Signed-off-by`
        #       trailer to the commit message (`--signoff`)
        #
        #       Alias: `:s`
        #
        #     @option options [Boolean] :no_signoff (false) suppress the
        #       `Signed-off-by` trailer (`--no-signoff`)
        #
        #     @option options [Boolean, String] :gpg_sign (false) GPG-sign the
        #       resulting commit (`--gpg-sign`)
        #
        #       When `true`, uses the default key. When a `String`, uses the
        #       specified key ID. Alias: `:S`
        #
        #     @option options [Boolean] :no_gpg_sign (false) disable GPG signing
        #       (`--no-gpg-sign`)
        #
        #     @option options [String] :cleanup (nil) commit message cleanup mode
        #
        #       Accepted values include `strip`, `whitespace`, `verbatim`,
        #       `scissors`, and `default`. Emits `--cleanup=<mode>`.
        #
        #     @option options [String] :strategy (nil) merge strategy to use
        #       (e.g., `'ort'`, `'recursive'`, `'resolve'`)
        #
        #       Emits `--strategy=<strategy>`.
        #
        #     @option options [String, Array<String>] :strategy_option (nil) pass
        #       option(s) to the merge strategy (e.g., `'ours'`, `'theirs'`)
        #
        #       Can be a single value or an array for multiple `-X` flags.
        #       Emits `--strategy-option=<option>`. Alias: `:X`
        #
        #     @option options [Boolean] :rerere_autoupdate (false) allow rerere to
        #       update the index with the auto-resolved conflict result
        #       (`--rerere-autoupdate`)
        #
        #     @option options [Boolean] :no_rerere_autoupdate (false) prevent rerere
        #       from auto-updating the index (`--no-rerere-autoupdate`)
        #
        #     @option options [Boolean] :reference (false) use compact reference
        #       format in the revert commit message instead of the full object name
        #
        #     @return [Git::CommandLineResult] the result of calling `git revert`
        #
        #     @raise [ArgumentError] if unsupported options are provided
        #
        #     @raise [Git::FailedError] if git exits with a non-zero exit status
      end
    end
  end
end
