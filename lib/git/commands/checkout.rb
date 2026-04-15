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
    # @example Switch to an existing branch
    #   cmd = Git::Commands::Checkout::Branch.new(lib)
    #   cmd.call('main')
    #
    # @example Create and switch to a new branch
    #   cmd = Git::Commands::Checkout::Branch.new(lib)
    #   cmd.call('main', b: 'feature/new-feature')
    #
    # @example Restore a file from the index (discard uncommitted changes)
    #   cmd = Git::Commands::Checkout::Files.new(lib)
    #   cmd.call(pathspec: ['lib/my_file.rb'])
    #
    # @example Restore a file from a specific branch
    #   cmd = Git::Commands::Checkout::Files.new(lib)
    #   cmd.call('main', pathspec: ['lib/my_file.rb'])
    #
    module Checkout
    end
  end
end
