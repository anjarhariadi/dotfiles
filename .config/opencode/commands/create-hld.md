---
description: Generate a High Level Design (HLD) Typst document from the current conversation, matching the house structure.
agent: build
---

# Create HLD

You are a senior engineer producing a **High Level Design (HLD)** Typst document
from the **current conversation**. The user discusses objectives, requirements,
and strategy first, then invokes this command. The output must be structurally
identical across every run so HLDs stay consistent and reviewable.

**Input:** none. Derive everything (project, tahap number, decisions) from the
conversation in the context window and the repo. If the project and tahap are
not clearly established, ask before writing.

## Phase 0 — Load references (always, before analyzing)

Read, in order:

1. `.docs/hld/template.typ` — the HLD template. Note the exported helpers:
   `conf`, `revision`, `approval1`, `approval2`, `render_pintora`, `be_spec`,
   and the `conf` defaults (cover, revision history, approvals, outline,
   daftar gambar).
2. The nearest sibling HLD for the same project (`ls .docs/hld/<project>/`) —
   copy its exact section order, heading levels, and pagebreak placement.
3. Prior tahap HLDs of the same project (`hld_<project>_tahap_{N-1}.typ`) —
   cite them under "Dokumen Terkait" and carry forward what the new tahap builds on.
4. If no sibling/prior HLD exists, use `.docs/hld/edc/hld_edc_tahap_3.typ` as the
   canonical structural reference.

Do not invent helper functions; use only the template's exported API. The
structure and style are fully specified in Phase 5 — follow them directly.

## Phase 1 — Mine the conversation comprehensively

Extract and build an internal checklist; every item must land in some HLD
section (traceability — do not invent features, do not silently drop discussed
bullets):

- Objectives the user stated and the requirement set they described.
- New strategy / direction and the reasoning behind it.
- Decisions locked during the discussion, and rejected alternatives that shaped them.
- Affected surfaces: backend services, API endpoints, data model, mobile, shared
  package, dashboard, infra.
- New clients/channels, changed external integrations.
- Open items the user explicitly left undecided.

If the conversation lacks an objective/requirement needed to complete a section,
ask (Phase 3) rather than guessing.

## Phase 2 — Ground in the real codebase

The HLD describes the **target**, but identifiers must be real. Explore the repo
(use the `explore` subagent in parallel where useful) to confirm: actual
service/module names, entity and DTO fields, existing route prefixes, middleware
names, enum values, package names. Do not contradict the code without flagging
it. Keep the HLD at surface level — no signatures, no code bodies.

## Phase 3 — Confirm open items with the user

Ask **only** genuine open decisions the conversation leaves unresolved. Batch
all questions in a single `question` tool call, each with concrete options and a
recommended default. Typical unknowns:

- Project name, tahap number, author, version, date, approvals (when not derivable).
- Output path when the project folder does not exist.
- Library/mechanism choices left tentative.
- Ratios/percentages/keys/paths that remain unspecified.
- Whether unresolved decisions go in the optional `Catatan Terbuka` section now
  or get resolved immediately.

Do not stall on anything you can reasonably default — ship the lazy, correct
default and state it. Never fabricate an answer.

## Phase 4 — Determine output

- **Path:** `.docs/hld/<project>/hld_<project>_tahap_N.typ`. Confirm with the
  user if the project folder does not exist yet. (`.docs` may be a symlink;
  resolve to the real path for compilation.)
- **Header block** (adapt, never hardcode):

  ```
  #import "../template.typ": *

  #let author = "<from conversation or existing HLD>"

  #show: conf.with(
    author: author,
    project: [<Project> #rect[Tahap N]],
    revisions: (
      revision(
        author: [#author],
        version: [v<N>.0],
        desc: [Inisialisasi dokumen untuk tahap N],
        date: [<date>],
      ),
    ),
    approvals: (approval1(), approval2(name: [<name>], position: [<position>])),
  )
  ```

  Carry author and approvals from the nearest existing HLD unless the
  conversation says otherwise. Use today's date.

## Phase 5 — Write the HLD (fixed structure)

### Formatting & style rules (apply to the whole document)

- Prose in **Indonesian**; every code identifier, field, endpoint path, enum
  value, Redis key, and file name in `` `backticks` ``; introduce plain-language
  terms in italics, e.g. _(self signup)_.
- Top-level sections are `= _Title_` (italic between underscores): `_TL;DR_`,
  `_Introduction_`, `_High Level Solution_`. Everything under `_High Level
Solution_` is `==`; flows and module groups are `===`; individual modules are `====`.
- Lists use `+` (Typst enumerated), one item per point.
- Tables: `#table(columns: (...), inset: 10pt, table.header([*...*]), ...)`;
  first column `auto`, content columns `1fr` (or `auto 1fr 1fr`). Bold header
  labels with `*...*`. Do not invent styling beyond this.
- Every backend and frontend module title is tagged `[Baru]` or `[Perubahan]`,
  e.g. `==== \[Perubahan\] Auth Service — Validasi Kanal`.
- Every backend module starts with a
  `#be_spec(service: [...], entity: [...], external_packages: [...])` table
  (`-` when none), followed by `+` bullets.
- No implementation source code, no method signatures (that is the LLD).
  Describe behavior and responsibility only.
- `#pagebreak()` placement exactly as listed below.
- Traceable to the conversation: nothing invented, no discussed item dropped.

Use exactly this section order:

1. `= _TL;DR_` — one dense paragraph (4–8 sentences) covering the whole tahap:
   what changes, why, which surfaces, which new concepts/enums/clients.
2. `= _Introduction_`
   - `== Tujuan` — one boilerplate paragraph (adapt project/tahap): provides the
     architecture breakdown at surface level, references the LLD for detail.
   - `== Scope` — `+` list of what the document covers.
   - `== Dokumen Terkait` — `+` list of prior HLDs/LLDs.
   - `#pagebreak()`
3. `= _High Level Solution_`
   - `== Latar Belakang` — one prose paragraph on the current state and why the
     tahap is needed, then a `+` list of the tahap's inclusions.
   - `== Tujuan` — `+` list of concrete goals.
   - `== Non-Goals` — `+` list of deliberately excluded items.
   - `#pagebreak()`
   - `== System Design` — exactly one `#render_pintora(...)` componentDiagram,
     then a short paragraph on what changed vs the previous tahap.
   - `#pagebreak()`
   - `== Data Flow End-to-End` — one `===` subsection per key flow (2–4 flows),
     each containing exactly one `#render_pintora(...)` sequenceDiagram.
   - `#pagebreak()`
   - `== Teknologi yang Dipakai` — one intro line, then a 2-column table
     `Lapisan | Teknologi`; call out new/changed layers.
   - `== Alternatives Considered` — one `===` per decision; each is a 3-column
     table `Aspek | <Alternative A> | <Alternative B (Dipilih)>` followed by a
     `Keputusan:` paragraph naming the chosen option and why.
   - `#pagebreak()`
   - `== Entitas dan Model Data` — one intro line, then a 3-column table
     `Entity | Status | Deskripsi` where `Status` ∈ `Fixed` / `Diubah` / `Baru`;
     add a short note only when a constraint is non-obvious.
   - `#pagebreak()`
   - `== Modul-Modul` — one intro line, then module groups in this order,
     omitting a group the tahap does not touch: `=== Backend Services`,
     `=== Mobile (Frontend)`, `=== Dashboard (Frontend)`. Each `====` module:
     backend uses a `be_spec` table + `+` bullets; frontend uses `+` bullets or
     one short paragraph.
   - `== Catatan Terbuka` — _optional_; emit only when unresolved decisions
     remain, as a `+` list, preceded by `#pagebreak()`. Omit the section entirely
     when everything is resolved.

### Diagram (pintora) rules — non-negotiable

Malformed diagrams crash the pintora WASM plugin. Always:

- Wrap in `#render_pintora(factor: <0.25–0.45>, caption: [...], raw: "...")`.
- Escape inner quotes as `\"`; use literal newlines inside the block.
- Use `participant X as Label` in sequence diagrams — **never** `actor`.
- **Never** put `&` in a message or condition label — use "dan".
- **Never** put `->` inside a message label — use words ("dapat", "menghasilkan").
- **Never** put a comma inside an `alt`/`else` condition — use "dan".
- Declare every node (`[...] as id`) before referencing it; quote spaced labels.
- Keep participant/node names identical across the document's diagrams.

## Phase 6 — Verify

Compile the HLD and fix all errors before reporting.

- If `typst` CLI is available: `typst compile <path> --root <docs-root>`.
- Else use the Python package (fast, no network): `pip install --user typst`,
  then
  `python3 -c "import typst; typst.compile('<real-typ-path>', output='/tmp/opencode/<name>.pdf', root='<real-docs-root>')"`.
  `.docs` may be a symlink; pass the **real** path and real root.
- A `plugin panicked: wasm unreachable` error is always a pintora diagram —
  bisect the `#render_pintora` blocks and apply the diagram rules above.
- Do not commit a broken document. Leave the PDF only in `/tmp` unless the user
  asked for it next to the `.typ`.

## Phase 7 — Report

Reply with: the output path, page count, user decisions baked in, and any items
deliberately deferred to `Catatan Terbuka` or the LLD. Keep it under a few lines;
no essays.

## Output contract (consistency guarantee)

Every invocation produces an HLD with: the header block above; the fixed section
order (TL;DR → Introduction → High Level Solution with Latar Belakang / Tujuan /
Non-Goals / System Design / Data Flow / Teknologi / Alternatives / Entitas /
Modul-Modul, plus optional Catatan Terbuka); `[Baru]`/`[Perubahan]` tags on every
module; `be_spec` tables on every backend module; pintora diagrams that compile;
and a `Keputusan:` line on every alternative. No section is omitted; untouched
module groups are dropped, not stubbed.
