# Proposed Redesigned Architecture for the Git Gem

This document outlines a proposal for a major redesign of the git gem, targeted for version 5.0.0. The goal of this redesign is to modernize the gem's architecture, making it more robust, maintainable, testable, and easier for new contributors to understand.

- [1. Motivation](#1-motivation)
- [2. The New Architecture: A Three-Layered Approach](#2-the-new-architecture-a-three-layered-approach)
- [3. Key Design Principles](#3-key-design-principles)
  - [A. Clear Public vs. Private API](#a-clear-public-vs-private-api)
  - [B. Dependency Injection](#b-dependency-injection)
  - [C. Immutable Return Values](#c-immutable-return-values)
  - [D. Clear Naming for Path Objects](#d-clear-naming-for-path-objects)
- [4. Testing Strategy Overhaul](#4-testing-strategy-overhaul)
- [5. Impact on Users: Breaking Changes for v5.0.0](#5-impact-on-users-breaking-changes-for-v500)

## 1. Motivation

The current architecture, while functional, has several design issues that have accrued over time, making it difficult to extend and maintain.

- **Unclear Separation of Concerns**: The responsibilities of the `Git`, `Git::Base`, and `Git::Lib` classes are "muddy." `Git::Base` acts as both a high-level API and a factory, while `Git::Lib` contains a mix of low-level command execution and high-level output parsing.

- **Circular Dependency**: A key architectural flaw is the circular dependency between `Git::Base` and `Git::Lib`. `Git::Base` creates and depends on `Git::Lib`, but `Git::Lib`'s constructor requires an instance of Git::Base to access configuration. This tight coupling makes the classes difficult to reason about and test in isolation.

- **Undefined Public API**: The boundary between the gem's public API and its internal implementation is not clearly defined. This has led some users to rely on internal classes like `Git::Lib`, making it difficult to refactor the internals without introducing breaking changes.

- **Slow and Brittle Test Suite**: The current tests rely heavily on filesystem fixtures and shelling out to the git command line for almost every test case. This makes the test suite slow and difficult to maintain, especially on non-UNIX platforms.

## 2. The New Architecture: A Three-Layered Approach

The new design is built on a clear separation of concerns, dividing responsibilities into three distinct layers: a Facade, an Execution Context, and Command Objects.

1. The Facade Layer: Git::Repository

    This is the primary public interface that users will interact with.

    **Renaming**: `Git::Base` will be renamed to `Git::Repository`. This name is more descriptive and intuitive.

    **Responsibility**: It will serve as a clean, high-level facade for all common git operations. Its methods will be simple, one-line calls that delegate the actual work to an appropriate command object.

    **Scalability**: To prevent this class from growing too large, its methods will be organized into logical modules (e.g., `Git::Repository::Branching`, `Git::Repository::History`) which are then included in the main class. This keeps the core class definition small and the features well-organized. These categories will be inspired by (but not slavishly follow) the git command line reference in [this page](https://git-scm.com/docs).

2. The Execution Layer: Git::ExecutionContext

    This is the low-level, private engine for running commands.

    **Renaming**: `Git::Lib` will be renamed to `Git::ExecutionContext`.

    **Responsibility**: Its sole purpose is to execute raw git commands. It will manage the repository's environment (working directory, .git path, logger) and use the existing `Git::CommandLine` class to interact with the system's git binary. It will have no knowledge of any specific git command's arguments or output.

3. The Logic Layer: Git::Commands

    This is where all the command-specific implementation details will live.

    **New Classes**: For each git operation, a new command class will be created within the `Git::Commands` namespace (e.g., `Git::Commands::Commit`, `Git::Commands::Diff`).

    **Dual Responsibility**: Each command class will be responsible for:

    1. **Building Arguments**: Translating high-level Ruby options into the specific command-line flags and arguments that git expects.

    2. **Parsing Output**: Taking the raw string output from the ExecutionContext and converting it into rich, structured Ruby objects.

    **Handling Complexity**: For commands with multiple behaviors (like git diff), we can use specialized subclasses (e.g., Git::Commands::Diff::NameStatus, Git::Commands::Diff::Stats) to keep each class focused on a single responsibility.

## 3. Key Design Principles

The new architecture will be guided by the following modern design principles.

### A. Clear Public vs. Private API

A primary goal of this redesign is to establish a crisp boundary between the public API and internal implementation details.

- **Public Interface**: The public API will consist of the `Git` module (for factories), the `Git::Repository` class, and the specialized data/query objects it returns (e.g., `Git::Log`, `Git::Status`, `Git::Object::Commit`).

- **Private Implementation**: All other components, including `Git::ExecutionContext` and all classes within the `Git::Commands` namespace, will be considered internal. They will be explicitly marked with the `@api private` YARD tag to discourage external use.

### B. Dependency Injection

The circular dependency will be resolved by implementing a clear, one-way dependency flow.

1. The factory methods (`Git.open`, `Git.clone`) will create and configure an instance of `Git::ExecutionContext`.

2. This `ExecutionContext` instance will then be injected into the constructor of the `Git::Repository` object.

This decouples the `Repository` from its execution environment, making the system more modular and easier to test.

### C. Immutable Return Values

To create a more predictable and robust API, methods will return structured, immutable data objects instead of raw strings or hashes.

This will be implemented using `Data.define` or simple, frozen `Struct`s.

For example, instead of returning a raw string, `repo.config('user.name')` will return a `Git::Config::Value` object containing the key, value, scope, and source path.

### D. Clear Naming for Path Objects

To improve clarity, all classes that represent filesystem paths will be renamed to follow a consistent `...Path` suffix convention.

- `Git::WorkingDirectory` -> `Git::WorkingTreePath`

- `Git::Index` -> `Git::IndexPath`

- The old `Git::Repository` (representing the .git directory/file) -> `Git::RepositoryPath`

## 4. Testing Strategy Overhaul

The test suite will be modernized to be faster, more reliable, and easier to work with.

- **Migration to RSpec**: The entire test suite will be migrated from TestUnit to RSpec to leverage its modern tooling and expressive DSL.

- **Layered Testing**: A three-layered testing strategy will be adopted:

  1. **Unit Tests**: The majority of tests will be fast, isolated unit tests for the `Command` classes, using mock `ExecutionContexts`.

  2. **Integration Tests**: A small number of integration tests will verify that `ExecutionContext` correctly interacts with the system's `git` binary.

  3. **Feature Tests**: A minimal set of high-level tests will ensure the public facade on `Git::Repository` works end-to-end.

- **Reduced Filesystem Dependency**: This new structure will dramatically reduce the suite's reliance on slow and brittle filesystem fixtures.

## 5. Impact on Users: Breaking Changes for v5.0.0

This redesign is a significant undertaking and will be released as version 5.0.0. It includes several breaking changes that users will need to be aware of when upgrading.

- **`Git::Lib` is Removed**: Any code directly referencing `Git::Lib` will break.

- **g.lib Accessor is Removed**: The `.lib` accessor on repository objects will be removed.

- **Internal Methods Relocated**: Methods that were previously accessible via g.lib will now be private implementation details of the new command classes and will not be directly reachable.

Users should only rely on the newly defined public interface.

