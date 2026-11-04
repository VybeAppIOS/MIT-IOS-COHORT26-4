---
name: Story (a screen or a piece of work)
about: One work item with acceptance criteria
title: "<ID>: <what it does>"
labels: story
---
**Time budget:** ½ day | 1 day

**Story:** As a Kothrud student, I want <x> so that <y>.

**Figma frame:** <link>   **Depends on:** <#issues merged>

**Acceptance criteria**
- Given <state>, when <action>, then <result>
- Loading / empty / error: <what each shows>

**Out of scope:**

**Check:** `./scripts/check.sh` passes + screenshot next to the Figma frame

**Definition of Ready:** screen ID, Figma link, acceptance criteria, dependencies merged.
