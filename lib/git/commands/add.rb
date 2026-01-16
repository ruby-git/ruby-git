# frozen_string_literal: true

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
    #   add.call(['file1.rb', 'file2.rb'])
    #   add.call('.', all: true)
    #
    class Add
      # Option map for building command-line arguments
      #
      # @return [Array<Hash>] the option configuration
      OPTION_MAP = [
        { keys: [:all], flag: '--all', type: :boolean },
        { keys: [:force], flag: '--force', type: :boolean }
      ].freeze

      # Initialize the Add command
      #
      # @param execution_context [Git::ExecutionContext, Git::Lib] the context for executing git commands
      #
      def initialize(execution_context)
        @execution_context = execution_context
      end

      # Execute the git add command
      #
      # @param paths [String, Array<String>] files to be added to the repository
      #   (relative to the worktree root)
      # @param options [Hash] command options
      #
      # @option options [Boolean] :all Add, modify, and remove index entries to match the worktree
      # @option options [Boolean] :force Allow adding otherwise ignored files
      #
      # @return [String] the command output (typically empty on success)
      #
      def call(paths = '.', options = {})
        args = build_args(options)
        args << '--'
        args.concat(Array(paths))

        run_command('add', *args)
      end

      private

      # Build command-line arguments from options
      #
      # @param options [Hash] the options hash
      # @return [Array<String>] the command-line arguments
      #
      def build_args(options)
        Git::ArgsBuilder.new(options, OPTION_MAP).build
      end

      # Run a git command through the execution context
      #
      # Uses send to access the private command method during the transition period.
      # Once ExecutionContext is fully implemented, this can be changed to a direct call.
      #
      # @param args [Array] the command and arguments to pass to git
      # @return [String] the command output
      #
      def run_command(...)
        @execution_context.send(:command, ...)
      end
    end
  end
end
