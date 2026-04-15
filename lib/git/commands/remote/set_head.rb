# frozen_string_literal: true

require 'git/commands/base'

module Git
  module Commands
    module Remote
      # `git remote set-head` command
      #
      # Sets or deletes the default branch (symbolic HEAD) for the named remote.
      #
      # @example Set the remote HEAD to a specific branch
      #   set_head = Git::Commands::Remote::SetHead.new(execution_context)
      #   set_head.call('origin', 'main')
      #
      # @example Auto-detect the remote HEAD by querying the remote
      #   set_head = Git::Commands::Remote::SetHead.new(execution_context)
      #   set_head.call('origin', auto: true)
      #
      # @example Delete the remote HEAD symbolic ref
      #   set_head = Git::Commands::Remote::SetHead.new(execution_context)
      #   set_head.call('origin', delete: true)
      #
      # @note `arguments` block audited against https://git-scm.com/docs/git-remote/2.53.0
      #
      # @see Git::Commands::Remote
      #
      # @see https://git-scm.com/docs/git-remote git-remote
      #
      # @api private
      #
      class SetHead < Git::Commands::Base
        arguments do
          literal 'remote'
          literal 'set-head'
          operand :name, required: true
          flag_option %i[auto a]
          flag_option %i[delete d]
          operand :branch
        end

        # @!method call(*, **)
        #
        #   @overload call(name, branch)
        #
        #     Set the remote's HEAD symbolic ref to a specific branch
        #
        #     @param name [String] the remote name to update
        #
        #     @param branch [String] the branch to set as the remote HEAD
        #
        #     @return [Git::CommandLineResult] the result of calling `git remote set-head`
        #
        #     @raise [ArgumentError] if unsupported options are provided
        #
        #     @raise [Git::FailedError] if git exits with a non-zero exit status
        #
        #   @overload call(name, **options)
        #
        #     Detect or delete the remote's HEAD symbolic ref
        #
        #     @param name [String] the remote name to update
        #
        #     @param options [Hash] command options
        #
        #     @option options [Boolean] :auto (nil) detect the remote HEAD by querying the remote
        #
        #       Mutually exclusive with `:delete`. Alias: :a
        #
        #     @option options [Boolean] :delete (nil) delete the configured remote HEAD symbolic ref
        #
        #       Mutually exclusive with `:auto`. Alias: :d
        #
        #     @return [Git::CommandLineResult] the result of calling `git remote set-head`
        #
        #     @raise [ArgumentError] if unsupported options are provided
        #
        #     @raise [Git::FailedError] if git exits with a non-zero exit status
      end
    end
  end
end
