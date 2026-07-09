---
name: yard-documentation
description: "General YARD documentation rules and workflow for all Ruby source code. Use when writing or reviewing YARD doc comments, generating missing docs, updating examples, fixing doc errors, or checking documentation coverage."
---

# YARD Documentation

General YARD documentation rules and workflow for all Ruby source code.

## Contents

- [Contents](#contents)
- [How to use this skill](#how-to-use-this-skill)
- [Related skills](#related-skills)
- [Reference files](#reference-files)
- [Precedence](#precedence)
- [Workflow](#workflow)
- [Named length limits](#named-length-limits)
- [Step 1: Identify What Needs Documentation](#step-1-identify-what-needs-documentation)
- [Step 2: Write Documentation](#step-2-write-documentation)
  - [Standard template (no `@overload`)](#standard-template-no-overload)
  - [Overload template](#overload-template)
  - [Overload decision matrix](#overload-decision-matrix)
  - [Documenting anonymous splats with `@overload`](#documenting-anonymous-splats-with-overload)
  - [Documenting other elements](#documenting-other-elements)
- [Step 3: Verify Documentation](#step-3-verify-documentation)
  - [Line and summary length checks](#line-and-summary-length-checks)
- [Documentation Standards](#documentation-standards)
  - [Formatting Rules](#formatting-rules)
    - [Doc comment placement](#doc-comment-placement)
    - [Blank lines around tags](#blank-lines-around-tags)
    - [Never use raw blank lines inside a doc comment block](#never-use-raw-blank-lines-inside-a-doc-comment-block)
    - [Short descriptions](#short-descriptions)
    - [Line and summary length](#line-and-summary-length)
    - [`@return` must always include a type](#return-must-always-include-a-type)
    - [No shell calls in `@example` blocks](#no-shell-calls-in-example-blocks)
    - [Blank lines within `@example` blocks](#blank-lines-within-example-blocks)
    - [`@example` titles are required](#example-titles-are-required)
    - [Cross-reference links only resolve to objects included in generated docs](#cross-reference-links-only-resolve-to-objects-included-in-generated-docs)
    - [Inline code formatting](#inline-code-formatting)
    - [Escaping opening braces in descriptions](#escaping-opening-braces-in-descriptions)
    - [Cross-reference links](#cross-reference-links)
    - [Type specifier conventions](#type-specifier-conventions)
    - [`Array<...>` (collection) vs `Array(...)` (tuple)](#array-collection-vs-array-tuple)
    - [`@api private` vs `@private`](#api-private-vs-private)
    - [Class and module `@api` visibility (Required)](#class-and-module-api-visibility-required)
    - [`@since` tags are not used](#since-tags-are-not-used)
    - [`@todo` tags are not used](#todo-tags-are-not-used)
    - [`@abstract`](#abstract)
  - [Method Rules](#method-rules)
    - [Short description](#short-description)
    - [Standard tags](#standard-tags)
    - [`@example` on non-private methods](#example-on-non-private-methods)
    - [Yield tags](#yield-tags)
    - [`@overload` for distinct signatures](#overload-for-distinct-signatures)
    - [`@overload` for anonymous splats](#overload-for-anonymous-splats)
    - [`@note` for callouts (Optional)](#note-for-callouts-optional)
    - [`@deprecated` on deprecated methods](#deprecated-on-deprecated-methods)
    - [`@api` on methods (Optional)](#api-on-methods-optional)
- [Command Reference](#command-reference)

## How to use this skill

Attach this file to your Copilot Chat context, then invoke it with the source
files that need YARD updates. Use it when adding new APIs, fixing doc warnings,
or improving existing YARD quality and examples.

Work top to bottom: follow the three-step [Workflow](#workflow), reaching into the
[Documentation Standards](#documentation-standards) reference below as you write,
and into [`element-rules.md`](element-rules.md) when documenting a class, module,
constant, attribute, dynamically defined method, or value object.

## Related skills

- [Command YARD Documentation](../command-yard-documentation/SKILL.md) — command-specific rules for writing and reviewing YARD docs on `Git::Commands::Base` subclasses

## Reference files

Situational rules live in a sibling file, loaded only when the element type calls
for it:

- [`element-rules.md`](element-rules.md) — per-element requirements for **classes,
  modules, constants, attributes, dynamically defined methods**, and value
  objects (`Data.define` / `Struct.new`). Read it whenever you document one
  of those elements. Rules for **methods** and rules that apply to **every** doc
  comment stay in this file.

## Precedence

When a more specific YARD skill applies, its rules override this general skill:

- [Command YARD Documentation](../command-yard-documentation/SKILL.md) overrides
  these rules for `Git::Commands::Base` subclasses.
- [Facade YARD Documentation](../facade-yard-documentation/SKILL.md) overrides these
  rules for `Git::Repository::*` topic modules.

Otherwise, the rules in this file apply to all Ruby source.

## Workflow

Documenting or fixing YARD docs follows three steps:

1. [Step 1: Identify What Needs Documentation](#step-1-identify-what-needs-documentation)
2. [Step 2: Write Documentation](#step-2-write-documentation) — apply the
   templates and the [Documentation Standards](#documentation-standards)
3. [Step 3: Verify Documentation](#step-3-verify-documentation) — lint, build,
   and manually check

ruby-git uses YARD for API documentation. All classes, modules, constants,
attributes, and methods must have YARD documentation. Methods with Ruby `private`
visibility require a short description and all applicable tags from the
[Method Rules](#method-rules) — `@param`, `@return`, `@raise`,
`@yield`/`@yieldparam`/`@yieldreturn`, and `@overload` — with the exception that
`@example` may be omitted unless an example materially clarifies the behavior.
Private methods still need YARD docs for developer reference in source, even though
YARD excludes them from generated HTML by default.

## Named length limits

Three named limits govern line and description length throughout this skill. They
are referenced by name in [Step 3](#step-3-verify-documentation) and the
[Formatting Rules](#formatting-rules):

- **`LINE_LIMIT`** (90 characters) — the preferred maximum length of any
  physical YARD comment line, measured from column 1 and including every
  character: indentation, `#`, tag metadata, and all text. Wrap prose at
  this limit wherever possible.
- **`LINE_MAX`** (120 characters) — the hard ceiling for lines that cannot
  be wrapped without breaking their meaning. The following content may
  exceed `LINE_LIMIT` up to `LINE_MAX`; it must not exceed `LINE_MAX`:
  - **URLs** — in `@see` tags or markdown links; a URL cannot be split
  - **Long inline code spans** — a `` `backtick` `` span whose content
    alone approaches or exceeds `LINE_LIMIT`
  - **Long `[Type]` expressions** — a type such as
    `[String, Pathname, Array<String, Pathname>]` that fills the tag
    metadata column before any description text begins
  - **`@example` code lines** — real code inside an example block that
    cannot be reflowed without changing its meaning
  - **Markdown table rows** — pipe-delimited table rows that cannot be
    split across lines
- **`SUMMARY_LIMIT`** (90 characters) — the maximum length of a short
  description — either a tag's description text or a documentable object's short
  description (class, module, method, constant, or attribute) — measured by
  concatenating the text from the first line with all immediately following
  indented continuation lines (stripping the leading `#` and continuation indent
  from each and joining with a single space).
  For tags, this covers the description text only — not the tag name, `[Type]`,
  option key, or `(default)`.

## Step 1: Identify What Needs Documentation

```bash
# Find undocumented objects
bundle exec yard stats --list-undoc

# Check a specific file
bundle exec yard doc lib/git/repository.rb --no-output
```

## Step 2: Write Documentation

Follow the YARD documentation templates below and apply the
[Documentation Standards](#documentation-standards) as you write. Use the
**standard template** when a method has a single call signature. Use the
**overload template** when a method has distinct call signatures with different
parameters or return types.

When `@overload` blocks are present:

- Keep signature-specific tags inside overload blocks only:
  `@example`, `@param`, `@option`, `@return`, overload-specific `@raise`,
  and `@yield`/`@yieldparam`/`@yieldreturn`
- Keep `@return` inside each `@overload` block. For overloaded methods,
  `@return` is overload-scoped even when the return type/text is the same
  across call shapes
- Keep shared `@raise` at top level only once (outside all overload blocks)
- Keep `@raise` inside an overload only when that exception applies to that
  overload shape only
- Never document the same `@raise` in both places (top-level and overload)
- Keep non-signature tags (`@note`, `@deprecated`, `@see`, `@api`) at top level
- Never nest `@api` inside an `@overload` block; it applies to the method
  itself, not to an individual call shape

Correct placement pattern:

```ruby
# @overload fetch(name)
#
#   @param name [String] the remote name
#
#   @return [Git::CommandLineResult] the command result
#
# @overload fetch(name, **options)
#
#   @param name [String] the remote name
#
#   @param options [Hash] command options
#
#   @return [Git::CommandLineResult] the command result
#
# @raise [ArgumentError] when the remote name is invalid
#
# @api public
```

Incorrect placement pattern:

```ruby
# @overload fetch(name)
#
#   @param name [String] the remote name
#
# @return [Git::CommandLineResult] the command result
#
# @raise [ArgumentError] when the remote name is invalid
#
# @overload fetch(name, **options)
#
#   @param name [String] the remote name
#
#   @param options [Hash] command options
#
#   @raise [ArgumentError] when the remote name is invalid
#
#   @api public
```

**Trigger: always use `@overload` for anonymous `*`, anonymous `**`, or `...`**

Anonymous splats and the forwarding parameter give `@param`, `@option`, `@yield`,
and `@yieldparam` no named parameter to bind to, so YARD silently drops them.
Switch to `@overload` for the entire signature — see
[Documenting anonymous splats with `@overload`](#documenting-anonymous-splats-with-overload).

### Standard template (no `@overload`)

When present, tags must appear in the order shown. `@param` tags appear in
parameter order, with one exception described below; `@option` tags appear
immediately after the `@param` for the hash they describe. Every `@option` tag
**must** be preceded by a `@param` for the options hash, and all `@option` tags
under that `@param` must reference the same parameter name. For keyword arguments
(`**options` or `**kwargs`), use `@param options [Hash]` (or the actual splat
name) as the preceding `@param`.

For public APIs with known option keys, every `@option` tag must document a real
supported key, such as `:force` or `:timeout`. Do not invent placeholder option
keys for a public `options` hash.

For private helpers that accept arbitrary keyword collectors whose keys are
validated elsewhere, use a neutral splat name such as `candidate_keywords` and
document the collector shape with a single pseudo-option entry named `key_name`.
A pseudo-option is required because yard-lint's `Documentation/UndocumentedOptions`
flags any documented `**` collector that has no `@option` tag, and that check has
no type, name, or visibility exemption for double-splats. Use `key_name` rather
than a literal-looking `key` so it is not mistaken for a real option key. This is
only for arbitrary-keyword helpers where the accepted keys are intentionally not
known at that abstraction layer:

```ruby
# Validate that candidate option keys are listed in `allowed`
#
# @param allowed [Array<Symbol>] the permitted option keys
#
# @param candidate_keywords [Hash<Symbol, Object>] the keywords to validate
#
# @option candidate_keywords [Object] key_name a candidate keyword value
#
# @return [void]
#
# @raise [ArgumentError] when any candidate key is not in `allowed`
#
def assert_valid_opts!(allowed, **candidate_keywords)
end
```

The exception to parameter order: all `@param` tags must come before the first
`@option` tag, because yard-lint's `Tags/Order` validator rejects a `@param` that
follows an `@option`. When a positional parameter follows the options hash in the
signature, document the options-hash `@param` (and its `@option` tags) last so the
`@option` tags stay grouped at the end — that is, move the options-hash `@param`
after the later positional `@param` rather than in strict signature order:

```ruby
# Short description of what the method does
#
# Longer description with more details about behavior,
# edge cases, or important notes.
#
# @example Basic usage
#   git = Git.open('/path/to/repo')
#   result = git.method_name('arg', {}, '/path')
#
# @example With options
#   git.method_name('arg', { option: true }, '/path')
#
# @param name [Type] description of parameter
#
# @param path [String] a parameter that follows the options hash in the signature
#
# @param options [Hash] options hash description
#
# @option options [Type] :key description of option
#
# @return [Type] description of return value
#
# @raise [ArgumentError] when invalid arguments are provided
#
# @raise [Git::FailedError] when git exits with a non-zero exit status
#
# @yield [commit] passes each commit to the block
#
# @yieldparam commit [Git::Object::Commit] a commit object
#
# @yieldreturn [void]
#
# @note This method is not thread-safe
#
# @deprecated Use {#new_method} instead
#
# @see #related_method
#
# @see Git::RelatedClass
#
# @see https://git-scm.com/docs/git-log
#
# @api public
#
def method_name(name, options = {}, path)
end
```

### Overload template

Each `@overload` block carries only signature-specific tags: `@example`,
`@param`, `@option`, `@return`, overload-specific `@raise`, and
`@yield`/`@yieldparam`/`@yieldreturn`. Tags that are **not**
call-signature-specific — `@note`, `@deprecated`, `@see`, `@api` — remain
at the top level. `@return` remains overload-scoped even when identical across
call shapes. `@raise` can be top-level when shared across all call shapes, and
overload-local when shape-specific. Never place `@api` inside an overload
block.

```ruby
# Short description of what the method does
#
# Longer description with more details about behavior,
# edge cases, or important notes.
#
# @overload method_name(arg)
#
#   Single-argument form description
#
#   @example Basic usage
#     result = git.method_name('arg')
#
#   @param arg [String] the argument
#
#   @return [String] the result
#
# @overload method_name(arg, options)
#
#   Two-argument form description
#
#   @example With options
#     result = git.method_name('arg', { force: true })
#
#   @param arg [String] the argument
#
#   @param options [Hash] additional options
#
#   @return [Array<String>] the results
#
# @raise [ArgumentError] when an invalid argument is provided
#
# @note This method is not thread-safe
#
# @deprecated Use {#new_method} instead
#
# @see #related_method
#
# @see https://git-scm.com/docs/git-log
#
# @api public
#
def method_name(arg, options = {})
end
```

### Overload decision matrix

Use this matrix to decide whether to use `@overload` and where to place tags:

| Method signature or behavior | Documentation form |
| --- | --- |
| Single named signature, no `*`/`**`/`...` | Standard template (no `@overload`) |
| Uses anonymous `*`, `**`, or `...` | `@overload` required |
| Private arbitrary keyword collector | Neutral splat name plus pseudo-option `key_name` |
| Multiple call shapes (different params and/or return types) | One `@overload` per shape |
| Return value for overloaded methods | `@return` in each overload; never top-level |
| Shared errors across all call shapes | Top-level `@raise` once (outside overloads) |
| Error only for specific call shape | `@raise` only in that overload |
| Same error documented top-level and inside overloads | Invalid; choose one placement |
| Method-level API visibility (`@api`) | Top-level `@api` only; never inside `@overload` |

### Documenting anonymous splats with `@overload`

When the method signature uses an anonymous splat — `def foo(*)`, `def foo(**)`,
`def foo(*, **)` — or the argument forwarding parameter `def foo(...)` —
`@param`, `@option`, `@yield`, and `@yieldparam` tags have no parameter name
to bind to. RuboCop's `Style/ArgumentsForwarding` cop prefers these forms when
arguments are forwarded unchanged, so naming the splat (or expanding `...`
into `*args, **kwargs, &block`) is **not** an acceptable workaround. Use
`@overload` blocks that introduce named parameters for documentation purposes
only:

```ruby
# Update the index with the current content found in the working tree
#
# @overload add(paths = '.', **options)
#
#   @example Stage a specific file
#     git.add('README.md')
#
#   @param paths [String, Array<String>] file(s) to add (relative to the
#     worktree root); defaults to `'.'` (all files)
#
#   @param options [Hash] command options
#
#   @option options [Boolean, nil] :all (nil) add, modify, and remove index entries to
#     match the worktree
#
#   @option options [Boolean, nil] :force (nil) allow adding otherwise ignored files
#
#   @return [String] the command output
#
#   @raise [Git::FailedError] if `git add` exits with a non-zero status
#
def add(paths = '.', **)
  Git::Commands::Add.new(@execution_context).call(*Array(paths), **).stdout
end
```

The same approach applies to `...`. The overload signature names the
parameters; the actual `def` keeps `...` so RuboCop is satisfied:

```ruby
# Run a command against the underlying execution context
#
# @overload run(command, *args, **options, &block)
#
#   @example Run git status
#     result = git.run('status')
#
#   @param command [String] the git subcommand to run
#
#   @param args [Array<String>] positional arguments forwarded to the command
#
#   @param options [Hash] keyword options forwarded to the command
#
#   @return [Git::CommandLineResult] the command result
#
#   @yield [result] yields the command result, when a block is given
#
#   @yieldparam result [Git::CommandLineResult] the command result
#
#   @yieldreturn [void]
#
def run(command, ...)
  Git::Commands::Run.new(@execution_context).call(command, ...)
end
```

When a method has multiple genuinely distinct call shapes, write one
`@overload` block per shape as in the [Overload template](#overload-template)
above.

**Anonymous block parameter (`&`)** is **not** covered by this rule.
`@yield`, `@yieldparam`, and `@yieldreturn` describe what is yielded to the
block, not the block parameter itself, so they bind correctly even with an
anonymous `&`. Use a named block parameter (`&block`) and a `@param block
[Proc]` tag only in the rare case where the block is documented as a
first-class `Proc` value (stored, returned, or passed elsewhere) rather than
yielded to.

### Documenting other elements

The templates above cover **methods**. When documenting a **class, module,
constant, attribute, dynamically defined method (`@!method`)**, or a value
object (`Data.define` / `Struct.new`), follow the per-element requirements
in [`element-rules.md`](element-rules.md).

## Step 3: Verify Documentation

First, run the automated linter. `yard-lint` enforces many of the rules in this
skill (undocumented objects, missing `@param`/`@option`/`@return`, tag order,
type syntax, orphaned doc comments) and the minimum documentation coverage
threshold:

```bash
# Lint YARD docs against the project standards (config: .yard-lint.yml)
bundle exec yard-lint lib/

# Lint only the files you changed
bundle exec yard-lint lib/ --diff main

# Or run it through rake (build + lint + example-test)
bundle exec rake yard
```

A clean `yard-lint` run is necessary but not sufficient: the linter cannot check
every rule here (e.g. the `LINE_LIMIT`/`LINE_MAX` distinction, `SUMMARY_LIMIT`,
short-description capitalization and punctuation, noun-phrase class descriptions,
required `@example` titles, class/module-level `@api` visibility correctness).
Still perform the manual checks below.

Legacy offenses are baselined in `.yard-lint-todo.yml`; when you touch a file
listed there, remove it from every `Exclude:` list that names it (a file may be
baselined under more than one validator) and fix the offenses as part of your
change.

Then generate and review the rendered docs:

```bash
# Generate and review docs
bundle exec yard doc
# then open doc/index.html in your browser

# Check for warnings
bundle exec yard doc 2>&1 | ruby -ne 'puts $_ if $_ =~ /warn/i'
```

Verify `@example` code runs correctly in `bundle exec bin/console`.
Check that all `@see` references point to valid targets.

### Line and summary length checks

Apply these checks to every YARD doc comment — the description on a class,
module, method, constant, or attribute, and every tag within it (`@param`,
`@return`, `@raise`, `@option`, `@yield`, `@yieldparam`, `@yieldreturn`, etc.).
Check all three limits:

1. **`LINE_LIMIT`**: Count every character from column 1 (indentation, `#`,
   metadata, text) on each physical line. If any wrappable line exceeds
   `LINE_LIMIT`, split at a word boundary onto a continuation line (indented
   two extra spaces). Apply this check to every continuation line
   independently.
2. **`LINE_MAX`**: Confirm no physical line exceeds `LINE_MAX` — the hard
   ceiling that nothing may cross. Only unwrappable content (URLs, long inline
   code spans, long `[Type]` expressions, `@example` code, markdown table rows)
   may sit between `LINE_LIMIT` and `LINE_MAX`; every other line must stay
   within `LINE_LIMIT`.
3. **`SUMMARY_LIMIT`**: For each short description — a tag's description or a
   documented object's short description — strip the leading `#` and its
   indentation from every continuation line and join with a single space. If the
   concatenated text exceeds `SUMMARY_LIMIT`, shorten it and move the excess into
   a paragraph after a blank `#` line.

## Documentation Standards

The rules below are the reference the [Workflow](#workflow) draws on. The
[Formatting Rules](#formatting-rules) apply to every doc comment regardless of
element type; the [Method Rules](#method-rules) govern method doc comments.
Per-element rules for classes, modules, constants, attributes, and value objects
are in [`element-rules.md`](element-rules.md).

Treat every rule in this section as mandatory unless its heading is marked
**(SHOULD)** or **(Optional)**. Headings that name a descriptive topic (e.g.
type-specifier conventions) are reference material; any obligations they carry are
stated with “must” inline.

### Formatting Rules

Doc comments are rendered as **markdown** via the redcarpet gem. Write all
free-text descriptions, tag values, and examples using markdown syntax. These rules
apply to all documentation regardless of element type. They reference the three
[Named length limits](#named-length-limits) (`LINE_LIMIT`, `LINE_MAX`,
`SUMMARY_LIMIT`) defined earlier.

#### Doc comment placement

YARD doc comments must appear immediately above the element they document (class,
module, method, constant, or attribute) with no intervening blank lines or
non-comment code.

#### Blank lines around tags

Every individual YARD tag must be preceded by a blank comment line (`#`) unless it is the very first line of a doc comment.
A YARD tag is any comment token matching `@!?[a-z_]+` — that is, `@word` (regular
tags such as `@param`, `@return`, `@raise`, `@api`, `@abstract`, `@deprecated`,
etc.) or `@!word` (directives such as `@!attribute`, `@!method`, `@!scope`, etc.).

Within the tag block there are no other exceptions: consecutive same-kind tags (e.g.
multiple `@param` lines) each require their own preceding blank line.

#### Never use raw blank lines inside a doc comment block

A raw blank line — an empty line with no leading `#` — terminates the YARD doc
comment block at that point. Any comment lines that follow the raw blank line are
treated as separate, unattached comments and will not appear in the generated
documentation. Always use a blank comment line (`#`) to separate paragraphs or
continuation text within a YARD block:

Correct — blank comment line keeps the block intact:

```ruby
# @option options [Boolean, nil] :ipv4 (nil) use IPv4 addresses only
#
#   Alias: :"4"
```

Incorrect — raw blank line silently drops the alias note:

```ruby
# @option options [Boolean, nil] :ipv4 (nil) use IPv4 addresses only

#   Alias: :"4"
```

Watch for editors that auto-strip trailing spaces from `#` lines, silently
creating raw blank lines.

#### Short descriptions

The short description (the first sentence of any doc comment, or the inline text of
a `@param`, `@return`, `@raise`, etc. tag) must:

- Be a single sentence
- Not end with sentence-ending punctuation (`.`, `?`, `!`)
- **Element-level short descriptions** (on classes, modules, and methods) **start
  with an uppercase letter** (e.g. `Returns the commit count`,
  `Represents a Git branch`)
- **Tag short descriptions** (`@option`, `@param`, `@return`, `@raise`, `@yield`,
  `@yieldparam`, etc.) **all start with a lowercase letter** (e.g. `@option options
  [Boolean, nil] :force (nil) overwrite existing files`, `@param name [String] the branch
  name`, `@return [String] the result`, `@raise [ArgumentError] when no name is provided`)

For tags, the **summary text** is the description that follows the tag
metadata (tag name, `[Type]`, option key, and `(default)`). For example, in:

```text
@option options [Boolean, nil] :ignore_case (nil) ignore case distinctions
```

the summary text is `ignore case distinctions`.

#### Line and summary length

Every physical YARD doc line should not exceed `LINE_LIMIT`. When a description
would push a line past `LINE_LIMIT`, split it at a word boundary
onto a continuation line indented two extra spaces. For content that cannot
be wrapped (URLs, long inline code spans, long `[Type]` expressions,
`@example` code lines, markdown table rows), lines may extend up to
`LINE_MAX` but must not exceed it.

Additionally, the concatenated description — the description text from the
first line joined with all continuation lines — must not exceed
`SUMMARY_LIMIT`. If the concatenated description exceeds `SUMMARY_LIMIT`,
shorten it and move the excess detail into a paragraph after a blank `#` line.

For example, this tag has a description of 84 characters (within
`SUMMARY_LIMIT`), but the single physical line is 102 characters (exceeds
`LINE_LIMIT`) and must be split:

```ruby
# @return [Array] a two-element array `[target, options]` containing the translated checkout arguments
```

Split so each physical line fits within `LINE_LIMIT`:

```ruby
# @return [Array] a two-element array `[target, options]` containing the
#   translated checkout arguments
```

If the tag metadata itself is long (e.g. a long `[Type]` or `@option` key),
start the description on an indented continuation line so only the metadata
appears on the first physical line.

If more explanation is needed, add continuation paragraphs after a blank
comment line (`#`). Every physical line — in the summary and in any
continuation paragraph — must independently fit within `LINE_LIMIT`
(or `LINE_MAX` for unwrappable content such as URLs, long inline code
spans, long `[Type]` expressions, `@example` code, or table rows).

These rules apply to every doc comment — an object's short description and a
tag's text alike; the first sentence is the short description. The no-punctuation rule applies only to
short descriptions; continuation paragraphs use normal prose punctuation (periods).
Separate continuation paragraphs with a blank comment line.

Correct — tag title without punctuation, blank line before continuation:

```ruby
# @option options [Boolean, nil] :ignore_case (nil) ignore case
#   distinctions in both the pattern and the file contents
#
#   Alias: :i
#
# @option options [String, Array<String>] :pattern the search pattern
#   (required; must not be nil)
#
#   Pass a String for a simple pattern (emitted as `-e <pattern>`).
#   Pass an Array of raw CLI arguments for compound boolean
#   expressions.
#
# @return [Git::CommandLineResult] the result of calling `git grep`
#
#   Exit status 0 means matches were found; exit status 1 means no
#   lines were selected (not an error).
```

Incorrect — trailing period on title, missing blank line before continuation, and `@return` concatenated summary exceeds `SUMMARY_LIMIT` (132 chars):

```ruby
# @option options [Boolean, nil] :ignore_case (nil) ignore case
#   distinctions in both the pattern and the file contents.
#   Alias: :i
#
# @return [Git::CommandLineResult] the result of calling `git grep`.
#   Exit status 0 means matches were found; exit status 1 means no
#   lines were selected (not an error).
```

#### `@return` must always include a type

Every `@return` tag must include a `[Type]` specifier. `@return the value` is
incorrect; write `@return [Object] the value` (or a more specific type). If the
return value is the block's return value, use `@return [Object]`.

#### No shell calls in `@example` blocks

Never use backtick shell calls (`` `true` ``, `` `git version` ``) or process-status
globals (`$?`, `$CHILD_STATUS`) in `@example` blocks. They are side-effecting,
environment-dependent, and confuse readers about the type of object being
demonstrated. Construct example objects directly in Ruby instead:

Incorrect:

```ruby
# @example Incorrect shell call
#   `true`
#   result = Git::CommandLine::Result.new([], $?, '', '')
```

Correct:

```ruby
# @example Constructing a result with a double
#   status = instance_double(ProcessExecuter::Result)
#   result = Git::CommandLine::Result.new([], status, '', '')
```

#### Blank lines within `@example` blocks

Within `@example` blocks, blank comment lines (`#`) render as literal blank lines in
the displayed code. Use them for readability between setup and assertions, but be
aware they are literal content, not tag separators.

#### `@example` titles are required

Every `@example` tag must include a title — the descriptive text on the same line
after `@example`. Write `@example Basic usage`, not bare `@example`. Titles appear
as headings in generated docs and help readers scan multiple examples.

#### Cross-reference links only resolve to objects included in generated docs

YARD renders `{ClassName#method}` as a hyperlink only when the target method is
included in the generated documentation. Public objects are included by default,
and objects marked with `@api private` remain included with a private annotation.
Ruby private methods are excluded by default. Do not write
`{Git::Commands::Base#execute_command}` — it will render as plain text and may
generate an unresolved reference warning.

If you need to refer to a private method, describe it in prose instead, or link to
the public method that callers should use.

#### Inline code formatting

Use backtick code spans for inline code (`` `true` ``, `` `nil` ``, symbols, type
names, method calls). Do not use the RDoc `+value+` style; it is inconsistent with
the project's markdown rendering via redcarpet.

#### Escaping opening braces in descriptions

YARD treats `{` as the start of a cross-reference link. Because redcarpet consumes
one `\` before YARD sees it, write `\\{` (two backslashes) to produce a literal
`{` — redcarpet reduces `\\` to `\`, leaving `\{` for YARD. For example, use
`'stash@\\{0}'` to render as `stash@{0}`. Using only `\{` still triggers a YARD
unresolved link warning.

#### Cross-reference links

Link to other code objects anywhere in a doc comment using `{ClassName}`,
`{ClassName#method}`, `{#method_in_same_class}`, or `{Class::CONSTANT}`. An
optional title follows the reference separated by a space:
`{Git::Repository#log the log method}`. Do not use brace syntax inside `@see` tags —
`@see` links automatically without braces. `@see` accepts three target forms:

- Code objects: `@see Git::Repository#log`
- URLs: `@see https://git-scm.com/docs/git-log`
- Quoted text: `@see "Pro Git, Chapter 2"`

#### Type specifier conventions

The `[Types]` field in `@param`, `@return`, `@raise`, etc. supports:

- Plain types: `[String]`, `[Integer]`, `[Git::Repository]`
- Multiple types: `[String, nil]`, `[String, Array<String>]`
- Parametrized collections: `[Array<String>]`, `[Hash<Symbol, String>]`
- Fixed-position tuples: `[Array(String, Integer)]`, `[Array(Symbol, (Integer, nil))]`
- Duck-types (responds to): `[#read]`, `[#to_s]`
- `[Boolean]` — conventional meta-type for `true` or `false` (not a real Ruby class)
- `[void]` — for `@return` tags on methods whose return value must not be used

#### `Array<...>` (collection) vs `Array(...)` (tuple)

YARD treats angle brackets and parentheses as distinct type constructors, so
choose the one that matches the value's shape:

- `Array<T>` (angle brackets) — a **collection**: an array *of* `T` with any
  number of elements, e.g. `Array<String>` is zero or more strings. Listing
  several types inside `<...>` means each element is one *of* those types
  (`Array<String, Symbol>` is an array whose elements are each a String or a
  Symbol), **not** a fixed sequence.
- `Array(A, B)` (parentheses) — a **tuple**: an array *containing* exactly `A`
  then `B` in that order, e.g. `Array(String, Integer)` is a two-element
  `[name, count]`. Use this whenever a method returns or accepts a
  fixed-position array such as `[status, similarity]` or `[path, options]`.

The same rule applies to nested types: `Array<Array(Integer, String)>` is a
collection of `[index, message]` tuples. Use `[Array]` with a prose description
only when the element types cannot be expressed concisely.

#### `@api private` vs `@private`

Use `@api private` (not `@private`) to mark internal classes and modules. `@api
private` includes the object in generated docs with a private annotation; YARD's
`@private` tag excludes the object from docs entirely.

#### Class and module `@api` visibility (Required)

Every documented class and module must declare API visibility explicitly with
exactly one tag:

- `@api public` for user-facing API
- `@api private` for internal implementation details

Do not rely on YARD's implicit default visibility.

`@api` visibility is inherited by child objects. Omit redundant method-level or
constant-level `@api` tags when a child matches its enclosing class/module
visibility.

Add method-level or constant-level `@api` only when a child intentionally differs
from its enclosing class/module visibility.

#### `@since` tags are not used

Do not add `@since` tags. The project has no historical `@since` annotations, and
retroactively tagging existing APIs is impractical at v4.x. Version introduction
history is tracked through git blame and the CHANGELOG instead.

#### `@todo` tags are not used

Do not add `@todo` tags. Track incomplete work in GitHub Issues, not in source
comments. YARD renders `@todo` prominently in generated docs, and these annotations
go stale quickly.

#### `@abstract`

Use `@abstract` on classes or methods that must be subclassed or overridden before
use. Include guidance text describing what the subclass must implement:
`@abstract Subclass and implement {#run}`. Do not use `@abstract` on concrete
classes or fully implemented methods.

### Method Rules

#### Short description

Every method must have a short description that:

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

#### Standard tags

Methods use these standard YARD tags:

- `@param` for each method parameter, in signature order; omit `@param` entirely
  on zero-argument methods
- `@return` on every method; use `[void]` when the return value must not be used
- `@raise` for each caller-relevant exception the method can raise as part of its
  contract; omit `@raise` when the method has no documented exceptional path

#### `@example` on non-private methods

Methods without Ruby `private` visibility must have one or more `@example`s;
Ruby-private methods may omit `@example` unless usage would otherwise be unclear.

#### Yield tags

Methods that yield to a block must include `@yield [param_names]`, one
`@yieldparam name [Type]` per yielded parameter, and `@yieldreturn [Type]`; omit
all yield tags on methods that do not yield.

#### `@overload` for distinct signatures

Use `@overload` when a method has distinct call signatures with different
parameters or return types — each overload gets its own full set of tags.
Methods that yield only when an optional block is given should use `@overload`
to document the with-block and without-block signatures separately.

#### `@overload` for anonymous splats

Methods whose signature uses an anonymous `*`, `**`, or `...` must document their
call shapes with named `@overload` blocks. Do **not** name the splat or expand
`...` into `*args, **kwargs, &block` to make tags bind — that conflicts with
RuboCop's `Style/ArgumentsForwarding` cop. See
[Documenting anonymous splats with `@overload`](#documenting-anonymous-splats-with-overload).

#### `@note` for callouts (Optional)

Use `@note` for callouts that need visual emphasis: thread-safety warnings,
significant side effects, or platform-specific behavior.

#### `@deprecated` on deprecated methods

Deprecated methods must include `@deprecated` explaining the migration path,
e.g. `@deprecated Use {#new_method} instead`.

#### `@api` on methods (Optional)

Method-level `@api` is exception-only: when omitted, the method inherits the
containing class's `@api` level. Use it only when the method's intended visibility
differs from the class's level (e.g. an `@api private` helper inside an `@api
public` class). For overloaded methods, place `@api` once at top level and never
nest it inside an `@overload` block.

## Command Reference

```bash
# Lint YARD documentation against the project standards
bundle exec yard-lint lib/

# Lint only changed files (great for pre-commit / CI)
bundle exec yard-lint lib/ --diff main

# Show documentation coverage statistics
bundle exec yard-lint lib/ --stats

# Generate documentation
bundle exec yard doc

# Generate and serve locally
bundle exec yard server --reload

# Check documentation coverage
bundle exec yard stats

# List undocumented objects
bundle exec yard stats --list-undoc

# Generate docs for specific file
bundle exec yard doc lib/git/repository.rb

# Check for YARD syntax errors
bundle exec yard doc --no-output 2>&1

# View documentation for specific class
bundle exec yard ri Git::Repository
```
