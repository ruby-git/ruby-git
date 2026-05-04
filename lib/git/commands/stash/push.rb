# frozen_string_literal: true

require 'git/commands/base'

module Git
  module Commands
    module Stash
      # Stash changes in the working directory
      #
      # Saves local modifications to a new stash entry and rolls them back
      # to HEAD (in the working tree and index). The command takes
      # various options to customize what gets stashed.
      #
      # @note `arguments` block audited against https://git-scm.com/docs/git-stash/2.53.0
      #
      # @see Git::Commands::Stash Git::Commands::Stash for usage examples
      #
      # @see https://git-scm.com/docs/git-stash git-stash documentation
      #
      # @api private
      #
      # @example Save all changes with a message
      #   Git::Commands::Stash::Push.new(execution_context).call(message: 'WIP: feature work')
      #
      # @example Stash only specific files
      #   Git::Commands::Stash::Push.new(execution_context).call('src/file.rb', message: 'Partial stash')
      #
      # @example Keep staged changes in index
      #   Git::Commands::Stash::Push.new(execution_context).call(keep_index: true)
      #
      # @example Include untracked files
      #   Git::Commands::Stash::Push.new(execution_context).call(include_untracked: true)
      #
      class Push < Git::Commands::Base
        arguments do
          literal 'stash'
          literal 'push'
          flag_option %i[patch p]
          flag_option %i[staged S]
          flag_option %i[keep_index k], negatable: true
          flag_option %i[quiet q]
          flag_option %i[include_untracked u]
          flag_option %i[all a]
          value_option %i[message m]
          value_option :pathspec_from_file, inline: true
          flag_option :pathspec_file_nul
          end_of_options
          operand :pathspec, repeatable: true
        end

        # @!method call(*, **)
        #
        #   @overload call(*pathspec, **options)
        #
        #     Stash changes in the working directory
        #
        #     @param pathspec [Array<String>] optional paths to limit what gets stashed
        #
        #     @param options [Hash] command options
        #
        #     @option options [Boolean] :patch (false) interactively select hunks to stash
        #
        #       Alias: :p
        #
        #     @option options [Boolean] :staged (false) stash only staged changes
        #
        #       Alias: :S
        #
        #     @option options [Boolean] :keep_index (false) keep staged changes in the index (`--keep-index`)
        #
        #       Alias: :k
        #
        #     @option options [Boolean] :no_keep_index (false) do not preserve staged changes in the index
        #       (`--no-keep-index`)
        #
        #     @option options [Boolean] :quiet (false) suppress informational messages
        #
        #       Alias: :q
        #
        #     @option options [Boolean] :include_untracked (false) include untracked files in the stash
        #
        #       Alias: :u
        #
        #     @option options [Boolean] :all (false) include untracked and ignored files in the stash
        #
        #       Alias: :a
        #
        #     @option options [String] :message (nil) descriptive message for the stash
        #
        #       Alias: :m
        #
        #     @option options [String] :pathspec_from_file (nil) read pathspecs from the given file
        #
        #     @option options [Boolean] :pathspec_file_nul (false) pathspecs in the file are NUL-separated
        #
        #     @return [Git::CommandLineResult] the result of calling `git stash push`
        #
        #     @raise [Git::FailedError] if git exits with a non-zero exit status
        #
      end
    end
  end
end
