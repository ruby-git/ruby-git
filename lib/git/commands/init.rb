# frozen_string_literal: true

require 'git/commands/options'

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
    # @example With bare option
    #   init = Git::Commands::Init.new(execution_context)
    #   init.call(bare: true)
    #
    # @example With initial branch
    #   init = Git::Commands::Init.new(execution_context)
    #   init.call(initial_branch: 'main')
    #
    class Init
      # Options DSL for building command-line arguments
      OPTIONS = Options.define do
        flag :bare
        inline_value :initial_branch
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
      # @param options [Hash] command options
      #
      # @option options [Boolean] :bare Create a bare repository
      # @option options [String] :initial_branch Name of the initial branch
      #
      # @return [String] the command output
      #
      def call(options = {})
        args = OPTIONS.build(**options)
        @execution_context.command('init', *args)
      end
    end
  end
end
