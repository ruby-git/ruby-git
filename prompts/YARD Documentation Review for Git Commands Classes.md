## YARD Documentation Review for `Git::Commands::*` Classes

### Goal

Verify and fix YARD documentation for a `Git::Commands::*` class so that every `@option`, `@param`, `@return`, `@raise`, `@example`, `@see`, and `@overload` tag is complete, accurate, and consistent with sibling command classes.

### Input

You will be given one or more command source files from `lib/git/commands/`. Each file defines a class with:

- An `ARGS` constant (using the `Arguments` DSL) that defines the command-line interface
- An `#initialize` method accepting an `execution_context`
- A `#call` method that binds arguments, executes the command, and handles exit codes

### What to Check

#### 1. Class-level documentation

- [ ] One-line summary describing the command's purpose
- [ ] Brief description of what the command returns (output format)
- [ ] `@see` link to the parent module (e.g., `@see Git::Commands::Diff Git::Commands::Diff for usage examples`)
- [ ] `@see` link to the relevant git documentation (e.g., `@see https://git-scm.com/docs/git-diff git-diff documentation`)
- [ ] `@api private` tag

#### 2. `ARGS` constant

- [ ] Has a YARD comment (e.g., `# Arguments DSL for building command-line arguments`)

#### 3. `#initialize` method

- [ ] `@param execution_context [Git::ExecutionContext]` documented

#### 4. `#call` method — Overloads

Every valid calling convention must have its own `@overload` block. Typical overloads for diff-style commands:

| Overload | Signature | Description |
|----------|-----------|-------------|
| Working tree vs index | `call(**options)` | Compare the index to the working tree |
| No-index | `call(path1, path2, no_index:, **options)` | Compare two paths on the filesystem |
| Cached/staged | `call(commit = nil, cached:, **options)` | Compare the index to HEAD or named commit |
| Single commit | `call(commit, **options)` | Compare the working tree to the named commit |
| Two commits | `call(commit1, commit2, **options)` | Compare two commits |
| Merge commit | `call(merge_commit, range, **options)` | Show changes introduced by a merge commit |

Each overload must have:

- [ ] **`@example`** with a comment showing the equivalent git command, followed by Ruby usage
- [ ] **`@param`** for every positional parameter
- [ ] **`@option`** for every keyword option that applies to that overload

#### 5. `#call` method — Options completeness (CRITICAL)

**Every option defined in `ARGS` must appear as an `@option` tag in every overload where it is valid.** This is the most common source of gaps.

Cross-reference the ARGS definition against each overload:

| ARGS entry | Option name | Applies to |
|------------|-------------|------------|
| `flag_option %i[cached staged]` | `:cached` / `:staged` | Only the cached overload (it's a required keyword there) |
| `flag_option :merge_base` | `:merge_base` | Two-commits overload only |
| `flag_option :no_index` | `:no_index` | Only the no-index overload (required keyword) |
| `flag_option :find_copies, args: '-C'` | `:find_copies` | All overloads |
| `flag_or_value_option :dirstat` | `:dirstat` | All overloads |
| `value_option :pathspecs` | `:pathspecs` | All overloads |

Note: Options that are required keyword arguments in a specific overload (like `cached:` or `no_index:`) appear as `@param`, not `@option`, in that overload.

When an option uses an alias (e.g., `%i[force f]`, `%i[cached staged]`), document the canonical (first/long) name as the `@option` name and mention the alias in the description (e.g., `also available as \`:f\``). The long option name must always be first in the alias array since it determines the generated flag. When git has both long and short forms, prefer aliases over `args:` overrides — only use `args:` when no Ruby symbol maps to the correct git flag (e.g., `args: '-C'` for copy detection). For `args:` overrides, mention the actual CLI flag in the description (e.g., `(adds \`-C\`)`).

#### 6. `#call` method — `@return` and `@raise`

- [ ] `@return [Git::CommandLineResult]` with consistent wording: `the result of calling \`git <subcommand>\``
- [ ] `@raise [Git::FailedError]` with description: `if git returns exit code >= 2 (actual error)`

#### 7. Blank lines before every YARD tag

Every YARD tag (`@param`, `@option`, `@return`, `@raise`, `@example`, `@see`, `@api`, `@overload`) must be preceded by a blank comment line (`#`). This improves readability and ensures YARD parses tags correctly.

**Correct:**
```ruby
        #   @param commit [String] commit reference
        #
        #   @param options [Hash] command options
        #
        #   @option options [Array<String>] :pathspecs (nil) zero or more pathspecs to limit diff to
        #
        #   @option options [Boolean] :find_copies (false) detect copies as well as renames (adds `-C`)
```

**Incorrect** (missing blank lines between tags):
```ruby
        #   @param commit [String] commit reference
        #   @param options [Hash] command options
        #   @option options [Array<String>] :pathspecs (nil) zero or more pathspecs to limit diff to
        #   @option options [Boolean] :find_copies (false) detect copies as well as renames (adds `-C`)
```

The only exception is when a tag has a multi-line description — the continuation lines of the *same paragraph* immediately follow the tag without a blank line:

```ruby
        #   @option options [Boolean, String] :dirstat (nil) include directory statistics.
        #     Pass true for default, or a string like 'lines,cumulative' for options.
        #
        #   @option options [Boolean] :find_copies (false) detect copies as well as renames (adds `-C`)
```

However, a **new paragraph** within a tag description must be separated from the previous content by a blank comment line (`#`). Without this blank line, YARD treats it as a continuation of the previous paragraph rather than a distinct paragraph.

**Correct** (new paragraph separated by blank line):
```ruby
        #   @option options [Boolean] :force (nil) Allow deleting the branch irrespective of
        #     its merged status.
        #
        #     Alias: :f
```

**Incorrect** (missing blank line before new paragraph):
```ruby
        #   @option options [Boolean] :force (nil) Allow deleting the branch irrespective of
        #     its merged status.
        #     Alias: :f
```

#### 8. Consistency across sibling commands

When reviewing multiple commands in the same module (e.g., Numstat, Patch, Raw under `Git::Commands::Diff`):

- [ ] **Default values** for shared options must match (e.g., all use `(false)` for boolean flags, `(nil)` for optional values)
- [ ] **Description text** for shared options must be identical (e.g., `:find_copies` always says `detect copies as well as renames (adds \`-C\`)`)
- [ ] **`@return` wording** must follow the same pattern
- [ ] **Formatting** must be consistent: blank lines between all tags, consistent use of `Pass true for default, or a string like 'lines,cumulative' for options.` for flag-or-value options

#### 9. Avoid Implementation Details

Keep YARD documentation focused on the **command interface** — describe *what* the caller can expect, not *how it works internally*.

There are two distinct categories to watch for:

**Internal mechanics (avoid entirely):**
- [ ] Git flag names in option descriptions (e.g., "adds `-r` flag", "adds `--ignore-case` flag")
- [ ] Internal format strings or parsing strategy (e.g., "uses `--format` to retrieve structured data")
- [ ] Internal implementation steps (e.g., "captures branch information before deletion")

**Externally visible behavior (keep, but phrase from the caller's perspective):**
- [ ] Describe what the caller gets, not what the code does internally

  **Avoid (implementation-focused):** "filters out detached HEAD entries"

  **Prefer (caller-focused):** "does not include detached HEAD entries in the result"

**Always keep:**
- [ ] Functional descriptions of what options do (e.g., "List only remote-tracking branches")
- [ ] Observable behavior the caller needs to know (e.g., "does not raise an error for partial failures")
- [ ] Return types and exceptions

**Example — Too much detail (avoid):**
```ruby
# @option options [Boolean] :all (nil) List both local and remote branches (adds `-a` flag).
```

**Example — Appropriate level (prefer):**
```ruby
# @option options [Boolean] :all (nil) List both local and remote branches.
```

**Rationale:** Internal details clutter the API documentation and become outdated as the implementation evolves. The Commands layer returns `CommandLineResult` — parsing, formatting, and data structure decisions belong in the facade layer, not in the Commands documentation.

### Common Issues to Watch For

1. **Option only documented in first overload** — e.g., `:find_copies` in `call(**options)` but missing from `call(commit, **options)` and others
2. **Inconsistent defaults** — e.g., `(nil)` in one file but `(false)` in another for the same boolean flag
3. **Missing detail** — e.g., `:find_copies` says "detect copies" in one file but "detect copies as well as renames (adds `-C`)" in another
4. **`@return` wording drift** — e.g., "return the result of" vs. "the result of calling"
5. **Missing blank lines between tags** — Every `@param`, `@option`, `@see`, `@api`, `@return`, `@raise` must have a blank comment line before it
6. **Missing blank line before new paragraph within a tag** — Additional paragraphs within a tag description (e.g., `Alias: :f` after the main description) must be separated by a blank comment line, otherwise YARD merges them into the previous paragraph
7. **Options that don't exist in ARGS** — Don't document options the command doesn't support (e.g., Numstat has no `:find_copies`)
8. **Implementation details in documentation** — Flag names ("adds `-r`"), internal format strings, parsing strategy. Externally visible behavior is fine but should be phrased from the caller's perspective

### Output

For each file, produce:
1. A table of issues found (or "No issues" if clean)
2. The corrected YARD documentation for any blocks that need changes
