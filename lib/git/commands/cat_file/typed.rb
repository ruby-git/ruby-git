# frozen_string_literal: true

require 'git/commands/base'

module Git
  module Commands
    module CatFile
      # Runs `git cat-file <type> <object>` to read the raw content of a single git object
      #
      # Returns the decompressed object content as raw bytes with no header or framing.
      # The `type` argument is validated — git exits non-zero if the named object is not
      # of the expected type (or trivially dereferenceable to it, e.g. asking for `tree`
      # against a commit ref).
      #
      # @see Git::Commands::CatFile Git::Commands::CatFile
      #
      # @see https://git-scm.com/docs/git-cat-file git-cat-file documentation
      #
      # @api private
      #
      # @example Read commit object data
      #   cmd = Git::Commands::CatFile::Typed.new(execution_context)
      #   result = cmd.call('commit', 'HEAD')
      #
      # @example Read annotated tag object data
      #   cmd = Git::Commands::CatFile::Typed.new(execution_context)
      #   result = cmd.call('tag', 'v1.0.0')
      #
      # @example Read a blob via treeish path reference
      #   cmd = Git::Commands::CatFile::Typed.new(execution_context)
      #   result = cmd.call('blob', 'HEAD:README.md')
      #
      class Typed < Base
        arguments do
          literal 'cat-file'
          operand :type, required: true
          operand :object, required: true
        end

        # @!method call(*, **)
        #
        #   Execute `git cat-file <type> <object>`.
        #
        #   @overload call(type, object)
        #     Read the raw content of a single git object as the given type.
        #
        #     @param type [String] expected object type — one of `commit`, `tree`, `blob`,
        #       or `tag`. Git also accepts a type that the object is trivially dereferenceable
        #       to (e.g. `tree` against a commit ref, `blob` against a tag that points to one).
        #
        #     @param object [String] object name (SHA, ref, `HEAD`, treeish path, etc.)
        #
        #     @return [Git::CommandLineResult] the result of calling `git cat-file <type> <object>`
        #
        #     @raise [Git::FailedError] if the object does not exist, is not of the expected
        #       type (or trivially dereferenceable to it), or `type` is not a valid git object type
      end
    end
  end
end
