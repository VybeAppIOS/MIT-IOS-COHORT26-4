#!/usr/bin/env python3
"""Creates one GitHub issue per task in docs/tasks/*.md (task X-6).

DRY RUN BY DEFAULT: it only prints what it would create. Lohitaksh runs it with --create once the team agrees.

  python3 scripts/create_issues.py                  dry run: one line block per issue, then a summary
  python3 scripts/create_issues.py --full           dry run, also print every issue body
  python3 scripts/create_issues.py --only SC-D3,F-0 only these tasks   (--exclude ID,ID skips tasks)
  python3 scripts/create_issues.py --include-backend   also BK-2..BK-14 (by default only BK-1, see 70-backend-later.md)
  python3 scripts/create_issues.py --create         create labels and issues with `gh` (must be installed and logged in)

Checks (exit 1 on any problem): no duplicate IDs, every dependency is a known task, every task has an area label,
every file that uses "common" defines it in its header. Dependency text it cannot read is listed, never fatal.
Standard library only (AGENTS.md section 4). Keep HEAD in sync with scripts/build_task_index.py.
"""
import argparse, glob, os, re, subprocess, sys, time

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
HEAD = re.compile(r'^### ([A-Z]+(?:-[A-Za-z0-9]+)+) — (.+?)\s+`\[([SML])\]`(.*)$')   # same as build_task_index.py
BK_ROW = re.compile(r'^\| (BK-\d+) \| (.+?) \| (.*) \|$')
ID = r'(?:F|DS|CP|SC|X|BK)-[A-Za-z0-9]+(?:-[A-Za-z0-9]+)*'
SHORTHAND = re.compile(r'\b((?:F|DS|CP|X|BK))-(\d+)((?:/(?:\1-)?\d+)+)\b')   # DS-1/2/3 or DS-1/DS-2/DS-3

# Area label from the task file and its "## " section (first match wins).
AREAS = [
    ('00-', None, 'foundation'),
    ('10-', 'Components', 'components'), ('10-', None, 'design-system'),
    ('20-', 'Onboarding', 'onboarding'), ('20-', 'Sign-in', 'auth'),
    ('20-', 'Discover', 'discover'), ('20-', 'Hangout detail', 'hangout-detail'),
    ('30-', 'Live Hangout', 'live'), ('30-', 'Search', 'search'), ('30-', 'Profile and Settings', 'profile'),
    ('40-', 'Community', 'community'), ('40-', 'Friends', 'friends'), ('40-', 'Chat', 'chat'),
    ('50-', 'Editor', 'editor'), ('50-', 'Posting', 'posting'), ('50-', 'Report, block and admin', 'moderation'),
    ('60-', 'Content', 'content'), ('60-', 'Tooling', 'tooling'), ('60-', 'Project settings', 'project-settings'),
    ('70-', None, 'backend'),
]
LABEL_COLOURS = {'area': '1d76db', 'size': 'c5def5', 'lead-only': 'b60205'}


def expand_shorthand(text):
    """'DS-1/2/3' and 'DS-1/DS-2/DS-3' become 'DS-1, DS-2, DS-3'."""
    def repl(m):
        prefix, first, rest = m[1], m[2], m[3]
        nums = [first] + [p.split('-')[-1] for p in rest.strip('/').split('/')]
        return ', '.join(f'{prefix}-{n}' for n in nums)
    return SHORTHAND.sub(repl, text)


def common_from_header(header):
    """IDs listed after 'Common dependencies' / 'Common "Depends on"' / 'common dependencies' in a file header."""
    flat = ' '.join(header.split())
    m = re.search(r'(?i)\bcommon\s+(?:"depends on"|dependencies)(.*?)(?:\.\s|\.$)', flat)
    return re.findall(ID, expand_shorthand(m[1].replace('*', ''))) if m else None


def parse_depends(raw, common):
    """Returns (ids, notes, unparsed). Never raises on prose."""
    ids, notes, unparsed = [], [], []
    text = expand_shorthand(raw.replace('`', ''))
    for note in re.findall(r'\(([^)]*)\)', text):
        notes.append(note.strip())
    text = re.sub(r'\([^)]*\)', '', text)
    for part in re.split(r',|\band\b', text):
        part = part.strip()
        if not part or part == 'nothing':
            continue
        if part == 'common':
            ids += common or []
            continue
        found = re.findall(ID, part)
        leftover = re.sub(ID, '', part).strip()
        ids += found
        if not found:
            unparsed.append(part)
        elif leftover:
            notes.append(leftover)
    return list(dict.fromkeys(ids)), notes, unparsed


def area_for(path, section):
    name = os.path.basename(path)
    for prefix, sec, label in AREAS:
        if name.startswith(prefix) and (sec is None or (section or '').startswith(sec)):
            return label
    return None


def load_tasks():
    tasks, problems = [], []
    for path in sorted(glob.glob(os.path.join(ROOT, 'docs/tasks/*.md'))):
        rel = os.path.relpath(path, ROOT)
        lines = open(path, encoding='utf-8').read().splitlines()
        header = []
        for line in lines[1:]:
            if line.startswith(('## ', '### ', '| ID')):
                break
            header.append(line)
        common = common_from_header('\n'.join(header))
        section, cur = None, None
        for line in lines:
            if line.startswith('## '):
                section, cur = line[3:].strip(), None
                continue
            if line.strip() == '---':
                cur = None
                continue
            m, bk = HEAD.match(line), BK_ROW.match(line)
            if m or bk:
                t = {'file': rel, 'section': section, 'common': common, 'body': []}
                if m:
                    t.update(id=m[1], title=m[2].strip(), size=m[3], note=m[4].strip())
                else:
                    t.update(id=bk[1], title=bk[2].strip(), size=None, note='',
                             body=[f'**Notes:** {bk[3].strip()}', '', '> ' + ' '.join(' '.join(header).split())])
                tasks.append(t)
                cur = t if m else None
                continue
            if cur is not None:
                cur['body'].append(line)
    for t in tasks:
        while t['body'] and not t['body'][-1].strip():
            t['body'].pop()
        raw = next((re.match(r'- \*\*Depends on:\*\*\s*(.*)', l)[1] for l in t['body']
                    if l.startswith('- **Depends on:**')), '')
        t['deps_raw'] = raw
        t['deps'], t['dep_notes'], t['dep_unparsed'] = parse_depends(raw, t['common'])
        if re.search(r'\bcommon\b', raw) and not t['common']:
            problems.append(f"{t['id']}: uses 'common' but {t['file']} has no Common dependencies header")
        t['area'] = area_for(t['file'], t['section'])
        if not t['area']:
            problems.append(f"{t['id']}: no area label for {t['file']} / section {t['section']!r}")
        t['lead_only'] = 'lohitaksh only' in (t['note'] + ' ' + (t['section'] or '')).lower()
        t['labels'] = [f"area:{t['area']}"] + ([f"size:{t['size']}"] if t['size'] else []) + \
                      (['lead-only'] if t['lead_only'] else [])
    seen = {}
    for t in tasks:
        if t['id'] in seen:
            problems.append(f"duplicate ID {t['id']} in {seen[t['id']]} and {t['file']}")
        seen[t['id']] = t['file']
    for t in tasks:
        for d in t['deps']:
            if d not in seen:
                problems.append(f"{t['id']}: depends on unknown task {d}")
    return tasks, problems


def skip_reason(t, include_backend):
    if t['title'].startswith('(moved)'):
        return 'moved: ' + t['title']
    if t['id'].startswith('BK-') and t['id'] != 'BK-1' and not include_backend:
        return 'backend, not started yet (use --include-backend)'
    return None


def issue_title(t):
    return f"{t['id']}: {t['title']}"


def depends_line(t):
    if not t['deps_raw']:
        return 'not stated in the task file'
    line = t['deps_raw']
    if re.search(r'\bcommon\b', line) and t['common']:
        line += f" (common, from this file's header = {', '.join(t['common'])})"
    return line


def issue_body(t):
    size = f" · **Size:** {t['size']}" if t['size'] else ''
    lead = ' · **Lead only** (Lohitaksh)' if t['lead_only'] else ''
    head = [f"**Task:** {t['id']}{size} · **Area:** {t['area']}{lead}",
            f"**Depends on:** {depends_line(t)}",
            f"**Source:** `{t['file']}` (edit the task there, not here)", '']
    foot = ['', '---', 'Definition of Done: `AGENTS.md` section 6. Claim this task by assigning yourself.']
    return '\n'.join(head + t['body'] + foot) + '\n'


def gh(*args, stdin=None):
    return subprocess.run(['gh', *args], input=stdin, capture_output=True, text=True)


def repo_slug():
    url = subprocess.run(['git', '-C', ROOT, 'remote', 'get-url', 'origin'], capture_output=True, text=True).stdout
    m = re.search(r'github\.com[:/](.+?)(?:\.git)?\s*$', url)
    return m[1] if m else None


def create(selected, repo):
    if subprocess.run(['which', 'gh'], capture_output=True).returncode != 0:
        sys.exit('gh is not installed. Install GitHub CLI, run `gh auth login`, then try again.')
    if gh('auth', 'status').returncode != 0:
        sys.exit('gh is not logged in. Run `gh auth login`, then try again.')
    listed = gh('issue', 'list', '--repo', repo, '--state', 'all', '--limit', '1000', '--json', 'title', '--jq', '.[].title')
    if listed.returncode != 0:
        sys.exit('Could not list existing issues:\n' + listed.stderr)
    existing = {line.split(':', 1)[0] for line in listed.stdout.splitlines() if ':' in line}
    for label in sorted({l for t in selected for l in t['labels']}):
        colour = LABEL_COLOURS[label.split(':')[0]]
        r = gh('label', 'create', label, '--repo', repo, '--color', colour, '--force')
        print(f"label {label}: {'ok' if r.returncode == 0 else 'FAILED ' + r.stderr.strip()}")
    made = 0
    for t in selected:
        if t['id'] in existing:
            print(f"skip {t['id']}: an issue with this ID already exists (open or closed)")
            continue
        args = ['issue', 'create', '--repo', repo, '--title', issue_title(t), '--body-file', '-']
        for label in t['labels']:
            args += ['--label', label]
        r = gh(*args, stdin=issue_body(t))
        if r.returncode != 0:
            sys.exit(f"FAILED on {t['id']} after {made} new issues (re-run to continue):\n{r.stderr}")
        made += 1
        print(f"created {t['id']}: {r.stdout.strip()}")
        time.sleep(2)   # stay under GitHub's limit on creating content quickly
    print(f'Done: {made} issues created.')


def main():
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument('--create', action='store_true', help='really create labels and issues with gh')
    ap.add_argument('--full', action='store_true', help='dry run: also print each issue body')
    ap.add_argument('--only', help='comma-separated task IDs to include')
    ap.add_argument('--exclude', help='comma-separated task IDs to skip')
    ap.add_argument('--include-backend', action='store_true', help='also BK-2..BK-14')
    ap.add_argument('--repo', help='owner/name (default: from the git remote)')
    a = ap.parse_args()

    tasks, problems = load_tasks()
    known = {t['id'] for t in tasks}
    only = {s.strip() for s in a.only.split(',')} if a.only else None
    exclude = {s.strip() for s in a.exclude.split(',')} if a.exclude else set()
    for i in sorted((only or set()) | exclude):
        if i not in known:
            problems.append(f'--only/--exclude names unknown task {i}')

    selected, skipped = [], []
    for t in tasks:
        reason = skip_reason(t, a.include_backend)
        if only is not None and t['id'] not in only:
            continue
        if t['id'] in exclude:
            reason = 'excluded with --exclude'
        (skipped.append((t['id'], reason)) if reason else selected.append(t))

    if not a.create:
        print('DRY RUN: nothing is sent to GitHub. Add --create to create the issues.\n')
        for n, t in enumerate(selected, 1):
            print(f"[{n}/{len(selected)}] {issue_title(t)}")
            print(f"  labels:     {', '.join(t['labels'])}")
            print(f"  depends on: {depends_line(t)}")
            print(f"  source:     {t['file']}")
            if a.full:
                print('  ----- body -----')
                print('\n'.join('  | ' + l for l in issue_body(t).splitlines()))
            print()
        labels = sorted({l for t in selected for l in t['labels']})
        print(f'Labels used ({len(labels)}): {", ".join(labels)}')
        print('Skipped:' if skipped else 'Skipped: none')
        for i, why in skipped:
            print(f'  {i}: {why}')

    notes = [(t['id'], n) for t in tasks for n in t['dep_notes']]
    unparsed = [(t['id'], u, t['deps_raw']) for t in tasks for u in t['dep_unparsed']]
    print(f'\nDependency notes kept as text, not treated as tasks ({len(notes)}):')
    for i, n in notes:
        print(f'  {i}: "{n}"')
    print(f'Dependency text that could not be parsed ({len(unparsed)}):' + ('' if unparsed else ' none'))
    for i, u, raw in unparsed:
        print(f'  {i}: "{u}"  (from: {raw})')

    if problems:
        print('\nPROBLEMS:')
        for p in problems:
            print(f'  - {p}')
        sys.exit(1)
    print(f'\nOK: {len(selected)} issues, {len(tasks)} tasks parsed, every dependency is a known task, no duplicate IDs.')
    if a.create:
        repo = a.repo or repo_slug()
        if not repo:
            sys.exit('Could not work out the repository; pass --repo owner/name.')
        create(selected, repo)


if __name__ == '__main__':
    main()
