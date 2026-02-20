# frozen_string_literal: true

module Git
  module Commands
    # Commands for reading git object store content via `git cat-file`
    #
    # This module contains command classes for querying repository objects.
    # Both classes use the `--batch` protocol, accepting object names via stdin
    # and returning one result line (and optionally content) per object.
    #
    # - {CatFile::ObjectMeta} - Object metadata only (sha, type, size)
    # - {CatFile::ObjectContent} - Object metadata plus raw content
    #
    # @api private
    #
    # @see https://git-scm.com/docs/git-cat-file git-cat-file documentation
    #
    # @example Query type and size for several objects
    #   info = Git::Commands::CatFile::ObjectMeta.new(lib)
    #   result = info.call('HEAD', 'v1.0', 'abc123')
    #   result.stdout
    #   # => "abc1234... commit 250\nabc5678... commit 198\n...\n"
    #
    # @example Fetch full content of a single commit
    #   content = Git::Commands::CatFile::ObjectContent.new(lib)
    #   result = content.call('HEAD')
    #   result.stdout
    #   # => "abc1234... commit 250\ntree ...\nauthor ...\n\nCommit message\n\n"
    #
    module CatFile
    end
  end
end
