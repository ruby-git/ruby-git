# frozen_string_literal: true

require 'git/commands/arguments'

module Git
  module Commands
    # Implements the `git mv` command
    #
    # This command moves or renames a file, directory, or symlink. The index is
    # updated after successful completion, but the change must still be committed.
    #
    # @api private
    #
    # @example Move a single file
    #   mv = Git::Commands::Mv.new(execution_context)
    #   mv.call('old_name.rb', 'new_name.rb')
    #
    # @example Move multiple files to a directory
    #   mv.call('file1.rb', 'file2.rb', 'destination_dir/')
    #
    # @example Force overwrite if destination exists
    #   mv.call('source.rb', 'dest.rb', force: true)
    #
    class Mv
      # Arguments DSL for building command-line arguments
      ARGS = Arguments.define do
        flag :force, flag: '--force'
        flag :dry_run, flag: '--dry-run'
        flag :verbose, flag: '--verbose'
        flag :skip_errors, flag: '-k'
        positional :source, variadic: true, separator: '--'
        positional :destination
      end.freeze

      # Initialize the Mv command
      #
      # @param execution_context [Git::ExecutionContext, Git::Lib] the context for executing git commands
      #
      def initialize(execution_context)
        @execution_context = execution_context
      end

      # Execute the git mv command
      #
      # @overload call(source, destination, options = {})
      #
      #   @param source [Array<String>] one or more source file(s) or directories to move
      #
      #   @param destination [String] the destination file or directory
      #
      #   @param options [Hash] command options
      #
      #   @option options [Boolean] :force Force renaming or moving even if the destination exists
      #
      #   @option options [Boolean] :dry_run Do nothing; only show what would happen
      #
      #   @option options [Boolean] :verbose Report the names of files as they are moved
      #
      #   @option options [Boolean] :skip_errors Skip move or rename actions which would lead to an error
      #
      # @return [String] the command output
      #
      def call(*source, destination, **)
        args = ARGS.build(*source, destination, **)
        @execution_context.command('mv', *args)
      end
    end
  end
end
