---
name: paul:add-phase
description: Add a new phase to current milestone
argument-hint: "[phase-name]"
allowed-tools: [Read, Write, Edit, Bash]
---

<objective>
Add a new phase to the current milestone's roadmap.

**When to use:** Scope expansion during milestone, adding planned work.
</objective>

<execution_context>
@C:\Users\littl\Documents\Codex\2026-08-02\research-c-users-littl-agents-skills\work\evidence\christopherkahler-paul\install-smoke/paul-framework/workflows/roadmap-management.md
</execution_context>

<context>
$ARGUMENTS

@.paul/PROJECT.md
@.paul/STATE.md
@.paul/ROADMAP.md
</context>

<process>
Follow workflow: @C:\Users\littl\Documents\Codex\2026-08-02\research-c-users-littl-agents-skills\work\evidence\christopherkahler-paul\install-smoke/paul-framework/workflows/roadmap-management.md

Execute: **add-phase** operation
</process>

<success_criteria>
- [ ] Phase added to ROADMAP.md
- [ ] Phase directory created
- [ ] STATE.md updated with new phase
</success_criteria>
