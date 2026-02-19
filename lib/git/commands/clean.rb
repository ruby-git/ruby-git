# frozen_string_literal: true

require 'git/commands/base'

module Git
  module Commands
    # Remove untracked files from the working tree
    #
    # This command removes files from the working directory that are not tracked by Git.
    # It respects standard ignore rules unless explicitly overridden.
    #
    # @see https://git-scm.com/docs/git-clean git-clean
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
    class Clean < Base
      arguments do
        literal 'clean'
        flag_option :force
        flag_option :force_force, as: '-ff'
        flag_option :d, as: '-d'
        flag_option :x, as: '-x'
        conflicts :force, :force_force
      end

      # Execute the git clean command
      #
      # @overload call(**options)
      #
      #   @param options [Hash] command options
      #
      #   @option options [Boolean] :force (nil) Force the clean operation when clean.requireForce is
      #     not set to false. If the Git configuration variable `clean.requireForce` is not set to `false`,
      #     git clean will refuse to delete files or directories unless given `-f`.
      #
      #   @option options [Boolean] :force_force (nil) Remove untracked nested git repositories
      #     (directories with a .git subdirectory)
      #
      #   @option options [Boolean] :d (nil) recurse into untracked directories
      #
      #   @option options [Boolean] :x (nil) Don't use the standard ignore rules
      #
      # @return [Git::CommandLineResult] the result of calling `git clean`
      #
      # @raise [Git::FailedError] if the command returns a non-zero exit status
      #
      def call(...) = super # rubocop:disable Lint/UselessMethodDefinition
    end
  end
end
