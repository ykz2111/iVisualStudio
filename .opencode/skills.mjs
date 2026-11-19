#!/usr/bin/env node
/**
 * iDE skill registry.
 *
 *   node .opencode/skills.mjs check    verify every id is callable, report drift
 *   node .opencode/skills.mjs build    rescan roots, rewrite catalog JSON + MD
 *   node .opencode/skills.mjs list <q> ids matching a task keyword
 *
 * Roots are the three layers OpenCode already discovers. Do not add a fourth.
 * The catalog is a human/agent index; OpenCode advertises id + description and
 * loads bodies on demand. Never treat the catalog as the thing being executed.
 */
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const HERE = path.dirname(fileURLToPath(import.meta.url));
const ROOT = path.resolve(HERE, '..');
const JSON_PATH = path.join(HERE, 'skills-catalog.json');
const MD_PATH = path.join(HERE, 'skills-catalog.md');
const LEARNED = path.join(HERE, 'learned-skills.md');
const STACK = path.join(HERE, 'skill-stack.json');

const LAYERS = [
  { layer: 'config', root: path.join(os.homedir(), '.config/opencode/skills'), label: '~/.config/opencode/skills' },
  { layer: 'claude', root: path.join(os.homedir(), '.claude/skills'), label: '~/.claude/skills' },
  { layer: 'agents', root: path.join(os.homedir(), '.agents/skills'), label: '~/.agents/skills' },
];

// Provided by the runtime, not present on disk. Kept so the index does not lie.
const BUILTIN = [
  { id: 'browser', category: 'root', description: 'Use the in-app browser: open and read pages, click and fill forms, take screenshots, check console and network logs, and profile performance and memory. Load it before your first browser tool call.' },
];

const DENY = ['godmode', 'obliteratus'];

function walk(dir, depth, out, maxDepth) {
  if (depth > maxDepth) return;
  let entries;
  try { entries = fs.readdirSync(dir, { withFileTypes: true }); } catch { return; }
  for (const e of entries) {
    // Marketplace layers are symlinks; isDirectory() is false for those, so the
    // entry type must be resolved through stat before deciding to skip.
    if (!e.isDirectory() && !e.isSymbolicLink()) continue;
    const p = path.join(dir, e.name);
    try { if (!fs.statSync(p).isDirectory()) continue; } catch { continue; }
    if (fs.existsSync(path.join(p, 'SKILL.md'))) out.push(p);
    walk(p, depth + 1, out, maxDepth);
  }
}

/**
 * Frontmatter descriptions arrive YAML-escaped from the copilot marketplace
 * layer (`\ \`, `\n`, `\u2014`, doubled apostrophes). Left raw they make the
 * index unreadable, so decode once at scan time.
 */
function clean(s) {
  return String(s)
    .replace(/\\u([0-9a-fA-F]{4})/g, (_, h) => String.fromCharCode(parseInt(h, 16)))
    .replace(/\\x([0-9a-fA-F]{2})/g, (_, h) => String.fromCharCode(parseInt(h, 16)))
    .replace(/\\\\/g, '\u0000')
    .replace(/\\n/g, ' ')
    .replace(/\\t/g, ' ')
    .replace(/\\"/g, '"')
    .replace(/\\'/g, "'")
    .replace(/\\ /g, ' ')
    .replace(/\u0000/g, '\\')
    .replace(/''/g, "'")
    .replace(/\s+/g, ' ')
    .trim();
}

/** Minimal frontmatter reader: name, description, including quoted and block values. */
function frontmatter(file) {
  let txt;
  try { txt = fs.readFileSync(file, 'utf8'); } catch { return {}; }
  if (!txt.startsWith('---')) return {};
  const end = txt.indexOf('\n---', 3);
  if (end === -1) return {};
  const body = txt.slice(3, end).split('\n');
  const out = {};
  for (let i = 0; i < body.length; i++) {
    const m = body[i].match(/^([A-Za-z_][\w-]*):\s*(.*)$/);
    if (!m) continue;
    const [, key, rest] = m;
    if (key !== 'name' && key !== 'description') continue;
    let v = rest.trim();
    if (v === '' || v === '>' || v === '|' || v === '>-' || v === '|-') {
      const buf = [];
      while (i + 1 < body.length && /^\s+\S/.test(body[i + 1])) { buf.push(body[++i].trim()); }
      out[key] = buf.join(' ');
      continue;
    }
    if (v.startsWith('"') || v.startsWith("'")) {
      const q = v[0];
      const buf = [v];
      while (!(v.length > 1 && v.endsWith(q)) && i + 1 < body.length) { v = body[++i].trim(); buf.push(v); }
      out[key] = buf.join(' ').replace(/^["']|["']$/g, '');
      continue;
    }
    out[key] = v;
  }
  return out;
}

function scan() {
  const found = new Map();
  for (const { layer, root, label } of LAYERS) {
    if (!fs.existsSync(root)) continue;
    const dirs = [];
    walk(root, 0, dirs, 4);
    for (const dir of dirs) {
      const id = path.basename(dir);
      if (id === 'skills') continue;
      const rel = path.relative(root, dir).split(path.sep);
      const category = rel.length > 1 ? rel[0] : 'root';
      const fm = frontmatter(path.join(dir, 'SKILL.md'));
      const rec = {
        id,
        name: fm.name || id,
        description: clean(fm.description || ''),
        category,
        layer,
        path: path.join(dir, 'SKILL.md').replace(os.homedir(), '~'),
        _abs: path.join(dir, 'SKILL.md'),
        _label: label,
      };
      if (!found.has(id)) found.set(id, []);
      found.get(id).push(rec);
    }
  }
  const skills = [];
  for (const [id, recs] of found) {
    // Precedence: config > claude > agents. First wins; the rest are duplicates.
    const order = { config: 0, claude: 1, agents: 2 };
    recs.sort((a, b) => order[a.layer] - order[b.layer]);
    const best = recs[0];
    skills.push({ ...best, duplicate_count: recs.length });
  }
  return skills.sort((a, b) => a.id.localeCompare(b.id));
}

function load() {
  try { return JSON.parse(fs.readFileSync(JSON_PATH, 'utf8')); } catch { return null; }
}

function build() {
  const prev = load();
  const prevById = new Map((prev?.skills || []).map(s => [s.id, s]));
  const scanned = scan();
  const seen = new Set(scanned.map(s => s.id));

  // Preserve authored category/flags where the id still exists, so re-running
  // never reshuffles the 734 rows someone already curated.
  for (const s of scanned) {
    const old = prevById.get(s.id);
    if (old) {
      if (old.category) s.category = old.category;
      if (old.flags?.length) s.flags = old.flags;
      if (old.layer === 'project' && s.layer !== 'project') s.layer = 'project';
    }
    if (DENY.includes(s.id)) s.flags = [...new Set([...(s.flags || []), 'do-not-invoke'])];
    delete s._abs; delete s._label;
  }

  for (const b of BUILTIN) {
    if (seen.has(b.id)) continue;
    scanned.push({ ...b, name: b.id, layer: 'built-in', path: null, duplicate_count: 0, flags: [] });
  }
  scanned.sort((a, b) => a.id.localeCompare(b.id));

  const byCategory = {};
  for (const s of scanned) byCategory[s.category] = (byCategory[s.category] || 0) + 1;

  const missingDesc = scanned.filter(s => !s.description).map(s => s.id);
  const removed = [...prevById.keys()].filter(id => !scanned.some(s => s.id === id));

  const out = {
    generated_for: 'iDE (ide_concept) // Groove Labs // YkZ21',
    organization: 'Groove Labs // YkZ21',
    generated_at: new Date().toISOString(),
    unique_skills: scanned.length,
    installed_on_disk: scanned.filter(s => s.path).length,
    builtin: scanned.filter(s => !s.path).map(s => s.id),
    installed_this_run: prev?.installed_this_run || [],
    already_linked: prev?.already_linked || [],
    discovery: {
      already_visible_to_opencode: LAYERS.map(l => l.label),
      project_install: '.opencode/skills',
      note: 'OpenCode advertises id + description. Full skill bodies load on demand with the skill tool. Do not load do-not-invoke skills. Regenerate with: node .opencode/skills.mjs build',
    },
    by_category: Object.fromEntries(Object.entries(byCategory).sort((a, b) => b[1] - a[1])),
    skills: scanned,
    do_not_invoke: DENY,
    missing_description: missingDesc,
  };

  fs.writeFileSync(JSON_PATH, JSON.stringify(out, null, 2) + '\n');
  fs.writeFileSync(MD_PATH, render(out));

  console.log(`built ${out.unique_skills} ids (${out.installed_on_disk} on disk, ${out.builtin.length} built-in)`);
  console.log(`categories: ${Object.keys(byCategory).length}`);
  if (removed.length) console.log(`dropped (no longer on disk or built-in): ${removed.join(', ')}`);
  const added = scanned.filter(s => !prevById.has(s.id)).map(s => s.id);
  if (added.length) console.log(`added: ${added.join(', ')}`);
  syncCounts(out.unique_skills);
  return out;
}

function trim(s, n = 150) {
  const flat = String(s).replace(/\s+/g, ' ').trim();
  if (flat.length <= n) return flat;
  const cut = flat.slice(0, n);
  const at = cut.lastIndexOf(' ');
  return (at > n * 0.6 ? cut.slice(0, at) : cut).replace(/[,;:]$/, '') + '...';
}

function render(cat) {
  const stack = [
    ['claude-design', 'Required'], ['ui-design-system', 'Required'],
    ['mobile-design', 'Required'], ['ip-as-logo', 'Required'],
    ['design-md', 'Helpful'], ['popular-web-designs', 'Helpful'],
    ['frontend-design', 'Helpful'], ['ui-ux-pro-max', 'Helpful'],
    ['anti-ui-slop', 'Helpful'], ['macos-golden-gate-design', 'Helpful'],
    ['playground', 'Helpful'], ['adversarial-ux-test', 'Helpful'],
  ];
  const roleOf = new Map(stack);
  const lines = [];
  const layerCounts = {};
  for (const s of cat.skills) layerCounts[s.layer] = (layerCounts[s.layer] || 0) + 1;
  const stackNames = new Set(stack.map(([id]) => id));
  lines.push('# Local AI skill catalog');
  lines.push('');
  lines.push(`${cat.unique_skills} unique ids — ${cat.installed_on_disk} on disk, ${cat.builtin.length} runtime-provided, ${cat.do_not_invoke.length} denied.`);
  lines.push('');
  lines.push(`Layer split: ${Object.entries(layerCounts).map(([k, v]) => `${k} ${v}`).join(', ')}. Ids appearing in more than one layer are collapsed to a single row using config > claude > agents precedence.`);
  lines.push('');
  lines.push('This is an index, not a preload. Match a task, then load one body with the skill tool by id. Never paste this file or a category dump into a design prompt.');
  lines.push('');
  lines.push(`Discovery roots: ${cat.discovery.already_visible_to_opencode.map(r => '`' + r + '`').join(', ')}.`);
  lines.push('');
  lines.push('Regenerate: `node .opencode/skills.mjs build`. Verify: `node .opencode/skills.mjs check`.');
  lines.push('');
  lines.push('## Do not invoke');
  lines.push('');
  lines.push(cat.do_not_invoke.join(', ') + '. Denied in `.opencode/opencode.json`. No task framing overrides this.');
  lines.push('');
  lines.push('## Project stack');
  lines.push('');
  lines.push('| id | role |');
  lines.push('|---|---|');
  for (const [id, role] of stack) lines.push(`| \`${id}\` | ${role} |`);
  lines.push('');
  for (const [catName, count] of Object.entries(cat.by_category)) {
    lines.push(`## ${catName} (${count})`);
    lines.push('');
    for (const s of cat.skills.filter(x => x.category === catName)) {
      const role = stackNames.has(s.id) ? ` [${roleOf.get(s.id)}]` : '';
      const flag = s.flags?.includes('do-not-invoke') ? ' [DENIED]' : '';
      const src = s.layer === 'built-in' ? ' (built-in)' : '';
      lines.push(`- \`${s.id}\`${role}${flag}${src}: ${trim(s.description) || 'no description'}`);
    }
    lines.push('');
  }
  return lines.join('\n');
}

function check() {
  const cat = load();
  if (!cat) { console.error('no catalog; run build first'); process.exit(1); }
  const problems = [];
  let ok = 0;
  for (const s of cat.skills) {
    if (!s.path) { ok++; continue; }
    const abs = s.path.replace(/^~/, os.homedir());
    if (fs.existsSync(abs)) ok++;
    else problems.push(`missing file: ${s.id} -> ${s.path}`);
  }
  const onDisk = scan();
  const diskIds = new Set(onDisk.map(s => s.id));
  const catIds = new Set(cat.skills.map(s => s.id));
  const unlisted = [...diskIds].filter(id => !catIds.has(id));
  const dead = [...catIds].filter(id => id !== 'browser' && !diskIds.has(id));

  const stack = JSON.parse(fs.readFileSync(STACK, 'utf8'));
  const stackIds = [...(stack.selected_stack || []), ...(stack.helpful || [])].map(s => s.id);
  const badStack = stackIds.filter(id => !catIds.has(id));

  const learned = fs.readFileSync(LEARNED, 'utf8');
  const routed = [...learned.matchAll(/`([a-z0-9][a-z0-9-]{2,})`/g)].map(m => m[1]);
  // Backticked tokens include category names and the stack name; those are
  // labels, not callable ids, so they must not be reported as dead refs.
  const notIds = new Set([...Object.keys(cat.by_category), ...cat.builtin, 'groove-labs-branding-design-ui-ux-stack']);
  const badRouted = [...new Set(routed)].filter(id => !catIds.has(id) && !notIds.has(id));

  const denyOk = DENY.every(id => cat.skills.find(s => s.id === id)?.flags?.includes('do-not-invoke'));

  console.log(`resolved      ${ok}/${cat.skills.length}`);
  console.log(`unlisted      ${unlisted.length}${unlisted.length ? ': ' + unlisted.join(', ') : ''}`);
  console.log(`dead entries  ${dead.length}${dead.length ? ': ' + dead.join(', ') : ''}`);
  console.log(`stack ids     ${stackIds.length} checked, ${badStack.length} unresolved${badStack.length ? ': ' + badStack.join(', ') : ''}`);
  console.log(`routed ids    ${new Set(routed).size} referenced, ${badRouted.length} unresolved${badRouted.length ? ': ' + badRouted.join(', ') : ''}`);
  console.log(`deny list     ${denyOk ? 'intact' : 'BROKEN'}`);
  problems.forEach(p => console.log('  ' + p));
  const fail = problems.length || unlisted.length || dead.length || badStack.length || badRouted.length || !denyOk;
  console.log(fail ? '\nFAIL' : '\nOK');
  process.exit(fail ? 1 : 0);
}

function list(q) {
  const cat = load();
  const needle = (q || '').toLowerCase();
  const rows = cat.skills.filter(s =>
    !needle || s.id.includes(needle) || (s.description || '').toLowerCase().includes(needle));
  for (const s of rows.slice(0, 80)) console.log(`${s.id}\t${trim(s.description, 110)}`);
  console.log(`\n${rows.length} match${rows.length === 1 ? '' : 'es'}`);
}

/** Keep prose counts from drifting out of the catalog. */
function syncCounts(n) {
  try {
    const learned = fs.readFileSync(LEARNED, 'utf8');
    const next = learned.replace(/Unique skills observed: \*\*\d+\*\*/, `Unique skills observed: **${n}**`)
      .replace(/catalog contains \d+ unique skills/, `catalog contains ${n} unique skills`);
    if (next !== learned) fs.writeFileSync(LEARNED, next);
  } catch {}
  try {
    const st = JSON.parse(fs.readFileSync(STACK, 'utf8'));
    if (st.total_available_in_openclaude !== n) {
      st.total_available_in_openclaude = n;
      fs.writeFileSync(STACK, JSON.stringify(st, null, 2) + '\n');
    }
  } catch {}
}

const [cmd, arg] = process.argv.slice(2);
if (cmd === 'build') build();
else if (cmd === 'check') check();
else if (cmd === 'list') list(arg);
else {
  console.log('usage: node .opencode/skills.mjs <check|build|list [query]>');
  process.exit(1);
}
