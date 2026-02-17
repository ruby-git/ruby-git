## Review Cross-Command Consistency

Review sibling command classes (same module/family) for consistent structure,
documentation, testing, and exit-status conventions under the `Base` architecture.

### Related prompts

- **Review Command Implementation** — canonical class-shape checklist, phased
  rollout gates, and internal compatibility contracts
- **Review Arguments DSL** — verifying DSL entries match git CLI
- **Review Command Tests** — unit/integration test expectations for command classes
- **Review YARD Documentation** — documentation completeness for command classes

### What to Check

#### 1. Class structure consistency

- [ ] all classes use `class < Base`
- [ ] all require `git/commands/base`
- [ ] all use `arguments do ... end` (no legacy `ARGS =` constants)
- [ ] all use YARD shim `def call(...) = super # rubocop:disable Lint/UselessMethodDefinition`

#### 2. Arguments DSL consistency

- [ ] shared options use same alias/modifier patterns
- [ ] shared entries appear in same relative order
- [ ] command-specific differences are intentional and documented

#### 3. Exit-status consistency

- [ ] siblings with same git exit semantics use same `allow_exit_status` range
- [ ] rationale comments are present and consistent in tone
- [ ] commands without non-zero successful exits do not declare custom ranges

#### 4. YARD consistency

- [ ] consistent class summaries and `@api private`
- [ ] `@overload` coverage consistent for equivalent call shapes
- [ ] `@return` and `@raise` wording consistent across siblings

#### 5. Unit spec consistency

- [ ] expectations include `raise_on_failure: false` where command invocation is asserted
- [ ] similar option paths use similar context naming
- [ ] exit-status tests are parallel where ranges are shared

#### 6. Integration spec consistency

- [ ] success/failure grouping uses same structure
- [ ] no output-format assertions (smoke + error handling only)

#### 7. Migration process consistency

See **Review Command Implementation § Phased rollout / rollback requirements** for
the canonical checklist. During a cross-command audit, verify that sibling commands
were migrated in the same slice and that the same quality gates were applied.

### Output

1. Summary table:

| Aspect | File A | File B | File C | Status |
|---|---|---|---|---|

2. Inconsistency list with canonical recommendation:

| Issue | Files | Recommended canonical form |
|---|---|---|
