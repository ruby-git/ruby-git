---
name: reviewing-skills
description: 'Audits Agent Skills for quality, discoverability, and adherence to best practices. Use when reviewing a skill, checking skill quality, auditing skill descriptions, or validating skill structure before committing.'
---

# Reviewing Skills

Audit one or more Agent Skills for quality, discoverability, consistency, and
adherence to the Anthropic skill-authoring best practices.

## Contents

- [How to use this skill](#how-to-use-this-skill)
- [Related skills](#related-skills)
- [Input](#input)
- [Review checklist](#review-checklist)
  - [1. Frontmatter](#1-frontmatter)
  - [2. Description quality](#2-description-quality)
  - [3. Body structure and size](#3-body-structure-and-size)
  - [4. Conciseness](#4-conciseness)
  - [5. Degrees of freedom](#5-degrees-of-freedom)
  - [6. Progressive disclosure](#6-progressive-disclosure)
  - [7. Workflows and feedback loops](#7-workflows-and-feedback-loops)
  - [8. Content quality](#8-content-quality)
  - [9. Cross-skill consistency](#9-cross-skill-consistency)
  - [10. Discoverability sections](#10-discoverability-sections)
- [Output](#output)
- [Reference: Anthropic best-practices summary](#reference-anthropic-best-practices-summary)

## How to use this skill

Attach this file to your Copilot Chat context, then invoke it with the skill
folder or SKILL.md file(s) to review. Examples:

```text
Using the Reviewing Skills skill, review .github/skills/scaffold-new-command/.
```

```text
Review all skills under .github/skills/ for best-practice compliance.
```

## Related skills

- [Make Skill Template](../make-skill-template/SKILL.md) — scaffold new skills;
  use this reviewing skill afterward to validate quality
- [PR Readiness Review](../pr-readiness-review/SKILL.md) — final pre-PR quality
  gate (broader than skill-specific review)

## Input

One or more skill directories or SKILL.md files from `.github/skills/`.

## Review checklist

Work through each section below for every skill under review.

### 1. Frontmatter

- [ ] `name` is present, 1-64 chars, lowercase letters/numbers/hyphens only
- [ ] `name` matches the folder name exactly
- [ ] `name` does not contain reserved words (`anthropic`, `claude`)
- [ ] `description` is present, 1-1024 chars
- [ ] `description` does not contain XML tags

### 2. Description quality

The description is the **primary discovery mechanism** — it determines whether the
skill is selected from potentially hundreds of available skills.

- [ ] Written in **third person** (not "I can…" or "You can…")
- [ ] Describes **what** the skill does (capabilities)
- [ ] Describes **when** to use it (triggers, scenarios, keywords)
- [ ] Includes specific key terms users are likely to mention
- [ ] Is not vague (e.g. "Helps with documents" is too vague)

### 3. Body structure and size

- [ ] SKILL.md body is **under 500 lines** (optimal performance threshold)
- [ ] If approaching the limit, content is split into separate reference files
- [ ] Reference files are at most **one level deep** from SKILL.md (no
      deeply-nested chains like SKILL → A.md → B.md → actual content)
- [ ] Reference files longer than 100 lines include a table of contents

### 4. Conciseness

Every token in a loaded skill competes with conversation history and other
context. Challenge each piece of information:

- [ ] Only includes context the model does not already have
- [ ] Does not over-explain concepts the model already knows
- [ ] Avoids redundant paragraphs or verbose preambles
- [ ] Uses code examples instead of lengthy prose where possible

### 5. Degrees of freedom

Match instruction specificity to task fragility:

- [ ] **High freedom** (general text guidance) for tasks where multiple
      approaches are valid and context determines the best route
- [ ] **Medium freedom** (pseudocode / parameterized templates) for tasks with a
      preferred pattern but acceptable variation
- [ ] **Low freedom** (exact scripts, no parameters) for fragile or
      error-prone operations where consistency is critical
- [ ] The chosen level is appropriate for the skill's domain

### 6. Progressive disclosure

- [ ] SKILL.md serves as an overview / table of contents
- [ ] Detailed materials are in separate files loaded only when needed
- [ ] File names are descriptive (not `doc1.md`, `file2.md`)
- [ ] Directory structure is organized by domain or feature

### 7. Workflows and feedback loops

- [ ] Complex multi-step operations are broken into clear, sequential steps
- [ ] Long workflows include a progress checklist the agent can track
- [ ] Validation / feedback loops are present for quality-critical tasks
      (run validator → fix errors → repeat until clean)
- [ ] Decision points use conditional workflow patterns (if X → workflow A,
      if Y → workflow B)

### 8. Content quality

- [ ] No time-sensitive information (dates that will become stale); if legacy
      context is needed, it is in a collapsible "old patterns" section
- [ ] Consistent terminology throughout (one term per concept, not synonyms)
- [ ] Examples are concrete, not abstract
- [ ] All file paths use forward slashes (no Windows-style backslashes)
- [ ] No "voodoo constants" — every magic number or config value is justified

### 9. Cross-skill consistency

When reviewing multiple skills in the same repository:

- [ ] Naming convention is consistent (all gerund, all noun-phrase, or all
      action-oriented — not a mix)
- [ ] Shared policies (branch rules, commit conventions, quality gates,
      changelog policy) do not contradict each other
- [ ] Cross-skill links in `## Related skills` resolve to existing files
- [ ] Every skill referenced in `.github/copilot-instructions.md`'s routing
      table resolves to an existing `.github/skills/*/SKILL.md` file
- [ ] Stop/ask checkpoints are used consistently for comparable risk levels

### 10. Discoverability sections

Every skill in this repository must include these standard sections:

- [ ] `## Contents` — table of contents with anchor links
- [ ] `## How to use this skill` — brief invocation guidance
- [ ] `## Related skills` — cross-links to related skills with one-line
      descriptions

## Output

For each reviewed skill, produce:

1. A per-check result table:

   | # | Check | Status | Issue |
   |---|-------|--------|-------|

2. A summary of required fixes (if any)

3. A list of suggestions for improvement (optional, lower priority)

## Reference: Anthropic best-practices summary

This checklist is derived from the official Anthropic skill-authoring best
practices at
<https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices>.

Key principles distilled:

| Principle | One-liner |
|-----------|-----------|
| Concise is key | Only add context the model does not already have |
| Degrees of freedom | Match specificity to task fragility |
| Progressive disclosure | SKILL.md is an overview; details in separate files |
| Effective descriptions | Third-person, specific, includes triggers and keywords |
| Workflows | Sequential steps with checklists and feedback loops |
| No time-sensitive info | Avoid dates that will become stale |
| Consistent terminology | One term per concept throughout |
| One-level references | No deeply nested file chains |
| Under 500 lines | Split if approaching the limit |
| Test with real usage | Iterate based on observed agent behavior |

> **Branch workflow:** Implement any fixes on a feature branch. Never commit or
> push directly to `main` — open a pull request when changes are ready to merge.
