# frozen_string_literal: true

require 'git/commands/base'

module Git
  module Commands
    module Remote
      # `git remote set-url` command
      #
      # Replaces a URL in the named remote's configuration. Sets the first URL
      # for the remote matching regex <oldurl> (or the first URL if no <oldurl>
      # is given) to <newurl>.
      #
      # @example Replace the fetch URL for a remote
      #   set_url = Git::Commands::Remote::SetUrl.new(execution_context)
      #   set_url.call('origin', 'https://example.com/repo.git')
      #
      # @example Replace the push URL for a remote
      #   set_url = Git::Commands::Remote::SetUrl.new(execution_context)
      #   set_url.call('origin', 'https://example.com/repo.git', push: true)
      #
      # @example Replace a URL matching a regex
      #   set_url = Git::Commands::Remote::SetUrl.new(execution_context)
      #   set_url.call('origin', 'https://new.example.com/repo.git', 'old.example.com')
      #
      # @note `arguments` block audited against https://git-scm.com/docs/git-remote/2.53.0
      #
      # @see Git::Commands::Remote
      #
      # @see https://git-scm.com/docs/git-remote git-remote
      #
      # @api private
      #
      class SetUrl < Git::Commands::Base
        arguments do
          literal 'remote'
          literal 'set-url'
          flag_option :push # --push

          end_of_options

          operand :name, required: true
          operand :newurl, required: true
          operand :oldurl
        end

        # @!method call(*, **)
        #
        #   @overload call(name, newurl, oldurl = nil, **options)
        #
        #     Execute the `git remote set-url` command
        #
        #     @param name [String] the remote name to update
        #
        #     @param newurl [String] the replacement URL
        #
        #     @param oldurl [String, nil] a regex matching the existing URL to replace
        #
        #     @param options [Hash] command options
        #
        #     @option options [Boolean] :push (nil) update push URLs instead of fetch URLs
        #
        #     @return [Git::CommandLineResult] the result of calling `git remote set-url`
        #
        #     @raise [ArgumentError] if unsupported options are provided
        #
        #     @raise [Git::FailedError] if git exits with a non-zero exit status
      end
    end
  end
end
