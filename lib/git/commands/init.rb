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
        literal 'init'
        flag_option :bare
        value_option :initial_branch, inline: true
        value_option :repository, inline: true, args: '--separate-git-dir'
        operand :directory
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
      # @overload call(directory = nil, **options)
      #
      #   @param directory [String] the directory to initialize (default: '.')
      #     If :bare is false, creates the repository in +<directory>/.git+.
      #     If :bare is true, creates a bare repository in +<directory>+.
      #
      #   @param options [Hash] command options
      #
      #   @option options [Boolean] :bare (nil) Create a bare repository
      #
      #   @option options [String] :initial_branch (nil) Use the specified name for the initial branch
      #
      #   @option options [String] :repository (nil) Path to put the .git directory (uses --separate-git-dir)
      #
      # @return [Git::CommandLineResult] the result of the command
      #
      # @raise [ArgumentError] if unsupported options are provided
      #
      def call(*, **)
        @execution_context.command(*ARGS.bind(*, **))
      end
    end
  end
end
