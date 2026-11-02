# Outside the factory methods, only a leading `~` in a path is expanded

[ADR-0010](0010-a-repository-locating-path-means-what-it-would-mean-at-a-shell-prompt.md)
covers the paths a factory method uses to locate a repository. This record covers every
other value ruby-git hands to git as a path: the git binary (`binary_path`), the SSH
wrapper (`git_ssh`), and the path arguments of repository methods.

Where git would take a leading `~` literally, ruby-git expands it before git runs,
because a shell would have. ruby-git starts git without a shell, so otherwise git, or
`Process.spawn` for the binary, looks for a directory literally named `~`. A leading `~`
alone decides: `Git::PathResolver.expand_home` expands a String that starts with `~` with
`File.expand_path` and returns every other value unchanged.

Every other value goes to git as given, which gives it the meaning it has when typed
after `git` at a shell prompt in the process working directory. Where git already expands
`~` itself, as its transport does for a local repository path given to `git ls-remote`,
ruby-git leaves the value alone.

There is one exception. A method that runs git in a directory other than the process
working directory, as `apply` and `apply_mail` run git in the working tree, expands a
relative path against the process working directory, so the path keeps the meaning it
has at the caller's prompt.

## Considered options

ADR-0010's full expansion, `File.expand_path` on every value, was rejected. A relative or
bare value is often not a path at all: `git` is a command name for the `PATH` lookup,
and `worktree_remove('feature')` names a worktree by the last component of its path.
Expanding either would turn it into a path under the process working directory. Where
the value is a path, git already gives it the command-line meaning: `git worktree add
../wt` resolves against the directory git was started in.

## Consequences

Expansion runs where the value is used, not where it is stored. `Git.config.binary_path`
and `Git.config.git_ssh` return the value as set, and `Git::ExecutionContext#binary_path`
and `#git_ssh` expand it for each command, so a change to `HOME` takes effect on the next
command.

ADR-0010 says git never expands `~`. That holds for the paths it covers, but not for a
local repository path that git's transport opens, which is why this record leaves such
a path to git.
