# frozen_string_literal: true

module Git
  module Commands
    # Commands for safely updating ref values via `git update-ref`
    #
    # This module contains command classes split by invocation mode:
    #
    # - {UpdateRef::Update} — set a ref to a new value (the default mode);
    #   also supports verifying the old value before updating
    # - {UpdateRef::Delete} — delete a ref (`-d` flag); optionally verifies
    #   the current value before deleting
    # - {UpdateRef::Batch} — read update/create/delete/verify instructions
    #   from stdin (`--stdin`); all modifications are applied atomically
    #
    # @api private
    #
    # @see https://git-scm.com/docs/git-update-ref git-update-ref documentation
    #
    # @example Update a branch ref to a new commit SHA
    #   cmd = Git::Commands::UpdateRef::Update.new(lib)
    #   cmd.call('refs/heads/main', 'abc1234')
    #
    # @example Delete a ref
    #   cmd = Git::Commands::UpdateRef::Delete.new(lib)
    #   cmd.call('refs/heads/old-branch')
    #
    # @example Atomically update multiple refs via stdin
    #   cmd = Git::Commands::UpdateRef::Batch.new(execution_context)
    #   cmd.call(
    #     'update refs/heads/main newsha oldsha',
    #     'delete refs/heads/old'
    #   )
    #
    module UpdateRef
    end
  end
end
