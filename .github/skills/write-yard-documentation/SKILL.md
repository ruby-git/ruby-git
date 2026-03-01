---
name: write-yard-documentation
description: "Guides documenting Ruby source code with YARD doc comments. Use when writing new code, generating missing docs, updating examples, fixing doc errors, or checking documentation coverage."
---

# YARD Documentation Workflow

Guides documenting Ruby source code with YARD doc comments and verifying the generated YARD documentation.

## Contents

- [Contents](#contents)
- [How to use this skill](#how-to-use-this-skill)
- [Related skills](#related-skills)
- [Documentation Standards](#documentation-standards)
  - [YARD Formatting Rules](#yard-formatting-rules)
  - [Element-Specific Rules](#element-specific-rules)
- [Step 1: Identify What Needs Documentation](#step-1-identify-what-needs-documentation)
- [Step 2: Write Documentation](#step-2-write-documentation)
- [Step 3: Verify Documentation](#step-3-verify-documentation)
- [Step 4: Update Prose Documentation](#step-4-update-prose-documentation)
- [Command Reference](#command-reference)

## How to use this skill

Attach this file to your Copilot Chat context, then invoke it with the source
files that need YARD updates. Use it when adding new APIs, fixing doc warnings,
or improving existing YARD quality and examples.

## Related skills

- [Review Command YARD Documentation](../review-command-yard-documentation/SKILL.md) — auditing YARD docs on `Git::Commands::Base` subclasses for completeness and correctness

## Documentation Standards

ruby-git uses YARD for API documentation:

All classes, modules, constants, attributes, and methods must have YARD
documentation. Private elements require a short description, `@param`, `@return`,
and `@raise` tags, but no `@example`.

### YARD Formatting Rules

Doc comments are rendered as **markdown** via the redcarpet gem. Write all
free-text descriptions, tag values, and examples using markdown syntax. These rules
apply to all documentation regardless of element type:

**Blank lines around tags**

Every YARD tag (`@param`, `@return`, `@raise`, `@example`, `@api`, etc.) must be
preceded by a blank comment line (`#`). Tags of the same kind may be grouped
together without blank lines between them, but the group as a whole must be preceded
by a blank line.

**Short descriptions**

The short description (the first line of any doc comment, or the inline text of a
`@param`, `@return`, `@raise`, etc. tag) must:

- Be a single sentence
- Be fewer than 80 characters
- Not end with punctuation (no trailing period, comma, or colon)

If more explanation is needed, use additional paragraphs after the short description.
Separate each paragraph from the next with a blank comment line (`#`). Wrap
individual lines at 90 characters.

**Inline code formatting**

Use backtick code spans (`` `value` ``) for inline code — values like `` `true` ``,
`` `false` ``, `` `nil` ``, symbols, type names, and method calls. Do not use the
RDoc `+value+` style; it is inconsistent with the project's markdown-first rendering
via redcarpet.

**Escaping `{` in descriptions**

YARD treats `{` as the start of a cross-reference link. Because doc comments are
rendered through redcarpet first, a single `\` is consumed by redcarpet before YARD
sees the text. To produce a literal `{`, write `\\{` (two backslashes). Redcarpet
reduces `\\` to `\`, leaving `\{` for YARD to interpret as an escaped brace.

For example, use `'stash@\\{0}'` in a `@param` description to render as
`stash@{0}` in the output. Using only `\{` will still trigger a YARD unresolved
link warning.

**Cross-reference links**

Link to other code objects anywhere in a doc comment using `{ClassName}`,
`{ClassName#method}`, `{#method_in_same_class}`, or `{Class::CONSTANT}`. An
optional title follows the reference separated by a space:
`{Git::Base#log the log method}`. Do not use brace syntax inside `@see` tags —
`@see` links automatically without braces.

**Type specifier conventions**

The `[Types]` field in `@param`, `@return`, `@raise`, etc. supports:

- Plain types: `[String]`, `[Integer]`, `[Git::Base]`
- Multiple types: `[String, nil]`, `[String, Array<String>]`
- Parametrized types: `[Array<String>]`, `[Hash<Symbol, String>]`
- Duck-types (responds to): `[#read]`, `[#to_s]`
- `[Boolean]` — conventional meta-type for `true` or `false` (not a real Ruby class)
- `[void]` — for `@return` tags on methods whose return value must not be used

### Element-Specific Rules

**Classes**

- One-sentence class description using noun phrase form — "Represents…",
  "Encapsulates…", "Provides…", "Immutable value object representing…"
- `@api public` or `@api private` tag to declare visibility
- At least one `@example` showing typical instantiation or primary usage
- `@!attribute [r/rw/w]` directive (with `@return [Type] description`) for every
  `attr_reader`, `attr_accessor`, or `attr_writer`
- Error/exception classes must also document when the error is raised

**Modules**

- One-sentence description — "Namespace for…", "Provides helpers for…", or
  "Mixin that adds…"
- `@api public` or `@api private`
- No `@example` required unless the module provides standalone methods

**Constants**

- A comment immediately above the constant describing its purpose and valid values
- No special YARD tag is needed; YARD picks up the preceding comment automatically
- If the constant's type or shape is non-obvious, add `# @return [Type]` above it

**Attributes**

- Every `attr_reader`, `attr_accessor`, and `attr_writer` must be preceded by a
  `# @!attribute [r/rw/w] name` YARD directive
- Must include `@return [Type] description` explaining the value and its units or
  constraints if relevant
- Defined at the class level, not inside method bodies

**Methods**

- All methods must have a short description that:
  - Starts with a verb (`Returns`, `Resets`, `Finds` — not "The…" or "This method…")
  - Omits the subject — write "Returns the commit count", not "This method returns
    the commit count"
  - States the outcome, not the mechanism — `Finds the nearest tagged ancestor` not
    `Iterates through commits checking tags`
  - Mentions key parameters inline — `Resets HEAD to the given ref` rather than
    relying solely on param tags
  - Avoids restating the method name — add specificity about what kind, from where,
    or what is returned
  - Is specific about return values — `Returns true if the branch exists, false
    otherwise` beats `Returns a Boolean`
  - Omits implementation details — callers don't care about internal loops or temp
    variables
- All methods must have standard YARD tags: `@param`, `@return`, `@raise`
- All public methods must also have one or more `@example`s
- Methods that yield to a block must include `@yield [param_names]`, one
  `@yieldparam name [Type]` per yielded parameter, and `@yieldreturn [Type]`
- Use `@overload` when a method has distinct call signatures with different
  parameters or return types — each overload gets its own full set of tags
- Use `@note` for callouts that need visual emphasis: thread-safety warnings,
  significant side effects, or platform-specific behaviour
- Deprecated methods and classes must include `@deprecated` explaining the
  migration path, e.g. `@deprecated Use {#new_method} instead`

## Step 1: Identify What Needs Documentation

1. **Check documentation coverage:**

   ```bash
   bundle exec yard stats --list-undoc
   ```

2. **Find methods without documentation:**

   ```bash
   bundle exec yard doc --no-output --no-cache 2>&1 | grep "Undocumented"
   ```

3. **Review specific files:**

   ```bash
   # Check documentation for a specific class
   bundle exec yard doc lib/git/base.rb --no-output
   ```

## Step 2: Write Documentation

Follow the YARD documentation template:

```ruby
# Short description of what the method does
#
# Longer description with more details about behavior,
# edge cases, or important notes.
#
# @param name [Type] Description of parameter
#
# @param options [Hash] Options hash description
#
# @option options [Type] :key Description of option
#
# @return [Type] Description of return value
#
# @return [nil] When no result is found
#
# @raise [ArgumentError] When invalid arguments provided
#
# @raise [Git::Error] When git command fails
#
# @yield [commit] Passes each commit to the block
#
# @yieldparam commit [Git::Object::Commit] a commit object
#
# @yieldreturn [void]
#
# @overload method_name(arg)
#   Single-argument form description
#   @param arg [String] the argument
#   @return [String] the result
# @overload method_name(arg, options)
#   Two-argument form description
#   @param arg [String] the argument
#   @param options [Hash] additional options
#   @return [Array<String>] the results
#
# @note This method is not thread-safe
#
# @deprecated Use {#new_method} instead
#
# @example Basic usage
#   git = Git.open('/path/to/repo')
#   result = git.method_name('arg')
#
# @example With options
#   git.method_name('arg', option: true)
#
# @see #related_method
#
# @see Git::RelatedClass
#
# @since 2.0.0
#
# @api public
#
def method_name(name, options = {})
end
```

## Step 3: Verify Documentation

1. **Generate and review docs:**

   ```bash
   bundle exec yard doc
   open doc/index.html
   ```

2. **Check for warnings:**

   ```bash
   bundle exec yard doc 2>&1 | grep -i "warn"
   ```

3. **Verify examples work:**

   Run code examples in a console to ensure they're correct:

   ```bash
   bundle exec bin/console
   ```

4. **Check cross-references:**

   Verify all `@see` references point to valid targets.

## Step 4: Update Prose Documentation

1. **README.md updates:**
   - Ensure examples match current API
   - Update feature descriptions
   - Check installation instructions

2. **CHANGELOG.md entries:**
   - DO NOT UPDATE THE CHANGELOG.md because it is automatically generated from commit
     messages.

3. **Inline comments:**
   - Update implementation comments if behavior changed
   - Remove outdated TODO comments

## Command Reference

```bash
# Generate documentation
bundle exec yard doc

# Generate and serve locally
bundle exec yard server --reload

# Check documentation coverage
bundle exec yard stats

# List undocumented objects
bundle exec yard stats --list-undoc

# Generate docs for specific file
bundle exec yard doc lib/git/base.rb

# Check for YARD syntax errors
bundle exec yard doc --no-output 2>&1

# View documentation for specific class
bundle exec yard ri Git::Base
```
