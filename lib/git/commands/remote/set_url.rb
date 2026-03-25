# frozen_string_literal: true

require 'git/commands/base'

module Git
  module Commands
    module Remote
      # Implements the `git remote set-url` command
      #
      # Replaces a URL in the named remote's configuration.
      #
      # @see Git::Commands::Remote
      # @see https://git-scm.com/docs/git-remote git-remote
      #
      # @api private
      class SetUrl < Git::Commands::Base
        arguments do
          literal 'remote'
          literal 'set-url'
          flag_option :push

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
        #     @param name [String] The remote name to update
        #
        #     @param newurl [String] The replacement URL
        #
        #     @param oldurl [String, nil] A regex selecting which existing URL to replace
        #
        #     @param options [Hash] command options
        #
        #     @option options [Boolean] :push (nil) Update push URLs instead of fetch URLs
        #
        #     @return [Git::CommandLineResult] the result of calling `git remote set-url`
        #
        #     @raise [ArgumentError] if name or newurl is not provided
        #
        #     @raise [Git::FailedError] if git exits with a non-zero exit status
      end
    end
  end
end
