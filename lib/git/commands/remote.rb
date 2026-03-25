# frozen_string_literal: true

module Git
  module Commands
    # Commands for managing git remotes via `git remote`
    #
    # This module contains command classes split by remote operation:
    # - {Remote::List} - list configured remotes
    # - {Remote::Add} - add a new remote
    # - {Remote::Rename} - rename an existing remote
    # - {Remote::Remove} - remove a remote
    # - {Remote::SetHead} - manage a remote's default branch
    # - {Remote::SetBranches} - configure tracked branches for a remote
    # - {Remote::GetUrl} - retrieve fetch or push URLs
    # - {Remote::SetUrl} - replace a remote URL
    # - {Remote::SetUrlAdd} - append a remote URL
    # - {Remote::SetUrlDelete} - delete a matching remote URL
    # - {Remote::Show} - show details about one or more remotes
    # - {Remote::Prune} - prune stale tracking refs for remotes
    # - {Remote::Update} - update one or more remotes or groups
    #
    # @api private
    #
    # @see https://git-scm.com/docs/git-remote git-remote documentation
    module Remote
    end
  end
end
