# `Git::Object::Commit`, `Tree`, and `Blob` become hollow shells

The v5.x redesign replaced ActiveRecord-style classes with value objects and facade
methods wherever it could. These three are the exception. They stay.

Add `CommitInfo`, `TreeInfo`, `TreeEntryInfo`, and `BlobInfo` alongside them, add typed
facade methods that return those, then reimplement the three existing classes on top of
the new ones. One implementation, two shapes of API, and no removal date.

Two reasons.

`log.first.message` and `repo.gcommit(sha).author` are among the most-used idioms in the
gem. Deleting the types behind them would break more callers than the rest of the
redesign put together, and the callers get nothing they can see in return.

Blob content has no size bound. `Git::Object::Blob` reads it on demand, so a caller can
hold a blob handle and never pay for the contents. A value object has to decide at
construction time, and both choices are bad. Reading eagerly pulls arbitrary bytes into
memory for a caller who wanted the SHA. Reading lazily inside a value object gives up
immutability, which was the reason to build a value object.

Issue #1636 says these classes are scheduled for removal. This record supersedes that,
and the issue needs updating.

The migration mechanics belong to the `facade-implementation` skill rather than here.
See [Migrating an ActiveRecord-style class to a `*Info` value object][info-migration].

[info-migration]: ../../.github/skills/facade-implementation/REFERENCE.md#migrating-an-activerecord-style-class-to-a-info-value-object
