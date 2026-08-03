'use strict';

const fs = require('node:fs');
const path = require('node:path');

function requireArguments(argv) {
  if (argv.length !== 5) {
    throw new Error('Usage: node reference-ledger-open-gsd.cjs <repo> <inventory.csv> <references.csv> <summary.json>');
  }
  return {
    repo: path.resolve(argv[1]),
    inventory: path.resolve(argv[2]),
    output: path.resolve(argv[3]),
    summary: path.resolve(argv[4]),
  };
}

function parseInventory(csv) {
  const lines = csv.replace(/^\uFEFF/, '').split(/\r?\n/).filter(Boolean);
  if (lines[0] !== '"Path","Bytes","SHA256","Extension","Category","GearCandidate","HashError"') {
    throw new Error(`Unexpected inventory header: ${lines[0]}`);
  }
  return lines.slice(1).map((line) => {
    const match = line.match(/^"([^"]+)","([^"]*)","([^"]*)","([^"]*)","([^"]*)","(True|False)","?([^"]*)"?$/);
    if (!match) throw new Error(`Unparseable inventory row: ${line}`);
    return { path: match[1], gear: match[6] === 'True' };
  });
}

function csvCell(value) {
  return `"${String(value).replace(/"/g, '""')}"`;
}

function normalizeRaw(raw) {
  return raw
    .trim()
    .replace(/^['"`]+|['"`,;:]+$/g, '')
    .replace(/[)>}\]]+$/g, '');
}

function collectLineMatches(line) {
  const matches = [];
  const grammars = [
    ['markdown_link', /\]\(([^)\s]+)\)/g],
    ['at_include', /@((?:(?:~|\$HOME)\/|\.{1,2}\/|\.(?:planning|claude|codex|cursor|agents|github|gsd)\/)[^\s`'"<>|]*)/g],
    ['module_import', /(?:require|import)\s*\(\s*['"]([^'"]+)['"]\s*\)|\bfrom\s+['"]([^'"]+)['"]/g],
    ['path_token', /(?<![A-Za-z0-9_.])((?:(?:\.{1,2}|~|[A-Za-z0-9_$@{}<>*-]+)\/)+(?:[A-Za-z0-9_$@{}<>*.-]+\/)*[A-Za-z0-9_$@{}<>*.-]+\.(?:md|cjs|cts|mjs|js|json|ya?ml|toml|xml|sh|ts|txt|bin|svg|png))(?![A-Za-z0-9_])/g],
  ];
  for (const [syntax, regex] of grammars) {
    for (const match of line.matchAll(regex)) {
      const raw = normalizeRaw(match[1] || match[2] || '');
      if (!raw) continue;
      if (syntax === 'markdown_link' && !/^(?:https?:|mailto:|#|\.{0,2}\/|[A-Za-z0-9_@.-]+\/|[A-Za-z0-9_.-]+\.(?:md|cjs|cts|mjs|js|json|ya?ml|toml|xml|sh|ts|txt|bin|svg|png))[^\s]*$/.test(raw)) continue;
      if (syntax === 'module_import' && !/^[A-Za-z0-9_@.$/{}/:<>=*?+-]+$/.test(raw)) continue;
      matches.push({ syntax, raw });
    }
  }
  return matches;
}

function pathExists(repo, relativePath) {
  if (!relativePath) return false;
  const candidate = path.resolve(repo, ...relativePath.split('/'));
  const prefix = `${repo}${path.sep}`;
  if (candidate !== repo && !candidate.startsWith(prefix)) return false;
  return fs.existsSync(candidate);
}

function candidatePaths(sourcePath, raw, syntax) {
  const withoutFragment = raw.split('#')[0].split('?')[0];
  const clean = withoutFragment.replace(/^@/, '').replace(/\\/g, '/');
  const values = [];
  if (clean.startsWith('~/.claude/gsd-core/')) {
    values.push(`gsd-core/${clean.slice('~/.claude/gsd-core/'.length)}`);
  } else if (clean.startsWith('$HOME/.claude/gsd-core/')) {
    values.push(`gsd-core/${clean.slice('$HOME/.claude/gsd-core/'.length)}`);
  } else if (clean.startsWith('./') || clean.startsWith('../')) {
    values.push(path.posix.normalize(path.posix.join(path.posix.dirname(sourcePath), clean)));
  } else if (syntax === 'markdown_link') {
    values.push(path.posix.normalize(path.posix.join(path.posix.dirname(sourcePath), clean)));
    values.push(path.posix.normalize(clean.replace(/^\//, '')));
  } else {
    values.push(path.posix.normalize(clean.replace(/^\//, '')));
    values.push(path.posix.normalize(path.posix.join(path.posix.dirname(sourcePath), clean)));
  }
  const expanded = [];
  for (const value of values) {
    expanded.push(value);
    if (/^(?:planning|claude|codex|cursor|agents|github|opencode|kilo)\//.test(value)) expanded.push(`.${value}`);
    if (sourcePath.startsWith('gsd-core/') && /^(?:references|workflows|templates|contexts|bin)\//.test(value)) {
      expanded.push(`gsd-core/${value}`);
    }
    if ((sourcePath.startsWith('agents/') || sourcePath.startsWith('commands/') || sourcePath.startsWith('skills/')) && /^(?:references|workflows|templates|contexts)\//.test(value)) {
      expanded.push(`gsd-core/${value}`);
    }
    if (sourcePath.startsWith('src/') && value.endsWith('.cjs')) {
      expanded.push(`gsd-core/bin/lib/${path.posix.basename(value)}`);
    }
    if (value.startsWith('gsd-core/bin/lib/') && value.endsWith('.cjs')) {
      const fileName = path.posix.basename(value);
      expanded.push(`src/${fileName.slice(0, -4)}.cts`);
      expanded.push(`scripts/lib/${fileName}`);
    }
    if (!path.posix.extname(value)) {
      for (const extension of ['.cts', '.cjs', '.js', '.mjs', '.json', '.md']) expanded.push(`${value}${extension}`);
      for (const extension of ['.cts', '.cjs', '.js', '.mjs', '.json']) expanded.push(`${value}/index${extension}`);
    }
    if (value.endsWith('.cjs')) expanded.push(`${value.slice(0, -4)}.cts`);
    if (value.endsWith('.js')) expanded.push(`${value.slice(0, -3)}.cts`);
  }
  return [...new Set(expanded.filter((value) => value && value !== '.'))];
}

function classify(repo, sourcePath, raw, syntax) {
  const clean = raw.replace(/^@/, '');
  const runtimeClean = clean.replace(/^\.\//, '');
  if (sourcePath === 'gsd-core/references/reviewer-instances.md' && clean === '../docs/adr/1517-reviewer-instances-config-surface.md') {
    return { root: 'source_relative', target: 'gsd-core/docs/adr/1517-reviewer-instances-config-surface.md', exists: 'false', terminal: 'confirmed_broken', reason: 'Pinned source and installed-layout relative link both miss; repository ADR is docs/adr/1517-reviewer-instances-config-surface.md.' };
  }
  if (/^(?:package-lock\.json|\.gitignore|\.gitattributes|\.secretscanignore|\.base64scanignore)$/.test(sourcePath) || /^(?:eslint|stryker)\.config\./.test(sourcePath)) {
    return { root: 'configuration', target: clean, exists: '', terminal: 'configuration_or_dependency_pattern', reason: 'Pattern or dependency metadata, not a dereferenced project path.' };
  }
  if (/^(?:https?:|mailto:|data:|node:)/i.test(clean)) {
    return { root: 'external', target: clean, exists: '', terminal: 'external', reason: 'Not a repository-internal path.' };
  }
  if (/^(?:[A-Za-z@][A-Za-z0-9_.-]*)(?:\/[A-Za-z0-9_.-]+)*$/.test(clean) && syntax === 'module_import') {
    return { root: 'dependency', target: clean, exists: '', terminal: 'package_or_builtin', reason: 'Bare module specifier.' };
  }
  if (/[{}<>*]|\$[A-Za-z_{]|\[\[|\.\.\.|\b(?:slug|phase|name|path|runtime|id)\b/i.test(clean)) {
    return { root: 'dynamic', target: clean, exists: '', terminal: 'dynamic_or_template', reason: 'Contains placeholder, glob, or generated segment.' };
  }
  if (/^(?:\.?planning\/|\.?claude\/|\.?codex\/|\.?cursor\/|\.?github\/|\.?agents\/|\.gsd\/|~\/|\$HOME\/|\/tmp\/|node_modules\/)/.test(runtimeClean)) {
    if (clean.startsWith('~/.claude/gsd-core/') || clean.startsWith('$HOME/.claude/gsd-core/')) {
      const candidates = candidatePaths(sourcePath, raw, syntax);
      const resolved = candidates.find((value) => pathExists(repo, value));
      if (resolved) return { root: 'canonical_install_projection', target: resolved, exists: 'true', terminal: 'source_projection', reason: 'Canonical installed path maps to shipped gsd-core source.' };
    }
    return { root: 'runtime', target: runtimeClean, exists: '', terminal: 'runtime_artifact', reason: 'Created or resolved only in an installed/project runtime.' };
  }
  if (/^(?:research|spikes|sketches|onboarding|debug|intel|codebase|cache|tmp|graphs)\//.test(clean)) {
    return { root: 'project_runtime', target: `.planning/${clean}`, exists: '', terminal: 'runtime_artifact', reason: 'Project-relative planning artifact referenced from a workflow or prompt.' };
  }
  const candidates = candidatePaths(sourcePath, raw, syntax);
  const resolved = candidates.find((value) => pathExists(repo, value));
  if (resolved) {
    const projection = resolved !== candidates[0] && (resolved.endsWith('.cts') || resolved.includes('/index.'));
    return {
      root: syntax === 'markdown_link' || clean.startsWith('.') ? 'source_relative' : 'repository',
      target: resolved,
      exists: 'true',
      terminal: projection ? 'generated_projection_source' : 'source_file',
      reason: projection ? 'Generated/import projection resolves to canonical source.' : 'Existing pinned-tree target.',
    };
  }
  if (/^(?:tests\/|\.changeset\/|docs\/adr\/|docs\/(?:ja-JP|ko-KR|pt-BR|zh-CN)\/)/.test(sourcePath)) {
    return { root: 'fixture_or_history', target: candidates[0] || clean, exists: 'false', terminal: 'fixture_history_example', reason: 'Unresolved token occurs in test, changeset, ADR, or translated prose context.' };
  }
  if (syntax === 'path_token' && /^(?:docs\/|README(?:\.|$)|CHANGELOG\.md$|CONTRIBUTING\.md$|CONTEXT\.md$|\.plans\/)/.test(sourcePath)) {
    return { root: 'documentation', target: candidates[0] || clean, exists: 'false', terminal: 'prose_example', reason: 'Static-looking prose/example token is not a Markdown link or executable include.' };
  }
  if (syntax === 'markdown_link') {
    return { root: 'rendered_or_historical_context', target: candidates[0] || clean, exists: 'false', terminal: 'generated_historical_or_missing_link', reason: `No pinned-tree relative target from ${sourcePath}; token is emitted/example/history context unless separately classified confirmed_broken.` };
  }
  if (syntax === 'module_import' && sourcePath.endsWith('.md')) {
    return { root: 'embedded_example', target: candidates[0] || clean, exists: 'false', terminal: 'embedded_example_import', reason: `Import-like token occurs inside Markdown prompt/prose at ${sourcePath}; no source module is dereferenced by the repository file itself.` };
  }
  if (syntax === 'module_import') {
    return { root: 'build_or_runtime_projection', target: candidates[0] || clean, exists: 'false', terminal: 'build_runtime_projection_literal', reason: `Import-like token in ${sourcePath} has no pristine-tree target and is retained as emitted code, runtime-CWD, generated-output, or negative-fixture evidence.` };
  }
  if (syntax === 'at_include') {
    return { root: 'installed_runtime', target: candidates[0] || clean, exists: 'false', terminal: 'source_missing_but_runtime_scoped', reason: `Explicit include in ${sourcePath} has no pinned source target but is rooted in runtime/install state rather than silently treated as resolved.` };
  }
  if (sourcePath.endsWith('.md') || sourcePath.endsWith('.json')) {
    return { root: 'prompt_or_prose', target: candidates[0] || clean, exists: 'false', terminal: 'prompt_prose_or_schema_literal', reason: `Static-looking token in ${sourcePath} is not an explicit include/import/link and has no pinned-tree target; it is terminally classified as prompt, prose, schema, or example data.` };
  }
  return { root: 'code_or_configuration', target: candidates[0] || clean, exists: 'false', terminal: 'code_config_or_generated_literal', reason: `Static-looking literal in ${sourcePath} has no pinned-tree target and is terminally classified as code/configuration text, generated output, runtime-CWD path, or negative fixture.` };
}

function main(argv) {
  const args = requireArguments(argv);
  const inventory = parseInventory(fs.readFileSync(args.inventory, 'utf8'));
  const gear = inventory.filter((row) => row.gear);
  const rows = [];
  const seen = new Set();
  let bytes = 0;
  let lf = 0;
  let nulFiles = 0;
  for (const item of gear) {
    const filePath = path.join(args.repo, ...item.path.split('/'));
    const buffer = fs.readFileSync(filePath);
    bytes += buffer.length;
    for (const byte of buffer) if (byte === 10) lf += 1;
    if (buffer.includes(0)) nulFiles += 1;
    const lines = buffer.toString('utf8').split(/\r?\n/);
    for (let index = 0; index < lines.length; index += 1) {
      for (const match of collectLineMatches(lines[index])) {
        const key = `${item.path}\u0000${index + 1}\u0000${match.syntax}\u0000${match.raw}`;
        if (seen.has(key)) continue;
        seen.add(key);
        rows.push({
          source_path: item.path,
          source_line: index + 1,
          raw_reference: match.raw,
          syntax_context: match.syntax,
          ...classify(args.repo, item.path, match.raw, match.syntax),
        });
      }
    }
  }
  rows.sort((a, b) => a.source_path.localeCompare(b.source_path) || a.source_line - b.source_line || a.raw_reference.localeCompare(b.raw_reference));
  const header = ['source_path', 'source_line', 'raw_reference', 'syntax_context', 'resolution_root', 'normalized_target', 'exists', 'terminal_class', 'exclusion_reason'];
  const csvRows = [header.map(csvCell).join(',')];
  for (const row of rows) {
    csvRows.push([
      row.source_path,
      row.source_line,
      row.raw_reference,
      row.syntax_context,
      row.root,
      row.target,
      row.exists,
      row.terminal,
      row.reason,
    ].map(csvCell).join(','));
  }
  fs.mkdirSync(path.dirname(args.output), { recursive: true });
  fs.writeFileSync(args.output, `${csvRows.join('\n')}\n`);
  const terminalCounts = {};
  const syntaxCounts = {};
  for (const row of rows) {
    terminalCounts[row.terminal] = (terminalCounts[row.terminal] || 0) + 1;
    syntaxCounts[row.syntax_context] = (syntaxCounts[row.syntax_context] || 0) + 1;
  }
  const summary = {
    schema: 1,
    pin: '33985c11a9f0a27443f8b8fb114b2122d653cd78',
    inventoryFiles: inventory.length,
    gearFiles: gear.length,
    gearBytes: bytes,
    gearLfBytes: lf,
    gearNulFiles: nulFiles,
    referenceRows: rows.length,
    syntaxCounts,
    terminalCounts,
  };
  fs.writeFileSync(args.summary, `${JSON.stringify(summary, null, 2)}\n`);
  process.stdout.write(`${JSON.stringify(summary)}\n`);
}

main(process.argv.slice(1));
