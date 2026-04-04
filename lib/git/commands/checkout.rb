# frozen_string_literal: true

require_relative 'checkout/branch'
require_relative 'checkout/files'

module Git
  module Commands
    # Commands for switching branches and restoring files via `git checkout`
    #
    # This module contains command classes split by checkout mode:
    #
    # - {Checkout::Branch} — switch branches or create and switch to a new branch
    # - {Checkout::Files} — restore working tree files from a given tree-ish
    #
    # @api private
    #
    # @see https://git-scm.com/docs/git-checkout git-checkout documentation
    #
    module Checkout
    end
  end
end
