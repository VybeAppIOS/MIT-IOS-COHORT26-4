#!/usr/bin/env python3
"""Builds docs/TASKS.md from docs/tasks/*.md and checks the task pool.

Run:  python3 scripts/build_task_index.py        (writes docs/TASKS.md, exits 1 on problems)
Checks: every "Depends on" task exists; no dependency cycles; every doc path mentioned exists;
every screen ID in docs/IA.md section 4 is covered by a task.
"""
import glob, os, re, sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
os.chdir(ROOT)
HEAD = re.compile(r'^### ([A-Z]+(?:-[A-Za-z0-9]+)+) — (.+?)\s+`\[([SML])\]`(.*)$')
tasks, order = {}, []
for path in sorted(glob.glob('docs/tasks/*.md')):
    cur = None
    for line in open(path, encoding='utf-8'):
        bk = re.match(r'^\| (BK-\d+) \| (.+?) \| (.*) \|$', line.rstrip('\n'))
        if bk:
            cur = {'id': bk[1], 'title': bk[2], 'size': 'L', 'note': '', 'file': path, 'deps': [], 'body': bk[3]}
            tasks[cur['id']] = cur; order.append(cur['id']); continue
        m = HEAD.match(line.rstrip('\n'))
        if m:
            cur = {'id': m[1], 'title': m[2], 'size': m[3], 'note': m[4].strip(), 'file': path, 'deps': [], 'body': ''}
            tasks[cur['id']] = cur; order.append(cur['id']); continue
        if cur is not None:
            cur['body'] += line
            d = re.match(r'- \*\*Depends on:\*\*\s*(.*)', line)
            if d: cur['deps_raw'] = d[1]

problems = []
KNOWN_GROUPS = {'common'}
for t in tasks.values():
    raw = t.get('deps_raw', '')
    ids = re.findall(r'\b((?:F|DS|CP|SC|X|BK)-[A-Za-z0-9-]+)', raw)
    t['deps'] = []
    for i in ids:
        i = i.rstrip('-')
        if i not in tasks:
            problems.append(f"{t['id']}: depends on unknown task {i}")
        else:
            t['deps'].append(i)
    # doc paths
    for p in re.findall(r'`((?:docs|scripts|VybeKit|Vybe|Config|backend)/[^`\s]+)`', t['body']):
        base = p.split('*')[0].rstrip('/')
        base = re.sub(r'[…]+.*$', '', base).rstrip('/')
        if not base or os.path.exists(base): continue
        # allow paths a task is going to create
        if re.search(r'\.(swift|json|md|py|yml|xcassets|gpx|xcprivacy|xcconfig)$', p) or 'Sources' in p or p.startswith(('docs/TOKENS', 'backend/')):
            continue
        problems.append(f"{t['id']}: references missing path {p}")

# cycles
def cyc(n, seen, stack):
    if n in stack: problems.append('cycle: ' + ' -> '.join(stack + [n])); return
    if n in seen: return
    seen.add(n)
    for d in tasks[n]['deps']: cyc(d, seen, stack + [n])
seen = set()
for n in tasks: cyc(n, seen, [])

# IA coverage
ia = open('docs/IA.md', encoding='utf-8').read()
sec = ia[ia.index('## 4. Screen inventory'):ia.index('## 5. Navigation map')]
ids = set()
for m in re.finditer(r'^\|\s*([A-Z]{1,3}\d{1,2}(?:[–-][A-Z]{0,3}\d{1,2})?)\s*\|', sec, re.M):
    t = m[1]; r = re.match(r'([A-Z]+)(\d+)[–-]([A-Z]*)(\d+)$', t)
    if r:
        p, a, _, b = r.groups(); ids.update(f'{p}{i}' for i in range(int(a), int(b) + 1))
    else: ids.add(t)
heads = ' '.join(f"{t['id']} {t['title']}" for t in tasks.values())
text_all = ' '.join(t['body'] for t in tasks.values()) + ' ' + heads
for i in sorted(ids):
    if not re.search(r'\b' + re.escape(i) + r'\b', heads) and i not in ('X1', 'WEB1'):
        problems.append(f'IA screen {i} is not named in any task heading')
for i in ('X1', 'WEB1'):
    if not re.search(r'\b' + i + r'\b', text_all): problems.append(f'IA screen {i} not covered')

# write index
areas = [('00-foundation', 'Foundation (do first)'), ('10-design', 'Design system and components'),
         ('20-screens', 'Screens: onboarding, sign-in, Discover, Hangout detail'),
         ('30-screens', 'Screens: live Hangout, Search, Profile, Settings'),
         ('40-screens', 'Screens: Community, Friends, Chat'),
         ('50-screens', 'Screens: Editor, Posting, Report/Block, Admin'),
         ('60-cross', 'Cross-cutting, content, project settings'), ('70-backend', 'Backend (later)')]
W = {'S': 0.5, 'M': 1.0, 'L': 1.75}
def days(prefixes):
    return sum(W[t['size']] for t in tasks.values() if t['id'].split('-')[0] in prefixes)
front = days({'F', 'DS', 'CP', 'SC', 'X'}); back = days({'BK'})
start_now = [t for t in (tasks[i] for i in order) if not t['deps'] and 'common' not in t.get('deps_raw', '')
             and not t['id'].startswith('BK') and t['id'] != 'F-12']
out = ['# Vybe task pool (generated: do not edit; run `python3 scripts/build_task_index.py`)', '',
       'Take any task whose **Depends on** tasks are merged. Details are in the linked file. Claim a task by',
       'assigning yourself on its GitHub issue. Start with `docs/START-HERE.md`. **Size:** S ≈ ½ day · M ≈ 1 day · L ≈ 1½–2 days.', '',
       f'**Total (estimates, not measured):** frontend + tooling + content ≈ {front:g} person-days; backend (later) ≈ {back:g}.',
       'Re-estimate after the first week from how many tasks actually get merged per day.', '',
       '## Start now (no dependencies)', '',
       ', '.join(f"**{t['id']}** {t['title']}" for t in start_now), '',
       '**Suggested order:** wave 0 = F-0 (Lohitaksh), F-1, DS-1, DS-6, X-C1, X-1 · wave 1 = F-2, F-3, F-4, DS-2/3/4/5, F-11, F-13, F-15 ·',
       'wave 2 = F-5, F-6, F-7, F-8, F-10, F-14, F-9 · wave 3 = components CP-1…CP-11, then any screen whose dependencies are merged · X tasks any time.', '']
n = 0
for key, label in areas:
    rows = [tasks[i] for i in order if os.path.basename(tasks[i]['file']).startswith(key)]
    if not rows: continue
    out += [f'## {label}', '', '| ID | Task | Size | Depends on | Details |', '|---|---|---|---|---|']
    for t in rows:
        base = ', '.join(t['deps']) if t['deps'] else '—'
        deps = ('common' + (', ' + base if t['deps'] else '')) if 'common' in t.get('deps_raw', '') else base
        note = f" {t['note']}" if t['note'] else ''
        out.append(f"| **{t['id']}** | {t['title']}{note} | {t['size']} | {deps} | `{t['file']}` |")
        n += 1
    out.append('')
open('docs/TASKS.md', 'w', encoding='utf-8').write('\n'.join(out))
print(f'{n} tasks indexed; {len(ids)} IA screens checked')
if problems:
    print('\nPROBLEMS:'); [print(' -', p) for p in problems]; sys.exit(1)
print('OK: dependencies resolve, no cycles, every IA screen has a task')
