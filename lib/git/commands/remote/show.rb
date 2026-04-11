# frozen_string_literal: true

require 'git/commands/base'

module Git
  module Commands
    module Remote
      # `git remote show` command
      #
      # Shows information about one or more remotes, including fetch and push URLs
      # and branch tracking information.
      #
      # @example Show information about a remote
      #   show = Git::Commands::Remote::Show.new(execution_context)
      #   show.call('origin')
      #
      # @example Show cached information without contacting the remote
      #   show = Git::Commands::Remote::Show.new(execution_context)
      #   show.call('origin', n: true)
      #
      # @example Show verbose output for multiple remotes
      #   show = Git::Commands::Remote::Show.new(execution_context)
      #   show.call('origin', 'upstream', verbose: true)
      #
      # @note `arguments` block audited against https://git-scm.com/docs/git-remote/2.53.0
      #
      # @see Git::Commands::Remote
      #
      # @see https://git-scm.com/docs/git-remote git-remote
      #
      # @api private
      #
      class Show < Git::Commands::Base
        arguments do
          literal 'remote'
          flag_option %i[verbose v]                   # --verbose (alias: :v)
          literal 'show'
          flag_option :n                              # -n

          end_of_options

          operand :name, repeatable: true, required: true
        end

        # @!method call(*, **)
        #
        #   @overload call(*name, **options)
        #
        #     Execute the `git remote show` command
        #
        #     @param name [Array<String>] one or more remote names to inspect
        #
        #     @param options [Hash] command options
        #
        #     @option options [Boolean] :verbose (nil) show the remote URL after the remote name
        #
        #       Alias: :v
        #
        #     @option options [Boolean] :n (nil) do not query remote heads with `git ls-remote`
        #
        #       Uses cached information instead of contacting the remote server.
        #
        #     @return [Git::CommandLineResult] the result of calling `git remote show`
        #
        #     @raise [ArgumentError] if unsupported options are provided
        #
        #     @raise [Git::FailedError] if git exits with a non-zero exit status
      end
    end
  end
end
