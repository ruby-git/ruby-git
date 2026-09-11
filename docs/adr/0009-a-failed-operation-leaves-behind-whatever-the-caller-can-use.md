# A failed operation leaves behind whatever the caller can use

*An operation* is any method a caller invokes that runs one or more git commands: a
`Git::Repository` facade method, a `Git` module function such as `Git.export`, or a
method on an object the gem returns, such as `Git::Object::Commit#archive`.

*A failure* is the operation letting an exception escape.

A step that fails and is handled within the operation is part of the operation's
normal flow and is not a failure. An example is when `Git::Repository#no_commits?`
rescues the `Git::FailedError` raised when `git rev-parse` exits non-zero on an
unborn HEAD and returns `true`.

An operation that fails partway through leaves everything where the failure left it,
except what would be of no use to the caller. The test is whether the caller can do
something with what remains. Which layer created it does not matter.

A failure can leave three kinds of state behind. The test decides each one:

1. **A repository left mid operation.** Leave the repository as the failure left it
   when the caller can use it. When `Git::Repository#merge_into` fails on a merge
   conflict, the repository stays checked out on the target branch with the merge in
   progress. That state can stay because `git status` names it and resolving the
   conflict is ordinary git work.
2. **A finished deliverable.** Leave the deliverable in place when the caller can use
   it. When `Git.export` cannot remove `.git`, the exported files stay where they
   are. They are what the caller asked for, and only `.git` is unwanted.
3. **A private scratch file.** Clean up the scratch file because the caller cannot use
   it. When `Git::Repository#archive` fails, its private helpers delete the
   temporary file they wrote and re-raise, so no partial archive is left at the
   caller's destination.

Restoring the pre-call state, a rollback or unwind, is rejected, whether on every
failure or conditionally when the restore can succeed.

For `#merge_into` and `Git::Repository#in_branch`, a restore that ran on every
failure would carry unfinished work in the working tree onto the original branch. For
`#merge_into` a conflicted merge would also make the restore fail on its own and hide
the error that stopped the merge. A restore that ran conditionally would leave a
different state after different failure modes of the same step, and the caller would
have to work out which one happened.

## Consequences

Block-taking methods like `File.open`, `Dir.chdir`, and the gem's own `with_*`
methods all restore on the way out, so a reader assumes any block-taking method puts
things back when the block ends.

`Git::Repository#in_branch` takes a block, as `with_index` does, but does not put
things back when the block ends. Reviewers who report its missing `ensure` are right
about the usual convention and wrong about the code. `#in_branch` breaks the
convention on purpose, and the reply to the report is this record and the method's
`@note`, not a change to the code.

The `with_*` methods are consistent with the record. They restore only the gem's own
execution context and remove a scratch directory, which is the third case above, and
they touch no repository state.

The guarantee is per operation and stated in each operation's own documentation. A
reader cannot infer it from the operation's shape. An operation that switches HEAD,
leaves git mid operation, or writes to a caller-named path says in its YARD docs what
a failure leaves behind. Issue 1831 tracks the operations whose docs do not say so
yet.

An operation may still discard state on a path that has not failed. `#in_branch`
hard-resets the working tree when its block returns a falsy value. That is the
documented contract, not a failure, so this record does not cover it.

The operational rules are normative policy in [Facade Implementation - Failure
state](../../.github/skills/facade-implementation/REFERENCE.md#failure-state).
