---
description: Generate a task list markdown file (epics → user stories → role-prefixed tasks) from LLD and/or HLD Typst documents.
agent: build
---

# Create Task List

You are a senior engineer producing a **task list** markdown document from one
or more design documents (HLD and/or LLD). The output must be structurally
identical across every run so task lists stay consistent and reviewable.

**Input:** `$ARGUMENTS` — one or two space-separated paths to `.typ` design
documents, e.g.
`.docs/hld/edc/hld_edc_tahap_3.typ .docs/lld/edc/lld_edc_tahap_3.typ`.
At least one path is required. When both are given the LLD is the primary
source for task detail; the HLD supplies scope context and non-goals. If
`$ARGUMENTS` is empty or a path does not exist, ask the user and stop until
they answer.

## Phase 0 — Load source documents

Read every file passed in `$ARGUMENTS`. Identify which are HLD and which are
LLD by path. (`.docs` may be a symlink; resolve to the real path when
needed.)

## Phase 1 — Analyze the plan comprehensively

Extract every user-facing feature and behavior from the source documents.
Build an internal checklist; every feature must land in exactly one user
story (traceability — do not invent features, do not silently drop
discussed items):

- New or changed user-visible flows (registration, payment, reporting, …).
- New or changed screens/pages and their interactions.
- New or changed API endpoints driven by user actions.
- New or changed user roles and what they can see and do.
- Error states and edge cases the user can encounter.
- Validation rules as the user sees them (form validation, error messages).

**Exclude** from the checklist — these never become user stories or tasks:

- Deployment, CI/CD, infrastructure, rollback.
- Database table creation, migrations, DTO/struct/class/method scaffolding.
- Architecture changes, service extraction, package migrations.
- Logging, monitoring, observability setup.
- Anything phrased as "as a developer", "as a devops", "as a QA".

Hidden technical work (DB tables, DTOs, middleware, auth wiring) is
**absorbed into the story points** of the feature story that requires it —
never listed as its own task.

If the source documents contain no user-facing features at all, warn the
user and stop.

## Phase 2 — Ground in the codebase

Explore the repo (use the `explore` subagent in parallel where useful) to
confirm which surfaces actually exist (backend services, mobile app,
dashboard/web frontend, shared packages) and map each feature to the correct
role prefix. Do not invent surfaces absent from the repo.

## Phase 3 — Confirm open items with the user

Ask **only** genuine open decisions the source documents leave unresolved.
Batch all questions in a single `question` tool call, each with concrete
options and a recommended default. Typical unknowns:

- Features mentioned in passing but not detailed enough to scope.
- Ambiguous surface ownership (e.g. mobile vs dashboard for a screen).
- Whether a behavior change is in scope for this tahap or deferred.
- Unclear end-user roles ("pelanggan" vs "merchant" vs "admin").
- The output file name when project or tahap cannot be derived.
- Any candidate story that clearly exceeds 13 points — ask for the
  preferred split.

Do not stall on anything you can reasonably default — ship the lazy,
correct default and state it. Never fabricate an answer.

## Phase 4 — Compose user stories and tasks

### Story point rules

- Fibonacci scale: 1, 2, 3, 5, 8, 13.
- A story whose total complexity exceeds 13 **must** be split into two or
  more smaller stories before writing — never cap a large story at 13.
- Points account for the full slice of work including hidden technical
  prerequisites (DB tables, DTOs, auth wiring) — those are never separate
  tasks.
- Calibrate against the repo's actual complexity: a new endpoint touching
  one entity is typically 3–5; a multi-screen flow is 8–13; a trivial copy
  or one-field change is 1–2.

### Epic rules

- Titles in **English**, numbered sequentially: `## Epic 1 - <Name>`.
- Group stories by cohesive user-facing context (Auth, Payment,
  Reporting, …).
- Never create an epic that contains only architectural work.

### User story rules

- Written in **Indonesian**.
- Format: `Sebagai <role>, saya ingin <aksi> sehingga <manfaat>.`
- `<role>` is an end-user role (pelanggan web, merchant mobile, admin
  dashboard, kasir, …) — never "developer", "devops", "QA", or similar.
- Numbered sequentially within each epic.

### Task rules

- Written in **English**.
- Format: `- [<ROLE>] <action> <object>` where `<ROLE>` is one of `BE`,
  `FE`, `Mobile` (extend only when Phase 2 confirms another owned surface).
- `BE` = backend service/API; `FE` = web dashboard/frontend; `Mobile` =
  mobile app.
- Tasks describe user-visible feature work only: "Implement register
  endpoint", "Slicing register page", "Integrate register API" — never
  "Setup DB table", "Create DTO", "Define struct".
- One task per independently verifiable piece of work. No dependencies,
  no task-level estimates.

## Phase 5 — Write the task list file

- **Path:** `.docs/tasks/tasks_<project>_tahap_<N>.md`. Derive `<project>`
  and `<N>` from the source documents; confirm with the user (Phase 3) if
  ambiguous. Create the `.docs/tasks` directory if it does not exist.
- **File structure** (exact — follow without deviation):

  ```markdown
  # Task List — <Project> Tahap <N>

  > Source: `<hld-path>` / `<lld-path>`
  > Date: <YYYY-MM-DD>

  ## Epic 1 - <Name>

  1. Sebagai <role>, saya ingin <aksi> sehingga <manfaat>. (<points>)
     - [BE] <task>
     - [FE] <task>
     - [Mobile] <task>

  2. Sebagai <role>, saya ingin <aksi> sehingga <manfaat>. (<points>)
     - [BE] <task>

  ## Epic 2 - <Name>

  …
  ```

## Phase 6 — Verify

Self-check the output against every rule before reporting; fix any
violation and re-check:

- Every user story is in Indonesian; every epic title and every task is
  in English.
- Every story point is in {1, 2, 3, 5, 8, 13}; no story exceeds 13.
- No story is addressed to a developer / devops / QA role.
- No task mentions DB tables, migrations, DTOs, structs, classes, or
  scaffolding.
- Every user-facing feature in the source documents is traceable to at
  least one story; no invented features appear.
- Markdown renders correctly: numbered stories, nested task bullets.

## Phase 7 — Report

Reply with: the output path, epic count, total story count, total story
points, decisions baked in from Phase 3, and any items deliberately
deferred. Keep it under a few lines; no essays.

## Output contract (consistency guarantee)

Every invocation produces a task list with: the header block above; epics
numbered `Epic N - <English Name>`; user stories in Indonesian with
Fibonacci points in parentheses; role-prefixed tasks in English; no
architectural stories or scaffolding tasks; and full traceability both
ways between the source documents and the story list.
