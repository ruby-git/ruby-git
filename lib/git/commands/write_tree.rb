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
    # @see https://git-scm.com/docs/git-write-tree git-write-tree documentation
    #
    # @see Git::Commands
    #
    # @api private
    #
    class WriteTree < Git::Commands::Base
      arguments do
        literal 'write-tree'

        # Disable check that all referenced objects exist in the object database
        flag_option :missing_ok

        # Write a tree for a subdirectory instead of the full index
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
      #     @option options [Boolean] :missing_ok (nil) disable the check that
      #       all objects referenced by the directory exist in the object
      #       database
      #
      #       Maps to `--missing-ok`.
      #
      #     @option options [String] :prefix (nil) write a tree object that
      #       represents a subdirectory
      #
      #       The prefix path should end with `/` (e.g. `'lib/'`). Maps to
      #       `--prefix=<prefix>/`.
      #
      #     @return [Git::CommandLineResult] the result of calling
      #       `git write-tree`
      #
      #     @raise [ArgumentError] if unsupported options are provided
      #
      #     @raise [Git::FailedError] if the command returns a non-zero exit
      #       status
    end
  end
end
