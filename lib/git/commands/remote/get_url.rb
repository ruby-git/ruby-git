# frozen_string_literal: true

require 'git/commands/base'

module Git
  module Commands
    module Remote
      # `git remote get-url` command
      #
      # Retrieves the fetch or push URL configured for the named remote.
      #
      # @example Retrieve the fetch URL for a remote
      #   get_url = Git::Commands::Remote::GetUrl.new(execution_context)
      #   get_url.call('origin')
      #
      # @example Retrieve the push URL for a remote
      #   get_url = Git::Commands::Remote::GetUrl.new(execution_context)
      #   get_url.call('origin', push: true)
      #
      # @example Retrieve all configured URLs for a remote
      #   get_url = Git::Commands::Remote::GetUrl.new(execution_context)
      #   get_url.call('origin', all: true)
      #
      # @note `arguments` block audited against https://git-scm.com/docs/git-remote/2.53.0
      #
      # @see Git::Commands::Remote
      #
      # @see https://git-scm.com/docs/git-remote git-remote
      #
      # @api private
      #
      class GetUrl < Git::Commands::Base
        arguments do
          literal 'remote'
          literal 'get-url'
          flag_option :push  # --push
          flag_option :all   # --all

          end_of_options

          operand :name, required: true
        end

        # @!method call(*, **)
        #
        #   @overload call(name, **options)
        #
        #     Execute the `git remote get-url` command
        #
        #     @param name [String] the remote name to query
        #
        #     @param options [Hash] command options
        #
        #     @option options [Boolean] :push (nil) query push URLs instead of fetch URLs
        #
        #     @option options [Boolean] :all (nil) return all configured URLs instead of only the first one
        #
        #     @return [Git::CommandLineResult] the result of calling `git remote get-url`
        #
        #     @raise [ArgumentError] if unsupported options are provided
        #
        #     @raise [Git::FailedError] if git exits with a non-zero exit status
      end
    end
  end
end
