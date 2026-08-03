# Fission OpenSpec ledger evidence

- Commit: `45cca5db6137ed209117cc70510eb3e057fb981b`
- Tracked files: `1041`
- Semantic gear rows: `1036`
- Non-gears: `5`
- Typed reference rows: `2441`
- Generic unresolved references: `0`
- Confirmed broken internal references: `1`

## Reference classes

The typed reference ledger covers Markdown links/images, TypeScript/JavaScript static and dynamic module imports plus `require`, GitHub Actions `uses` edges, built-in schema template/output edges, npm binary/publish-root declarations, and package dependencies. Each detected edge terminates as a tracked file, generated artifact, runtime builtin, external package/action/endpoint, package boundary, document anchor, prose/code example, or confirmed broken internal reference. External endpoints were inventoried but not fetched.

Generic unresolved is a forbidden terminal and is asserted to remain zero by the generator. Confirmed broken references are preserved separately rather than relabeled as unresolved.
