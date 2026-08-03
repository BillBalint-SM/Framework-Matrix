# Retained System Design template contract

## Source identity

- Retained reference: `work/document-template/reference.docx`
- SHA-256: `13504F6C221A42C1726460A9E865E563355539FF97D702D6C9B2267B4B261D76`
- Reference rendering: 6 portrait Letter pages.
- The retained reference is read-only and must remain byte-identical.
- Task-local builder: `work/document-template/build_system_design.py`.
- Editable output: `outputs/sdd-framework-system-design.docx`.

## Structural inventory

- One section, Letter 8.5 x 11 in, portrait, margins L/R/T 0.70 in and B 0.62 in.
- Different first page; independent header/footer; two header parts and two footer parts retained.
- 89 body paragraphs, 9 tables, 1 inline image, and one template footnote marker/part.
- Paragraph styles: 21 Heading 1, 3 Heading 3, 2 Title, 63 normal.
- Embedded Helvetica Neue and Helvetica Neue Light regular/bold/italic/bold-italic fonts.
- Numbering, styles, theme, settings, headers, footers, font table, relationships, and embedded fonts are preserve-only package features.

## Component and slot map

- Cover: system name, proposal title, status/owner/date strip, authors/reviewers/related-materials/scope table.
- Body: 12 numbered sections using retained Heading 1 geometry; retained Heading 3 subheads for component and contract callouts.
- Tables: goals/non-goals, component inventory, primary contract, failure scenarios, readiness, alternatives, and milestones keep the reference row/column geometry.
- Figure: replace only `word/media/image1.png` through its existing relationship and set meaningful title/description text.
- Footer: retain its position and styling; replace only visible label text.
- Open questions: retain four separate alphabetically numbered paragraphs; each item must start on its own rendered baseline.

## Fidelity and acceptance gates

- Preserve every reference package part and all preserve-only styling/numbering/section behavior. The builder may add only `docProps/core.xml` plus its content-type/root-relationship declarations for task-owned metadata.
- Content growth may extend the filled document from the 6-page template baseline to 7 pages, but must not create clipping, overlap, split list boundaries, orphaned headings, or unreadable tables.
- Render every final page with the task-local portable LibreOffice path and inspect 100% of the page images.
- Run section, heading, image, footnote, style, accessibility, and package-structure audits after every accepted regeneration.
- The final image must have meaningful alt text. The two retained Heading 1 to Heading 3 skips are inherited template semantics and are the only accepted accessibility warnings.
- Verify the retained reference SHA-256 again after generation.
