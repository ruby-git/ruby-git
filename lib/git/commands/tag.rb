# frozen_string_literal: true

require_relative 'tag/create'
require_relative 'tag/delete'
require_relative 'tag/list'
require_relative 'tag/verify'

module Git
  module Commands
    # Commands for managing tags via `git tag`
    #
    # This module contains command classes split by tag operation:
    #
    # - {Tag::Create} — create a new lightweight or annotated tag
    # - {Tag::Delete} — delete one or more tags (`--delete`)
    # - {Tag::List} — list tags with optional filtering (`--list`)
    # - {Tag::Verify} — verify GPG signatures of tags (`--verify`)
    #
    # @api private
    #
    # @see https://git-scm.com/docs/git-tag git-tag documentation
    #
    module Tag
    end
  end
end
