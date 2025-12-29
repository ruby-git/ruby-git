# GitHub Copilot Instructions for ruby-git

## Project Overview

ruby-git is a Ruby gem that provides a Ruby interface to Git repositories.

The git gem wraps system calls to the `git` command line and provides an API to:
- Create, read, and manipulate Git repositories
- Work with branches, commits, tags, and remotes
- Inspect repository history and objects
- Perform Git operations like merge, clone, fetch, push, etc.
- Handle complex interactions including branching, merging, and patch generation

**Current Status:** Stable project supporting Ruby 3.2.0+ minimum and Git 2.28.0+.
Compatible with MRI Ruby on Mac, Linux, and Windows.

## Architecture & Module Organization

ruby-git follows a modular architecture:

- **Git::Base** - Main interface for repository operations (most major actions)
- **Git::Lib** - Low-level Git command execution via system calls
- **Git::CommandLine** - Handles Git command construction and execution with timeout
  support
- **Git Objects** - Repository objects (Commit, Tree, Blob, Tag) via `Git::Object`
- **Git::Status** - Working directory status (tracked/untracked/modified files)
- **Git::Diff** - Diff operations returning file-level patches and statistics
- **Git::Log** - Enumerable query builder for commit history
- **Git::Branch/Branches** - Branch management (local and remote)
- **Git::Remote** - Remote repository references
- **Git::Worktree/Worktrees** - Git worktree support
- **Git::Stash/Stashes** - Stash management

Key directories:

- `lib/git/` - Core library code
- `tests/units/` - Test::Unit test suite
- `doc/` - YARD-generated documentation
- `pkg/` - Built gem packages
- `redesign/` - Architecture redesign documentation

## Coding Standards

### Ruby Style

- Use `frozen_string_literal: true` at the top of all Ruby files
- Follow Ruby community style guide (Rubocop-compatible)
- Require Ruby 3.2.0+ features and idioms
- Use keyword arguments for methods with multiple parameters
- Prefer `private` over `private :method_name` for method visibility
- Use pattern matching for complex conditional logic where appropriate

### Code Organization

- Keep classes focused and single-responsibility
- Use modules for mixins and namespace organization
- Place related classes in the same file only if they're tightly coupled
- One public class per file as a general rule
- Core library code organized in `lib/git/` directory

### Naming Conventions

- Classes/Modules: PascalCase (e.g., `Git::Base`, `Git::Branch`, `Git::CommandLine`)
- Methods/variables: snake_case (e.g., `current_branch`, `ls_files`, `commit_all`)
- Constants: UPPER_SNAKE_CASE (e.g., `VERSION`)
- Predicate methods: end with `?` (e.g., `bare?`, `success?`, `exist?`)
- Dangerous methods: end with `!` if they modify in place
- Instance variables: `@variable_name`
- Avoid class variables; prefer class instance variables or constants

## Design Philosophy

**Note:** As of v2.x, this design philosophy is aspirational. Future versions may
include interface changes to fully align with these principles.

The git gem is designed as a lightweight wrapper around the `git` command-line tool,
providing a simple and intuitive Ruby interface for programmatically interacting with
Git.

### Principle of Least Surprise

- Do not introduce unnecessary abstraction layers
- Do not modify Git's core functionality
- Maintain close alignment with the existing `git` command-line interface
- Avoid extensions or alterations that could lead to unexpected behaviors
- Allow users to leverage their existing knowledge of Git

### Direct Mapping to Git Commands

- Git commands are implemented within the `Git::Base` class
- Each method should directly correspond to a `git` command
- Example: `git add` → `Git::Base#add`, `git ls-files` → `Git::Base#ls_files`
- When a single Git command serves multiple distinct purposes, use the command name
  as a prefix followed by a descriptive suffix
  - Example: `#ls_files_untracked`, `#ls_files_staged`
- Introduce aliases to provide more user-friendly method names where appropriate

### Parameter Naming

- Parameters are named after their corresponding long command-line options
- Ensures familiarity for developers already accustomed to Git
- Note: Not all Git command options are supported

### Output Processing

- Translate Git command output into Ruby objects for easier programmatic use
- Ruby objects often include methods that allow for further Git operations
- Provide additional functionality while staying true to underlying Git behavior

### Documentation

- Use YARD syntax for all public methods
- Include `@param`, `@return`, `@raise`, `@example` tags
- Document edge cases, platform differences, and security considerations
- Keep method documentation up-to-date with implementation
- Add `@api private` for internal-only methods
- Document Git version requirements and compatibility

Example:

```ruby
# Opens a Git repository
#
# @param [String, Pathname] path The path to the working directory or .git directory
# @param [Hash] options The options for this command (see list of valid options below)
# @option options [Logger] :log A logger to use for Git operations
# @option options [Numeric] :timeout Maximum seconds to wait for Git commands (0 for no timeout)
# @return [Git::Base] an object that can execute git commands in the context of the repository
# @raise [ArgumentError] if path is not a valid Git repository
# @example Open a repository
#   git = Git.open('/path/to/repo')
#   puts git.log.first.message
# @api public
def self.open(path, options = {})
  # implementation
end
```

## Key Technical Details

### Git Command Execution

All Git commands are executed through the `Git::CommandLine` class which:
- Constructs Git commands with proper argument escaping
- Handles environment variables and working directory context
- Manages command execution with timeout support
- Captures stdout, stderr, and exit status
- Raises appropriate errors on command failures

### Major Classes and Their Responsibilities

1. **Git::Base**: The main repository interface
   - Entry point for most Git operations
   - Delegates to `Git::Lib` for low-level operations
   - Manages working directory, index, and repository references
   - Returns domain objects (Branch, Status, Diff, Log, etc.)

2. **Git::Lib**: Low-level command execution
   - Executes Git commands via `Git::CommandLine`
   - Parses Git command output
   - Minimal business logic - focuses on command execution

3. **Git::CommandLine**: Command execution layer
   - Builds Git command arrays with proper escaping
   - Manages subprocess execution with timeout support
   - Handles timeout and error conditions
   - Returns `Git::CommandLineResult` with output and status

4. **Git Objects** (Commit, Tree, Blob, Tag)
   - Immutable representations of Git objects
   - Lazy-loaded from repository
   - Methods for inspecting object properties and relationships

5. **Git::Status**: Working directory status
   - Enumerable collection of `Git::Status::StatusFile`
   - Tracks added, changed, deleted, and untracked files
   - Similar to `git status` command output

6. **Git::Diff**: Diff operations
   - Enumerable collection of `Git::Diff::DiffFile`
   - Per-file patches and statistics
   - Total insertion/deletion statistics

7. **Git::Log**: Commit history query builder
   - Chainable methods for building log queries
   - Enumerable returning `Git::Object::Commit` objects
   - Supports filtering by path, date range, author, etc.

### Path Handling

ruby-git handles three types of paths:
- **Working directory paths**: Relative to repository working directory
- **Git directory paths**: The `.git` directory location
- **Object paths**: Paths within Git tree objects

The gem provides `Git::Path` and `Git::EscapedPath` for handling paths with special
characters.

### Error Handling

The gem raises errors that inherit from `Git::Error`:
- `Git::FailedError`: Git command exited with non-zero status
- `Git::SignaledError`: Git command was killed by a signal
- `Git::TimeoutError`: Git command exceeded timeout (subclass of SignaledError)
- `ArgumentError`: Invalid arguments passed to methods

All Git command errors include the command, output, and status for debugging.

## Development Methodology

### Test Driven Development (TDD)

**This project strictly follows TDD practices. All code MUST be written using the
Red-Green-Refactor cycle.**

You are an expert software engineer following a strict Test-Driven Development (TDD)
workflow.

**Core TDD Principles**

- **Never write production code without a failing test first.**
- **Bug Fixes Start with Tests:** Before fixing any bug, write a failing test that
  demonstrates the bug and fails in the expected way. Only then fix the code to make
  the test pass.
- **Tests Drive Design:** Let the test dictate the API and architecture. If the test
  is hard to write, the design is likely wrong. When this happens, stop and suggest
  one or more design alternatives. Offer to stash any current changes and work on the
  design improvements first before continuing with the original task.
- **Write Tests Incrementally:** Focus on small, atomic tests that verify exactly one
  logical behavior.
- **No Implementation in Advance:** Only write the code strictly needed to pass the
  current test.

**Phase 1: Analysis & Planning** Before writing any code:

1. Analyze the request.
2. Create a checklist of small, isolated implementation steps.

**Phase 2: The RED-GREEN-REFACTOR Cycle** Execute the checklist items one by one.
Build each checklist item using multiple RED-GREEN iterations if needed. Follow with
a REFACTOR step before moving to the next checklist item.

You must complete the _entire_ cycle for a checklist item before moving to the next.

**Completion Criteria for a Checklist Item:**
- All functionality for that item is implemented
- All related tests pass
- Code is clean and well-factored
- Ready to move to the next independent item

1. **RED (The Failing Test):**

   - Write a single, focused, failing test or extend an existing test for the current
     checklist item
   - Only write enough of a test to get an expected, failing result (the test should
     fail for the *right* reason)
   - **Execute** the test using the terminal command `bundle exec ruby -I lib:tests
     tests/units/test_name.rb` or `bin/test test_name` and **analyze** the output.
   - Confirm it fails with an _expected_ error (e.g., assertion failure or missing
     definition).
   - **Validation:** If the test passes without implementation, the test is invalid
     or the logic already exists—revise or skip.

2. **GREEN (Make it Pass):**

   - Write the _minimum amount of code_ required to make the test pass.
   - It is acceptable to use hardcoded values or "quick and dirty" logic here just to
     get to green, even if this means intentionally writing clearly suboptimal code
     that you will improve during the REFACTOR step.
   - **Execute** the test again using the terminal command `bundle exec ruby -I
     lib:tests tests/units/test_name.rb` or `bin/test test_name` and **verify** it
     passes.
   - _Constraint:_ Do not implement future features or optimizations yet.

3. **REFACTOR (Make it Right):**

   - **Critical Step:** You must consider refactoring _before_ starting the next
     checklist item.
   - Remove duplication, improve variable names, and apply design patterns.
   - Skip this step only if the code is already clean and simple—avoid
     over-engineering.
   - **Execute** all tests using the terminal command `bundle exec rake` and
     **verify** they still pass.
   - **Test Independence:** Verify tests can run independently in any order.

**Additional Guidelines**

These supplement the RED-GREEN-REFACTOR cycle:

- If the implementation reveals a complex logic gap, add it to your checklist, but
  finish the current cycle first.
- Do not generate a "wall of text." Keep code blocks small and focused on the current
  step.
- Stop and ask for clarification if a step is ambiguous.

#### Example TDD Session

```ruby
# Step 1: Write first failing test
require_relative '../test_helper'

class TestGitBranch < Test::Unit::TestCase
  def setup
    @repo = clone_working_repo
    @git = Git.open(@repo)
  end

  def test_creates_new_branch
    @git.branch('feature').create
    assert @git.branches.local.map(&:name).include?('feature')
  end
end

# Run test → RED (method doesn't exist or doesn't work)

# Step 2: Minimal code to pass
class Git::Branch
  def create
    @base.lib.branch_new(@name)
  end
end

# Run test → GREEN

# Step 3: Write next failing test
def test_checks_out_new_branch
  branch = @git.branch('feature').create
  @git.checkout(branch)
  assert_equal 'feature', @git.current_branch
end

# Run test → RED (checkout doesn't work correctly)

# Step 4: Implement actual functionality
def checkout
  @base.lib.checkout(@name)
  @base.lib.branch_current
end

# Run test → GREEN

# Step 5: REFACTOR - Improve code organization
def checkout
  @base.checkout(@name)
end

# Run all tests → Still GREEN
# Checklist item complete, move to next item...
```

## Testing Requirements

### Test Framework

- Use **Test::Unit** for all tests
- Tests located in `tests/units/` directory
- Test files named `test_*.rb`
- Main test helper: `tests/test_helper.rb` provides utility methods
- Uses Mocha for mocking

### Coverage Target

Maintain **high code coverage** through TDD practice.

### Test Organization

```ruby
require_relative '../test_helper'

class TestGitOpen < Test::Unit::TestCase
  def setup
    @repo = clone_working_repo
  end

  def test_opens_existing_repository
    git = Git.open(@repo)
    assert_kind_of Git::Base, git
  end

  def test_raises_on_invalid_path
    assert_raises(ArgumentError) do
      Git.open('/nonexistent/path')
    end
  end
end
```

### Critical Test Cases

- Repository operations (open, init, clone)
- Branch operations (create, checkout, delete, merge)
- Commit operations (add, commit, reset)
- Remote operations (fetch, pull, push)
- Status and diff operations
- Log queries with various filters
- Timeout handling for long-running operations
- Error conditions (invalid repos, failed commands, timeouts)
- Cross-platform compatibility (Mac, Linux, Windows)
- Path handling with special characters and Unicode
- Encoding issues with different character sets
- Git version compatibility (minimum 2.28.0)

### Test Helpers

The `Test::Unit::TestCase` base class provides:
- `clone_working_repo`: Creates a temporary clone of test repository
- `create_temp_repo`: Creates a temporary repository for testing
- `with_temp_dir`: Provides a temporary directory for tests
- `git_teardown`: Automatically cleans up temporary files
- Test fixtures in `tests/files/`

## Running Tests

```bash
# Run all tests
bundle exec rake test

# Run specific test file
bundle exec ruby -I lib:tests tests/units/test_base.rb

# Run specific test by name
bundle exec ruby -I lib:tests tests/units/test_base.rb -n test_opens_existing_repository

# Run tests in Docker (tests against multiple Ruby versions)
bin/test-in-docker

# View coverage report
open coverage/index.html
```

## Ruby and Git Version Compatibility

### Current Support

- Minimum Ruby: 3.2.0
- Minimum Git: 2.28.0 or greater
- Actively tested on: MRI Ruby 3.2+
- Platforms: Mac, Linux, Windows
- CI tests on multiple Ruby versions and platforms

### Dependencies

- `activesupport` (>= 5.0) - For utilities and deprecation handling
- `addressable` (~> 2.8) - For URI parsing
- `process_executer` (~> 4.0) - For subprocess execution with timeout
- `rchardet` (~> 1.9) - For character encoding detection

### Platform Considerations

**Cross-Platform Compatibility:**
- Git command execution works on all platforms
- Handle Windows path separators and drive letters appropriately
- Test Git operations on all platforms
- Be aware of platform-specific Git behavior (e.g., line endings, permissions)
- Windows has different path handling and file system behavior

**Git Version Compatibility:**
- Minimum Git version is 2.28.0
- Test with different Git versions when using newer features
- Gracefully handle missing Git features on older versions
- Document Git version requirements for specific features

**Encoding Handling:**
- Handle different default encodings across platforms
- Use `rchardet` for automatic encoding detection
- Test with UTF-8 and other encodings
- Binary vs. text mode differences on Windows

## Configuration & Settings

### Gemspec Configuration

Located in `git.gemspec`:

- Runtime dependencies: activesupport, addressable, process_executer, rchardet
- Development dependencies: test-unit, mocha, rake, rubocop, yard, etc.
- `required_ruby_version >= 3.2.0`
- Git requirement: `git 2.28.0 or greater`

### Rake Configuration

Located in `Rakefile`:

- Default task runs Test::Unit tests
- Rubocop for linting
- YARD for documentation generation
- Tasks defined in `tasks/` directory

## Error Handling

- Raise specific exception classes from `Git::Error` hierarchy
- Always include relevant context (command, status, output) in exceptions
- Provide helpful error messages that guide users to solutions
- Handle platform-specific errors gracefully
- Document all error conditions in method YARD docs
- Never swallow exceptions silently
- Use `ArgumentError` for invalid method arguments

**Error Design Principles:**
- Inherit from `Git::Error` for all gem-specific errors
- `Git::FailedError`: Command failed (non-zero exit)
- `Git::SignaledError`: Command killed by signal
- `Git::TimeoutError`: Command exceeded timeout (subclass of SignaledError)
- Include structured data (command, output, status) for debugging
- Make errors programmatically inspectable
- Distinguish between user errors and runtime errors

## Performance Considerations

### Git Command Execution

- Commands execute with configurable timeout (global or per-command)
- Clean up resources properly
- Handle large repository operations efficiently
- Subprocess execution is handled internally by `Git::CommandLine`

### Memory Management

- Lazy-load Git objects when possible
- Stream large outputs rather than buffering everything
- Be mindful of memory usage with large diffs and logs
- Clean up temporary files and resources

### Repository Operations

- Minimize Git command executions
- Cache Git objects when appropriate
- Use batch operations where possible
- Consider performance implications of deep history traversal

## Documentation

- Keep CHANGELOG.md updated with all user-facing changes
- Update README.md examples when API changes
- Document breaking changes prominently in CHANGELOG
- Use inline YARD comments for comprehensive API documentation
- Generate docs with `bundle exec yard doc`
- Ensure examples in documentation actually work
- Document platform-specific behavior
- Document Git version requirements for features
- Include security considerations (e.g., shell injection risks with certain
  operations)

## Key Documents

Always consult these before implementing features:

- **README.md** - Project overview, usage examples, and getting started
- **CHANGELOG.md** - Version history, breaking changes, and migration guides
- **LICENSE** - MIT License
- **CONTRIBUTING.md** - Contribution guidelines
- **MAINTAINERS.md** - Maintainer information
- **redesign/** - Architecture redesign documentation
- Full YARD documentation at https://rubydoc.info/gems/git/

## Code Quality Checklist

Before committing, ensure:

**Testing:**
- [ ] **TDD process followed** - Tests written before implementation
- [ ] All tests pass (`bundle exec rake test`)
- [ ] No Ruby warnings when running tests

**Code Style:**
- [ ] Code follows Ruby style conventions (Rubocop)
- [ ] YARD documentation for public methods

**Compatibility:**
- [ ] Backward compatibility maintained (unless breaking change)
- [ ] Cross-platform compatibility considered (Windows, macOS, Linux)
- [ ] Git version compatibility (minimum 2.28.0)

**Documentation & Safety:**
- [ ] CHANGELOG.md updated for user-facing changes
- [ ] Security considerations addressed (command injection, etc.)
- [ ] Resource cleanup (file handles, temporary files)

## Git Commit Conventions

**CRITICAL:** All commits **MUST** adhere to the [Conventional Commits
standard](https://www.conventionalcommits.org/en/v1.0.0/). Commits not adhering to
this standard will cause the CI build to fail. PRs will not be merged if they include
non-conventional commits.

### Conventional Commit Format

The simplest format: `type: description`

**Valid types** (see [.commitlintrc.yml](../.commitlintrc.yml) for full list):
- `feat:` - New user facing functionality
- `fix:` - Bug fixes
- `docs:` - Documentation only
- `test:` - Adding/updating tests
- `refactor:` - Code restructuring without changing behavior
- `chore:` - Chores and maintenance (e.g., tooling, dependency bumps)
- `perf:` - Performance improvements
- `build:` - Build system or external dependency changes
- `ci:` - Continuous integration configuration and scripts
- `style:` - Code style and formatting only (no functional changes)
- `revert:` - Revert a previous commit

**Description rules:**
1. Must NOT start with an upper case letter
2. Must be no more than 100 characters
3. Must NOT end with punctuation

**Examples:**
- `feat: add the --merges option to Git::Lib.log`
- `fix: exception thrown by Git::Lib.log when repo has no commits`
- `docs: add conventional commit announcement to README.md`

**Breaking changes** must include an exclamation mark before the colon:
- `feat!: removed Git::Base.commit_force`

**Full format:**
```
type[optional scope][!]: description

[optional body]

[optional footer(s)]
```

**Version incrementing:**
- Breaking change → **major** version increment
- New feature → **minor** version increment
- Neither → **patch** version increment

**Pre-commit hook:** Run `bin/setup` in the project root to install a git pre-commit
hook that validates conventional commit messages before pushing to GitHub.

This project uses [release-please](https://github.com/googleapis/release-please) for
automated releases based on conventional commits.

## Pull Request Guidelines

**Branch Strategy:**

1. Ensure local main is up-to-date: `git fetch origin main`
2. Create a new branch from origin/main: `git checkout -b feature/your-feature
   origin/main`
3. Make your changes following TDD
4. Ensure all tests pass and code quality checks pass
5. Push the branch and create a PR

**PR Description Should Include:**

- What problem does this solve?
- What approach was taken?
- Any breaking changes?
- Testing performed (manual and automated)
- Platform-specific considerations
- Related issues/PRs

**Review Checklist:**

- All commits follow Conventional Commits standard (CI will fail otherwise)
- Tests demonstrate the change works
- All tests pass (`bundle exec rake default`)
- Documentation updated (YARD comments for public methods)
- CHANGELOG.md will be automatically updated by release-please
- No breaking changes without major version bump or exclamation mark in commit
- At least one approval from a project maintainer required before merge

## Special Considerations

### Security

- **Command Injection**: When using single-string commands, be aware of shell
  injection risks
- **Input Validation**: Validate and sanitize user input before passing to commands
- **File Permissions**: Be careful with file descriptors and permissions
- **Resource Limits**: Consider timeout and resource consumption
- Document security implications in YARD comments

## Current Priorities

Based on project status and maintenance needs:

### Stability and Compatibility

1. Maintain Ruby 3.2+ compatibility
2. Keep cross-platform support (Mac, Linux, Windows)
3. Support Git 2.28.0+ versions
4. Ensure backward compatibility within major versions

### Code Quality

1. Maintain high test coverage
2. Follow TDD strictly for all changes
3. Keep Rubocop violations at zero
4. Comprehensive YARD documentation

### Feature Enhancements

Consider these only after TDD test is written:
- Improved worktree support
- Enhanced Git LFS integration
- Better handling of large repositories
- Performance optimizations for common operations
- Additional Git operations as needed

### Documentation

- Keep README.md examples current and comprehensive
- Add more real-world examples
- Document common pitfalls and gotchas
- Platform-specific behavior documentation
- Complete architecture redesign documentation in `redesign/`

## Useful Commands

```bash
# Install dependencies and setup pre-commit hooks
bin/setup

# Or just install dependencies
bundle install

# Run full test suite
bundle exec rake test

# Run specific test file using bin/test (preferred method)
bin/test test_base

# Run multiple test files
bin/test test_object test_archive

# Run all unit tests using bin/test
bin/test

# Run tests with a different Git version
GIT_PATH=/path/to/git/bin-wrappers bin/test

# Alternative: run specific test file directly
bundle exec ruby -I lib:tests tests/units/test_base.rb

# Run specific test by name
bundle exec ruby -I lib:tests tests/units/test_base.rb -n test_opens_existing_repository

# Run tests in Docker
bin/test-in-docker

# Generate YARD documentation
bundle exec yard doc

# Start documentation server
bundle exec yard server --reload

# Build gem
bundle exec rake build

# Check code style
bundle exec rubocop

# Auto-fix code style issues
bundle exec rubocop -a

# View coverage report (if configured)
open coverage/index.html
```

## Getting Help

- Review README.md for usage examples and architecture
- Check CHANGELOG.md for version history and breaking changes
- Read inline YARD documentation in source code
- Browse full API docs at https://rubydoc.info/gems/git/
- Look at existing tests for testing patterns
- Check CI configuration in `.github/workflows/` for supported platforms
- Review architecture redesign docs in `redesign/` directory

## Important Implementation Notes

### When Working with Git Commands

- Always use `Git::CommandLine` for command execution
- Handle command output encoding properly
- Consider timeout implications for long-running operations
- Test with various Git versions (minimum 2.28.0)
- Properly escape arguments and paths
- Handle Git error messages and exit codes

### When Working with Paths

- Use `Git::Path` for path handling
- Use `Git::EscapedPath` for paths with special characters
- Handle Windows path separators appropriately
- Test with Unicode filenames
- Consider relative vs. absolute paths

### When Working with Repository Objects

- Lazy-load objects when possible
- Cache objects appropriately
- Handle missing or invalid objects gracefully
- Test with various object types (commits, trees, blobs, tags)
- Consider performance with large repositories

### When Working with Encoding

- Use `rchardet` for encoding detection
- Handle different platform encodings
- Test with UTF-8, ASCII, and other encodings
- Be aware of Git's encoding configuration
- Handle binary files appropriately

### When Working with Timeouts

- Use global timeout configuration or per-command overrides
- Handle `Git::TimeoutError` appropriately
- Test timeout behavior with long-running operations
- Document timeout implications in YARD comments
- Timeout support is built into the command execution layer

### Security Considerations

- Be careful with user-supplied paths and arguments
- Validate and sanitize inputs
- Use proper argument escaping via `Git::CommandLine`
- Document security implications
- Consider Git hook execution risks
