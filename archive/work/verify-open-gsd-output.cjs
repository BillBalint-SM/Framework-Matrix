'use strict';

const crypto = require('node:crypto');
const fs = require('node:fs');
const path = require('node:path');
const child = require('node:child_process');

const root = path.resolve(__dirname, '..');
const repo = path.join(root, 'work', 'repos', 'open-gsd-gsd-core');
const runtimeRepo = path.join(root, 'work', 'runtime', 'open-gsd-gsd-core-test');
const inventoryPath = path.join(root, 'work', 'inventory', 'open-gsd-gsd-core-files.csv');
const ledgerPath = path.join(root, 'work', 'evidence', 'open-gsd-gsd-core', 'references.csv');
const summaryPath = path.join(root, 'work', 'evidence', 'open-gsd-gsd-core', 'reference-summary.json');
const runtimeEvidencePath = path.join(root, 'work', 'evidence', 'open-gsd-gsd-core', 'runtime-verification.json');
const reportPath = path.join(root, 'work', 'research', 'open-gsd-gsd-core-agent-report.md');
const dossierPath = path.join(root, 'outputs', '03-open-gsd-gsd-core.md');
const pin = '33985c11a9f0a27443f8b8fb114b2122d653cd78';

function invariant(condition, message) {
  if (!condition) throw new Error(message);
}

function parseCsvLine(line) {
  const cells = [];
  let value = '';
  let quoted = false;
  for (let index = 0; index < line.length; index += 1) {
    const character = line[index];
    if (quoted && character === '"' && line[index + 1] === '"') {
      value += '"';
      index += 1;
    } else if (character === '"') {
      quoted = !quoted;
    } else if (character === ',' && !quoted) {
      cells.push(value);
      value = '';
    } else {
      value += character;
    }
  }
  invariant(!quoted, `Unclosed CSV quote: ${line.slice(0, 120)}`);
  cells.push(value);
  return cells;
}

function readCsv(filePath) {
  const lines = fs.readFileSync(filePath, 'utf8').replace(/^\uFEFF/, '').trimEnd().split(/\r?\n/);
  const header = parseCsvLine(lines[0]);
  return { header, rows: lines.slice(1).map(parseCsvLine) };
}

function git(repository, args) {
  return child.execFileSync('git', ['-C', repository, ...args], { encoding: 'utf8' }).trim();
}

function lineCount(buffer) {
  let count = 1;
  for (const byte of buffer) if (byte === 10) count += 1;
  return count;
}

function validateCitations(documentPath, buffers) {
  const text = fs.readFileSync(documentPath, 'utf8');
  const regex = /\[33985c1:([^:\]\r\n]+):L(\d+)-L(\d+)\]/g;
  const seen = [];
  for (const match of text.matchAll(regex)) {
    const sourcePath = match[1];
    const start = Number(match[2]);
    const end = Number(match[3]);
    invariant(buffers.has(sourcePath), `${documentPath}: citation path absent: ${sourcePath}`);
    invariant(start >= 1 && end >= start, `${documentPath}: invalid citation range: ${match[0]}`);
    invariant(end <= lineCount(buffers.get(sourcePath)), `${documentPath}: citation beyond EOF: ${match[0]}`);
    seen.push(match[0]);
  }
  invariant(seen.length > 0, `${documentPath}: no pinned citations`);
  invariant(!text.includes('Unresolved static candidate | 745'), `${documentPath}: obsolete unresolved count remains`);
  invariant(text.includes('2,730') || text.includes('2 730'), `${documentPath}: missing full-tree coverage count`);
  invariant(text.includes('2,725') || text.includes('2 725'), `${documentPath}: missing gear coverage count`);
  return seen.length;
}

const inventory = readCsv(inventoryPath);
invariant(inventory.header.join('|') === 'Path|Bytes|SHA256|Extension|Category|GearCandidate|HashError', 'Unexpected inventory header');
invariant(inventory.rows.length === 2730, `Inventory rows ${inventory.rows.length}`);
const tracked = child.execFileSync('git', ['-C', repo, 'ls-files', '-z'], { encoding: 'utf8' }).split('\0').filter(Boolean).sort();
const inventoryPaths = inventory.rows.map((row) => row[0]).sort();
invariant(JSON.stringify(tracked) === JSON.stringify(inventoryPaths), 'Inventory paths differ from git ls-files');

const buffers = new Map();
let fullBytes = 0;
let fullLf = 0;
let fullNul = 0;
let gearFiles = 0;
let gearBytes = 0;
let gearLf = 0;
let gearNul = 0;
const gearPaths = new Set();
for (const row of inventory.rows) {
  const [relativePath, byteText, expectedHash, , , gearText, hashError] = row;
  const buffer = fs.readFileSync(path.join(repo, ...relativePath.split('/')));
  buffers.set(relativePath, buffer);
  invariant(buffer.length === Number(byteText), `Byte mismatch: ${relativePath}`);
  invariant(crypto.createHash('sha256').update(buffer).digest('hex').toUpperCase() === expectedHash.toUpperCase(), `SHA mismatch: ${relativePath}`);
  invariant(hashError === '', `Inventory hash error: ${relativePath}: ${hashError}`);
  const lf = buffer.reduce((total, byte) => total + (byte === 10 ? 1 : 0), 0);
  const nul = buffer.includes(0);
  fullBytes += buffer.length;
  fullLf += lf;
  if (nul) fullNul += 1;
  if (gearText === 'True') {
    gearPaths.add(relativePath);
    gearFiles += 1;
    gearBytes += buffer.length;
    gearLf += lf;
    if (nul) gearNul += 1;
  }
}
invariant(fullBytes === 36309998 && fullLf === 773586 && fullNul === 5, `Full census mismatch: ${fullBytes}/${fullLf}/${fullNul}`);
invariant(gearFiles === 2725 && gearBytes === 36203101 && gearLf === 773276 && gearNul === 3, `Gear census mismatch: ${gearFiles}/${gearBytes}/${gearLf}/${gearNul}`);

const ledger = readCsv(ledgerPath);
const expectedLedgerHeader = ['source_path', 'source_line', 'raw_reference', 'syntax_context', 'resolution_root', 'normalized_target', 'exists', 'terminal_class', 'exclusion_reason'];
invariant(JSON.stringify(ledger.header) === JSON.stringify(expectedLedgerHeader), 'Unexpected reference ledger header');
invariant(ledger.rows.length === 42366, `Reference rows ${ledger.rows.length}`);
const ledgerKeys = new Set();
let unresolved = 0;
let confirmedBroken = 0;
const brokenEdges = new Set();
for (const row of ledger.rows) {
  invariant(row.length === expectedLedgerHeader.length, `Reference column count ${row.length}`);
  const [sourcePath, sourceLine, rawReference, syntax, , normalizedTarget, , terminalClass, reason] = row;
  invariant(gearPaths.has(sourcePath), `Ledger source not in gear set: ${sourcePath}`);
  invariant(Number(sourceLine) >= 1 && Number(sourceLine) <= lineCount(buffers.get(sourcePath)), `Ledger source line invalid: ${sourcePath}:${sourceLine}`);
  invariant(rawReference.length > 0 && syntax.length > 0 && terminalClass.length > 0 && reason.length > 0, `Incomplete ledger row: ${sourcePath}:${sourceLine}`);
  const key = [sourcePath, sourceLine, rawReference, syntax].join('\0');
  invariant(!ledgerKeys.has(key), `Duplicate ledger row: ${sourcePath}:${sourceLine}:${rawReference}:${syntax}`);
  ledgerKeys.add(key);
  if (terminalClass === 'unresolved_static_candidate') unresolved += 1;
  if (terminalClass === 'confirmed_broken') {
    confirmedBroken += 1;
    brokenEdges.add([sourcePath, rawReference, normalizedTarget].join('\0'));
  }
}
invariant(unresolved === 0, `Unresolved static candidates: ${unresolved}`);
invariant(confirmedBroken === 2 && brokenEdges.size === 1, `Broken edge accounting: ${confirmedBroken}/${brokenEdges.size}`);

const summary = JSON.parse(fs.readFileSync(summaryPath, 'utf8'));
invariant(summary.pin === pin, 'Reference summary pin mismatch');
invariant(summary.inventoryFiles === 2730 && summary.gearFiles === 2725 && summary.referenceRows === 42366, 'Reference summary coverage mismatch');
invariant((summary.terminalCounts.unresolved_static_candidate || 0) === 0, 'Reference summary unresolved count nonzero');
invariant(summary.terminalCounts.confirmed_broken === 2, 'Reference summary broken count mismatch');

const reportCitations = validateCitations(reportPath, buffers);
const dossierCitations = validateCitations(dossierPath, buffers);
const dossier = fs.readFileSync(dossierPath, 'utf8');
const dossierHeadings = [...dossier.matchAll(/^## (\d+)\. /gm)].map((match) => Number(match[1]));
invariant(dossierHeadings.length === 16, `Dossier heading count ${dossierHeadings.length}`);
invariant(JSON.stringify(dossierHeadings) === JSON.stringify(Array.from({ length: 16 }, (_, index) => index + 1)), `Dossier headings out of sequence: ${dossierHeadings.join(',')}`);

const runtimeEvidence = JSON.parse(fs.readFileSync(runtimeEvidencePath, 'utf8'));
invariant(runtimeEvidence.pin === pin, 'Runtime evidence pin mismatch');
for (const item of runtimeEvidence.commands) invariant(item.exitCode === 0, `Runtime command failed: ${item.id}`);
invariant(runtimeEvidence.timeoutRuns.status === 'unverified_coordinator_report', 'Timeout evidence not downgraded');
invariant(runtimeEvidence.targeted865Run.status === 'unverified_coordinator_report', '865 evidence not downgraded');

for (const repository of [repo, runtimeRepo]) {
  invariant(git(repository, ['rev-parse', 'HEAD']) === pin, `HEAD mismatch: ${repository}`);
  invariant(git(repository, ['status', '--short']) === '', `Dirty tracked worktree: ${repository}`);
}
const sourceCjs = fs.readdirSync(path.join(repo, 'gsd-core', 'bin', 'lib')).filter((name) => name.endsWith('.cjs')).length;
const runtimeCjs = fs.readdirSync(path.join(runtimeRepo, 'gsd-core', 'bin', 'lib')).filter((name) => name.endsWith('.cjs')).length;
invariant(sourceCjs === 17 && runtimeCjs === 173, `Source/build CJS census mismatch: ${sourceCjs}/${runtimeCjs}`);

process.stdout.write(`${JSON.stringify({
  pin,
  inventoryFiles: inventory.rows.length,
  gearFiles,
  fullBytes,
  gearBytes,
  referenceRows: ledger.rows.length,
  unresolvedStaticCandidates: unresolved,
  confirmedBrokenRows: confirmedBroken,
  confirmedBrokenUniqueEdges: brokenEdges.size,
  reportCitations,
  dossierCitations,
  dossierSections: dossierHeadings.length,
  sourceCjs,
  runtimeCjs,
  sourceClean: true,
  runtimeClean: true,
}, null, 2)}\n`);
