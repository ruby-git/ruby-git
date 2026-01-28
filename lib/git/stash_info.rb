# frozen_string_literal: true

module Git
  # Immutable value object representing stash entry information
  #
  # StashInfo encapsulates the parsed data from `git stash list` output.
  # Each entry contains comprehensive information about the stash including
  # its index, reference name, commit SHA, branch, message, author/committer
  # details, and timestamps.
  #
  # @api public
  #
  # @example Create a StashInfo from parsed stash list output
  #   info = Git::StashInfo.new(
  #     index: 0,
  #     name: 'stash@{0}',
  #     oid: 'abc123def456789...',
  #     short_oid: 'abc123d',
  #     branch: 'main',
  #     message: 'WIP on main: abc123 Initial commit',
  #     author_name: 'Jane Doe',
  #     author_email: 'jane@example.com',
  #     author_date: '2026-01-24T10:30:00-08:00',
  #     committer_name: 'Jane Doe',
  #     committer_email: 'jane@example.com',
  #     committer_date: '2026-01-24T10:30:00-08:00'
  #   )
  #
  #   info.index           # => 0
  #   info.name            # => 'stash@{0}'
  #   info.oid             # => 'abc123def456789...'
  #   info.short_oid       # => 'abc123d'
  #   info.branch          # => 'main'
  #   info.message         # => 'WIP on main: abc123 Initial commit'
  #   info.author_name     # => 'Jane Doe'
  #   info.author_email    # => 'jane@example.com'
  #   info.author_date     # => '2026-01-24T10:30:00-08:00'
  #   info.committer_name  # => 'Jane Doe'
  #   info.committer_email # => 'jane@example.com'
  #   info.committer_date  # => '2026-01-24T10:30:00-08:00'
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
  # @!attribute [r] author_name
  #   @return [String] the name of the stash author
  #
  # @!attribute [r] author_email
  #   @return [String] the email of the stash author
  #
  # @!attribute [r] author_date
  #   @return [String] the author date in ISO 8601 format
  #
  # @!attribute [r] committer_name
  #   @return [String] the name of the stash committer
  #
  # @!attribute [r] committer_email
  #   @return [String] the email of the stash committer
  #
  # @!attribute [r] committer_date
  #   @return [String] the committer date in ISO 8601 format
  #
  StashInfo = Data.define(
    :index,
    :name,
    :oid,
    :short_oid,
    :branch,
    :message,
    :author_name,
    :author_email,
    :author_date,
    :committer_name,
    :committer_email,
    :committer_date
  ) do
    # Returns the stash reference name
    #
    # @return [String] the stash name (e.g., 'stash@\\{0}')
    #
    # @example
    #   info.to_s # => 'stash@{0}'
    #
    def to_s
      name
    end
  end
end
