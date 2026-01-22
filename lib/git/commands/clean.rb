# frozen_string_literal: true

require 'git/commands/arguments'

module Git
  module Commands
    # Remove untracked files from the working tree
    #
    # @api private
    #
    # @example Clean untracked files
    #   clean = Git::Commands::Clean.new(execution_context)
    #   clean.call
    #
    # @example Force cleaning of untracked files
    #   clean.call(force: true)
    #
    # @example Force cleaning of untracked nested git repositories
    #   clean.call(force_force: true)
    #
    # @example Recurse into untracked directories
    #   clean.call(d: true)
    #
    # @example Don’t use the standard ignore rules
    #   clean.call(x: true)
    #
    class Clean
      # Arguments DSL for building command-line arguments
      ARGS = Arguments.define do
        flag :force
        flag :force_force, args: '-ff'
        flag :d, args: '-d'
        flag :x, args: '-x'
        conflicts :force, :force_force
      end.freeze

      # Initialize the Clean command
      #
      # @param execution_context [Git::ExecutionContext, Git::Lib] the context for executing git commands
      #
      def initialize(execution_context)
        @execution_context = execution_context
      end

      # Execute the git clean command
      #
      # @overload call(force: nil, force_force: nil, d: nil, x: nil)
      #
      #   @param force [Boolean] Force the clean operation when clean.requireForce is
      #   not set to false
      #
      #     If the Git configuration variable `clean.requireForce` is not set to `false`,
      #     git clean will refuse to delete files or directories unless given `-f`.
      #
      #   @param force_force [Boolean] Remove untracked nested git repositories
      #     (directories with a .git subdirectory)
      #
      #   @param d [Boolean] recurse into untracked directories
      #
      #   @param x [Boolean] Don’t use the standard ignore rules
      #
      # @return [String] the command output (typically empty on success)
      #
      def call(*, **)
        args = ARGS.build(*, **)
        @execution_context.command('clean', *args)
      end
    end
  end
end
