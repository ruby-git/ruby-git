# frozen_string_literal: true

require 'git/commands/base'

module Git
  module Commands
    module CatFile
      # Runs `git cat-file -p` to pretty-print the content of a single git object
      #
      # Auto-detects the object type and formats the output for human readability.
      # Output format varies by type:
      #
      # - **commit** — commit text (`tree`, `parent`, `author`, `committer`, message)
      # - **tree** — one `<mode> <type> <sha>\t<name>` line per entry (human-readable;
      #   contrast with the raw binary that `Typed` returns for trees)
      # - **blob** — raw file content bytes
      # - **tag** — tag text (`object`, `type`, `tag`, `tagger`, message)
      #
      # @see Git::Commands::CatFile Git::Commands::CatFile
      #
      # @see https://git-scm.com/docs/git-cat-file git-cat-file documentation
      #
      # @api private
      #
      # @example Pretty-print a blob via treeish path reference
      #   cmd = Git::Commands::CatFile::Pretty.new(execution_context)
      #   result = cmd.call('HEAD:README.md')
      #
      # @example Pretty-print a tree (human-readable entry listing)
      #   cmd = Git::Commands::CatFile::Pretty.new(execution_context)
      #   result = cmd.call('HEAD^{tree}')
      #   result.stdout
      #   # => "100644 blob abc1234...\t.gitignore\n040000 tree def5678...\tsrc\n"
      #
      # @example Pretty-print a commit
      #   cmd = Git::Commands::CatFile::Pretty.new(execution_context)
      #   result = cmd.call('HEAD')
      #
      class Pretty < Base
        arguments do
          literal 'cat-file'
          literal '-p'
          operand :object, required: true
        end

        # @!method call(*, **)
        #
        #   Execute `git cat-file -p` for one object.
        #
        #   @overload call(object)
        #     Pretty-print the content of a single git object.
        #
        #     @param object [String] object name (SHA, ref, `HEAD`, treeish path, etc.)
        #
        #     @return [Git::CommandLineResult] the result of calling `git cat-file -p`
        #
        #     @raise [Git::FailedError] if the object does not exist or the ref cannot be resolved
      end
    end
  end
end
