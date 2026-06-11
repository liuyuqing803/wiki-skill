---
name: wiki
description: "Use when building or maintaining an Obsidian-style personal research knowledge base with LLMs: ingesting raw sources, compiling markdown wiki pages, asking questions against the wiki, producing markdown/slides/visual outputs, running health checks, and feeding outputs back into the knowledge base."
metadata:
  short-description: Build and maintain LLM-operated personal research wikis
---

# Personal LLM Knowledge Base

Use this skill when the user wants to turn research materials into a living personal knowledge base, especially one viewed in Obsidian and maintained mostly by an LLM agent.

Core idea: the user provides or points to raw materials; the LLM agent maintains the wiki. The user should rarely hand-edit compiled wiki pages.

This skill implements Karpathy's "LLM Knowledge Bases" mental model — Data ingest → IDE → Q&A → Output → Linting — as a six-step executable workflow with hard quality gates.

## Operating Model

Default folder structure:

```text
knowledge-base/
├── raw/              # Source materials, clipped pages, papers, repos, datasets, images
├── tmp/              # Temporary extraction/capture artifacts, not polished outputs
├── wiki/             # LLM-compiled markdown wiki
│   ├── _indexes/     # Topic maps, source index, glossary, open questions, tools index
│   ├── concepts/     # Concept pages
│   ├── sources/      # Source summaries
│   └── outputs/      # Short filed-output cards, not full output mirrors
├── outputs/          # Polished human-facing deliverables
│   ├── decks/        # Marp slide decks
│   ├── scripts/      # Generator scripts (matplotlib, etc.)
│   ├── diagrams/     # Excalidraw / Mermaid sources
│   └── assets/       # Generated images, figures
├── tools/            # Optional KB-local CLI helpers (search, stats, orphans)
└── logs/             # Runs, decisions, ingest reports, health checks
```

Adapt names to an existing vault or repo, but preserve the distinction between `raw/`, compiled `wiki/`, and generated `outputs/`.

## IDE: Obsidian Vault Recognition

Karpathy's mental model treats Obsidian as the frontend. On entering a KB root:

1. Check for `.obsidian/` directory. If present, treat as an active vault and assume these plugins are available unless told otherwise: core markdown rendering, Marp, Excalidraw, Bases.
2. Use naming conventions that let outputs render in Obsidian without extra setup:
   - Marp decks: `.md` with `marp: true` frontmatter
   - Excalidraw drawings: `.excalidraw.md`
   - Bases views: `.base` files (see `obsidian-bases` capability)
3. Prefer wikilinks `[[page]]` over relative paths so backlinks light up in Obsidian.
4. Embed local images with `![[assets/foo.png]]` (Obsidian shorthand) when the image lives under the same vault.

## Artifact Contracts

Do not let every artifact become a summary. Each folder has a different job:

| Location | Job | Must Not Do |
|---|---|---|
| `raw/` | Preserve original source material, including raw web captures and original files | Rewrite, summarize, or interpret |
| `tmp/` | Hold temporary extraction artifacts such as PDF text dumps, DOM JSON, OCR text, or scratch files | Store polished deliverables or long-term wiki pages |
| `logs/` | Record run notes, decisions, failures, health checks, and capture limitations | Replace source summaries or output briefs |
| `wiki/sources/` | Summarize one source at a time: what this source says, its evidence, and related concepts | Write cross-source synthesis or article drafts |
| `wiki/concepts/` | Define one atomic concept per page with short definition, why it matters, source evidence, and related links | Become a multi-source article, broad literature review, or output brief |
| `wiki/_indexes/` | Provide Chinese navigation and routing: what exists, how topics connect, what to read next, what is missing | Carry the main synthesis, article draft, or full brief |
| `outputs/` | Hold polished human-facing deliverables: briefs, checklists, templates, article drafts, decks, or reusable reports | Store temporary extraction text, DOM JSON, or raw dumps |
| `wiki/outputs/` | Hold short filed-output cards that point to `outputs/` deliverables and explain reuse value | Mirror or copy the full output text |
| `tools/` | KB-local CLI helpers used by both humans and agents (search, orphans, stats) | Replace wiki pages or store data |

Anti-duplication rule:

- `source summary` summarizes a single source only.
- `concept page` explains one concept only.
- `index map` routes readers and agents; it does not carry the main argument.
- `output brief` is where cross-source synthesis, framework reconstruction, and article drafts belong.
- If two generated artifacts would overlap by more than roughly half of their function, shrink the index or filed-output card and keep the full value in `outputs/`.

Language rules:

- `raw/` preserves the source language.
- `wiki/_indexes/*map*.md`, source indexes, open questions, and navigation pages default to Chinese.
- `wiki/concepts/` default to Chinese while preserving necessary English terms.
- `wiki/sources/` may follow the source language, but Chinese sources should be summarized in Chinese.
- `outputs/` default to Chinese unless the user asks for English or bilingual output.

## Capability References

This skill describes the *capabilities* it needs rather than naming specific skills, so it stays useful as the skill ecosystem evolves. When an action below names a capability, use `find-skills` to match it against currently installed skills. Common matches today:

| Capability | What it does |
|---|---|
| URL→markdown capture | Fetch a URL, render with a real browser, output clean markdown |
| HTML→markdown fallback | Parse local HTML to markdown when capture fails or is unavailable |
| Image localizer | Download referenced images into a local `assets/` folder and rewrite links |
| Login-aware / dynamic browser | Browse pages that require login state or JS rendering (follow project-level browsing rules — e.g. the user's global CLAUDE.md may pin a specific browse command) |
| Obsidian vault tooling | Recognize `.obsidian/` vault, generate `.base` views or Excalidraw embeds |
| HTML deck | Upgrade path when Marp is insufficient |
| Diagram generator | Excalidraw / Mermaid producer |
| Data charting | Matplotlib / scripted chart generation |
| Markdown formatter | Clean up broken markdown without changing semantics |
| PDF exporter | Markdown → PDF for archival |

When a capability has no match, fall back to direct tools (curl + manual extraction) and log the gap in `logs/`.

## Workflow

### 1. Orient

- Inspect the current folder structure before creating files.
- Detect KB root (look for `wiki/_indexes/` or a `.obsidian/` directory).
- If the user has named a source file or folder, treat it as the source of truth.
- Identify the mode: new build, incremental ingest, Q&A, output generation, or health check.
- If `tools/` exists, `ls` it and ensure `wiki/_indexes/tools-index.md` reflects current scripts.

> **Karpathy alignment:** sets up the *IDE* context — know whether we're in an Obsidian vault and what CLI helpers exist.

### 2. Ingest Raw Sources

Ingest is a 5-substep pipeline with an explicit Definition of Done. Do not skip steps to "save time" — partial ingest produces silently-broken `raw/`.

**2.1 Capture.** Route by source_type:

| source_type | Action |
|---|---|
| `article` (public URL) | Use "URL→markdown capture" capability; save markdown to `raw/<slug>/index.md` and the HTML snapshot alongside |
| `article` (login / dynamic) | Use "login-aware browser" capability — respect the project's browsing rules (e.g. a global CLAUDE.md may pin a specific browse command) |
| `paper` (PDF) | Keep original at `raw/<slug>/source.pdf`; extract text to `tmp/<slug>.txt`; only summarize into `wiki/sources/` from `raw/` content |
| `video` / `podcast` | Save transcript to `raw/<slug>/transcript.md`; do not store the media file |
| `repo` / `dataset` | Save README, key files inventory, and any docs to `raw/<slug>/`; never clone the full tree |
| `note` (user paste) | Save verbatim to `raw/<slug>/index.md` |

**2.2 Localize Images.** Use "image localizer" capability (or fetch directly) to download every referenced image into `raw/<slug>/assets/` and rewrite markdown references to relative paths. This unlocks multimodal review by future agents and survives link rot. Failed downloads logged to `logs/ingest-<date>.md`.

**2.3 Normalize.** Validate and write frontmatter to `raw/<slug>/index.md`. Required fields:

```yaml
title:
url:                # original source URL, if any
authors:
source_type:        # article | paper | repo | dataset | video | note
captured_at:        # YYYY-MM-DD
language:           # zh | en | ...
word_count:
```

Slug convention: `YYYY-MM-DD-<kebab-case-title>`. Use "markdown formatter" capability if the captured markdown is malformed; never edit semantics.

**2.4 Register.** Two writes, always:

- Upsert one row in `wiki/_indexes/source-index.md`: `slug | title | source_type | status (stub/summarized/deep) | captured_at`.
- Create `wiki/sources/<slug>.md` as a stub from the template with `status: stub`. Do not write the summary body yet — that's step 3.

**2.5 Per-Source Definition of Done.** Ingest is complete only when **all** boxes tick:

- [ ] `raw/<slug>/index.md` exists with complete frontmatter
- [ ] All inline images localized to `raw/<slug>/assets/` (or failure logged)
- [ ] `wiki/sources/<slug>.md` exists as at least a stub
- [ ] `wiki/_indexes/source-index.md` has the new row
- [ ] Any capture failures or limitations recorded in `logs/ingest-<date>.md`

If any box is unchecked, the source is not ingested. Do not move to step 3.

> **Karpathy alignment:** *Data ingest* + the Obsidian image-localization habit so multimodal review works in the *IDE*.

### 3. Compile The Wiki

Write summaries and concept pages. Three hard constraints apply to **new pages and any page you modify**; pages last touched before this skill version are exempt (see Legacy Exemption below).

**3.1 Concept atomicity.** A concept page's `## One-Sentence Definition` must be exactly one sentence. If the natural definition needs sub-headings or two or more sentences to land, split into multiple concepts. Example: ✗ a single page titled "RAG"; ✓ separate pages for `Chunking`, `Embedding Retrieval`, `Reranking`, `Generation Conditioning`.

**3.2 Citation with location.** Every claim under `## Evidence` (in either source summaries or concept pages) must carry either:

- A wikilink with anchor: `[[<source-slug>#section-or-paragraph]]`, or
- A direct quote ≤30 words from the source.

Claims without locatable evidence go under `## Synthesis` (not `## Evidence`) and are flagged as inference. Synthesis is allowed; mislabeling inference as evidence is not.

**3.3 Dedup gate.** Before creating a new concept page, grep `wiki/concepts/` for the proposed title and all aliases. On any match, either merge into the existing page or add the new term to that page's `## Aliases`. Log the decision in `logs/compile-<date>.md`. Never silently create a synonym page.

**3.4 Legacy exemption.** Pages created before this skill version may retain old frontmatter and missing fields. Health check (step 6) lists them under `legacy → revise`; they do not block ingest or compile. A page is "modified" — and thus loses exemption — only when its body changes. Touching only `updated:` does not strip the legacy tag.

**Compile DoD checklist:**

- [ ] `wiki/sources/<slug>.md` has all five template sections populated
- [ ] Every `[[wikilink]]` target page exists (auto-create stubs for missing concepts)
- [ ] `wiki/_indexes/concept-map.md` updated with this source's concept cluster
- [ ] `wiki/_indexes/open-questions.md` records any gap this source exposed

> **Karpathy alignment:** maintains the wiki the *IDE* shows; the hard constraints are what stops the wiki from drifting into LLM-soup over time.

### 4. Answer Questions Against The Wiki

**Indexes-first protocol.** Read in this order, every time:

1. `wiki/_indexes/source-index.md` + `wiki/_indexes/concept-map.md` + `wiki/_indexes/glossary.md`
2. At most 3 most-relevant `wiki/sources/*.md`
3. At most 5 most-relevant `wiki/concepts/*.md`
4. Only if summaries are insufficient: open `raw/<slug>/`
5. If `tools/` has a search or grep helper, prefer it over raw bash grep

Do not skip indexes and grep `raw/` directly — that collapses the model to naive RAG and bypasses curation.

If the wiki lacks the evidence to answer:
- Say so explicitly.
- Append the question to `wiki/_indexes/open-questions.md` with a suggested ingest action.
- Offer to run ingest (step 2) or invoke a web research capability.

Answer placement:
- One-shot conversational answer: respond inline.
- Answer with reuse value (brief, template, comparison, framework): write to `outputs/<slug>.md` (step 5) and offer to file back (step 5's filing rule).

> **Karpathy alignment:** *Q&A* against curated summaries beats raw grep at this scale — but only if indexes are kept fresh by steps 2-3.

### 5. Generate Outputs

Pick the channel that matches the artifact. Each channel has a fixed path so Obsidian and the agent both know where to look:

| Channel | Path | Trigger | Renders in Obsidian via |
|---|---|---|---|
| Markdown brief | `outputs/<slug>.md` | Default | Native |
| Marp slide deck | `outputs/decks/<slug>.md` with `marp: true` frontmatter | User asks for deck/slides/PPT | Marp plugin |
| Chart / data viz | `outputs/scripts/<slug>.py` + `outputs/assets/<slug>.png` | Numerical / data result | Embedded PNG |
| Excalidraw diagram | `outputs/diagrams/<slug>.excalidraw.md` | Flowchart / mindmap | Excalidraw plugin |
| HTML deck | Use "HTML deck" capability (escape hatch) | Marp expressivity insufficient | Browser |
| PDF archive | Use "PDF exporter" capability on a markdown brief | User asks for PDF | External viewer |

When the user asks for `输出物` / `brief` / `整理成文` / `可复用内容`, write a full `outputs/<slug>.md` using the output template:

- `Brief 结论`: 3–8 high-density takeaways.
- `主要概念 / 步骤清单`: table — concept/step | definition | explanation | source evidence (wikilink) | use case.
- `结构与框架关系`: source/framework structure, table or Mermaid.
- `文章草稿`: Chinese original draft reorganized from source claims (not copied).
- `Wiki Links`: links to source summaries and concept pages used.

**Filing rule.** After any useful output, ask whether to file it back. Filing means creating a short filed-output card in `wiki/outputs/` — never copy the full text. The card explains what the output is, when to reuse it, what its sources are, and links back via `../../outputs/<file>.md`.

> **Karpathy alignment:** *Output* — multiple visual channels, all viewable in the IDE, all linkable back into the wiki.

### 6. Run Health Checks (Linting)

Run on demand or on a schedule. Each lint produces structured findings in `logs/health-<date>.md`. The seven lints:

1. **Index parity** — every row in `_indexes/source-index.md` has a matching `wiki/sources/*.md`, and vice versa.
2. **Orphan concepts** — every `wiki/concepts/*.md` is back-linked from at least one `wiki/sources/*.md`.
3. **Evidence citations** — every `## Evidence` bullet on a non-legacy page has a wikilink with anchor or a quoted location. Legacy pages reported under `legacy → revise`, not as failures.
4. **Concept dedup** — no two concept pages share title or alias.
5. **Image localization** — no `raw/<slug>/*.md` references an external image URL.
6. **Output filing** — every `outputs/*.md` has a corresponding `wiki/outputs/*.md` card (or an explicit "do not file" log entry).
7. **Stale questions** — items in `_indexes/open-questions.md` older than 30 days get a suggested next action (re-ingest, close, escalate).

Each lint also notes high-value follow-ups: candidate new articles, suspected inconsistencies across sources, missing data fillable by web research.

> **Karpathy alignment:** *Linting* — incremental data-integrity passes that surface new article candidates and keep the wiki honest.

## Wiki CLI Hooks

Karpathy notes that small KB-local tools (a tiny search engine, an orphan finder, a stats script) are very useful both for the human and for the LLM agent. If the KB has a `tools/` directory:

- Scan it on Orient (step 1) and upsert `wiki/_indexes/tools-index.md` with: command, purpose, example invocation, last-seen date.
- Q&A (step 4) and Health Check (step 6) prefer these tools over raw bash grep when they cover the query.
- When you find yourself running the same multi-step grep three times, suggest filing it as a new tool under `tools/`.

If no `tools/` exists, this section is a no-op — do not create the directory unless the user wants tooling.

## User-Specific Defaults

For this user's AI/tool knowledge-base work, prefer a practical operating taxonomy:

```text
场景 -> 任务 -> 方案 -> 工具
```

Do not turn the knowledge base into a tool encyclopedia first. Beginners describe problems and symptoms before they know tool names.

For skill-first AI workflows, explicitly decide:

- `find skill`: when an existing workflow likely exists.
- `install skill`: when the workflow is reusable and available locally or remotely.
- `create skill`: when no good workflow exists and the process will repeat.

Avoid starter examples that are already one-click native capabilities in mainstream tools.

When the user asks for "评估 / 优化某个 skill"–style work, write the result to `outputs/skill-reviews/<skill-name>.md` and file a card to `wiki/outputs/`.

## Page Conventions

Use Obsidian-friendly markdown:

- YAML frontmatter for page type, status, source, created date, and updated date.
- `[[wikilinks]]` for concepts and related pages; `[[source#anchor]]` for in-page locations.
- Short source-backed summaries before interpretation.
- `> [!note]`, `> [!warning]`, `> [!todo]` callouts when useful.
- Clear sections for evidence, synthesis, open questions, and next actions.

## Templates

### Source summary

```markdown
---
type: source-summary
status: stub          # stub | summarized | deep | legacy
source:               # raw/<slug>/index.md or URL
source_type:          # article | paper | repo | dataset | video | note
authors:
captured_at:
language:
word_count:
created:
updated:
---

# Source: <title>

## TL;DR

<≤3 sentences>

## Claim → Evidence

| Claim | Evidence (location or ≤30-word quote) | Confidence |
|---|---|---|

## Concepts Touched

- [[concept-a]]
- [[concept-b]]

## Useful Quotes

> "..." — §section

## Synthesis

<inference / cross-source connections — NOT evidence>

## Open Questions

- [ ] ...
```

### Concept page

```markdown
---
type: concept
status: stub          # stub | defined | legacy
aliases: []
created:
updated:
---

# <Concept>

## Aliases

<comma-separated alternative names; used by dedup gate>

## One-Sentence Definition

<exactly one sentence>

## Why It Matters

## Evidence

| Claim | Source | Location |
|---|---|---|
|  | [[source-slug]] | #anchor or quote |

## Synthesis

<inference / your interpretation>

## Related

- [[other-concept]]

## Open Questions

- [ ] ...
```

### Output brief

```markdown
---
type: output
status: draft
source:
created:
updated:
---

# <Topic> Brief

## Brief 结论

## 主要概念 / 步骤清单

| 概念/步骤 | 定义 | 解释 | 来源依据 | 使用场景 |
|---|---|---|---|---|

## 结构与框架关系

## 文章草稿

## Wiki Links
```

### Filed output card

```markdown
---
type: filed-output-card
status: active
source_output:       # ../../outputs/<file>.md
created:
updated:
---

# Output: <title>

## 这是什么

## 适合何时复用

## 来源

## 链接

[查看完整输出](../../outputs/<file>.md)
```

### Health check report

```markdown
---
type: health-check
created:
scope:
---

# Knowledge Base Health Check

## 1. Index parity

## 2. Orphan concepts

## 3. Evidence citation gaps (excluding `legacy`)

## 4. Concept duplicates / alias conflicts

## 5. Un-localized images

## 6. Unfiled outputs

## 7. Stale open questions

## Legacy → revise

## New article candidates

## Recommended next runs
```

## Guardrails

- Do not overwrite raw sources.
- Do not invent citations or source claims.
- Do not silently mix old outputs with newly named source data.
- If using web research or a browser, follow the browsing rules active in the current project (e.g. the user's global CLAUDE.md may pin a specific browse command — respect it).
- Keep generated artifacts inside the knowledge-base folder unless the user asks otherwise.
- Do not place extraction dumps, browser JSON, OCR output, or other intermediate evidence in `outputs/`; use `tmp/` or `logs/`.
- Do not mirror full `outputs/` files into `wiki/outputs/`; create filed-output cards only.
- Do not write topic maps as polished essays or briefs; keep them as Chinese navigation artifacts.
- **Dedup before create:** grep `wiki/concepts/` titles and aliases before creating a new concept page.
- **No unsourced evidence:** a claim under `## Evidence` without a wikilink-with-anchor or ≤30-word quote is a lint failure on non-legacy pages.
- **Indexes-first for Q&A:** never grep `raw/` to answer a question without reading `_indexes/` and at least one `sources/` summary first.
- **Register on ingest:** every new source must appear in `wiki/_indexes/source-index.md` before compile begins.
- **Update timestamps:** any modification to a `wiki/` page must update its `updated:` frontmatter field.
- When installing this skill locally, copy the entire skill folder, not only `SKILL.md`.
