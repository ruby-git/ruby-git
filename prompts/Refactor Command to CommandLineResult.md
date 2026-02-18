## How to use this prompt

Attach this file to your Copilot Chat context, then invoke it with the command
class or source file to migrate. Examples:

```text
Using the Refactor Command to CommandLineResult prompt, migrate
Git::Commands::Stash::Pop to the Base pattern.
```

```text
Refactor Command to CommandLineResult: lib/git/commands/branch/delete.rb
```

The invocation needs the command class name or file path of the command to
refactor.

---

## Refactor Command to CommandLineResult

Migrate a command that still performs parsing or custom execution logic to the
`Git::Commands::Base` pattern, so command classes return raw
`Git::CommandLineResult` and parsing moves to facade/parser layers.

### Related prompts

- **Review Command Implementation** — canonical class-shape checklist, phased
  rollout gates, and internal compatibility contracts
- **Review Arguments DSL** — verifying DSL entries match git CLI
- **Review Command Tests** — unit/integration test expectations for command classes
- **Review Backward Compatibility** — preserving `Git::Lib` return-value contracts

### Target end state

```ruby
class SomeCommand < Base
  arguments do
    ...
  end

  # optional for non-zero successful exits
  # rationale comment
  # allow_exit_status 0..1

  def call(...) = super # rubocop:disable Lint/UselessMethodDefinition
end
```

### Refactor steps

1. Move parsing/transforming logic out of command class into caller/facade/parser.
2. Replace legacy `ARGS` constant + custom `initialize` with `arguments do` +
   inheritance from `Base`.
3. Replace custom `#call` body with `def call(...) = super`.
4. If command requires non-default success exits, add `allow_exit_status` with
   rationale comment.
5. Update callers to consume `CommandLineResult` and parse `result.stdout` where
   needed.

### What to remove from command classes

- parser invocations
- output transformation logic
- manual `raise_on_failure` / manual exit-code checks (unless temporarily needed in
  an unmigrated class)
- duplicated bind/execute logic

### What to update in tests

- unit specs should assert CLI args and `CommandLineResult` behavior
- remove parsed-object assertions from command unit specs
- move parsing expectations to parser/facade tests
- include `raise_on_failure: false` in mocked command expectations

### YARD updates

- update `@return` to `Git::CommandLineResult`
- keep command-specific `@overload` docs on `def call(...) = super`
- ensure `@raise` wording reflects allowed range behavior

### Migration process and internal compatibility

See **Review Command Implementation** for the canonical phased rollout checklist
and internal compatibility contract. In summary:

- **always work on a feature branch** — never commit or push directly to `main`;
  create a branch before starting (`git checkout -b <feature-branch-name>`) and
  open a pull request when the slice is ready
- perform refactor in phased slices (pilot/family)
- keep each slice independently revertible
- do not mix unrelated behavior changes with refactor-only changes
- pass slice gates: `bundle exec rspec`, `bundle exec rake test`,
  `bundle exec rubocop`, `bundle exec yard`
