# frozen_string_literal: true

require_relative 'merge/abort'
require_relative 'merge/continue'
require_relative 'merge/quit'
require_relative 'merge/start'

module Git
  module Commands
    # Commands for joining development histories via `git merge`
    #
    # This module contains command classes for the initial merge ({Start}) and
    # session management ({Continue}, {Abort}, {Quit}):
    #
    # - {Merge::Start} — merge one or more branches into the current branch
    # - {Merge::Continue} — resume after resolving merge conflicts (`--continue`)
    # - {Merge::Abort} — abort the in-progress merge (`--abort`)
    # - {Merge::Quit} — forget the in-progress merge but leave the working tree
    #   as-is (`--quit`)
    #
    # @api private
    #
    # @see https://git-scm.com/docs/git-merge git-merge documentation
    #
    module Merge
    end
  end
end
