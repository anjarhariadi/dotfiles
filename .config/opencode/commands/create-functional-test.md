---
description: Generate a functional testing markdown document (single table of test cases grouped by epic) from a task list and/or HLD.
agent: build
---

# Create Functional Test

You are a senior engineer producing a **functional testing** markdown document
from a task list and/or HLD. The output must be structurally identical across
every run so test documents stay consistent and reviewable.

**Input:** `$ARGUMENTS` — one or two space-separated paths: a task list
`.md` (e.g. `.docs/tasks/tasks_edc_tahap_3.md`) and/or an HLD `.typ`
(e.g. `.docs/hld/edc/hld_edc_tahap_3.typ`). The task list (when given) is
the primary source for epics and features; the HLD adds flow detail,
validation rules, and error cases. If `$ARGUMENTS` is empty or a path does
not exist, ask the user and stop until they answer.

## Phase 0 — Load source documents

Read every file passed in `$ARGUMENTS`; identify the task list (`.md`) and
the HLD (`.typ`) by extension. (`.docs` may be a symlink; resolve to the
real path when needed.) Then:

1. If a sibling functional test for the same project exists
   (`ls .docs/functional-test/<project>/`), read the nearest one — copy
   its epic grouping style and test code prefix.
2. Otherwise use `.docs/functional-test/goumroh/functional-testing-tahap-3.md`
   as the canonical structural reference (table columns, epic header rows).

## Phase 1 — Analyze the plan comprehensively

Build an internal checklist of testable user-facing behavior from the
source documents (traceability — do not invent features, do not silently
drop discussed items):

- Every epic and user story in the task list becomes test scope.
- Every user-visible flow in the HLD: happy paths, alternate paths, and
  the validation rules and error cases the user can encounter.
- Every screen/page: normal state, empty state, and invalid-input state.
- Every role boundary visible to users (e.g. role A must not see role
  B's data on user-facing pages).

**Exclude** — these never become test cases:

- Deployment, CI/CD, infrastructure, rollback verification.
- Database integrity, migrations, DTO/struct internals.
- Logging, monitoring, observability.
- Anything only an engineer or devops would exercise, not an end user.

For each feature, plan at least one Positive test; add Negative tests
where the user can plausibly hit a failure (invalid input, wrong role,
missing data, invalid/expired codes, out-of-range values, empty states).

If the source documents contain no user-facing features at all, warn the
user and stop.

## Phase 2 — Ground in the codebase

Explore the repo (use the `explore` subagent in parallel where useful) to
confirm the real screens/pages, routes, and user roles so test steps
reference actual menus, URLs, and role names. Do not invent surfaces
absent from the repo.

## Phase 3 — Confirm open items with the user

Ask **only** genuine open decisions the source documents leave unresolved.
Batch all questions in a single `question` tool call, each with concrete
options and a recommended default. Typical unknowns:

- Test code prefix when it cannot be derived (canonical convention:
  `P<N>T<NNN>` where `N` is the tahap number).
- The `<Subtitle>` in the document title (e.g. "Agency System").
- The staging URL line under the title (omit when unknown).
- Whether regression cases for the previous tahap belong in this
  document (default: new features only).

Do not stall on anything you can reasonably default — ship the lazy,
correct default and state it. Never fabricate an answer.

## Phase 4 — Compose test cases

### Content language

The whole document is in **Indonesian**: epic header names, `Judul`,
`Detail`, and `Ekspektasi`. Translate or adapt task list epic names to
Indonesian for the header rows.

### Kode rules

- Format: `<PREFIX>T<NNN>` (default prefix `P<N>` with the tahap number;
  use the convention confirmed in Phase 3 when a sibling exists).
- Numbers are sequential from `T001`, ordered by epic then position
  within the epic. Unique across the document.

### Column rules

The table has exactly 9 columns in this order. Only the five listed are
ever filled — the rest stay empty in every row:

| Column | Content |
|---|---|
| Kode | test code per the Kode rules |
| Judul | short Indonesian title of what is being tested |
| Tipe | `Positive` or `Negative` |
| Tester | empty |
| Detail | ordered list of steps in Indonesian, inside the cell: `1. Step<br>2. Step<br>3. Step` |
| Ekspektasi | expected outcome as prose in Indonesian |
| Hasil | empty |
| Log/Error Message | empty |
| Catatan/Screenshot | empty |

### Epic header rows

Every epic starts with a header row: bold epic name in the Kode column,
every other cell empty:

`| **1. Nama Epic (Konteks)** | | | | | | | | |`

- Number epics sequentially from 1.
- Append a short parenthetical context when useful, e.g.
  `(Dashboard Agen)`, `(Calon Jamaah)`.
- One single table spans the whole document — never split into multiple
  tables.

### Scenario rules

- Positive tests cover the happy path of each user story.
- Negative tests cover: invalid or unauthorized input, wrong-role
  access, empty states, invalid codes/IDs, boundary values.
- `Detail` steps must be executable by a tester without guessing: name
  the role to log in as, the menu/page to open, the action to take, and
  what to observe.
- `Ekspektasi` states what the system must visibly do — never
  implementation internals.

## Phase 5 — Write the document

- **Path:** `.docs/functional-test/<project>/functional-testing-tahap-<N>.md`
  mirroring the reference layout. Derive `<project>` and `<N>` from the
  sources; confirm with the user (Phase 3) when ambiguous. Create the
  directory if it does not exist.
- **Header** (adapt, never hardcode):

  ```markdown
  # **Hasil Functional Testing** **Platform <Project> Tahap <N> (<Subtitle>)**

  ( <staging-url> )
  ```

  Omit the URL line when unknown.

- **Table:** one table with this 9-column header row (names exactly as
  in the reference), then per epic: one epic header row followed by that
  epic's test rows:

  ```
  | Kode | Judul | Tipe | Tester | Detail | Ekspektasi | Hasil | Log/Error Message | Catatan/Screenshot |
  |---|---|---|---|---|---|---|---|---|
  ```

## Phase 6 — Verify

Self-check the output against every rule before reporting; fix any
violation and re-check:

- All content in Indonesian (epic headers, Judul, Detail, Ekspektasi).
- `Tipe` is only `Positive` or `Negative`.
- Tester, Hasil, Log/Error Message, Catatan/Screenshot columns are
  empty in every row, including epic header rows.
- Detail cells use ordered-list format with `<br>` between steps.
- Every epic has a bold header row with empty sibling cells; exactly
  one table in the document.
- Kode values unique and sequential per the convention.
- Every user-facing feature in the source documents is covered by at
  least one test; no architectural or engineering-only tests appear.

## Phase 7 — Report

Reply with: the output path, epic count, total test case count (positive
vs negative), decisions baked in from Phase 3, and any source features
deliberately deferred. Keep it under a few lines; no essays.

## Output contract (consistency guarantee)

Every invocation produces a functional testing document with: the title
header above; a single 9-column table; bold epic header rows with empty
cells; sequential unique test codes; Positive/Negative typed cases with
ordered-list Detail and prose Ekspektasi; and empty Tester/Hasil/Log/
Catatan columns throughout.
