# frozen_string_literal: true

require_relative 'branch/copy'
require_relative 'branch/create'
require_relative 'branch/delete'
require_relative 'branch/list'
require_relative 'branch/move'
require_relative 'branch/set_upstream'
require_relative 'branch/show_current'
require_relative 'branch/unset_upstream'

module Git
  module Commands
    # Commands for managing branches via `git branch`
    #
    # This module contains command classes split by branch operation:
    #
    # - {Branch::Create} — create a new branch
    # - {Branch::Delete} — delete one or more branches (`--delete` / `--delete --force`)
    # - {Branch::List} — list branches with optional filtering
    # - {Branch::Move} — rename a branch (`--move` / `--move --force`)
    # - {Branch::Copy} — copy a branch (`--copy` / `--copy --force`)
    # - {Branch::ShowCurrent} — print the current branch name (`--show-current`)
    # - {Branch::SetUpstream} — set upstream tracking (`--set-upstream-to`)
    # - {Branch::UnsetUpstream} — remove upstream tracking (`--unset-upstream`)
    #
    # @api private
    #
    # @see https://git-scm.com/docs/git-branch git-branch documentation
    #
    module Branch
    end
  end
end
