# frozen_string_literal: true

require_relative 'revert/abort'
require_relative 'revert/continue'
require_relative 'revert/quit'
require_relative 'revert/skip'
require_relative 'revert/start'

module Git
  module Commands
    # Commands for reverting commits via `git revert`
    #
    # This module contains command classes for starting a revert and managing
    # in-progress revert sessions:
    #
    # - {Revert::Start} — revert one or more commits
    # - {Revert::Continue} — resume after resolving conflicts (`--continue`)
    # - {Revert::Skip} — skip the current commit (`--skip`)
    # - {Revert::Abort} — abort the in-progress revert (`--abort`)
    # - {Revert::Quit} — forget the in-progress revert (`--quit`)
    #
    # @api private
    #
    # @see https://git-scm.com/docs/git-revert git-revert documentation
    #
    module Revert
    end
  end
end
