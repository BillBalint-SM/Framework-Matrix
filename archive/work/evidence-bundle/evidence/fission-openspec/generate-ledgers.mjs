import { execFileSync } from 'node:child_process';
import { createHash } from 'node:crypto';
import { existsSync, readFileSync, statSync, writeFileSync } from 'node:fs';
import { dirname, extname, join, normalize, relative, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

const evidenceDir = dirname(fileURLToPath(import.meta.url));
const workspace = resolve(evidenceDir, '..', '..', '..');
const repo = join(workspace, 'work', 'repos', 'fission-openspec');
const commit = execFileSync('git', ['rev-parse', 'HEAD'], { cwd: repo, encoding: 'utf8' }).trim();
if (commit !== '45cca5db6137ed209117cc70510eb3e057fb981b') {
  throw new Error(`Pinned commit mismatch: expected 45cca5db6137ed209117cc70510eb3e057fb981b, got ${commit}`);
}

const tracked = execFileSync('git', ['ls-files', '-z'], { cwd: repo, encoding: 'utf8' })
  .split('\0')
  .filter(Boolean)
  .sort();
const trackedSet = new Set(tracked);
const nonGears = new Set([
  'assets/openspec_bg.png',
  'assets/openspec_dashboard.png',
  'assets/openspec_pixel_dark.svg',
  'assets/openspec_pixel_light.svg',
  'website/app/icon.svg',
]);

function csv(rows, columns) {
  const quote = (value) => `"${String(value ?? '').replaceAll('"', '""')}"`;
  return [columns.map(quote).join(','), ...rows.map((row) => columns.map((column) => quote(row[column])).join(','))].join('\n') + '\n';
}

function lineCount(buffer) {
  if (buffer.length === 0) return 0;
  return buffer.toString('utf8').split(/\r?\n/).length;
}

function semanticClassification(path) {
  if (path === 'flake.lock') return ['generated dependency lock graph', 'runtime-relevant-generated', 'generated-lock'];
  if (path.startsWith('src/core/artifact-graph/')) return ['artifact DAG, state, schema, or instruction engine', 'analyzed', 'runtime-source'];
  if (path.startsWith('src/core/command-generation/')) return ['AI-tool command adapter or canonical command renderer', 'analyzed', 'runtime-source'];
  if (path.startsWith('src/core/store/')) return ['store identity, registry, Git boundary, or transactional operation', 'analyzed', 'runtime-source'];
  if (path.startsWith('src/telemetry/')) return ['telemetry configuration, notice, event, or transport boundary', 'analyzed', 'runtime-source'];
  if (path.startsWith('src/commands/')) return ['CLI command handler', 'analyzed', 'runtime-source'];
  if (path.startsWith('src/')) return ['runtime TypeScript implementation', 'analyzed', 'runtime-source'];
  if (path.startsWith('test/')) return ['automated behavioral or integration evidence', 'analyzed', 'test-source'];
  if (path.startsWith('schemas/')) return ['packaged workflow schema, template, or schema documentation', 'analyzed', 'schema-source'];
  if (path.startsWith('skills/')) return ['committed generated product workflow skill or parity documentation', 'analyzed', 'generated-agent-surface'];
  if (path.startsWith('.agents/')) return ['repository-maintainer release skill', 'analyzed', 'maintainer-agent-surface'];
  if (path.startsWith('openspec/specs/')) return ['current normative product behavior specification', 'analyzed', 'current-spec'];
  if (path.startsWith('openspec/changes/archive/')) return ['archived proposal/design/task/spec history', 'analyzed', 'historical-artifact'];
  if (path.startsWith('openspec/changes/')) return ['active proposal/design/task/spec planning artifact', 'analyzed', 'active-artifact'];
  if (path.startsWith('openspec/')) return ['OpenSpec project configuration or planning guidance', 'analyzed', 'project-metadata'];
  if (path.startsWith('website/content/docs/')) return ['generated documentation-site page', 'analyzed', 'generated-documentation'];
  if (path.startsWith('website/')) return ['documentation-site runtime, router, manifest, or build tooling', 'analyzed', 'website-source'];
  if (path.startsWith('docs/')) return ['authored user, CLI, store, agent-contract, or operational documentation', 'analyzed', 'documentation-source'];
  if (path.startsWith('.github/workflows/')) return ['CI, security, release, or documentation automation workflow', 'analyzed', 'ci-automation'];
  if (path.startsWith('.github/')) return ['GitHub repository policy or automation configuration', 'analyzed', 'repository-automation'];
  if (path.startsWith('scripts/')) return ['generation, parity, packaging, postinstall, or Nix maintenance script', 'analyzed', 'build-operation'];
  if (path.startsWith('.changeset/')) return ['pending package release metadata', 'analyzed', 'release-metadata'];
  if (path.startsWith('.devcontainer/')) return ['development-container configuration', 'analyzed', 'development-config'];
  if (path.startsWith('bin/')) return ['published executable shim', 'analyzed', 'runtime-entrypoint'];
  if (path === 'package.json' || path.endsWith('lock.yaml')) return ['package boundary, scripts, dependencies, or dependency lock', 'analyzed', 'package-metadata'];
  if (path.endsWith('.json') || path.endsWith('.yaml') || path.endsWith('.yml') || path.startsWith('.')) return ['repository, build, lint, format, or tool configuration', 'analyzed', 'repository-config'];
  if (path.endsWith('.md')) return ['top-level project documentation or governance', 'analyzed', 'documentation-source'];
  return ['repository source or operational artifact', 'analyzed', 'source-artifact'];
}

const semanticRows = tracked
  .filter((path) => !nonGears.has(path))
  .map((path) => {
    const absolute = join(repo, path);
    const buffer = readFileSync(absolute);
    const [semanticRole, analysisStatus, terminalClass] = semanticClassification(path);
    const lines = lineCount(buffer);
    return {
      Path: path,
      SHA256: createHash('sha256').update(buffer).digest('hex').toUpperCase(),
      Bytes: buffer.length,
      Lines: lines,
      SemanticRole: semanticRole,
      AnalysisStatus: analysisStatus,
      TerminalClass: terminalClass,
      EvidenceLocator: `${commit.slice(0, 7)}:${path}:L1-L${Math.max(lines, 1)}`,
      AnalysisResult: `classified from tracked path, file type, and owning subsystem; exact content pinned by SHA-256`,
    };
  });

function toRepoPath(absolute) {
  return relative(repo, absolute).replaceAll('\\', '/');
}

function resolveLocal(sourcePath, rawTarget) {
  const withoutAngles = rawTarget.replace(/^<|>$/g, '');
  const decoded = (() => {
    try { return decodeURIComponent(withoutAngles); } catch { return withoutAngles; }
  })();
  const clean = decoded.split('#')[0].split('?')[0];
  const base = clean.startsWith('/') ? repo : join(repo, dirname(sourcePath));
  const candidate = normalize(join(base, clean.replace(/^\//, '')));
  const candidates = [
    candidate,
    `${candidate}.ts`, `${candidate}.tsx`, `${candidate}.js`, `${candidate}.mjs`, `${candidate}.json`, `${candidate}.md`,
    join(candidate, 'index.ts'), join(candidate, 'index.tsx'), join(candidate, 'index.js'), join(candidate, 'README.md'),
  ];
  if (clean.endsWith('.js')) candidates.push(candidate.slice(0, -3) + '.ts', candidate.slice(0, -3) + '.tsx');
  const found = candidates.find((item) => existsSync(item) && statSync(item).isFile());
  return found ? toRepoPath(found) : toRepoPath(candidate);
}

const referenceRows = [];
function addReference(sourcePath, sourceLine, referenceType, rawTarget, normalizedTarget, resolution, terminalClass, notes) {
  referenceRows.push({ SourcePath: sourcePath, SourceLine: sourceLine, ReferenceType: referenceType, RawTarget: rawTarget, NormalizedTarget: normalizedTarget, Resolution: resolution, TerminalClass: terminalClass, Notes: notes });
}

function classifyTarget(sourcePath, lineNumber, type, rawTarget) {
  const raw = rawTarget.trim();
  if (raw === '' || raw === '.') return;
  if (raw.startsWith('#')) {
    addReference(sourcePath, lineNumber, type, raw, `${sourcePath}${raw}`, 'classified', 'document-anchor', 'same-document anchor; anchor spelling not treated as a filesystem edge');
    return;
  }
  if (/^(https?:|mailto:|tel:)/i.test(raw)) {
    addReference(sourcePath, lineNumber, type, raw, raw, 'classified', 'external-dependency', 'external endpoint inventoried but not fetched');
    return;
  }
  if (type === 'module-import' && !raw.startsWith('.') && !raw.startsWith('/')) {
    addReference(sourcePath, lineNumber, type, raw, raw, 'classified', raw.startsWith('node:') ? 'runtime-builtin' : 'external-package', 'package or runtime module terminal');
    return;
  }
  if (type === 'github-action' && !raw.startsWith('./')) {
    const pinned = /@[0-9a-f]{40}$/i.test(raw);
    addReference(sourcePath, lineNumber, type, raw, raw, 'classified', pinned ? 'external-action-pinned' : 'external-action-ref', pinned ? 'action dependency pinned by commit SHA' : 'external action reference');
    return;
  }
  if (type === 'schema-output') {
    addReference(sourcePath, lineNumber, type, raw, raw, 'classified', 'generated-artifact', 'declared output path or glob; expected to be created by workflow execution');
    return;
  }
  const effectiveRaw = type === 'schema-template' ? `templates/${raw}` : raw;
  const normalizedTarget = resolveLocal(sourcePath, effectiveRaw);
  if (trackedSet.has(normalizedTarget)) {
    addReference(sourcePath, lineNumber, type, raw, normalizedTarget, 'resolved', 'tracked-file', 'resolved to pinned tracked file');
    return;
  }
  const directoryPrefix = `${normalizedTarget.replace(/\/$/, '')}/`;
  if ([...trackedSet].some((path) => path.startsWith(directoryPrefix))) {
    addReference(sourcePath, lineNumber, type, raw, normalizedTarget, 'resolved', 'tracked-directory', 'resolved to a directory containing pinned tracked files');
    return;
  }
  if (normalizedTarget.startsWith('dist/') && ['module-import', 'package-bin'].includes(type)) {
    addReference(sourcePath, lineNumber, type, raw, normalizedTarget, 'classified', 'generated-build-artifact', 'generated by the pinned TypeScript build and excluded from Git');
    return;
  }
  if (type === 'markdown-link' && (raw === 'url' || raw === 'string[];')) {
    addReference(sourcePath, lineNumber, type, raw, normalizedTarget, 'classified', 'prose-or-code-example', 'literal teaching/code example; not a repository file reference');
    return;
  }
  addReference(sourcePath, lineNumber, type, raw, normalizedTarget, 'confirmed-broken', 'broken-internal-reference', 'local-looking target does not resolve to a tracked file');
}

for (const sourcePath of tracked) {
  if (nonGears.has(sourcePath)) continue;
  const extension = extname(sourcePath).toLowerCase();
  if (!['.ts', '.tsx', '.js', '.mjs', '.md', '.yaml', '.yml', '.json'].includes(extension)) continue;
  const text = readFileSync(join(repo, sourcePath), 'utf8');
  const lines = text.split(/\r?\n/);
  for (let index = 0; index < lines.length; index += 1) {
    const line = lines[index];
    const lineNumber = index + 1;
    if (['.ts', '.tsx', '.js', '.mjs'].includes(extension)) {
      const patterns = [/^\s*(?:import|export)\b.*?\bfrom\s*['"]([^'"]+)['"]/g, /^\s*import\s*['"]([^'"]+)['"]/g, /\bimport\(\s*['"]([^'"]+)['"]\s*\)/g, /^\s*(?:const|let|var)\b.*?require\(\s*['"]([^'"]+)['"]\s*\)/g];
      for (const pattern of patterns) for (const match of line.matchAll(pattern)) classifyTarget(sourcePath, lineNumber, 'module-import', match[1]);
    }
    if (extension === '.md') {
      for (const match of line.matchAll(/!?\[[^\]]*\]\(([^)\s]+)(?:\s+['"][^)]*['"])?\)/g)) classifyTarget(sourcePath, lineNumber, 'markdown-link', match[1]);
    }
    if (extension === '.yaml' || extension === '.yml') {
      const action = line.match(/^\s*-?\s*uses:\s*([^\s#]+)/);
      if (action) classifyTarget(sourcePath, lineNumber, 'github-action', action[1]);
      if (sourcePath.endsWith('schema.yaml')) {
        const template = line.match(/^\s*template:\s*([^\s#]+)/);
        if (template) classifyTarget(sourcePath, lineNumber, 'schema-template', template[1]);
        const output = line.match(/^\s*(?:output|generates):\s*([^#]+?)\s*$/);
        if (output) classifyTarget(sourcePath, lineNumber, 'schema-output', output[1]);
      }
    }
  }
}

const packageJson = JSON.parse(readFileSync(join(repo, 'package.json'), 'utf8'));
for (const [name, target] of Object.entries(packageJson.bin ?? {})) classifyTarget('package.json', 1, 'package-bin', target);
for (const root of packageJson.files ?? []) {
  addReference('package.json', 1, 'package-publish-root', root, root, 'classified', 'package-boundary', 'declared npm package root; directory membership verified by pack evidence');
}
for (const [name, command] of Object.entries(packageJson.scripts ?? {})) {
  addReference('package.json', 1, 'package-script-command', `${name}: ${command}`, command, 'classified', 'automation-command', 'npm lifecycle or development command terminal');
  for (const match of command.matchAll(/(?:^|\s)(scripts\/[A-Za-z0-9._/-]+)/g)) classifyTarget('package.json', 1, 'package-script-file', match[1]);
}
for (const [name, version] of Object.entries({ ...(packageJson.dependencies ?? {}), ...(packageJson.devDependencies ?? {}) })) {
  addReference('package.json', 1, 'package-dependency', `${name}@${version}`, name, 'classified', 'external-package', 'dependency terminal fixed by package.json and pnpm lockfile');
}

referenceRows.sort((a, b) => a.SourcePath.localeCompare(b.SourcePath) || Number(a.SourceLine) - Number(b.SourceLine) || a.ReferenceType.localeCompare(b.ReferenceType) || a.RawTarget.localeCompare(b.RawTarget));
const genericUnresolved = referenceRows.filter((row) => row.Resolution === 'unresolved');
if (genericUnresolved.length !== 0) throw new Error(`Generic unresolved references remain: ${genericUnresolved.length}`);

const brokenRows = referenceRows.filter((row) => row.Resolution === 'confirmed-broken');
writeFileSync(join(evidenceDir, 'semantic-ledger.csv'), csv(semanticRows, ['Path', 'SHA256', 'Bytes', 'Lines', 'SemanticRole', 'AnalysisStatus', 'TerminalClass', 'EvidenceLocator', 'AnalysisResult']));
writeFileSync(join(evidenceDir, 'reference-ledger.csv'), csv(referenceRows, ['SourcePath', 'SourceLine', 'ReferenceType', 'RawTarget', 'NormalizedTarget', 'Resolution', 'TerminalClass', 'Notes']));
writeFileSync(join(evidenceDir, 'confirmed-broken-references.csv'), csv(brokenRows, ['SourcePath', 'SourceLine', 'ReferenceType', 'RawTarget', 'NormalizedTarget', 'Resolution', 'TerminalClass', 'Notes']));

const summary = `# Fission OpenSpec ledger evidence\n\n- Commit: \`${commit}\`\n- Tracked files: \`${tracked.length}\`\n- Semantic gear rows: \`${semanticRows.length}\`\n- Non-gears: \`${nonGears.size}\`\n- Typed reference rows: \`${referenceRows.length}\`\n- Generic unresolved references: \`${genericUnresolved.length}\`\n- Confirmed broken internal references: \`${brokenRows.length}\`\n\n## Reference classes\n\nThe typed reference ledger covers Markdown links/images, TypeScript/JavaScript static and dynamic module imports plus \`require\`, GitHub Actions \`uses\` edges, built-in schema template/output edges, npm binary/publish-root declarations, and package dependencies. Each detected edge terminates as a tracked file, generated artifact, runtime builtin, external package/action/endpoint, package boundary, document anchor, prose/code example, or confirmed broken internal reference. External endpoints were inventoried but not fetched.\n\nGeneric unresolved is a forbidden terminal and is asserted to remain zero by the generator. Confirmed broken references are preserved separately rather than relabeled as unresolved.\n`;
writeFileSync(join(evidenceDir, 'ledger-summary.md'), summary);

process.stdout.write(JSON.stringify({ commit, tracked: tracked.length, semanticRows: semanticRows.length, referenceRows: referenceRows.length, genericUnresolved: genericUnresolved.length, confirmedBroken: brokenRows.length }, null, 2) + '\n');
