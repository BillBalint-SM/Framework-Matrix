# PAUL Framework — Ideation

Future development ideas for the PAUL orchestration framework. Referenced during milestone planning.

---

## Build > Log > Content Pipeline

**Concept:** When PAUL's UNIFY step runs at the end of a phase, it already captures what was built, decisions made, and outcomes. Extend this into an automated content generation pipeline.

### The Flow

```
BUILD (normal PAUL workflow)
    |
    v
UNIFY (existing step — captures build summary, decisions, outcomes)
    |
    v
BUILD LOG (new) — structured capture of what happened, why, how
    |
    v
CONTENT REVIEW SKILL (new) — reviews build logs, generates content outlines
    |
    v
BLOG STRATEGY WRITER SKILL (future) — transforms outlines into full posts
    |
    v
PUBLISH — post to chrisai.cv blog, optionally share to social
```

### Build Log Specification

The unify step currently produces a summary. The build log extends this with content-oriented metadata:

- **What was built** — Feature, tool, fix, framework update (already captured)
- **Why it matters** — The problem it solves, who cares, why now
- **How it was approached** — Key decisions, alternatives considered, trade-offs made
- **Meta-insights** — Patterns, principles, or methods that are teachable
- **Content hooks** — Suggested angles for turning this into content (tutorial, opinion piece, case study, quick tip)
- **Complexity tag** — Is this a quick-tip, a deep-dive, or a multi-part series?
- **Audience tag** — Beginner, intermediate, advanced Claude Code users

### Content Review Skill

A new PAUL skill (or post-unify hook) that:

1. Reads accumulated build logs since last review
2. Groups related work into potential content pieces
3. Generates content outlines with:
   - Suggested title
   - Key points to cover
   - Target format (blog post, carousel, video script, X thread)
   - Estimated depth (quick tip vs deep dive)
4. Queues outlines for the blog strategy writer workflow

### Integration Points

- **PSMM** — Build logs could feed PSMM entries for workspace-level awareness
- **Social Poster** — Content outlines tagged as "quick tip" or "carousel" route to social-poster for shortform
- **Course Command** — Deep-dive outlines could become course lessons
- **chrisai.cv** — Blog posts publish directly via site's content API

### Implementation Notes

- The unify step already runs — this is an EXTENSION, not a replacement
- Build log format should be a structured JSON/markdown hybrid for both human and machine readability
- The content review skill should be manually triggered (not automatic) to maintain quality control
- First version: just capture the build log. Content generation comes second.

### Open Questions

- Should build logs accumulate per-project or globally?
- How often should the content review skill run? Weekly? Per-milestone?
- Where do build logs live? Per-project `.paul/` or a central content staging area?
- How to handle builds that span multiple sessions?
