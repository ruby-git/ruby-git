# frozen_string_literal: true

require 'git/commands/base'

module Git
  module Commands
    # Implements the `git mv` command
    #
    # This command moves or renames a file, directory, or symlink. The index is
    # updated after successful completion, but the change must still be committed.
    #
    # @see https://git-scm.com/docs/git-mv git-mv
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
    class Mv < Base
      arguments do
        literal 'mv'
        flag_option :force, args: '--force'
        flag_option :dry_run, args: '--dry-run'
        flag_option :verbose, args: '--verbose'
        flag_option :skip_errors, args: '-k'
        operand :source, repeatable: true, required: true, separator: '--'
        operand :destination, required: true
      end

      # Execute the git mv command
      #
      # @overload call(*source, destination, **options)
      #
      #   @param source [Array<String>] one or more source file(s) or directories to move
      #
      #   @param destination [String] the destination file or directory
      #
      #   @param options [Hash] command options
      #
      #   @option options [Boolean] :force (nil) Force renaming or moving even if the destination exists
      #
      #   @option options [Boolean] :dry_run (nil) Do nothing; only show what would happen
      #
      #   @option options [Boolean] :verbose (nil) Report the names of files as they are moved
      #
      #   @option options [Boolean] :skip_errors (nil) Skip move or rename actions which would lead to an error
      #
      # @return [Git::CommandLineResult] the result of calling `git mv`
      #
      # @raise [Git::FailedError] if the command returns a non-zero exit status
      #
      def call(...) = super # rubocop:disable Lint/UselessMethodDefinition
    end
  end
end
