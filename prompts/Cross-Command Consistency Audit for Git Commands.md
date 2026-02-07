## Cross-Command Consistency Audit for `Git::Commands::*`

### Goal

Verify structural and stylistic consistency across all command classes within a single module (e.g., all classes under `Git::Commands::Diff`). Sibling commands that implement different output formats of the same git subcommand should follow identical patterns unless there is a deliberate, documented reason to diverge.

### Input

You will be given all command source files within a module, their unit tests, and their integration tests.

### What to Check

#### 1. ARGS Definition Structure

All sibling commands should follow the same structural pattern in their `ARGS` block.

**Check:**
- [ ] **Same ordering convention** — literals → flag_options → flag_or_value_options → operands → value_options
- [ ] **Same literal order** — the subcommand name comes first, then format-specific flags, then shared flags (e.g., `-M` for rename detection)
- [ ] **Shared options use identical DSL calls** — if all siblings support `:cached`, they should all define it the same way (`flag_option %i[cached staged]`, not `flag_option :cached` in one and `flag_option %i[cached staged]` in another). Options with long/short forms should consistently use aliases (e.g., `%i[force f]`) rather than `args:` overrides
- [ ] **Shared options appear in the same relative position** — e.g., `flag_option %i[cached staged]` is always the first flag_option after literals
- [ ] **Options unique to one command are clearly intentional** — e.g., only Patch has `--src-prefix`/`--dst-prefix`, only Numstat lacks `:find_copies`

Produce a side-by-side comparison table:

| ARGS entry | Command A | Command B | Command C | Consistent? |
|------------|-----------|-----------|-----------|-------------|
| Subcommand | `literal 'diff'` | `literal 'diff'` | `literal 'diff'` | Yes |
| Format flag | `literal '--numstat'` | `literal '--patch'` | `literal '--raw'` | Yes (expected difference) |
| Rename detection | `literal '-M'` | `literal '-M'` | `literal '-M'` | Yes |
| cached/staged | `flag_option %i[cached staged]` | `flag_option %i[cached staged]` | `flag_option %i[cached staged]` | Yes |
| find_copies | *(not defined)* | `flag_option :find_copies, args: '-C'` | `flag_option :find_copies, args: '-C'` | — (intentional) |

#### 2. `#call` Method Implementation

The `#call` method body should be identical across siblings (modulo the ARGS constant name, which is always `ARGS`).

**Check:**
- [ ] **Same `bind` pattern** — `ARGS.bind(*, **)`
- [ ] **Same `raise_on_failure: false`** — all siblings use the same value
- [ ] **Same exit code threshold** — all siblings raise `FailedError` at the same threshold (e.g., `>= 2` for diff commands)
- [ ] **Same error class** — all siblings raise `Git::FailedError`
- [ ] **Same inline comment** — e.g., `# git diff exit codes: 0 = no diff, 1 = diff found, 2+ = error`

If any sibling diverges, flag it as an issue unless the divergence is justified by different git behavior.

#### 3. Class-Level YARD Documentation

**Check:**
- [ ] **Same structure** — one-line summary, description, `@see` to parent module, `@see` to git docs, `@api private`
- [ ] **Same `@see` targets** — all siblings link to the same parent module and same git documentation URL
- [ ] **Same `@api` tag** — all siblings are `@api private` (or all public)
- [ ] **Consistent blank line formatting** — blank comment lines between `@see` and before `@api`, and before new paragraphs within tag descriptions (e.g., `Alias:` lines)

#### 4. `#call` YARD Overloads

**Check:**
- [ ] **Same set of overloads** — all siblings define the same calling conventions (unless a command doesn't support a particular convention)
- [ ] **Same overload order** — overloads appear in the same sequence across all siblings
- [ ] **Same `@param` entries** — identical parameter names, types, and descriptions
- [ ] **Shared `@option` entries are identical** — same name, type, default value, and description text for options that exist in all siblings

Produce a comparison for shared options:

| Option | Command A | Command B | Consistent? |
|--------|-----------|-----------|-------------|
| `:pathspecs` | `[Array<String>] :pathspecs (nil) zero or more pathspecs to limit diff to` | `[Array<String>] :pathspecs (nil) zero or more pathspecs to limit diff to` | Yes |
| `:find_copies` | *(not applicable)* | `[Boolean] :find_copies (false) detect copies as well as renames (adds \`-C\`)` | — |
| `:dirstat` | `[Boolean, String] :dirstat (nil) include directory statistics. Pass true for default, or a string like 'lines,cumulative' for options.` | Same | Yes |

**Common inconsistencies to catch:**
- Default value `(nil)` in one file vs `(false)` in another for the same boolean flag
- Description says "detect copies" in one file but "detect copies as well as renames (adds `-C`)" in another
- `@return` says "the result of calling" in one file but "return the result of" in another
- Missing blank lines between tags in some files but not others

#### 5. `#initialize` YARD Documentation

**Check:**
- [ ] **Same `@param` description** — all siblings use the same wording for the execution context parameter

#### 6. Unit Test Structure

**Check:**
- [ ] **Same context hierarchy** — siblings follow the same nesting pattern (e.g., `context 'with no arguments'`, `context 'with single commit'`, etc.)
- [ ] **Same context ordering** — contexts appear in the same order across all siblings
- [ ] **Shared options have matching test descriptions** — e.g., all use "includes the --cached flag" not "adds --cached flag" in one and "includes the --cached flag" in another
- [ ] **Same exit code tests** — identical `describe 'exit code handling'` block structure
- [ ] **Consistent use of `let(:static_args)`** — if one command extracts static args to a `let` block (because the literal list is long), evaluate whether siblings should do the same

Produce a comparison:

| Context | Command A test | Command B test | Consistent? |
|---------|---------------|---------------|-------------|
| No args | "runs diff with --numstat, --shortstat, and -M flags" | "runs diff with --raw, --numstat, --shortstat, and -M flags" | Yes (expected difference) |
| Cached | "includes the --cached flag" | "includes the --cached flag" | Yes |
| Staged alias | "accepts :staged alias" | "accepts :staged alias" | Yes |
| Exit code 0 | "returns successfully with exit code 0 when no differences" | "returns successfully with exit code 0 when no differences" | Yes |

#### 7. Integration Test Structure

**Check:**
- [ ] **Same number of tests** — all siblings should have the same smoke test + exit code test pattern
- [ ] **Same test descriptions** — identical wording for equivalent tests
- [ ] **Same test structure** — identical assertion patterns (e.g., all check `be_a(Git::CommandLineResult)` and `not_to be_empty`)
- [ ] **Same shared context** — all siblings use the same `include_context`
- [ ] **No output format assertions** — none of the siblings assert on git output format (that's testing git, not the command)

#### 8. `require` Statements

**Check:**
- [ ] **Same set of requires** — all siblings require the same dependencies (except format-specific parsers)
- [ ] **Same order** — requires in the same order

### Output

Produce:

1. **Summary table** — one row per aspect checked, with pass/fail per sibling
2. **Inconsistencies found** — detailed list of each inconsistency with the file, line, and what should change
3. **Recommended canonical form** — for each inconsistency, specify which sibling has the correct version that others should match (prefer the most complete/descriptive version)

| Aspect | Numstat | Patch | Raw | Status |
|--------|---------|-------|-----|--------|
| ARGS ordering | OK | OK | OK | Consistent |
| Exit code threshold | `>= 2` | `>= 2` | `>= 2` | Consistent |
| `@return` wording | "the result of calling" | "the result of calling" | "the result of calling" | Consistent |
| `:find_copies` default | N/A | `(false)` | `(false)` | Consistent |
| `:dirstat` description | 2-line | 2-line | 2-line | Consistent |
| Integration test count | 4 | 4 | 4 | Consistent |
| Unit test descriptions | OK | OK | OK | Consistent |
