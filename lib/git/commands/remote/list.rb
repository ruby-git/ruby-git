# frozen_string_literal: true

require 'git/commands/base'

module Git
  module Commands
    module Remote
      # `git remote` command (list remotes)
      #
      # Lists all configured remote connections.
      #
      # @example List all remotes
      #   list = Git::Commands::Remote::List.new(execution_context)
      #   list.call
      #
      # @example List remotes with URLs
      #   list = Git::Commands::Remote::List.new(execution_context)
      #   list.call(verbose: true)
      #
      # @note `arguments` block audited against https://git-scm.com/docs/git-remote/2.53.0
      #
      # @see Git::Commands::Remote
      #
      # @see https://git-scm.com/docs/git-remote git-remote
      #
      # @api private
      #
      class List < Git::Commands::Base
        arguments do
          literal 'remote'
          flag_option %i[verbose v]
        end

        # @!method call(*, **)
        #
        #   @overload call(**options)
        #
        #     Execute the `git remote` command
        #
        #     @param options [Hash] command options
        #
        #     @option options [Boolean] :verbose (nil) show remote URLs alongside remote names
        #
        #       Alias: :v
        #
        #     @return [Git::CommandLineResult] the result of calling `git remote`
        #
        #     @raise [ArgumentError] if unsupported options are provided
        #
        #     @raise [Git::FailedError] if git exits with a non-zero exit status
      end
    end
  end
end
