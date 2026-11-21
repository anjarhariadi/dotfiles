---
description: Generate an LLD Typst document from an HLD Typst file, matching the house structure.
agent: build
---

# Create LLD

You are a senior engineer producing a **Low Level Design (LLD)** Typst document
from an existing **High Level Design (HLD)** Typst document. The output must be
structurally identical across every run so that LLDs are consistent and
reviewable.

**Input:** `$ARGUMENTS` — path to the HLD `.typ` file (e.g.
`.docs/hld/edc/hld_edc_tahap_3.typ`). If `$ARGUMENTS` is empty, ask the user for
the HLD path and stop until they answer.

## Phase 0 — Load references (always, before analyzing)

Read these, in order:

1. The HLD given in `$ARGUMENTS` — the single source of truth for scope.
2. `.docs/lld/template.typ` — the LLD template. Note the exported helpers:
   `conf`, `revision`, `approval1`, `approval2`, `render_pintora`, `be_spec`.
3. Any sibling LLD for the same project/tahap if one exists (to extend, not
   duplicate).

Do **not** invent helper functions. Use only the template's exported API. The
required document structure and style are fully specified in **Phase 5** and the
**Diagram rules** below — follow them directly, without reading an example LLD.

## Phase 1 — Analyze the HLD comprehensively

Extract and build an internal checklist; every item must land in some LLD
section (traceability — do not invent features, do not silently drop HLD
bullets):

- Solution architecture, new clients/channels, changed external integrations.
- New/changed backend modules: methods, inputs, validation rules, error codes.
- Data model: entities, new/renamed columns, nullability, constraints, migrations.
- API surface: new/changed endpoints, HTTP verbs, paths, auth/client scope.
- Caching / Redis: keys, values, TTLs, expiry and cleanup.
- Frontend changes per surface (mobile / shared package / dashboard).
- Cross-cutting: security, logging, error handling, transaction boundaries.
- Rollout: CI/CD, infrastructure, rollback, migration order.
- Non-goals and "Alternatives Considered" decisions — reflect the chosen option
  in the design, and echo rejected alternatives only where they affect the design.
- Package/dependency or third-party client migrations (state the need, no code).

## Phase 2 — Ground in the real codebase

The LLD describes the **target** design, but identifiers must be real. Explore
the repo (use the `explore` subagent in parallel where possible) to confirm:
actual service/module names, entity and DTO fields, existing route prefixes,
middleware names, enum values, Redis key namespaces, and the nearest existing
pattern to follow. Cite `file:line` in Backend Detail where it clarifies a
change. Do not contradict the code without flagging it.

## Phase 3 — Confirm unknowns with the user

Ask **only** genuine open decisions the HLD leaves unresolved. Batch all
questions in a single `question` tool call, each with concrete options and a
recommended default. Typical unknowns:

- How an entity/identifier is bound (e.g. env at build vs config endpoint vs request body).
- Library/mechanism choice left "tentative" in the HLD.
- Split/ratio/key-namespace/rate-limit values that are not specified.
- Output location, author, version, and date when they cannot be derived.
- Whether to include existing-bug fixes (default: new features only).

Do not stall on anything you can reasonably default — ship the lazy, correct
default and state it. Never fabricate an answer.

## Phase 4 — Determine output

- **Path:** mirror the HLD's sibling LLD folder:
  `.docs/hld/<project>/hld_<project>_tahap_N.typ` →
  `.docs/lld/<project>/lld_<project>_tahap_N.typ`.
  Confirm with the user if the project folder does not exist yet.
- **Header block** (adapt, never hardcode):
  ```
  #import "../template.typ": *

  #let author = "<from HLD author>"

  #show: conf.with(
    author: author,
    project: [<Project> #rect[Tahap N]],
    revisions: (
      revision(
        author: [#author],
        version: [v<N>.0],
        desc: [Inisialisasi Low Level Design <Project> tahap N],
        date: [<date>],
      ),
    ),
    approvals: (approval1(), approval2(name: [<name>], position: [<position>])),
  )
  ```
  Carry author, project name, approvals, and tahap number from the HLD. Use
  today's date unless the HLD date is the intended sync point.

## Phase 5 — Write the LLD (fixed structure)

### Formatting & style rules (apply to the whole document)

- Prose in **Indonesian** (matches the existing docs); every code identifier,
  field, endpoint path, enum value, and Redis key in `` `backticks` ``.
- Headings: top-level sections are `= _Title_` (title italic between
  underscores, Title Case); module subsections are `==`; deeper detail is `====`
  only when needed. Every module subsection title ends with a `[Baru]` or
  `[Perubahan]` tag, e.g. `== Auth Service — Login Mobile [Baru]`.
- Lists use `+` (Typst enumerated list), one item per behavior or rule.
- Tables: always `#table(columns: (...), inset: 8pt, table.header([...]), ...)`.
  Use `inset: 10pt` for the wider prose tables and `8pt` for list-like tables.
  Do not invent styling beyond this.
- Insert `#pagebreak()` before `_API Contracts_`, `_Cross-Cutting Concerns_`,
  `_Rollout & Deployment_`, `_API Surface Reference_`, and `_Glossary_`.
- Describe behavior and contracts only — no implementation source code. JSON
  samples and method signatures are allowed; code bodies are not.
- Keep it dense and traceable to the HLD: nothing invented, no section omitted.

Use exactly this section order:

1. `= _Backend Detail_`
   - One short intro paragraph framing the tahap's backend changes.
   - One `== <Service> — <change> [Baru]` / `[Perubahan]` subsection per module.
     Each starts with a `#be_spec(service: [...], entity: [...], external_packages: [...])`
     table, then a `*Method:*` bullet list (signature + behavior), then
     `*Aturan validasi:*` / `*Pembatasan laju:*` / key/TTL bullets as applicable,
     then one `#render_pintora(...)` sequence diagram where behavior is non-trivial.
   - Include a `== Migrasi ... [Perubahan]` subsection for package/dependency or
     data migrations; state the need, not the code.
   - State new enums/constants explicitly.
2. `= _API Contracts_`
   - `#table` with header `Status | Path | Auth | Deskripsi`; `Status` ∈ `BARU` / `DIUBAH`.
   - Follow with fenced ```json request/response samples for each new endpoint.
3. `= _Caching Detail_`
   - `#table` with header `Keperluan | Kunci Redis | Nilai | TTL`; if there is no
     change, replace the table with one line: `Tidak ada penambahan caching untuk tahap <N>.`
4. `= _Frontend Detail_`
   - `==` subsection per surface (`Mobile — ...`, `Paket \`shared\` — ...`,
     `Dashboard — ...`), each `[Baru]` / `[Perubahan]`, bullet-heavy, no code.
5. `= _Cross-Cutting Concerns_`
   - `== Security` (a 2-column table `Aspek | Implementasi`), `== Logging & Observability`,
     `== Caching Strategy`, `== Error Handling`, `== Transaction Handling`.
   - Reuse the HLD's own wording for "same as tahap sebelumnya" concerns.
6. `= _Rollout & Deployment_`
   - `== CI/CD Pipeline`, `== Deployment Infrastructure` (with a
     `componentDiagram` via `#render_pintora`), `== Rollback Strategy`.
7. `= _API Surface Reference_`
   - `#table` with header `Kategori | Auth`, grouped by trust boundary
     (Public, Device/EDC, Device/Mobile, Dashboard/WEB, Webhook).
8. `= _Glossary_`
   - `#table` with header `Istilah | Definisi`; define every domain term, enum
     value, and acronym introduced by the HLD.

### Diagram (pintora) rules — non-negotiable

Malformed diagrams crash the pintora WASM plugin. Always:

- Wrap diagrams in `#render_pintora(factor: <0.25–0.45>, caption: [...], raw: "...")`.
- Escape inner quotes as `\"` and newlines as literal newlines inside the block.
- **Never** put `->` inside a message label — use words ("dapat", "menghasilkan").
- **Never** put a comma inside an `alt` / `else` condition — use "dan".
- Declare every node (`[...] as id`) before referencing it; quote spaced labels.
- Prefer the same participant/node names as the HLD diagrams.

## Phase 6 — Verify

Compile the LLD and fix all errors before reporting.

- If `typst` CLI is available: `typst compile <path> --root <docs-root>`.
- Else use the Python package (fast, no network): `pip install --user typst`
  then compile with the docs root, e.g.
  `python3 -c "import typst; typst.compile('<real-typ-path>', output='/tmp/opencode/<name>.pdf', root='<real-docs-root>')"`.
  Note: `.docs` may be a symlink; pass the **real** path and real root.
- A `plugin panicked: wasm unreachable` error is always a pintora diagram —
  bisect the `#render_pintora` blocks (render each raw string in a scratch file
  inside the docs root) and apply the diagram rules above.
- Do not commit a broken document. Leave the PDF only in `/tmp` unless the user
  asked for it next to the `.typ`.

## Phase 7 — Report

Reply with: the output path, page count, any user decisions baked in, and any
HLD bullets deliberately deferred. Keep it under a few lines; no essays.

## Output contract (consistency guarantee)

Every invocation of this command produces an LLD with: the header block above,
the 8 sections in the fixed order, `[Baru]`/`[Perubahan]` tags on every
backend/frontend module subsection, `be_spec` tables, pintora diagrams that
compile, and an API Contracts table plus API Surface Reference table. No section
is omitted; empty ones state "Tidak ada …" explicitly.
