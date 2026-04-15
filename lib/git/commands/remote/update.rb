# frozen_string_literal: true

require 'git/commands/base'

module Git
  module Commands
    module Remote
      # `git remote update` command
      #
      # Fetches updates for remotes or remote groups in the repository. When neither
      # a remote nor a group is specified, updates all remotes that are not marked
      # with `remote.<name>.skipDefaultUpdate`.
      #
      # @example Fetch updates for all configured remotes
      #   update = Git::Commands::Remote::Update.new(execution_context)
      #   update.call
      #
      # @example Fetch updates for a specific remote
      #   update = Git::Commands::Remote::Update.new(execution_context)
      #   update.call('origin')
      #
      # @example Fetch updates and prune stale tracking refs
      #   update = Git::Commands::Remote::Update.new(execution_context)
      #   update.call('origin', prune: true)
      #
      # @note `arguments` block audited against https://git-scm.com/docs/git-remote/2.53.0
      #
      # @see Git::Commands::Remote
      #
      # @see https://git-scm.com/docs/git-remote git-remote
      #
      # @api private
      #
      class Update < Git::Commands::Base
        arguments do
          literal 'remote'
          flag_option %i[verbose v]
          literal 'update'
          flag_option %i[prune p]

          end_of_options

          operand :remote_or_group, repeatable: true
        end

        # @!method call(*, **)
        #
        #   @overload call(*remote_or_group, **options)
        #
        #     Execute the `git remote update` command
        #
        #     @param remote_or_group [Array<String>] zero or more remote names or remote group names
        #
        #     @param options [Hash] command options
        #
        #     @option options [Boolean] :verbose (nil) show remote URLs alongside remote names
        #
        #       Alias: :v
        #
        #     @option options [Boolean] :prune (nil) prune stale tracking refs while updating remotes
        #
        #       Alias: :p
        #
        #     @return [Git::CommandLineResult] the result of calling `git remote update`
        #
        #     @raise [ArgumentError] if unsupported options are provided
        #
        #     @raise [Git::FailedError] if git exits with a non-zero exit status
      end
    end
  end
end
