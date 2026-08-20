# Analysis of the Current Git Gem Architecture and Its Challenges

This document provides an in-depth look at the current architecture of the `git` gem,
outlining its primary components and the design challenges that have emerged over
time. Understanding these challenges is the key motivation for the proposed
architectural redesign.

- [1. Overview of the Current Architecture](#1-overview-of-the-current-architecture)
- [2. Key Architectural Challenges](#2-key-architectural-challenges)
  - [A. Unclear Separation of Concerns](#a-unclear-separation-of-concerns)
  - [B. Circular Dependency](#b-circular-dependency)
  - [C. Undefined Public API Boundary](#c-undefined-public-api-boundary)
  - [D. Slow and Brittle Test Suite](#d-slow-and-brittle-test-suite)

## 1. Overview of the Current Architecture

The gem's current design is centered around three main classes: `Git`, `Git::Base`,
and `Git::Lib`.

- **`Git` (Top-Level Module)**: This module serves as the primary public entry point
  for creating repository objects. It contains class-level factory methods like
  `Git.open`, `Git.clone`, and `Git.init`. It also provides an interface for
  accessing global git configuration settings.

- **`Git::Base`**: This is the main object that users interact with after creating or
  opening a repository. It holds the high-level public API for most git operations
  (e.g., `g.commit`, `g.add`, `g.status`). It is responsible for managing the
  repository's state, such as the paths to the working directory and the `.git`
  directory.

- **`Git::Lib`**: This class is intended to be the low-level wrapper around the `git`
  command-line tool. It contains the methods that build the specific command-line
  arguments and execute the `git` binary. In practice, it also contains a significant
  amount of logic for parsing the output of these commands.

## 2. Key Architectural Challenges

While this structure has been functional, several significant design challenges make
the codebase difficult to maintain, test, and evolve.

### A. Unclear Separation of Concerns

The responsibilities between Git::Base and Git::Lib are "muddy" and overlap
significantly.

- `Git::Base` sometimes contains logic that feels like it should be lower-level.

- `Git::Lib`, which should ideally only be concerned with command execution, is
  filled with high-level logic for parsing command output into specific Ruby objects
  (e.g., parsing log output, diff stats, and branch lists).

This blending of responsibilities makes it hard to determine where a specific piece
of logic should reside, leading to an inconsistent and confusing internal structure.

### B. Circular Dependency

This is the most critical architectural flaw in the current design.

- A `Git::Base` instance is created.

- The first time a command is run, `Git::Base` lazily initializes a `Git::Lib`
  instance via its `.lib` accessor method.

- The `Git::Lib` constructor is passed the `Git::Base` instance (`self`) so that it
  can read the repository's path configuration back from the object that is creating
  it.

This creates a tight, circular coupling: `Git::Base` depends on `Git::Lib` to execute
commands, but `Git::Lib` depends on `Git::Base` for its own configuration. This
pattern makes the classes difficult to instantiate or test in isolation and creates a
fragile system where changes in one class can have unexpected side effects in the
other.

### C. Undefined Public API Boundary

The gem lacks a formally defined public interface. Because `Git::Base` exposes its
internal `Git::Lib` instance via the public `g.lib` accessor, many users have come to
rely on `Git::Lib` and its methods as if they were part of the public API.

This has two negative consequences:

1. It prevents the gem's maintainers from refactoring or changing the internal
   implementation of `Git::Lib` without causing breaking changes for users.

2. It exposes complex, internal methods to users, creating a confusing and
   inconsistent user experience.

### D. Slow and Brittle Test Suite

The current testing strategy, built on `TestUnit`, suffers from two major issues:

- **Over-reliance on Fixtures**: Most tests depend on having a complete, physical git
  repository on the filesystem to run against. Managing these fixtures is cumbersome.

- **Excessive Shelling Out**: Because the logic for command execution and output
  parsing are tightly coupled, nearly every test must shell out to the actual `git`
  command-line tool.

This makes the test suite extremely slow, especially on non-UNIX platforms like
Windows where process creation is more expensive. The slow feedback loop discourages
frequent testing and makes development more difficult. The brittleness of
filesystem-dependent tests also leads to flickering or unreliable test runs.
