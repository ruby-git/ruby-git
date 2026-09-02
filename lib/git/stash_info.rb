# frozen_string_literal: true

require 'time'

require 'git/author_info'

module Git
  # Immutable value object representing stash entry information
  #
  # StashInfo encapsulates the parsed data from `git stash list` output.
  # Each entry contains comprehensive information about the stash including
  # its index, reference name, commit SHA, branch, message, and the author and
  # committer identities.
  #
  # The author and committer are nested {Git::AuthorInfo} values. Their `date`
  # is a `Time` parsed from git's ISO 8601 output, not an ISO 8601 string.
  #
  # @example Create a StashInfo from parsed stash list output
  #   info = Git::StashInfo.new(
  #     index: 0,
  #     name: 'stash@{0}',
  #     oid: 'abc123def456789...',
  #     short_oid: 'abc123d',
  #     branch: 'main',
  #     message: 'WIP on main: abc123 Initial commit',
  #     author: Git::AuthorInfo.new(
  #       name: 'Jane Doe',
  #       email: 'jane@example.com',
  #       date: Time.iso8601('2026-01-24T10:30:00-08:00')
  #     ),
  #     committer: Git::AuthorInfo.new(
  #       name: 'Jane Doe',
  #       email: 'jane@example.com',
  #       date: Time.iso8601('2026-01-24T10:30:00-08:00')
  #     )
  #   )
  #
  #   info.index           # => 0
  #   info.name            # => 'stash@{0}'
  #   info.oid             # => 'abc123def456789...'
  #   info.short_oid       # => 'abc123d'
  #   info.branch          # => 'main'
  #   info.message         # => 'WIP on main: abc123 Initial commit'
  #   info.author.name     # => 'Jane Doe'
  #   info.author.email    # => 'jane@example.com'
  #   info.author.date     # => 2026-01-24 10:30:00 -0800
  #   info.committer.name  # => 'Jane Doe'
  #
  # @see Git::AuthorInfo for the nested author and committer identities
  #
  # @api public
  #
  # @!attribute [r] index
  #   @return [Integer] the stash index (0, 1, 2, ...)
  #
  # @!attribute [r] name
  #   @return [String] the stash reference name (e.g., 'stash@\\{0\\}')
  #
  # @!attribute [r] oid
  #   @return [String] the full 40-character object identifier of the stash
  #
  # @!attribute [r] short_oid
  #   @return [String] the abbreviated object identifier (typically 7 characters)
  #
  # @!attribute [r] branch
  #   @return [String, nil] the branch name where the stash was created,
  #     or nil for custom stash messages
  #
  # @!attribute [r] message
  #   @return [String] the stash message (e.g., 'WIP on main: abc123 commit msg')
  #
  # @!attribute [r] author
  #   The identity of the stash author; the nested `date` is a `Time`.
  #
  #   @return [Git::AuthorInfo] the author of the stash commit
  #
  # @!attribute [r] committer
  #   The identity of the stash committer; the nested `date` is a `Time`.
  #
  #   @return [Git::AuthorInfo] the committer of the stash commit
  #
  StashInfo = Data.define(
    :index,
    :name,
    :oid,
    :short_oid,
    :branch,
    :message,
    :author,
    :committer
  ) do
    # Returns the stash reference name
    #
    # @example Convert to string
    #   info.to_s # => 'stash@{0}'
    #
    # @return [String] the stash name (e.g., 'stash@\\{0}')
    def to_s
      name
    end
  end
end
