# frozen_string_literal: true

require 'git/commands/arguments'
require 'git/commands/stash/list'

module Git
  module Commands
    module Stash
      # Stash changes in the working directory
      #
      # Saves local modifications to a new stash entry and rolls them back
      # to HEAD (in the working tree and index). The command takes
      # various options to customize what gets stashed.
      #
      # @see https://git-scm.com/docs/git-stash git-stash documentation
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
      class Push
        # Arguments DSL for building command-line arguments
        ARGS = Arguments.define do
          static 'stash'
          static 'push'
          flag %i[patch p], args: '--patch'
          flag %i[staged S], args: '--staged'
          negatable_flag %i[keep_index k], args: '--keep-index'
          flag %i[include_untracked u], args: '--include-untracked'
          flag %i[all a], args: '--all'
          inline_value %i[message m], args: '--message'
          inline_value :pathspec_from_file, args: '--pathspec-from-file'
          flag :pathspec_file_nul, args: '--pathspec-file-nul'
          positional :pathspecs, variadic: true, separator: '--'
        end.freeze

        # Creates a new Push command instance
        #
        # @param execution_context [Git::ExecutionContext] the execution context for running commands
        #
        def initialize(execution_context)
          @execution_context = execution_context
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
        #     Alias: :m
        #
        #   @option options [Boolean] :patch (nil) interactively select hunks to stash.
        #     Alias: :p
        #
        #   @option options [Boolean] :staged (nil) stash only staged changes.
        #     Alias: :S
        #
        #   @option options [Boolean, nil] :keep_index (nil) keep staged changes in index;
        #     true adds --keep-index, false adds --no-keep-index, nil omits the flag.
        #     Alias: :k
        #
        #   @option options [Boolean] :include_untracked (nil) include untracked files.
        #     Alias: :u
        #
        #   @option options [Boolean] :all (nil) include untracked and ignored files.
        #     Alias: :a
        #
        #   @option options [String] :pathspec_from_file (nil) read pathspecs from file
        #
        #   @option options [Boolean] :pathspec_file_nul (nil) pathspecs are NUL separated
        #
        # @return [Git::StashInfo, nil] the newly created stash info, or nil if nothing was stashed
        #
        def call(*, **)
          output = @execution_context.command(*ARGS.build(*, **))

          # No stash created if there were no local changes
          return nil if output&.include?('No local changes to save')

          # New stash is always at index 0
          stash_list.first
        end

        private

        # @return [Array<Git::StashInfo>] list of all stashes
        def stash_list
          Git::Commands::Stash::List.new(@execution_context).call
        end
      end
    end
  end
end
