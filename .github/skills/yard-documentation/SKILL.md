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
- [Documentation Standards](#documentation-standards)
  - [YARD Formatting Rules](#yard-formatting-rules)
  - [Element-Specific Rules](#element-specific-rules)
- [Step 1: Identify What Needs Documentation](#step-1-identify-what-needs-documentation)
- [Step 2: Write Documentation](#step-2-write-documentation)
  - [Standard template (no `@overload`)](#standard-template-no-overload)
  - [Overload template](#overload-template)
  - [Documenting anonymous splats with `@overload`](#documenting-anonymous-splats-with-overload)
- [Step 3: Verify Documentation](#step-3-verify-documentation)
- [Command Reference](#command-reference)

## How to use this skill

Attach this file to your Copilot Chat context, then invoke it with the source
files that need YARD updates. Use it when adding new APIs, fixing doc warnings,
or improving existing YARD quality and examples.

## Related skills

- [Command YARD Documentation](../command-yard-documentation/SKILL.md) — command-specific rules for writing and reviewing YARD docs on `Git::Commands::Base` subclasses

## Documentation Standards

ruby-git uses YARD for API documentation:

All classes, modules, constants, attributes, and methods must have YARD
documentation. Methods with Ruby `private` visibility require a short description
and all applicable tags from the [Methods](#methods) rules — `@param`, `@return`,
`@raise`, `@yield`/`@yieldparam`/`@yieldreturn`, and `@overload` — with the
exception that `@example` may be omitted unless an example materially clarifies
the behavior. Private methods still need YARD docs for developer reference in
source, even though YARD excludes them from generated HTML by default.

### YARD Formatting Rules

Doc comments are rendered as **markdown** via the redcarpet gem. Write all
free-text descriptions, tag values, and examples using markdown syntax. These rules
apply to all documentation regardless of element type:

**Doc comment placement**

YARD doc comments must appear immediately above the element they document (class,
module, method, constant, or attribute) with no intervening blank lines or
non-comment code.

**Blank lines around tags**

Every individual YARD tag must be preceded by a blank comment line (`#`) unless it is the very first line of a doc comment.
A YARD tag is any comment token matching `@!?[a-z_]+` — that is, `@word` (regular
tags such as `@param`, `@return`, `@raise`, `@api`, `@abstract`, `@deprecated`,
etc.) or `@!word` (directives such as `@!attribute`, `@!method`, `@!scope`, etc.).

Within the tag block there are no other exceptions: consecutive same-kind tags (e.g.
multiple `@param` lines) each require their own preceding blank line.

**Never use raw blank lines inside a doc comment block**

A raw blank line — an empty line with no leading `#` — terminates the YARD doc
comment block at that point. Any comment lines that follow the raw blank line are
treated as separate, unattached comments and will not appear in the generated
documentation. Always use a blank comment line (`#`) to separate paragraphs or
continuation text within a YARD block:

Correct — blank comment line keeps the block intact:

```ruby
# @option options [Boolean] :ipv4 (nil) use IPv4 addresses only
#
#   Alias: :"4"
```

Incorrect — raw blank line silently drops the alias note:

```ruby
# @option options [Boolean] :ipv4 (nil) use IPv4 addresses only

#   Alias: :"4"
```

Watch for editors that auto-strip trailing spaces from `#` lines, silently
creating raw blank lines.

**Short descriptions**

The short description (the first sentence of any doc comment, or the inline text of
a `@param`, `@return`, `@raise`, etc. tag) must:

- Be a single sentence
- Not end with sentence-ending punctuation (`.`, `?`, `!`)
- **Element-level short descriptions** (on classes, modules, and methods) **start
  with an uppercase letter** (e.g. `Returns the commit count`,
  `Represents a Git branch`)
- **Tag short descriptions** (`@option`, `@param`, `@return`, `@raise`, `@yield`,
  `@yieldparam`, etc.) **all start with a lowercase letter** (e.g. `@option options
  [Boolean] :force (nil) overwrite existing files`, `@param name [String] the branch
  name`, `@return [String] the result`, `@raise [ArgumentError] when no name is provided`)

For tags, the **summary text** is the description that follows the tag
metadata (tag name, `[Type]`, option key, and `(default)`). For example, in:

```
@option options [Boolean] :ignore_case (nil) ignore case distinctions
```

the summary text is `ignore case distinctions`. The entire physical line —
including indentation, `#`, tag metadata, and summary text — must fit within
the 90-character line limit. If the tag metadata is long, start the summary
on an indented continuation line.

If more explanation is needed, use additional paragraphs after the short description.
Separate each paragraph from the next with a blank comment line (`#`). Wrap
individual lines at 90 characters total — counting every character from column 1,
including leading indentation, the `#`, and all text.

These rules apply equally to tag text (`@param`, `@return`, etc.) — the first
sentence of a tag is its short description. The no-punctuation rule applies only to
short descriptions; continuation paragraphs use normal prose punctuation (periods).
Separate continuation paragraphs with a blank comment line.

Correct — tag title without punctuation, blank line before continuation:

```ruby
# @option options [Boolean] :ignore_case (nil) ignore case
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

Incorrect — trailing period on title, missing blank line before continuation:

```ruby
# @option options [Boolean] :ignore_case (nil) ignore case
#   distinctions in both the pattern and the file contents.
#   Alias: :i
#
# @return [Git::CommandLineResult] the result of calling `git grep`.
#   Exit status 0 means matches were found; exit status 1 means no
#   lines were selected (not an error).
```

**`@return` must always include a type**

Every `@return` tag must include a `[Type]` specifier. `@return the value` is
incorrect; write `@return [Object] the value` (or a more specific type). If the
return value is the block's return value, use `@return [Object]`.

**No shell calls in `@example` blocks**

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

**Blank lines within `@example` blocks**

Within `@example` blocks, blank comment lines (`#`) render as literal blank lines in
the displayed code. Use them for readability between setup and assertions, but be
aware they are literal content, not tag separators.

**`@example` titles are required**

Every `@example` tag must include a title — the descriptive text on the same line
after `@example`. Write `@example Basic usage`, not bare `@example`. Titles appear
as headings in generated docs and help readers scan multiple examples.

**Cross-reference links only resolve to objects included in generated docs**

YARD renders `{ClassName#method}` as a hyperlink only when the target method is
included in the generated documentation. Public objects are included by default,
and objects marked with `@api private` remain included with a private annotation.
Ruby private methods are excluded by default. Do not write
`{Git::Lib#some_private_method}` — it will render as plain text and may generate
an unresolved reference warning.

If you need to refer to a private method, describe it in prose instead, or link to
the public method that callers should use.

**Inline code formatting**

Use backtick code spans for inline code (`` `true` ``, `` `nil` ``, symbols, type
names, method calls). Do not use the RDoc `+value+` style; it is inconsistent with
the project's markdown rendering via redcarpet.

**Escaping `{` in descriptions**

YARD treats `{` as the start of a cross-reference link. Because redcarpet consumes
one `\` before YARD sees it, write `\\{` (two backslashes) to produce a literal
`{` — redcarpet reduces `\\` to `\`, leaving `\{` for YARD. For example, use
`'stash@\\{0}'` to render as `stash@{0}`. Using only `\{` still triggers a YARD
unresolved link warning.

**Cross-reference links**

Link to other code objects anywhere in a doc comment using `{ClassName}`,
`{ClassName#method}`, `{#method_in_same_class}`, or `{Class::CONSTANT}`. An
optional title follows the reference separated by a space:
`{Git::Base#log the log method}`. Do not use brace syntax inside `@see` tags —
`@see` links automatically without braces. `@see` accepts three target forms:

- Code objects: `@see Git::Base#log`
- URLs: `@see https://git-scm.com/docs/git-log`
- Quoted text: `@see "Pro Git, Chapter 2"`

**Type specifier conventions**

The `[Types]` field in `@param`, `@return`, `@raise`, etc. supports:

- Plain types: `[String]`, `[Integer]`, `[Git::Base]`
- Multiple types: `[String, nil]`, `[String, Array<String>]`
- Parametrized types: `[Array<String>]`, `[Hash<Symbol, String>]`
- Duck-types (responds to): `[#read]`, `[#to_s]`
- `[Boolean]` — conventional meta-type for `true` or `false` (not a real Ruby class)
- `[void]` — for `@return` tags on methods whose return value must not be used

**`@api private` vs `@private`**

Use `@api private` (not `@private`) to mark internal classes and modules. `@api
private` includes the object in generated docs with a private annotation; YARD's
`@private` tag excludes the object from docs entirely.

**`@since` — do not use**

Do not add `@since` tags. The project has no historical `@since` annotations, and
retroactively tagging existing APIs is impractical at v4.x. Version introduction
history is tracked through git blame and the CHANGELOG instead.

**`@todo` — do not use**

Do not add `@todo` tags. Track incomplete work in GitHub Issues, not in source
comments. YARD renders `@todo` prominently in generated docs, and these annotations
go stale quickly.

**`@abstract`**

Use `@abstract` on classes or methods that must be subclassed or overridden before
use. Include guidance text describing what the subclass must implement:
`@abstract Subclass and implement {#run}`. Do not use `@abstract` on concrete
classes or fully implemented methods.

### Element-Specific Rules

**Classes**

- One-sentence class description as a **noun phrase** (or starting with "Represents…") — the description should pass
  the "This class is a…" litmus test (i.e. you should be able to prefix "This class
  is a" and produce a grammatical sentence). "Represents…" is an accepted convention.
  Do not start descriptions with "This class is…", "Provides…", or "Encapsulates…".
  - Good: `Wrapper around the git binary`, `Immutable value object for a branch
    delete result`, `Represents a git branch`
  - Bad: `This class wraps the git binary`, `Provides branch deletion`,
    `Encapsulates branch state`
- `@api public` or `@api private` tag to declare visibility — use `@api public` for
  stable user-facing classes; use `@api private` for internal implementation classes
  (e.g., `Git::Lib`, `Git::Commands::*`, parsers)
- At least one `@example` showing typical instantiation or primary usage — this
  applies to all classes including `@api private` classes
- Error/exception classes must also state when the error is raised in class-level
  prose, using caller-facing wording such as `Raised when branch deletion fails`
- Deprecated classes must include `@deprecated` explaining the migration path
- When present, class-level tags must appear in this order: `@example`, `@note`,
  `@deprecated`, `@see`, `@api`, `@abstract`

**Modules**

- One-sentence description — "Namespace for…", "Provides helpers for…", or
  "Mixin that adds…"
- `@api public` or `@api private` — use `@api public` for stable user-facing modules;
  use `@api private` for internal implementation modules
- No `@example` required unless the module provides standalone methods
- Deprecated modules must include `@deprecated` explaining the migration path
- When present, module-level tags must appear in the same order as class-level
  tags: `@example`, `@note`, `@deprecated`, `@see`, `@api`

**Constants**

- A comment immediately above the constant describing its purpose and valid values
- No special YARD tag is needed; YARD picks up the preceding comment automatically
- Add `# @return [Type]` when the constant holds a collection, frozen structure, or
  domain-specific type whose shape is not immediately obvious from the value

**Attributes**

- For explicitly written `attr_reader`, `attr_accessor`, and `attr_writer` declarations,
  place the documentation directly above the attribute; do **not** use the `@!attribute`
  directive
- For dynamically created attributes, `Data.define` members, or `Struct.new`
  members, you **must** use a `# @!attribute [r/rw/w] name` YARD directive
- Must include `@return [Type] description` explaining the value and its units or
  constraints if relevant
- For explicit `attr_reader`/`attr_accessor`/`attr_writer`, include a short
  description paragraph above the attribute in addition to `@return`
- For `@!attribute` directives (in `Data.define` / `Struct.new`), the `@return`
  tag inside the directive block serves as the sole documentation — no separate
  short description is needed
- Tags inside `@!attribute` (and `@!method`) directive blocks must be indented
  two extra spaces relative to the directive itself
- Must be defined at the class level, not inside method bodies

**Dynamically defined methods (`@!method`)**

Use the `# @!method name(params)` directive for methods created via
metaprogramming (`define_method`, method-generating DSLs, etc.) that have no
literal `def`. Place the directive and its doc comment where the method would
logically appear in the class body. Tags inside the directive block follow the
same indentation rule as `@!attribute` — indented two extra spaces relative to
the directive.

**`Data.define` classes**

Immutable value objects defined with `Data.define` use the following conventions
(see `Git::BranchDeleteFailure` for a canonical example):

- Class-level doc: noun-phrase short description, `@example`, `@see`, `@api`
- One `@!attribute [r]` directive per member with `@return [Type] description`
- Attribute directives are placed after class-level tags and before the
  `Data.define` line
- Custom methods defined inside the `Data.define` block follow standard method
  rules

**`Struct.new` classes**

Document `Struct.new` classes using the same conventions as `Data.define` classes:
class-level doc with a noun-phrase short description, `@example`, `@see`, `@api`,
and one `@!attribute` directive per member with `@return [Type] description`.

```ruby
# Immutable value object for a failed branch delete
#
# @example Create a failure object
#   failure = Git::BranchDeleteFailure.new(name: 'feature', result: result)
#   failure.name   #=> "feature"
#   failure.result #=> #<Git::CommandLineResult ...>
#
# @see Git::BranchDeleteResult
#
# @api public
#
# @!attribute [r] name
#
#   @return [String] the branch name that failed to delete
#
# @!attribute [r] result
#
#   @return [Git::CommandLineResult] the result of the failed delete
#
BranchDeleteFailure = Data.define(:name, :result)
```

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
- Methods use these standard YARD tags:
  - `@param` for each method parameter, in signature order; omit `@param` entirely
    on zero-argument methods
  - `@return` on every method; use `[void]` when the return value must not be used
  - `@raise` for each caller-relevant exception the method can raise as part of its
    contract; omit `@raise` when the method has no documented exceptional path
- Methods without Ruby `private` visibility must have one or more `@example`s;
  Ruby-private methods may omit `@example` unless usage would otherwise be unclear
- Methods that yield to a block must include `@yield [param_names]`, one
  `@yieldparam name [Type]` per yielded parameter, and `@yieldreturn [Type]`; omit
  all yield tags on methods that do not yield
- Use `@overload` when a method has distinct call signatures with different
  parameters or return types — each overload gets its own full set of tags.
  Methods that yield only when an optional block is given should use `@overload`
  to document the with-block and without-block signatures separately
- Methods whose signature uses an **anonymous keyword splat** (`**`),
  **anonymous positional splat** (`*`), or the **argument forwarding
  parameter** (`...`) must document their call shapes with `@overload` blocks
  that name the parameters. `@param`, `@option`, `@yield`, and `@yieldparam`
  cannot bind to an anonymous splat or to `...` — the named overload signature
  is what gives YARD a parameter to attach the docs to. Do **not** introduce a
  named splat (or expand `...` into `*args, **kwargs, &block`) solely so the
  tags will bind; that conflicts with RuboCop's `Style/ArgumentsForwarding`
  cop, and the `@overload` form satisfies both
- Use `@note` for callouts that need visual emphasis: thread-safety warnings,
  significant side effects, or platform-specific behaviour
- Deprecated methods must include `@deprecated` explaining the migration path,
  e.g. `@deprecated Use {#new_method} instead`
- `@api` is optional on methods — when omitted, the method inherits the containing
  class's `@api` level. Use it only when the method's intended visibility differs
  from the class's level (e.g. an `@api private` helper inside an `@api public`
  class)

## Step 1: Identify What Needs Documentation

```bash
# Find undocumented objects
bundle exec yard stats --list-undoc

# Check a specific file
bundle exec yard doc lib/git/base.rb --no-output
```

## Step 2: Write Documentation

Follow the YARD documentation templates below. Use the **standard template** when a
method has a single call signature. Use the **overload template** when a method has
distinct call signatures with different parameters or return types.

**Do NOT mix top-level `@param`/`@return`/`@raise` with `@overload` blocks** — YARD
silently ignores top-level tags when overloads are present. In both templates
below, include only the tags that apply to the method.

### Standard template (no `@overload`)

When present, tags must appear in the order shown. `@param` tags appear in
parameter order; `@option` tags appear immediately after the `@param` for the hash
they describe. Every `@option` tag **must** be preceded by a `@param` for the
options hash, and all `@option` tags under that `@param` must reference the same
parameter name. For keyword arguments (`**options` or `**kwargs`), use
`@param options [Hash]` (or the actual splat name) as the preceding `@param`:

```ruby
# Short description of what the method does
#
# Longer description with more details about behavior,
# edge cases, or important notes.
#
# @example Basic usage
#   git = Git.open('/path/to/repo')
#   result = git.method_name('arg')
#
# @example With options
#   git.method_name('arg', option: true)
#
# @param name [Type] description of parameter
#
# @param options [Hash] options hash description
#
# @option options [Type] :key description of option
#
# @param path [String] a parameter after the options hash
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
def method_name(name, options = {})
end
```

### Overload template

Each `@overload` block carries its own `@example`, `@param`, `@option`, `@return`,
`@raise`, `@yield`, `@yieldparam`, and `@yieldreturn` tags. Tags that are
**not** call-signature-specific — `@note`, `@deprecated`, `@see`, `@api` — remain
at the top level:

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
#     result = git.method_name('arg', force: true)
#
#   @param arg [String] the argument
#
#   @param options [Hash] additional options
#
#   @return [Array<String>] the results
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
def method_name(name, options = {})
end
```

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
#   @option options [Boolean] :all add, modify, and remove index entries to
#     match the worktree
#
#   @option options [Boolean] :force allow adding otherwise ignored files
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

## Step 3: Verify Documentation

```bash
# Generate and review docs
bundle exec yard doc
open doc/index.html

# Check for warnings
bundle exec yard doc 2>&1 | grep -i "warn"
```

Verify `@example` code runs correctly in `bundle exec bin/console`.
Check that all `@see` references point to valid targets.

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
