# frozen_string_literal: true

require 'git/commands/base'
require 'git/commands/archive'

module Git
  module Commands
    class Archive
      # Format lister for `git archive --list`
      #
      # Lists all available archive formats supported by the current git
      # installation. This is a standalone mode of `git archive` that does not
      # require a tree-ish operand.
      #
      # @example List available archive formats
      #   cmd = Git::Commands::Archive::ListFormats.new(execution_context)
      #   result = cmd.call
      #   result.stdout  # => "tar\ntgz\ntar.gz\nzip\n"
      #
      # @see Git::Commands::Archive
      #
      # @see https://git-scm.com/docs/git-archive git-archive documentation
      #
      # @api private
      #
      class ListFormats < Git::Commands::Base
        arguments do
          literal 'archive'
          literal '--list'
        end

        # @!method call(*, **)
        #
        #   @overload call
        #
        #     Execute `git archive --list` to show available formats
        #
        #     @return [Git::CommandLineResult] the result of calling
        #       `git archive --list`
        #
        #     @raise [Git::FailedError] if the command returns a non-zero
        #       exit status
      end
    end
  end
end
