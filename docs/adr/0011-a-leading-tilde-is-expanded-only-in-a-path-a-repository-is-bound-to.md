# A leading `~` is expanded only in a path a `Git::Repository` is bound to

ruby-git expands `~` only in a path a `Git::Repository` is bound to: the paths given to
`Git.open`, `Git.bare`, `Git.init`, and `Git.clone` to say where that repository lives
([ADR-0010](0010-a-repository-locating-path-means-what-it-would-mean-at-a-shell-prompt.md)),
and the paths given to `with_working`, `with_index`, `set_working`, and `set_index`. The
`:chdir` of `Git.clone` is expanded too, because the other clone paths are expanded
against it.

ruby-git stores these paths and uses them after the caller may have changed directory,
so it makes them absolute with `File.expand_path`, which expands `~` in the same step.
`Git.open` and `Git.bare` have done this since 2007. ADR-0010 reads a
repository-locating path as if typed unquoted at a shell prompt, which is why `~` is
expanded there. This record keeps that reading for those paths only, and reads every
other path as if quoted.

Every other path is used as given, and a leading `~` is not expanded. That covers:

- `binary_path`, which ruby-git starts with `Process.spawn`, and `git_ssh`, which git
  runs as `GIT_SSH`
- the path arguments of repository methods, such as the worktree methods, `apply`,
  `apply_mail`, and the output file of `archive`
- the source, `:reference`, and `:template` of `Git.clone`, and the repository given to
  `Git.ls_remote`, none of which a `Git::Repository` is bound to

A shell expands `~`; git and Ruby do not. git takes a quoted `'~/x'` literally, and so
do `Process.spawn` and Ruby's `File` methods. ruby-git runs git without a shell, so
passing the path through gives it the meaning it has when quoted after `git` at a shell
prompt, which keeps the gem close to the git command line. A caller who means the home
directory expands the path with `File.expand_path` first. Where git itself is
inconsistent, ruby-git leaves it to git: `git ls-remote '~/repo'` expands `~`, and
`git clone '~/repo'` does not.

`apply` and `apply_mail` are the exception to that meaning. They check that the patch
exists from the process working directory but run git in the working tree, so a relative
patch path can name a different file to each. This record does not decide whether
ruby-git should make such a path absolute; issue 1959 does.

## Considered options

Expanding a leading `~` wherever a shell would have was rejected. The first version of
this record did that for `binary_path` and `git_ssh`, and issue 1907 proposed it for the
worktree methods, `archive`, `apply`, and `apply_mail`. Each path raised another case
where the rewritten path no longer meant what the caller typed. `File.expand_path`
resolves `..` by text where the operating system follows a symlink first, drops a
trailing `/` that tells the operating system the path must be a directory, and reads
`~draft.patch` as a user lookup that raises `ArgumentError`. Replacing only the `~`
prefix avoids those but brings its own encoding and platform questions, and it would
give `~` a second meaning beside the factory paths.

Expanding a path when ruby-git reads it itself, and passing it through when only git
reads it, was rejected. Whether ruby-git or git writes the `archive` output file is an
implementation detail; the caller sees a wrapper around `git archive --output`. The
rule would also have split `binary_path` from `git_ssh`, two settings that both name a
program and are set the same ways.

Expanding `~` nowhere, the factory paths included, was rejected. `Git.open('~/repo')`
has worked since 2007, and v6.0.0 extended the expansion to `Git.init` and `Git.clone`
so that the same string names the same directory in all four factory methods (issue
1873).

## Consequences

`archive` still chooses its staging directory with `File.expand_path`, so a `~name`
destination raises `ArgumentError` when `name` is not a user, even though the
destination itself is used as given. Using `File.absolute_path` there would stop that,
but it changes the class of the exception, so under the rule in ADR-0008 it waits for
the next major.

ADR-0010 says git never expands `~`. That holds for the paths it covers, but not for a
local repository path that git's transport opens, such as the one given to
`git ls-remote`.
