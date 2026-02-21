# frozen_string_literal: true

require 'git/commands/base'

module Git
  module Commands
    # Implements the `git init` command
    #
    # This command creates an empty Git repository or reinitializes an existing one.
    #
    # @see https://git-scm.com/docs/git-init git-init
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
    class Init < Base
      arguments do
        literal 'init'
        flag_option :bare
        value_option :separate_git_dir, inline: true
        value_option %i[initial_branch b], inline: true
        operand :directory
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
      #   @option options [String] :initial_branch (nil) Use the specified name for the initial branch.
      #     Alias: :b
      #
      #   @option options [String] :separate_git_dir (nil) Path to put the .git directory (`--separate-git-dir`)
      #
      # @return [Git::CommandLineResult] the result of calling `git init`
      #
      # @raise [ArgumentError] if unsupported options are provided
      #
      # @raise [Git::FailedError] if the command returns a non-zero exit status
      #
      def call(...) = super # rubocop:disable Lint/UselessMethodDefinition
    end
  end
end
