# frozen_string_literal: true

require 'git/commands/base'

module Git
  module Commands
    module Remote
      # `git remote set-url --add` command
      #
      # Appends a new URL to the named remote's fetch or push URL list.
      #
      # @example Add an additional fetch URL to an existing remote
      #   set_url_add = Git::Commands::Remote::SetUrlAdd.new(execution_context)
      #   set_url_add.call('origin', 'https://mirror.example.com/repo.git')
      #
      # @example Add a push URL to an existing remote
      #   set_url_add = Git::Commands::Remote::SetUrlAdd.new(execution_context)
      #   set_url_add.call('origin', 'https://push.example.com/repo.git', push: true)
      #
      # @note `arguments` block audited against https://git-scm.com/docs/git-remote/2.53.0
      #
      # @see Git::Commands::Remote
      #
      # @see https://git-scm.com/docs/git-remote git-remote
      #
      # @api private
      #
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
        #     @param name [String] the remote name to update
        #
        #     @param newurl [String] the URL to append
        #
        #     @param options [Hash] command options
        #
        #     @option options [Boolean] :push (nil) add a push URL instead of a fetch URL
        #
        #     @return [Git::CommandLineResult] the result of calling `git remote set-url --add`
        #
        #     @raise [Git::FailedError] if git exits with a non-zero exit status
      end
    end
  end
end
