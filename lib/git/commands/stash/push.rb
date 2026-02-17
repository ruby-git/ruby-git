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
      class Push < Base
        arguments do
          literal 'stash'
          literal 'push'
          flag_option %i[patch p]
          flag_option %i[staged S]
          flag_option %i[keep_index k], negatable: true
          flag_option %i[include_untracked u]
          flag_option %i[all a]
          value_option %i[message m], inline: true
          value_option :pathspec_from_file, inline: true
          flag_option :pathspec_file_nul
          operand :pathspecs, repeatable: true, separator: '--'
        end

        # Stash changes in the working directory
        #
        # @overload call(*pathspecs, **options)
        #
        #   @param pathspecs [Array<String>] optional paths to limit what gets stashed
        #
        #   @param options [Hash] command options
        #
        #   @option options [String] :message (nil) descriptive message for the stash.
        #
        #     Alias: :m
        #
        #   @option options [Boolean] :patch (nil) interactively select hunks to stash.
        #
        #     Alias: :p
        #
        #   @option options [Boolean] :staged (nil) stash only staged changes.
        #
        #     Alias: :S
        #
        #   @option options [Boolean, nil] :keep_index (nil) keep staged changes in index.
        #
        #     Alias: :k
        #
        #   @option options [Boolean] :include_untracked (nil) include untracked files.
        #
        #     Alias: :u
        #
        #   @option options [Boolean] :all (nil) include untracked and ignored files.
        #
        #     Alias: :a
        #
        #   @option options [String] :pathspec_from_file (nil) read pathspecs from file
        #
        #   @option options [Boolean] :pathspec_file_nul (nil) pathspecs are NUL separated
        #
        # @return [Git::CommandLineResult] the result of calling `git stash push`
        #
        def call(...) = super # rubocop:disable Lint/UselessMethodDefinition
      end
    end
  end
end
