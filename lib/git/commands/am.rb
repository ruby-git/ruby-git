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
    # Namespace module for `git am` subcommands
    #
    # `git am` applies a series of patches from a mailbox. This module contains
    # command classes for the initial patch application ({Apply}) and session
    # management ({Continue}, {Skip}, {Abort}, {Quit}, {Retry}, {ShowCurrentPatch}).
    #
    # @see https://git-scm.com/docs/git-am git-am
    #
    # @api private
    #
    module Am
    end
  end
end
