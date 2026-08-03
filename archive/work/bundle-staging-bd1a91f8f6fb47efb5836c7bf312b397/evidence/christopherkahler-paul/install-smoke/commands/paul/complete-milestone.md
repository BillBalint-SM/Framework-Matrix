---
name: paul:complete-milestone
description: Mark current milestone as complete
argument-hint: "[version]"
allowed-tools: [Read, Write, Edit, Bash, Glob]
---

<objective>
Complete the current milestone, archive it, and evolve PROJECT.md.

**When to use:** All phases in current milestone are complete and verified.
</objective>

<execution_context>
@C:\Users\littl\Documents\Codex\2026-08-02\research-c-users-littl-agents-skills\work\evidence\christopherkahler-paul\install-smoke/paul-framework/workflows/complete-milestone.md
</execution_context>

<context>
$ARGUMENTS

@.paul/PROJECT.md
@.paul/STATE.md
@.paul/ROADMAP.md
@.paul/MILESTONES.md
</context>

<process>
Follow workflow: @C:\Users\littl\Documents\Codex\2026-08-02\research-c-users-littl-agents-skills\work\evidence\christopherkahler-paul\install-smoke/paul-framework/workflows/complete-milestone.md
</process>

<success_criteria>
- [ ] Milestone archived with summary
- [ ] PROJECT.md evolved with learnings
- [ ] Git tag created for version
- [ ] STATE.md updated to reflect completion
</success_criteria>
