# frozen_string_literal: true

require_relative 'am/apply'
require_relative 'am/abort'
require_relative 'am/continue'
require_relative 'am/quit'
require_relative 'am/retry'
require_relative 'am/show_current_patch'
require_relative 'am/skip'

module Git
  module Commands
    # Commands for applying patches from a mailbox via `git am`
    #
    # This module contains command classes for patch application and session
    # management:
    #
    # - {Am::Apply} — apply a series of patches from a mailbox
    # - {Am::Abort} — abort the current patch application (`--abort`)
    # - {Am::Continue} — resume after resolving conflicts (`--continue`)
    # - {Am::Quit} — drop the current patch session (`--quit`)
    # - {Am::Retry} — retry the current patch
    # - {Am::ShowCurrentPatch} — show the patch being applied (`--show-current-patch`)
    # - {Am::Skip} — skip the current patch (`--skip`)
    #
    # @api private
    #
    # @see https://git-scm.com/docs/git-am git-am documentation
    #
    module Am
    end
  end
end
