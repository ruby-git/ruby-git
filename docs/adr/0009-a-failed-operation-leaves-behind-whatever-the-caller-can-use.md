# A failed operation leaves behind whatever the caller can use

A facade method that fails partway through does not undo its earlier steps. It removes
only what would be of no use to anyone, and leaves everything else exactly where the
failure left it. The test is whether the caller can do something with what remains, not
which layer created it.

Three kinds of leftover, decided the same way each time. A repository stopped mid
operation stays: `Git::Repository#merge_into` leaves a conflicted merge checked out on
the target branch, because `git status` names that state and resolving it is ordinary
git work. A finished deliverable stays: `Git.export` leaves the exported files in place
when it cannot remove `.git`, because the files are what the caller asked for and only
the vestigial `.git` is unwanted. A private scratch file goes: `Git::Repository#archive`
and its `atomic_replace` helper delete the temporary file they wrote and re-raise, so a
failure never leaves a partial archive at the caller's destination.

The rejected alternative in every case is unwinding to the pre-call state. It is the
obvious-looking option, and it fails for a different reason each time it is tried. In
`merge_into` and `#in_branch` the restore checkout is deliberately not wrapped in
`ensure`: with a conflicted merge in the worktree that checkout fails on its own, and
the `ensure` would raise a second error that masks the real one. In `Git.export` a
cleanup cannot outrun the failure that triggered it, because the permission wall that
stopped `.git` from being removed stops the cleanup too, and a cleanup that did succeed
would delete the exported files, turning a partial success into a total loss. Only the
scratch-file case has an unwind that is both possible and harmless, which is why it is
the only one that unwinds.

Gem-internal state is not covered by any of this and always unwinds.
`Git::Repository#with_index`, `#with_working`, and `#with_temp_index` restore the
execution context in `ensure`, because a context left pointing at a removed temporary
directory breaks every later call on that object and no caller can repair it from a
shell.

Leaving repository state in place is safe only when git reports it, so the two guards
that establish that condition run before anything is mutated. `SharedPrivate.assert_local_branch!`
rejects a commit SHA, tag, or remote-tracking branch, each of which detaches HEAD, so
that work committed there cannot be stranded at a commit nothing references.
`SharedPrivate.head_restore_point` rejects an unborn HEAD, which has no ref to return
to. These are preconditions of the rule rather than incidental validation: without them
a failure would leave a state git cannot describe and the caller cannot name.

## Consequences

Ruby convention runs the other way. `File.open`, `Dir.chdir`, and the gem's own
`with_*` methods all restore on the way out, so a block-taking method reads as a context
manager. `Git::Repository#in_branch` takes a block, is named like one of them, and does
not behave like one. Reviewers have raised its missing `ensure` repeatedly, which is the
convention working as expected rather than a defect in the review.

So the guarantee is per-method and stated in the method's own documentation, never
inferred from its shape. Every facade method that switches HEAD, leaves git mid
operation, or writes to a caller-named path says in its YARD docs what a failure leaves
behind. `#in_branch`, `#merge_into`, and `Git.export` each document that today.

A method may still discard state on a path that has not failed. `#in_branch` hard-resets
the working tree when its block returns a falsy value. That is the documented contract,
not a failure path, and this record does not speak to it.

The operational rules are normative policy in
[Facade Implementation - Failure state](../../.github/skills/facade-implementation/REFERENCE.md#failure-state).
