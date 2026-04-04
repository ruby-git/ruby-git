# frozen_string_literal: true

require_relative 'show_ref/exclude_existing'
require_relative 'show_ref/exists'
require_relative 'show_ref/list'
require_relative 'show_ref/verify'

module Git
  module Commands
    # Commands for querying git refs via `git show-ref`
    #
    # This module contains command classes split by invocation mode:
    #
    # - {ShowRef::List} — standard ref listing with optional pattern filtering
    #   (`git show-ref [options] [<pattern>...]`)
    # - {ShowRef::Verify} — strict per-ref verification by full refname
    #   (`git show-ref --verify [options] [<ref>...]`)
    # - {ShowRef::ExcludeExisting} — stdin-based filter for ref names, excluding
    #   refs that already exist in the repository
    #   (`git show-ref --exclude-existing[=<pattern>]`)
    # - {ShowRef::Exists} — boolean existence check without output (git >= 2.43)
    #   (`git show-ref --exists <ref>`)
    #
    # @api private
    #
    # @see https://git-scm.com/docs/git-show-ref git-show-ref documentation
    #
    # @example List all refs matching a pattern
    #   cmd = Git::Commands::ShowRef::List.new(execution_context)
    #   result = cmd.call('refs/tags/', tags: true)
    #   result.stdout
    #   # => "abc1234 refs/tags/v1.0\ndef5678 refs/tags/v2.0\n"
    #
    # @example Verify a specific ref
    #   cmd = Git::Commands::ShowRef::Verify.new(execution_context)
    #   result = cmd.call('refs/heads/main')
    #   result.stdout  # => "abc1234 refs/heads/main\n"
    #
    module ShowRef
    end
  end
end
