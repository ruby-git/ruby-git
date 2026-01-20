# frozen_string_literal: true

require 'git/commands/arguments'

module Git
  module Commands
    # Implements the `git init` command
    #
    # This command creates an empty Git repository or reinitializes an existing one.
    #
    # @api private
    #
    # @example Basic usage
    #   init = Git::Commands::Init.new(execution_context)
    #   init.call
    #
    # @example Create a bare repository
    #   init = Git::Commands::Init.new(execution_context)
    #   init.call('my-repo.git', bare: true)
    #
    # @example Specify the initial branch name
    #   init = Git::Commands::Init.new(execution_context)
    #   init.call('my-repo', initial_branch: 'main')
    #
    class Init
      # Arguments DSL for building command-line arguments
      ARGS = Arguments.define do
        flag :bare
        inline_value :initial_branch
        inline_value :repository, flag: '--separate-git-dir'
        positional :directory, default: '.'
      end.freeze

      # Initialize the Init command
      #
      # @param execution_context [Git::ExecutionContext, Git::Lib] the context for executing git commands
      #
      def initialize(execution_context)
        @execution_context = execution_context
      end

      # Execute the git init command
      #
      # @overload call(directory, bare: nil, initial_branch: nil, repository: nil)
      #
      #   @param directory [String] the directory to initialize (default: '.')
      #     If :bare is false, creates the repository in +<directory>/.git+.
      #     If :bare is true, creates a bare repository in +<directory>+.
      #
      #   @param bare [Boolean] Create a bare repository
      #
      #   @param initial_branch [String] Use the specified name for the initial branch
      #
      #   @param repository [String] Path to put the .git directory (uses --separate-git-dir)
      #
      # @return [void]
      #
      # @raise [ArgumentError] if unsupported options are provided
      #
      def call(directory = '.', **)
        path = File.expand_path(directory)
        args = ARGS.build(path, **)
        @execution_context.command('init', *args)
      end
    end
  end
end
