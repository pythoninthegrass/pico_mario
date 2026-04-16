---
id: TASK-023
title: Add Taskfile.yml with Lua/PICO-8 and Python task runners
status: Done
assignee: []
created_date: '2026-04-16 06:45'
updated_date: '2026-04-16 22:27'
labels:
  - tooling
  - dx
dependencies: []
references:
  - ~/git/mt/taskfile.yml
  - ~/git/mt/taskfiles/ci.yml
  - 'https://taskfile.dev'
  - 'CLAUDE.md ## Commands'
documentation:
  - 'https://taskfile.dev/usage'
  - 'https://taskfile.dev/reference/schema'
priority: medium
ordinal: 1000
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Set up Taskfile (https://taskfile.dev) tooling for this repo to replace ad-hoc shell commands with structured, documented tasks. Reference ~/git/mt/taskfile.yml for patterns (vars, env, includes, status checks). Cover the Lua/PICO-8 and Python workflows defined in CLAUDE.md commands section.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [x] #1 Taskfile.yml exists at repo root with version 3.0, set/shopt, and dotenv like mt template
- [x] #2 task lint -- runs ruff format --check and ruff check on scripts/
- [x] #3 task format -- runs ruff format on scripts/
- [x] #4 task build -- runs uv run scripts/generate_cart.py --no-sprites
- [x] #5 task build:sprites -- runs generate_cart.py with sprite patching
- [x] #6 task test -- runs busted (unit tests)
- [x] #7 task test:e2e -- runs uv run scripts/e2e_test.py
- [x] #8 task test:e2e:update -- runs e2e with --update-baselines
- [x] #9 task play -- copies cart to PICO-8 iCloud carts folder
- [x] #10 task launch -- runs pico8 -run mario.p8
- [x] #11 task default -- lists available tasks
- [x] #12 All tasks use preconditions or status checks where appropriate (e.g. command -v busted, test -f mario.p8)
- [x] #13 mise is used for runtime paths (MISE_SHIMS on PATH)
<!-- AC:END -->

## Definition of Done
<!-- DOD:BEGIN -->
- [ ] #1 Cart loads in PICO-8 without errors
- [ ] #2 Play-test affected functionality
- [ ] #3 Copy cart to iCloud: cp mario.p8 ~/iCloud/pico-8/carts/marioish/mario.p8
- [ ] #4 Token count verified under 8192 limit
<!-- DOD:END -->
