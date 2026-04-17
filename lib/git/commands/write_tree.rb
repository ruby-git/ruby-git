# frozen_string_literal: true

require 'git/commands/base'

module Git
  module Commands
    # Implements the `git write-tree` command
    #
    # Creates a tree object using the current index and prints the SHA-1 name of
    # the new tree object to standard output. The index must be in a fully
    # merged state.
    #
    # @example Write the current index as a tree object
    #   write_tree = Git::Commands::WriteTree.new(execution_context)
    #   result = write_tree.call
    #   sha = result.stdout   # => "abc123..."
    #
    # @example Write only a subdirectory as a tree object
    #   write_tree = Git::Commands::WriteTree.new(execution_context)
    #   result = write_tree.call(prefix: 'lib/')
    #
    # @example Allow missing objects in the object database
    #   write_tree = Git::Commands::WriteTree.new(execution_context)
    #   result = write_tree.call(missing_ok: true)
    #
    # @note `arguments` block audited against https://git-scm.com/docs/git-write-tree/2.53.0
    #
    # @see https://git-scm.com/docs/git-write-tree git-write-tree
    #
    # @see Git::Commands
    #
    # @api private
    #
    class WriteTree < Git::Commands::Base
      arguments do
        literal 'write-tree'
        flag_option :missing_ok
        value_option :prefix, inline: true
      end

      # @!method call(*, **)
      #
      #   @overload call(**options)
      #
      #     Execute the `git write-tree` command
      #
      #     @param options [Hash] command options
      #
      #     @option options [Boolean] :missing_ok (false) disable the check that
      #       all objects referenced by the directory exist in the object
      #       database
      #
      #     @option options [String] :prefix (nil) write a tree object that
      #       represents a subdirectory
      #
      #       The prefix path should end with `/` (e.g., `'lib/'`).
      #
      #     @return [Git::CommandLineResult] the result of calling `git write-tree`
      #
      #     @raise [ArgumentError] if unsupported options are provided
      #
      #     @raise [Git::FailedError] if git exits with a non-zero exit status
      #
      #   @api public
      #
    end
  end
end
