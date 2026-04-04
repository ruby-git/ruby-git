# frozen_string_literal: true

require_relative 'stash/apply'
require_relative 'stash/branch'
require_relative 'stash/clear'
require_relative 'stash/create'
require_relative 'stash/drop'
require_relative 'stash/list'
require_relative 'stash/pop'
require_relative 'stash/push'
require_relative 'stash/show'
require_relative 'stash/store'

module Git
  module Commands
    # Commands for stashing working directory changes via `git stash`
    #
    # This module contains command classes split by stash operation:
    #
    # - {Stash::Push} — save changes to a new stash entry
    # - {Stash::Pop} — apply the top stash and remove it from the stash list
    # - {Stash::Apply} — apply a stash without removing it
    # - {Stash::Drop} — remove a single stash entry
    # - {Stash::Clear} — remove all stash entries
    # - {Stash::List} — list stash entries
    # - {Stash::Show} — show changes recorded in a stash entry
    # - {Stash::Branch} — create a new branch from a stash entry
    # - {Stash::Create} — create a stash object without storing it
    # - {Stash::Store} — store a stash object created with `create`
    #
    # @api private
    #
    # @see https://git-scm.com/docs/git-stash git-stash documentation
    #
    module Stash
    end
  end
end
