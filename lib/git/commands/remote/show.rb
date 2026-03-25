# frozen_string_literal: true

require 'git/commands/base'

module Git
  module Commands
    module Remote
      # Implements the `git remote show` command
      #
      # Shows information about one or more remotes, including fetch and push URLs and branch tracking.
      #
      # @see Git::Commands::Remote
      # @see https://git-scm.com/docs/git-remote git-remote
      #
      # @api private
      class Show < Git::Commands::Base
        arguments do
          literal 'remote'
          flag_option %i[verbose v]
          literal 'show'
          flag_option :n

          end_of_options

          operand :name, repeatable: true, required: true
        end

        # @!method call(*, **)
        #
        #   @overload call(*name, **options)
        #
        #     Execute the `git remote show` command
        #
        #     @param name [Array<String>] One or more remote names to inspect
        #
        #     @param options [Hash] command options
        #
        #     @option options [Boolean] :verbose (nil) Show the remote name and
        #       URL as a header before the detailed output
        #
        #       Alias: :v
        #
        #     @option options [Boolean] :n (nil) Do not query remote heads with `git ls-remote`
        #
        #       Uses cached information instead of contacting the remote server.
        #
        #     @return [Git::CommandLineResult] the result of calling `git remote show`
        #
        #     @raise [ArgumentError] if no remote names are provided
        #
        #     @raise [Git::FailedError] if git exits with a non-zero exit status
      end
    end
  end
end
