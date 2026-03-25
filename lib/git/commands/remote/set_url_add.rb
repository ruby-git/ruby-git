# frozen_string_literal: true

require 'git/commands/base'

module Git
  module Commands
    module Remote
      # Implements the `git remote set-url --add` command
      #
      # Adds a new URL to the named remote's fetch or push URL list.
      #
      # @see Git::Commands::Remote
      # @see https://git-scm.com/docs/git-remote git-remote
      #
      # @api private
      class SetUrlAdd < Git::Commands::Base
        arguments do
          literal 'remote'
          literal 'set-url'
          literal '--add'
          flag_option :push

          end_of_options

          operand :name, required: true
          operand :newurl, required: true
        end

        # @!method call(*, **)
        #
        #   @overload call(name, newurl, **options)
        #
        #     Execute the `git remote set-url --add` command
        #
        #     @param name [String] The remote name to update
        #
        #     @param newurl [String] The URL to append
        #
        #     @param options [Hash] command options
        #
        #     @option options [Boolean] :push (nil) Add a push URL instead of a fetch URL
        #
        #     @return [Git::CommandLineResult] the result of calling `git remote set-url --add`
        #
        #     @raise [ArgumentError] if name or newurl is not provided
        #
        #     @raise [Git::FailedError] if git exits with a non-zero exit status
      end
    end
  end
end
