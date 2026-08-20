# The public API models git's data model

ruby-git exposes the relationships git indexes. It does not invent relationships git has
no concept of, even when a convenient one is easy to imagine and easy to fake.

The case that forced the rule was branch-scoped stashes. Stashes live on the
`refs/stash` reflog, one stack per repository. A stash entry records the branch that was
current when it was created, but that is a label in the entry's message, not an index
git can filter on. Popping a stash onto a different branch is ordinary usage rather than
an error.

`Git::Branch#stashes` looked like a branch-scoped API and was not one. It ignored the
branch receiver and returned every stash in the repository, so
`repo.branch('feature').stashes` and `repo.branch('main').stashes` gave the same answer.
There were two ways to make it honest. Implement real branch scoping, or remove it.

Real branch scoping means filtering entries by the branch name in their message. That is
a ruby-git invention wearing a git-shaped name. It returns a wrong answer for any stash
applied across branches, and the caller has no reason to doubt a method that hands back
plausible results.

So ruby-git will offer no `branch.stashes`, no `stashes_for(branch)`, and no other
signature implying the stash stack is partitioned by branch. `Git::Branch#stashes` is
still present and is scheduled for removal under issue #1637. The replacement is
`Git::Repository#stashes_all`, which reads the same stack and returns a different
shape.

## Scope

The rule covers relationships between git concepts, not convenience in general. ruby-git
offers plenty that git has no single command for. `Git::Status` assembles several
plumbing calls into one object, and the diff stat objects total numbers git prints
separately. Those compose answers git gave. Branch-scoped stashes would have
manufactured a link that is absent from the data.

Relates to issue #1637.
