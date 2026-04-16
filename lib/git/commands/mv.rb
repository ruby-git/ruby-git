# frozen_string_literal: true

require 'git/commands/base'

module Git
  module Commands
    # Implements `git mv` to move or rename a file, a directory, or a symlink
    #
    # The index is updated after successful completion, but the change must still
    # be committed.
    #
    # @example Move a single file
    #   mv = Git::Commands::Mv.new(execution_context)
    #   mv.call('old_name.rb', 'new_name.rb')
    #
    # @example Move multiple files to a directory
    #   mv = Git::Commands::Mv.new(execution_context)
    #   mv.call('file1.rb', 'file2.rb', 'destination_dir/')
    #
    # @example Force overwrite if destination exists
    #   mv = Git::Commands::Mv.new(execution_context)
    #   mv.call('source.rb', 'dest.rb', force: true)
    #
    # @note `arguments` block audited against https://git-scm.com/docs/git-mv/2.53.0
    #
    # @see https://git-scm.com/docs/git-mv git-mv
    #
    # @see Git::Commands
    #
    # @api private
    #
    class Mv < Git::Commands::Base
      arguments do
        literal 'mv'
        flag_option %i[verbose v]
        flag_option %i[force f]
        flag_option %i[dry_run n]
        flag_option :k
        end_of_options
        operand :source, repeatable: true, required: true
        operand :destination, required: true
      end

      # @!method call(*, **)
      #
      #   @overload call(*source, destination, **options)
      #
      #     Execute the git mv command
      #
      #     @param source [Array<String>] one or more source file(s) or directories to move
      #
      #     @param destination [String] the destination file or directory
      #
      #     @param options [Hash] command options
      #
      #     @option options [Boolean] :verbose (false) Report the names of files as they are moved
      #
      #       Alias: `:v`
      #
      #     @option options [Boolean] :force (false) Force renaming or moving even if the destination exists
      #
      #       Alias: `:f`
      #
      #     @option options [Boolean] :dry_run (false) Do nothing; only show what would happen
      #
      #       Alias: `:n`
      #
      #     @option options [Boolean] :k (false) Skip move or rename actions which would lead to an error
      #
      #     @return [Git::CommandLineResult] the result of calling `git mv`
      #
      #     @raise [ArgumentError] if unsupported options are provided
      #
      #     @raise [Git::FailedError] if git exits with a non-zero exit status
    end
  end
end
