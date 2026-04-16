---
id: TASK-023
title: Add Taskfile.yml with Lua/PICO-8 and Python task runners
status: To Do
assignee: []
created_date: '2026-04-16 06:45'
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
---

## Description

<!-- SECTION:DESCRIPTION:BEGIN -->
Set up Taskfile (https://taskfile.dev) tooling for this repo to replace ad-hoc shell commands with structured, documented tasks. Reference ~/git/mt/taskfile.yml for patterns (vars, env, includes, status checks). Cover the Lua/PICO-8 and Python workflows defined in CLAUDE.md commands section.
<!-- SECTION:DESCRIPTION:END -->

## Acceptance Criteria
<!-- AC:BEGIN -->
- [ ] #1 Taskfile.yml exists at repo root with version 3.0, set/shopt, and dotenv like mt template
- [ ] #2 task lint -- runs ruff format --check and ruff check on scripts/
- [ ] #3 task format -- runs ruff format on scripts/
- [ ] #4 task build -- runs uv run scripts/generate_cart.py --no-sprites
- [ ] #5 task build:sprites -- runs generate_cart.py with sprite patching
- [ ] #6 task test -- runs busted (unit tests)
- [ ] #7 task test:e2e -- runs uv run scripts/e2e_test.py
- [ ] #8 task test:e2e:update -- runs e2e with --update-baselines
- [ ] #9 task play -- copies cart to PICO-8 iCloud carts folder
- [ ] #10 task launch -- runs pico8 -run mario.p8
- [ ] #11 task default -- lists available tasks
- [ ] #12 All tasks use preconditions or status checks where appropriate (e.g. command -v busted, test -f mario.p8)
- [ ] #13 mise is used for runtime paths (MISE_SHIMS on PATH)
<!-- AC:END -->

## Definition of Done
<!-- DOD:BEGIN -->
- [ ] #1 Cart loads in PICO-8 without errors
- [ ] #2 Play-test affected functionality
- [ ] #3 Copy cart to iCloud: cp mario.p8 ~/iCloud/pico-8/carts/marioish/mario.p8
- [ ] #4 Token count verified under 8192 limit
<!-- DOD:END -->
