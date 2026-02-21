# Review Backward Compatibility

Review `Git::Lib` methods for backward compatibility after commands are moved to
`Git::Commands::*` classes. This prompt guides the process of restoring backward
compatibility for a specific set of git commands while maintaining the benefits of
the new command infrastructure.

## How to use this prompt

Attach this file to your Copilot Chat context, then invoke it with the git
command name(s) to audit. Example:

```text
Remove methods added to Git::Lib since v4.3.0 for the `branch` git command
and ensure the remaining methods are backward compatible.
```

Replace `branch` with the specific git command(s) you want to audit (e.g.,
`worktree`, `tag`, `merge`, `reset`).

## Related prompts

- **Refactor Command to CommandLineResult** — migrating command classes to Base;
  the counterpart to this prompt's `Git::Lib` facade focus
- **Review Command Implementation** — class structure, phased rollout gates, and
  internal compatibility contracts

## Objective

For the specified git command(s), remove methods added to `Git::Lib` since v4.3.0 and ensure that remaining methods (which existed in v4.3.0) are backward compatible.

## Current Command Architecture Note

When auditing modern implementations, assume command classes follow `Git::Commands::Base`:

- classes use `class < Git::Commands::Base` with `arguments do ... end`
- command entrypoint is `call(*, **)` (inherited from `Base`)
- exit-status behavior is centralized via `allow_exit_status` declarations on the class

Because of this, backward-compatibility adaptation should happen in `Git::Lib`
methods (facade/adapter layer), not by reintroducing legacy execution logic inside
command classes.

## Instructions

### Branch setup

All work must be done on a feature branch. **Never commit or push directly to
`main`.**

Before starting, create a new branch:

```bash
git checkout -b <feature-branch-name>
```

All commits in this workflow go on the feature branch. When work is complete,
open a pull request — do not merge or push directly into `main`.

### Step 1: Identify Methods Added Since v4.3.0

1. Check out the v4.3.0 tag to examine the historical state:
   ```bash
   git checkout v4.3.0
   ```

2. Search `lib/git/lib.rb` for all methods related to the specified git command(s):
   ```bash
   grep -n "def <command_name>" lib/git/lib.rb
   ```

3. Document each method found, including:
   - Method name and signature
   - Return value type (String, Array, Hash, Boolean, etc.)
   - Exact return value format (e.g., `Array<[Integer, String]>`, `String` with specific content)

4. Return to the main branch:
   ```bash
   git checkout main
   ```

5. Search for the same command methods in the current version:
   ```bash
   grep -n "def <command_name>" lib/git/lib.rb
   ```

6. Create two lists:
   - **Legacy methods**: Methods that existed in v4.3.0 (must be preserved and made compatible)
   - **New methods**: Methods that don't exist in v4.3.0 (should be removed)

### Step 2: Remove New Methods

1. Identify all new methods that were added after v4.3.0
2. Remove these methods entirely from `lib/git/lib.rb`
3. Remove any `require` statements that are only used by the removed methods

### Step 3: Restore Backward-Compatible Implementations

For each legacy method that needs to be preserved:

1. **Use modern command infrastructure internally:**
   - Call the appropriate `Git::Commands::<Command>::*` class
   - Ensure all necessary command classes are required at the top of the file

2. **Convert return values to match v4.3.0 exactly:**
   - Compare the return type from the modern command with the v4.3.0 return type
   - If they differ, add conversion logic to transform the result
   - Modern commands typically return `CommandLineResult` objects with `.stdout`, `.stderr`, and `.status`
   - Legacy methods may have returned raw strings, arrays, or other types

3. **Create helper methods if needed:**
   - For complex conversions (e.g., parsing output into specific formats), create private helper methods
   - Name helpers clearly (e.g., `<command>_info_to_legacy`)
   - Place helpers near the bottom of the file in the private section

### Step 4: Add Required Dependencies

1. Ensure all necessary `require` statements are present:
   ```ruby
   require_relative 'git/commands/<command>/<action>'
   require_relative 'git/parsers/<command>' # if using parsers
   ```

2. Only keep requires for:
   - Command classes used by the legacy methods
   - Parsers needed for conversion
   - Remove requires for deleted commands

### Step 5: Verify the Changes

1. Check the diff to ensure:
   ```bash
   git diff lib/git/lib.rb
   ```
   - All new methods are removed
   - All legacy methods are present with correct signatures
   - Return value conversions are in place
   - Correct require statements are present

2. Verify that the implementation uses modern command classes:
   ```bash
   git diff lib/git/lib.rb | grep -E "^\+.*Git::Commands::<Command>"
   ```

3. Check the net line change (should be negative if removing methods):
   ```bash
   git diff --stat lib/git/lib.rb
   ```

## Example: Stash Commands

Here's how this process was applied to the `stash` commands:

### Legacy Methods (v4.3.0)
- `stashes_all` → returned `Array<[Integer, String]>` (index and message pairs)
- `stash_save(message)` → returned regex match result (truthy/falsy)
- `stash_apply(id)` → returned `String` (stdout)
- `stash_clear` → returned `String` (stdout)
- `stash_list` → returned `String` (stdout)

### New Methods (removed)
- `stash_branch`
- `stash_create`
- `stash_drop`
- `stash_pop`
- `stash_push`
- `stashes_list`
- `git_stash_show_*` methods

### Implementation Pattern

```ruby
# Requires at top of file
require_relative 'git/commands/stash/apply'
require_relative 'git/commands/stash/clear'
require_relative 'git/commands/stash/list'
require_relative 'git/commands/stash/push'
require_relative 'git/parsers/stash'

# Legacy method implementations
def stashes_all
  result = Git::Commands::Stash::List.new(self).call
  stashes = Git::Parsers::Stash.parse_list(result.stdout)
  stashes.map { |info| stash_info_to_legacy(info) }
end

def stash_save(message)
  result = Git::Commands::Stash::Push.new(self).call(message: message)
  result.stdout =~ /HEAD is now at/
end

def stash_apply(id = nil)
  result = Git::Commands::Stash::Apply.new(self).call(id)
  result.stdout
end

def stash_clear
  result = Git::Commands::Stash::Clear.new(self).call
  result.stdout
end

def stash_list
  result = Git::Commands::Stash::List.new(self).call
  result.stdout
end

# Helper method (in private section)
private

def stash_info_to_legacy(stash_info)
  [stash_info.index, stash_info.message]
end
```

## Key Principles

1. **Maintain exact v4.3.0 return values**: Don't change return types even slightly
2. **Use modern infrastructure internally**: Leverage `Git::Commands::*` classes for actual git operations
3. **Remove all new methods**: Don't try to make new methods backward compatible - just remove them
4. **Minimize changes**: Only modify what's necessary for backward compatibility
5. **Document conversions**: Make helper methods clear and well-named

## Validation Checklist

- [ ] Working on a feature branch (not `main`)
- [ ] Identified all methods for the command in v4.3.0
- [ ] Documented v4.3.0 return values exactly
- [ ] Removed all methods not present in v4.3.0
- [ ] Implemented legacy methods using modern command classes
- [ ] Added conversion logic where return types differ
- [ ] Created helper methods for complex conversions
- [ ] Updated require statements correctly
- [ ] Verified changes with git diff
- [ ] Net line count decreased (removed more than added)

## Usage

To apply this process, say:

> Remove methods added to Git::Lib since v4.3.0 for `<command_name>` git command(s) and ensure the remaining methods are backward compatible.

Replace `<command_name>` with the specific git command(s) you want to audit (e.g., `branch`, `merge`, `tag`, `reset`, etc.).
