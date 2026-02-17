# frozen_string_literal: true

require 'git/commands/base'

module Git
  module Commands
    # Implements the `git add` command
    #
    # This command updates the index using the current content found in the working tree,
    # to prepare the content staged for the next commit.
    #
    # @api private
    #
    # @example Basic usage
    #   add = Git::Commands::Add.new(execution_context)
    #   add.call('path/to/file')
    #   add.call('file1.rb', 'file2.rb')
    #   add.call(all: true)
    #
    class Add < Base
      arguments do
        literal 'add'
        flag_option :all
        flag_option :force
        operand :paths, repeatable: true, default: [], separator: '--'
      end

      # Execute the git add command
      #
      # @overload call(*paths, **options)
      #
      #   @param paths [Array<String>] files to be added to the repository
      #     (relative to the worktree root)
      #
      #   @param options [Hash] command options
      #
      #   @option options [Boolean] :all (nil) Add, modify, and remove index entries to match the worktree
      #
      #   @option options [Boolean] :force (nil) Allow adding otherwise ignored files
      #
      # @return [Git::CommandLineResult] the result of the command
      #
      def call(...) = super # rubocop:disable Lint/UselessMethodDefinition
    end
  end
end
