# frozen_string_literal: true

require 'git/commands/base'

module Git
  module Commands
    module Remote
      # `git remote set-url --delete` command
      #
      # Removes all URLs matching a regex from the named remote's configured URL list.
      # By default operates on fetch URLs; pass `push: true` to target push URLs instead.
      #
      # @example Delete a fetch URL matching a pattern
      #   set_url_delete = Git::Commands::Remote::SetUrlDelete.new(execution_context)
      #   set_url_delete.call('origin', 'github')
      #
      # @example Delete a push URL matching a pattern
      #   set_url_delete = Git::Commands::Remote::SetUrlDelete.new(execution_context)
      #   set_url_delete.call('origin', 'github', push: true)
      #
      # @note `arguments` block audited against https://git-scm.com/docs/git-remote/2.53.0
      #
      # @see Git::Commands::Remote
      #
      # @see https://git-scm.com/docs/git-remote git-remote
      #
      # @api private
      #
      class SetUrlDelete < Git::Commands::Base
        arguments do
          literal 'remote'
          literal 'set-url'
          literal '--delete'
          flag_option :push

          end_of_options

          operand :name, required: true
          operand :url, required: true
        end

        # @!method call(*, **)
        #
        #   @overload call(name, url, **options)
        #
        #     Execute the `git remote set-url --delete` command
        #
        #     @param name [String] the remote name to update
        #
        #     @param url [String] a regex selecting the URL or URLs to delete
        #
        #     @param options [Hash] command options
        #
        #     @option options [Boolean] :push (nil) delete push URLs instead of fetch URLs
        #
        #     @return [Git::CommandLineResult] the result of calling `git remote set-url --delete`
        #
        #     @raise [ArgumentError] if unsupported options are provided
        #
        #     @raise [Git::FailedError] if git exits with a non-zero exit status
      end
    end
  end
end
