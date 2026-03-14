# frozen_string_literal: true

module Git
  module Commands
    # Commands for reading git object store content via `git cat-file`
    #
    # This module contains command classes split by invocation protocol:
    #
    # - {CatFile::Raw} — single object as a CLI argument; raw content, type, size, or
    #   existence check (`-e`, `-t`, `-s`, `-p`, `<type>`)
    # - {CatFile::Filtered} — single object as a CLI argument; content after
    #   `.gitattributes` filter processing (`--textconv`, `--filters`)
    # - {CatFile::Batch} — objects fed via stdin; all batch streaming modes
    #   (`--batch`, `--batch-check`, `--batch-command`)
    #
    # @api private
    #
    # @see https://git-scm.com/docs/git-cat-file git-cat-file documentation
    #
    # @example Check whether an object exists
    #   cmd = Git::Commands::CatFile::Raw.new(lib)
    #   result = cmd.call('HEAD', e: true)
    #   result.status.exitstatus  # => 0 (exists) or 1 (not found)
    #
    # @example Pretty-print a single object
    #   cmd = Git::Commands::CatFile::Raw.new(lib)
    #   result = cmd.call('HEAD', p: true)
    #   result.stdout
    #   # => "tree abc1234...\nauthor ...\n\nCommit message\n"
    #
    # @example Fetch content after working-tree filters
    #   cmd = Git::Commands::CatFile::Filtered.new(lib)
    #   result = cmd.call('HEAD:README.md', filters: true)
    #   result.stdout
    #
    # @example Fetch metadata for several objects via batch
    #   cmd = Git::Commands::CatFile::Batch.new(lib)
    #   result = cmd.call('HEAD', 'v1.0', batch_check: true)
    #   result.stdout
    #   # => "abc1234... commit 250\nabc5678... tag 143\n"
    #
    module CatFile
    end
  end
end
