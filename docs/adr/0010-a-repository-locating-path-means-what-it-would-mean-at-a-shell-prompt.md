# A repository-locating path means what it would mean at a shell prompt

A path a caller gives to a factory method (`Git.open`, `Git.bare`, `Git.init`, or
`Git.clone`) to locate a repository means what it would mean typed at a shell prompt in
the process working directory at the time of the call, or in `:chdir` for `Git.clone`.
That covers the positional directory, `:repository`, and `:index`.

The rule has three parts.

1. **A relative path is expanded against that base and nothing else.** It is never
   expanded against the working tree or the git directory. Those supply only the
   defaults when an option is omitted: `:repository` defaults to `<working_dir>/.git`
   and `:index` to `<git_dir>/index`. An absolute path is used as given. The base is
   `Dir.pwd` at the moment the factory runs, so the same call resolves differently
   after `Dir.chdir` or inside a `Git::Repository#chdir` block. A relative `:chdir` is
   itself resolved against the process working directory, because that is where git is
   started from.
2. **`~` is expanded in Ruby before git sees the path.** This follows from the
   shell-prompt reading: the shell expands `~` before git runs, and git itself never
   does. ruby-git spawns git without a shell, so a `~` handed to git is a directory
   literally named `~`.
3. **`File.expand_path(path, base)` is the primitive.** It does what the shell plus
   git would do: expands `~`, joins a relative path onto the base, normalizes `.` and
   `..`, and leaves an absolute path alone. Every expansion runs through
   `Git::SystemCallGuard`, so a removed process working directory raises `Git::Error`
   like any other filesystem failure ([ADR-0008](0008-errors-from-outside-the-gem-are-converted-at-the-boundary-that-admits-them.md)).
   `File.join` is rejected as the primitive because it does none of that and glues the
   base onto an absolute path.

There is one exception, because the path never passes through Ruby's hands as a shell
argument would: a relative target inside a `gitdir:` pointer file resolves against the
pointer file's directory. It is file content, written by git, and never saw a shell.

## Considered options

Layout-relative resolution, where `:repository` was expanded against the working
directory and `:index` against the git directory, was the behavior through v5.x and
was removed by issue 1871. It made the defaults and the explicit values follow
different rules: an omitted `:index` lived under the git directory, and so did a
relative one, but an absolute one did not, and the positional directory and
`set_index` had always been relative to the process working directory. A caller had to
know which option they were passing to know what a relative path meant. The
shell-prompt rule gives every path the same meaning, and a caller who wants the old
location joins it themselves.

Leaving `~` to git, which was the v5.x behavior of `Git.init` and `Git.clone`, was
rejected with issue 1873. `Git.init` ran git on the literal path and then opened the
expanded one, so the returned repository pointed at a directory git never created.
`Git.clone` only worked because it re-read the literal path from git's output.
Expanding before git runs makes the directory git creates the one the repository is
bound to.

## Consequences

The rule covers only paths that locate a repository. A path passed to an operation
such as `add`, `rm`, or `checkout` is relative to the repository working directory,
because that is what git does with a pathspec, and the [Project Context
skill](../../.github/skills/project-context/SKILL.md) states that rule in one line
under Path Handling. This record is the fuller statement of the distinction; the two
do not contradict each other.

A factory method that accepts a path expands it before git runs and hands git the
absolute path. git reports the absolute path back, which is why `Git.clone` can still
read the created directory from git's output.
