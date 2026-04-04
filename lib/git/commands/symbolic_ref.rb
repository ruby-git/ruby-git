# frozen_string_literal: true

require_relative 'symbolic_ref/delete'
require_relative 'symbolic_ref/read'
require_relative 'symbolic_ref/update'

module Git
  module Commands
    # Commands for reading, updating, and deleting symbolic refs via
    # `git symbolic-ref`
    #
    # This module contains command classes split by invocation mode:
    #
    # - {SymbolicRef::Read} — read the target of a symbolic ref
    # - {SymbolicRef::Update} — create or update a symbolic ref to point
    #   at a given branch
    # - {SymbolicRef::Delete} — delete a symbolic ref
    #
    # @api private
    #
    # @see https://git-scm.com/docs/git-symbolic-ref git-symbolic-ref documentation
    #
    # @example Read the current HEAD
    #   cmd = Git::Commands::SymbolicRef::Read.new(lib)
    #   cmd.call('HEAD')
    #
    # @example Update HEAD to point to a branch
    #   cmd = Git::Commands::SymbolicRef::Update.new(lib)
    #   cmd.call('HEAD', 'refs/heads/main')
    #
    # @example Delete a symbolic ref
    #   cmd = Git::Commands::SymbolicRef::Delete.new(lib)
    #   cmd.call('HEAD')
    #
    module SymbolicRef
    end
  end
end
