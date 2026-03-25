# frozen_string_literal: true

require 'git/commands/base'

module Git
  module Commands
    module Remote
      # Implements the `git remote set-url --delete` command
      #
      # Removes URLs matching a regex from the named remote's configuration.
      #
      # @see Git::Commands::Remote
      # @see https://git-scm.com/docs/git-remote git-remote
      #
      # @api private
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
        #   Execute the git remote set-url --delete command
        #
        #   @overload call(name, url, **options)
        #
        #     @param name [String] The remote name to update
        #
        #     @param url [String] A regex selecting the URL or URLs to delete
        #
        #     @param options [Hash] command options
        #
        #     @option options [Boolean] :push (nil) Delete push URLs instead of fetch URLs
        #
        #     @return [Git::CommandLineResult] the result of calling `git remote set-url --delete`
        #
        #     @raise [ArgumentError] if name or url is not provided
        #
        #     @raise [Git::FailedError] if git exits with a non-zero exit status
      end
    end
  end
end
