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
      # @note `arguments` block audited against https://git-scm.com/docs/git-stash/2.52.0
      #
      class Push < Git::Commands::Base
        arguments do
          literal 'stash'
          literal 'push'
          flag_option %i[patch p]
          flag_option %i[staged S]
          flag_option %i[keep_index k], negatable: true
          flag_option %i[quiet q]
          flag_option %i[include_untracked u], negatable: true
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
        #     @option options [Boolean] :patch (nil) Interactively select hunks to stash
        #
        #       Alias: :p
        #
        #     @option options [Boolean] :staged (nil) Stash only staged changes
        #
        #       Alias: :S
        #
        #     @option options [Boolean] :keep_index (nil) Keep staged changes in the index
        #
        #       Alias: :k
        #
        #     @option options [Boolean] :quiet (nil) Suppress feedback messages
        #
        #       Alias: :q
        #
        #     @option options [Boolean] :include_untracked (nil) Include untracked files in the stash
        #
        #       Pass `true` to include untracked files (`--include-untracked`).
        #       Pass `false` to explicitly exclude untracked files (`--no-include-untracked`).
        #
        #       Alias: :u
        #
        #     @option options [Boolean] :all (nil) Include untracked and ignored files in the stash
        #
        #       Alias: :a
        #
        #     @option options [String] :message (nil) Descriptive message for the stash
        #
        #       Alias: :m
        #
        #     @option options [String] :pathspec_from_file (nil) Read pathspecs from the given file
        #
        #     @option options [Boolean] :pathspec_file_nul (nil) Pathspecs in the file are NUL-separated
        #
        #     @return [Git::CommandLineResult] the result of calling `git stash push`
        #
        #     @raise [Git::FailedError] if git exits with a non-zero exit status
        #
        #   @api private
        #
      end
    end
  end
end
