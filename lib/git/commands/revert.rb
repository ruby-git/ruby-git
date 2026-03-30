# frozen_string_literal: true

require_relative 'revert/abort'
require_relative 'revert/continue'
require_relative 'revert/quit'
require_relative 'revert/skip'
require_relative 'revert/start'

module Git
  module Commands
    # Namespace module for `git revert` subcommands
    #
    # `git revert` creates new commits that undo the changes introduced by
    # specified commits. This module contains command classes for starting a
    # revert ({Start}) and managing in-progress revert sessions ({Continue},
    # {Skip}, {Abort}, {Quit}).
    #
    # @see https://git-scm.com/docs/git-revert git-revert
    #
    # @api private
    #
    module Revert
    end
  end
end
