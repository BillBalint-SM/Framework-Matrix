---
name: paul:plan
description: Enter PLAN phase for current or new plan
argument-hint: "[phase-plan]"
allowed-tools: [Read, Write, Glob, AskUserQuestion]
---

<objective>
Create or continue a PLAN for the specified phase.

**When to use:** Starting new work or resuming incomplete plan.
</objective>

<execution_context>
@C:\Users\littl\Documents\Codex\2026-08-02\research-c-users-littl-agents-skills\work\evidence\christopherkahler-paul\install-smoke/paul-framework/workflows/plan-phase.md
@C:\Users\littl\Documents\Codex\2026-08-02\research-c-users-littl-agents-skills\work\evidence\christopherkahler-paul\install-smoke/paul-framework/templates/PLAN.md
@C:\Users\littl\Documents\Codex\2026-08-02\research-c-users-littl-agents-skills\work\evidence\christopherkahler-paul\install-smoke/paul-framework/references/plan-format.md
</execution_context>

<context>
$ARGUMENTS

@.paul/PROJECT.md
@.paul/STATE.md
@.paul/ROADMAP.md
</context>

<process>
Follow workflow: @C:\Users\littl\Documents\Codex\2026-08-02\research-c-users-littl-agents-skills\work\evidence\christopherkahler-paul\install-smoke/paul-framework/workflows/plan-phase.md
</process>

<success_criteria>
- [ ] PLAN.md created in correct phase directory
- [ ] All acceptance criteria defined
- [ ] STATE.md updated with loop position
</success_criteria>
