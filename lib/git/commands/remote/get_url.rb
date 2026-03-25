# frozen_string_literal: true

require 'git/commands/base'

module Git
  module Commands
    module Remote
      # Implements the `git remote get-url` command
      #
      # Retrieves the fetch or push URL configured for the named remote.
      #
      # @see Git::Commands::Remote
      # @see https://git-scm.com/docs/git-remote git-remote
      #
      # @api private
      class GetUrl < Git::Commands::Base
        arguments do
          literal 'remote'
          literal 'get-url'
          flag_option :push
          flag_option :all

          end_of_options

          operand :name, required: true
        end

        # @!method call(*, **)
        #
        #   @overload call(name, **options)
        #
        #     Execute the `git remote get-url` command
        #
        #     @param name [String] The remote name to query
        #
        #     @param options [Hash] command options
        #
        #     @option options [Boolean] :push (nil) Query push URLs instead of fetch URLs
        #
        #     @option options [Boolean] :all (nil) Return all configured URLs instead of the first one
        #
        #     @return [Git::CommandLineResult] the result of calling `git remote get-url`
        #
        #     @raise [ArgumentError] if name is not provided
        #
        #     @raise [Git::FailedError] if git exits with a non-zero exit status
      end
    end
  end
end
