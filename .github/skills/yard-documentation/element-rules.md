# YARD Element-Specific Rules

Per-element YARD requirements for classes, modules, constants, attributes,
dynamically defined methods, and value objects
(`Data.define` / `Struct.new`).

Consult this file when documenting one of those elements. Rules that apply to
**every** doc comment (formatting, length limits, tag order) and to **methods**
live in [SKILL.md](SKILL.md).

## Contents

- [Contents](#contents)
- [Classes](#classes)
- [Modules](#modules)
- [Constants](#constants)
- [Attributes](#attributes)
- [Dynamically defined methods (`@!method`)](#dynamically-defined-methods-method)
- [`Data.define` classes](#datadefine-classes)
- [`Struct.new` classes](#structnew-classes)

## Classes

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
  (e.g., `Git::ExecutionContext::*`, `Git::Commands::*`, parsers)
- At least one `@example` showing typical instantiation or primary usage — this
  applies to all classes including `@api private` classes
- Error/exception classes must also state when the error is raised in class-level
  prose, using caller-facing wording such as `Raised when branch deletion fails`
- Deprecated classes must include `@deprecated` explaining the migration path
- When present, class-level tags must appear in this order: `@example`, `@note`,
  `@deprecated`, `@see`, `@api`, `@abstract`

## Modules

- One-sentence description — "Namespace for…", "Provides helpers for…", or
  "Mixin that adds…"
- `@api public` or `@api private` — use `@api public` for stable user-facing modules;
  use `@api private` for internal implementation modules
- No `@example` required unless the module provides standalone methods
- Deprecated modules must include `@deprecated` explaining the migration path
- When present, module-level tags must appear in the same order as class-level
  tags: `@example`, `@note`, `@deprecated`, `@see`, `@api`

## Constants

- A comment immediately above the constant describing its purpose and valid values
- No special YARD tag is needed; YARD picks up the preceding comment automatically
- Add `# @return [Type]` when the constant holds a collection, frozen structure, or
  domain-specific type whose shape is not immediately obvious from the value

## Attributes

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

## Dynamically defined methods (`@!method`)

Use the `# @!method name(params)` directive for methods created via
metaprogramming (`define_method`, method-generating DSLs, etc.) that have no
literal `def`. Place the directive and its doc comment where the method would
logically appear in the class body. Tags inside the directive block follow the
same indentation rule as `@!attribute` — indented two extra spaces relative to
the directive.

If an `@!method` block uses `@overload`, follow overload tag-placement rules in
[SKILL.md](SKILL.md): keep `@return` inside each overload, keep shared
`@raise` at top level, and keep `@api` at top level.

## `Data.define` classes

Immutable value objects defined with `Data.define` use the following conventions
(see `Git::BranchDeleteFailure` for a canonical example):

- Class-level doc: noun-phrase short description, `@example`, `@see`, `@api`
- One `@!attribute [r]` directive per member with `@return [Type] description`
- Attribute directives are placed after class-level tags and before the
  `Data.define` line
- Custom methods defined inside the `Data.define` block follow standard method
  rules

```ruby
# Immutable value object for a failed branch delete
#
# @example Create a failure object
#   failure = BranchDeleteFailure.new(
#     name: 'nonexistent',
#     error_message: "branch 'nonexistent' not found."
#   )
#   failure.name          #=> 'nonexistent'
#   failure.error_message #=> "branch 'nonexistent' not found."
#
# @see Git::BranchDeleteResult
#
# @api public
#
# @!attribute [r] name
#
#   @return [String] the branch name that failed to delete
#
# @!attribute [r] error_message
#
#   @return [String] the git error message explaining the failure
#
BranchDeleteFailure = Data.define(:name, :error_message)
```

## `Struct.new` classes

Document `Struct.new` classes using the same conventions as `Data.define` classes:
class-level doc with a noun-phrase short description, `@example`, `@see`, `@api`,
and one `@!attribute` directive per member with `@return [Type] description`.

Unlike `Data.define`, a `Struct.new` class is **mutable** — it generates
read-write accessors — so use `@!attribute [rw]` (not `[r]`) for its members and
do not describe it as immutable.

```ruby
# Value object for a diff hunk's location within a file
#
# @example Create and update a hunk location
#   loc = HunkLocation.new(start_line: 10, line_count: 3)
#   loc.start_line #=> 10
#   loc.line_count = 4
#   loc.line_count #=> 4
#
# @see Git::DiffInfo
#
# @api public
#
# @!attribute [rw] start_line
#
#   @return [Integer] the 1-based line where the hunk begins
#
# @!attribute [rw] line_count
#
#   @return [Integer] the number of lines the hunk spans
#
HunkLocation = Struct.new(:start_line, :line_count, keyword_init: true)
```
