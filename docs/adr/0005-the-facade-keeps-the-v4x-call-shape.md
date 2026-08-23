# The facade keeps the v4.x call shape

A `Git::Repository` facade method whose predecessor was public API on `Git::Base` or
`Git::Lib` copies the predecessor's signature verbatim. Most v4.x methods took options
as a positional `opts = {}` hash — the intended convention — but a few drifted to a
keyword splat (`add(paths = '.', **)`). The facade preserves the drift along with the
convention: callers bind to the signature that shipped, not the one that was intended,
so correcting an old inconsistency is as much a breaking change as modernizing a
correct signature. Methods with no v4.x predecessor use `opts = {}`, so the public API
stays uniform until the whole surface can move at once.

The rejected alternative was rewriting the facade with keyword arguments, and it was
not rejected on paper: six methods (`checkout`, `reset`, `commit`, `commit_all`,
`commit_tree`, `write_and_commit_tree`) shipped with `**opts` signatures during the
v5.x redesign and were rolled back. Ruby 3 no longer converts a trailing positional
`Hash` into keywords, so a v4.x caller holding options in a variable —
`opts = { force: true }; repo.reset('HEAD', opts)` — raises `ArgumentError` against
a keyword-accepting signature. Keyword signatures type-checked as an upgrade and
behaved as a silent breaking change for exactly the callers v5.0.0 promised to carry
forward.

The consequence worth recording is that these signatures contradict the project's own
coding standard, which prefers keyword arguments for multi-parameter methods. A reader
of `lib/git/repository/` will find dozens of `opts = {}` signatures and be tempted to
modernize them. Do not: flipping any one of them is a breaking change for
positional-hash callers, which is why the kwargs migration is deferred to a future
major release where it can be applied uniformly and announced as such. `checkout`
additionally guards `branch.is_a?(Hash)` because its v4.x form accepted the options
hash in the first position.
