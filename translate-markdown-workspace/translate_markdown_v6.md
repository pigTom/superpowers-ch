---
name: translate-markdown
description: Translate English Markdown documents into Simplified Chinese. Use this skill whenever the user asks to translate a single Markdown file, or to batch-translate every Markdown file under a directory tree, into Chinese. Trigger this skill on phrases like "translate this doc to Chinese", "把这个markdown翻译成中文", "翻译目录下所有md", or when given a source folder/file and a target folder/file with translation intent.
---
# Translate Markdown to Chinese (v6)

Orchestrate translating English Markdown into Simplified Chinese. The orchestrator (you) does NOT translate prose itself — every per-file translation is delegated to a Haiku subagent. Your responsibilities: task discovery, dispatch with the right tool budget, post-completion review, context-preserving follow-up via SendMessage when needed, and re-dispatch only as a last resort.

## Inputs and outputs

The user provides one of:

- A single `.md` / `.MD` / `.markdown` file path (source), and optionally a target path.
- A directory (source root), and optionally a target directory.

If no target is specified, derive it by replacing the source root with its `-ch` sibling. Examples:

- `/Dev/superpowers/agents/code-reviewer.md` → `/Dev/superpowers-ch/agents/code-reviewer.md`
- `/Dev/superpowers/skills/brainstorming/SKILL.md` → `/Dev/superpowers-ch/skills/brainstorming/SKILL.md`

If the user explicitly specifies a target, use exactly what they specified.

## Step 1 — Discover translation tasks

1. If input is a file, the task list has one entry. Verify the extension is `.md`, `.MD`, or `.markdown`; refuse other types.
2. If input is a directory, recursively walk it and collect every file whose extension (case-insensitive) is `.md`, `.MD`, or `.markdown`. Apply these exclusions:
  - **Skip hidden directories**: any path containing a segment that starts with `.` (e.g. `.github/`, `.codex/`, `.opencode/`, `.git/`).
  - Skip non-Markdown files.
3. For each surviving task, compute absolute source/target paths. Create parent dirs before writing.
4. Track via TaskCreate / TaskUpdate (status: pending / in_progress / done / needs_redo).

## Step 2 — Dispatch each file to a subagent (Haiku) with a tool budget

Use the Agent tool with `subagent_type: general-purpose`, `model: haiku`. Use the prompt template in "Subagent prompt template" below, with source/target paths AND a tool-call budget filled in.

Tool-call budget (counts every Read / Write / Bash / Edit call):


| Source line count | Tool budget |
| ----------------- | ----------- |
| ≤ 200 lines       | 8           |
| 201 – 600 lines   | 12          |
| > 600 lines       | 18          |


The budget protects against the subagent thrashing on a self-imposed conflict (e.g. trying to brute-force literal line-count parity that can't be achieved). The subagent must self-monitor and stop when the budget is exhausted, returning a partial-but-honest report.

Cap parallelism at 4 concurrent subagents.

## Step 3 — Receive each subagent's report

A clean report has: `summary`, `self_rating`, `difficulties`, `target_path`, `evidence`, `tool_calls_used`, `budget_exhausted` (true/false).

## Step 4 — Post-completion review (KEY: context-preserving follow-up)

For every report, do the following IN ORDER:

### 4.1 Quick sanity scan

- Read the target file. Verify it exists and is non-empty.
- Spot-check structural anchors: heading lines align, code fence positions align, blank-line paragraph breaks align.
- Cross-verify the subagent's evidence claims against the actual file: pick 2-3 entries from `evidence` and check that the quoted source/target snippets are really at the claimed positions, and that section F categorization (F.1 verbatim / F.2-F.3 `中文(英文)`) was applied correctly to the most prominent terms.
- Note any of these struggle signals:
  - `tool_calls_used` ≥ 80% of budget.
  - `budget_exhausted: true`.
  - `duration_ms` > 5 × (lines / 100) seconds (heuristic for thrashing).
  - Self-rating `done with warning`.
  - Hack-shaped fixes (e.g. trailing blank-line padding to satisfy a line-count rule).

### 4.2 Decide the next action

Pick exactly one:

**(a) Accept** — file is clean, no struggle signals. Mark task `completed`.

**(b) Fix-only re-dispatch** — file has fixable issues that are localized (a finite list of specific lines, not a systemic translation problem). Spawn a NEW Agent (still `subagent_type: general-purpose`, still `model: haiku`) with a fix-only prompt:

- Tell the agent: read the existing target file at `<TARGET_PATH>`, read the source at `<SOURCE_PATH>`, then apply ONLY the corrections listed below.
- Provide an explicit list of issues, each with: line number, source snippet, current target snippet, expected target snippet.
- Forbid re-translating any other line. Every line not on the fix list must remain byte-identical to the existing target.
- Keep the tool budget tight (e.g. 5 calls — Read source, Read target, Edit/Write, verify, report).

This is cheaper than a full re-translate and avoids regressions in already-correct lines. (Note: an earlier draft of this skill described an "SendMessage to original agentId" path. SendMessage is NOT a tool available to the orchestrator in this environment; fix-only re-dispatch is the practical equivalent.)

**(c) Re-dispatch with stronger model** — file has SYSTEMIC issues that aren't localized to a few lines (whole sections mis-translated, structural anchors broken, or fix-only re-dispatch failed once). Spawn a new Agent with `model: sonnet`, same prompt + the lessons learned from the failed run.

**(d) Revise the prompt and re-dispatch** — the issue stems from rule ambiguity (multiple subagents independently hit the same misinterpretation). Update the subagent prompt in this file, then re-dispatch with the revised prompt to ALL affected files.

### 4.3 Record the action

In TaskUpdate's metadata or a workspace log, note: which action was taken, why, and whether it resolved the issue. This makes failure modes traceable.

## Step 5 — Final summary

When all tasks are `completed`, report total files, rating distribution, files coached / re-dispatched / revised, and a glossary of recurring terms.

---

## Subagent prompt template

When dispatching, send a prompt with this structure (fill `<SOURCE_PATH>`, `<TARGET_PATH>`, `<TOOL_BUDGET>`):

```
You are translating one English Markdown document into Simplified Chinese. Read the file at <SOURCE_PATH>. Write the translated file to <TARGET_PATH> (create parent dirs as needed). Then return a structured report with concrete evidence (described at the bottom).

# Tool-call budget

You have a HARD budget of <TOOL_BUDGET> tool calls (every Read / Write / Bash / Edit counts). Track your own usage. The budget is enough to: read the source once, write the target once, run a couple of verification commands, and re-write if you spot a violation. It is NOT enough to thrash on iterative rewrites.

If you exhaust the budget before finishing the self-check, STOP. Return whatever report you have, set `budget_exhausted: true`, mark `self_rating: done with warning`, and explain in `difficulties` what you ran out of time for. Do NOT try to squeeze in one more write.

# Conflict-handling protocol

If you discover that a rule below conflicts with the source's reality (example: a strict line-count rule cannot be met because Chinese is more compact than English for prose), DO NOT hack the file to satisfy the rule (e.g. padding blank lines, splitting sentences mid-clause). Instead:

1. Translate honestly per the rule's INTENT.
2. Note the conflict in `difficulties` with `{phrase: "<rule name vs reality>", why_hard: "<conflict>", how_resolved: "translated honestly; rule cannot be literally satisfied"}`.
3. Set `self_rating: done with warning`.

The orchestrator will judge whether to relax the rule or take other action. Hacks ALWAYS make things worse.

# Translation rules

## A. Markdown structure — preserve STRUCTURAL ANCHORS, not literal line count

A Markdown source has two kinds of newlines:

- **Hard structural anchors**: heading lines (`# ...`, `## ...`), list items (`- ...`, `1. ...`), table rows (`| ... |`), code-fence opens/closes (` ``` `), frontmatter delimiters (`---`), blank lines that separate paragraphs.
- **Soft wraps**: line breaks INSIDE a paragraph that are purely visual (English authors often wrap at ~80 chars). Markdown renders soft-wrapped lines as one continuous paragraph.

Your translated file MUST:

1. Place every hard structural anchor at the same conceptual position as the source. Heading order, list order, code blocks, frontmatter — all preserved 1:1.
2. Preserve blank lines between paragraphs (so paragraph count matches).
3. Preserve every code block byte-for-byte where the rules below say so.

Your translated file is **NOT REQUIRED** to:

- Have the exact same total line count as the source. Chinese prose is naturally more compact than English; a 3-line English soft-wrapped paragraph may translate into a 1- or 2-line Chinese paragraph. That is correct.
- Match each source line 1:1 within a paragraph. Translate by paragraph, not by line.

DO NOT pad blank lines at end-of-file or anywhere else just to match a line count. That is a hack.

## B. Frontmatter (YAML between leading `---` lines)
- Translate human-prose values like `description`.
- Do NOT translate field names, the `name` value, file paths, model identifiers.
- Inside frontmatter description, keep `<example>`, `</example>`, `<commentary>`, `</commentary>`, `<context>` tags byte-for-byte.
- Keep structural conversation labels in English: `Context:`, `user:`, `assistant:`, `Examples:`, `Example:`, `Note:`.

## C. Fenced code blocks — four cases

The case is decided ONLY by the language tag on the opening fence.

### Case 1 — Programming-language tag (```python ```bash ```js ```ts ```json ```yaml ```toml ```go ```rust ```html ```css ```sh ```bat ```sql ```powershell ```diff)
- Keep all code byte-for-byte. Translate ONLY human-language line comments.

### Case 2 — Markdown / docs tag (```markdown ```md)
- Apply ALL rules recursively.
- Translate prose-like content: heading text, bracketed placeholders.
- Keep verbatim: field names (`name: my-skill`), code-syntax tokens.

### Case 3 — No language tag (just ```)
KEEP THE ENTIRE BLOCK CONTENT BYTE-FOR-BYTE. Even if contents look like programming-style comments (`#`, `//`, `--`), they are NOT comments — they are part of a no-tag block.

### Case 4 — Text/output tag (```text ```txt ```plain ```output ```console ```log ```shell-session)
Same as case 3.

## D. Inline code spans — never translated.

## E. Acronyms

- **First-use expansion format: `中文全称(英文缩写)` — Chinese first, English in parens.** Examples:
  - `TDD` → `测试驱动开发(TDD)` (NOT `TDD(测试驱动开发)`)
  - `CLI` → `命令行界面(CLI)`
  - `API` → `应用程序接口(API)`
  - `LLM` → `大语言模型(LLM)`
  - `IDE` → `集成开发环境(IDE)`
  - `OS` → `操作系统(OS)`
  - `GUI` → `图形界面(GUI)`
  - `YAGNI` → `你不会需要它(YAGNI)`
  - `DRY` → `不重复自己(DRY)`
- After first use either form is acceptable, but be consistent within the document.
- **Keep verbatim, do NOT expand**: `SOLID`, `REST`, `JSON`, `YAML`, `XML`, `HTML`, `CSS`, `HTTP`, `HTTPS`, `URL`, `URI`, `SSH`, `TLS`, `SSL`, `ORM`, `DI`, `MVC`, `CRUD`, `SDK`, `JSONL`, `UUID`.
- **Product/brand**: `AWS`, `GCP`, `IBM`, `npm`, `pnpm`, `yarn`, `JVM`, `JIT`.
- `CLI` as part of a product name (`OpenAI Codex CLI`, `gh CLI`): keep whole product name English.

## F. Proper nouns and domain terms — three categories

These three categories use DIFFERENT rules. Read each carefully.

### F.1 Software / model / company names — keep English verbatim

These are brand / product / model names that should stay in English. No parenthetical Chinese.

List: `Claude`, `Claude Code`, `Anthropic`, `OpenAI`, `Gemini`, `Gemini 3.0`, `ChatGPT`, `GitHub`, `GitLab`, `Bash`, `Python`, `Go`, `Node.js`, `npm`, `Git`, `Docker`, `Kubernetes`, `macOS`, `Linux`, `Windows`, `WSL`, `MSYS2`, `Cygwin`, `PowerShell`, `Codex`, `Superpowers`.

Examples:
- `Gemini 3.0` → `Gemini 3.0` (NEVER `双子星 3.0`)
- `Claude Code` → `Claude Code`

### F.2 Domain / platform terms — `中文(英文)` on first use

These are concepts that have natural Chinese renderings AND a recognized English form in the platform vocabulary. On first occurrence in the document, use `中文全称(英文)` with Chinese first and English in parens. After first use, either form is acceptable — be consistent within the document.

Terms list: `subagent`, `agent`, `hook`, `skill`, `plugin`, `prompt`, `frontmatter`, `TodoWrite`, `Task`, `Skill`, `Agent`, `polyglot`, `junction`, `symlink`, `here-document`, `here-doc`, `marketplace`, `headless`, `session`, `transcript`.

Examples (first use):
- `subagent` → `子代理(subagent)`
- `hook` → `钩子(hook)`
- `skill` → `技能(skill)`
- `symlink` → `符号链接(symlink)`
- `junction` → `连接(junction)`
- `frontmatter` → `前置元数据(frontmatter)`
- `marketplace` → `市场(marketplace)`
- `headless` → `无头(headless)`

After first use any later occurrence may use either the Chinese name or the English form, but the document must be internally consistent: pick one and stick with it.

### F.3 Composite (hyphen-separated) identifiers — `中文全称(英文)` on first use; treat as a single unit

Hyphen-connected multi-word identifiers like `subagent-driven-development`, `using-superpowers`, `claude-code`, `pre-commit`, `read-eval-print-loop` are skill names / package names / function names. They are a single conceptual unit and **must never be partially translated** (e.g. `subagent驱动开发` is forbidden because it splits the identifier).

On first occurrence in the document, render as `中文全称(原始英文)` with the original hyphenated identifier preserved verbatim inside the parens.

Examples (first use):
- `subagent-driven-development` → `子代理驱动开发(subagent-driven-development)`
- `using-superpowers` → `使用 Superpowers(using-superpowers)`
- `pre-commit` → `预提交(pre-commit)`

After first use any later occurrence may use either the Chinese name or the original identifier verbatim, but the document must be internally consistent.

NEVER produce partial mixes like `subagent驱动开发` or `使用-superpowers`. The original token inside parens must always appear as the exact hyphenated string from the source.

### F.4 Default for proper nouns not on the lists

When in doubt, the Chinese-first preference is `中文全称(英文)`. Pick a Chinese rendering, put the original English in parens on first use, stay consistent thereafter.

### F.5 Verbatim contexts (override all of F.1 – F.4)

Inline code spans, file paths, env variables, JSON keys, command-line flags, URL anchors, and anything inside language-tagged code blocks remain verbatim — no Chinese is added even if the token appears in F.2 / F.3. The `中文(英文)` expansion only applies in regular prose.

## G. Style

- Simplified Chinese, technical-document tone, neutral and concise.
- Chinese punctuation for Chinese sentences (，。：；！？「」), ASCII inside code/paths.
- Around inline code, English words, numbers: prefer no extra spaces.
- Translate by meaning, not word-for-word. Translate by paragraph, not by line.
- Render close synonyms in same passage as distinct Chinese terms (`scalability and extensibility` → `可伸缩性和可扩展性`).
- Render fixed idioms naturally: `nice to have` → `锦上添花`. `must fix` → `必须修复`. `should fix` → `应当修复`.

## H. Heading consistency

Within a single document, **all headings of the same level must use the same treatment**. Mixed treatment is forbidden — for example you cannot translate `## Sponsorship` to `## 赞助` while leaving `## Installation` as English in the same file.

Default treatment for headings:
- Heading text that is regular prose → translate to Chinese (e.g. `## How it works` → `## 工作原理`).
- Heading text that IS purely a F.1 brand name → keep verbatim (e.g. `## Anthropic` stays `## Anthropic`).
- Heading text that contains a F.2 domain term or F.3 composite identifier → apply the section F rule on first use (e.g. `## subagent-driven-development` → `## 子代理驱动开发(subagent-driven-development)`).

Whatever rule you apply at one level (`##`), apply it uniformly to every heading at that level in the same document.

## I. Do NOT add, remove, or summarize content
Every paragraph, list item, code block, and tag in the source must appear in the same conceptual position in the target. Total line count may differ; paragraph and structural-anchor count must match.

## J. Mandatory self-check with EVIDENCE (run before reporting)

After writing the file, RE-READ your output and produce a concrete evidence table. For each check, fetch source/target snippets and put them side by side. Do NOT just write "✓". n/a if absent.

### J.1 Structural evidence (`evidence` field)

- `structural_anchor_alignment`: list at least 5 hard structural anchors from the source (a heading, a list item, a code-fence opener, a code-fence closer, a blank line) and the line where each appears in source AND target. They should appear at compatible positions (same relative order; target line may differ from source line because of paragraph compaction, but the anchors must be in the same order).
- `xml_tags`: first source line with an HTML/XML-like tag. n/a if absent.
- `structural_labels`: first line containing `Context:` / `user:` / `assistant:` / etc. n/a if absent.
- `no_tag_block`: first line inside a no-tag block. Bytes must match. n/a if absent.
- `text_tag_block`: same for text/txt/plain/output/console/log/shell-session. n/a if absent.
- `code_block_comment`: first line inside a programming-language block with a comment. n/a if absent.
- `markdown_block`: first prose-like line inside a ```markdown block. n/a if absent.
- `synonym_pair`: close synonyms in same passage. n/a if absent.
- `acronym_first_use`: pick the FIRST acronym you expanded; show source line + target line. Verify format is `中文(英文)` not `英文(中文)`. n/a if no expansion.
- `heading_consistency`: list every `##` heading in source and how it was rendered in target (English or Chinese). All must use the same treatment.
- `f_2_first_use_audit`: walk EVERY term in the section F.2 list (`subagent`, `agent`, `hook`, `skill`, `plugin`, `prompt`, `frontmatter`, `TodoWrite`, `Task`, `Skill`, `Agent`, `polyglot`, `junction`, `symlink`, `here-document`, `here-doc`, `marketplace`, `headless`, `session`, `transcript`). For each term: search the source for its FIRST prose occurrence (NOT inside inline code spans, NOT inside fenced code blocks — those are F.5 verbatim contexts and do not count). Then locate the corresponding line in the target and verify the term appears as `中文(英文)` exactly once. Report each term as one of:

  - `{term: "skill", appears_in_prose: true, first_source_line: N, first_target_line: M, target_text: "...技能(skill)...", verdict: "ok"}` — first prose use is rendered as `中文(英文)`.
  - `{term: "skill", appears_in_prose: true, first_source_line: N, first_target_line: M, target_text: "...技能...", verdict: "violation"}` — first prose use is missing the English in parens. If discovered during self-check, FIX the file (insert the parens at the first prose occurrence) and re-verify; if it still fails after one fix, leave as `violation` and set `self_rating: done with warning`.
  - `{term: "subagent", appears_in_prose: false, only_in_code_or_identifiers: true, verdict: "n/a"}` — term only appears inside inline code spans or as part of an F.3 hyphenated identifier (e.g. `subagent-driven-development`); F.2 first-use rule does not apply here.
  - `{term: "junction", appears_in_source: false, verdict: "n/a"}` — does not appear in source.

  This audit is mandatory because previous test runs showed subagents repeatedly skipping F.2 first-use expansion in dense bullet-list contexts. Walking the explicit list catches what general scanning misses. Do NOT abbreviate or skip terms — the orchestrator will cross-check the report against the actual file.

### J.2 Retry budget on self-check failures

If a self-check item shows a violation, attempt ONE fix. If the second self-check still shows the violation, STOP fixing. Set `self_rating: done with warning`, list the violation in `difficulties`, return the report. The orchestrator will follow up via fix-only re-dispatch if needed.

### J.3 Self-rating

- `perfect` — every evidence item ok, no judgement calls.
- `good` — every item ok or n/a BUT non-trivial judgement calls.
- `done with warning` — at least ONE violation you could not fix in one attempt, OR you ran out of tool budget, OR a rule conflicts with the source.

# Output

Return a JSON-shaped report:

- `summary`: ~50 Chinese words.
- `self_rating`.
- `difficulties`: list of `{phrase, why_hard, how_resolved}`.
- `target_path`.
- `evidence`: object as in J.1.
- `tool_calls_used`: integer (your honest count).
- `budget_exhausted`: true if you stopped due to budget.

Return only the report.
```

---

## When all tasks finish

TaskUpdate each to `completed`. Print the Step 5 summary. If the user passed a directory, also print the target tree.

## Orchestrator failure-mode log (sketch — for traceability)

For each file, record in workspace log:

```
file: <path>
attempt 1: model=haiku, agentId=<X>, tools=N, duration=Tms, rating=<R>, action=<accept|coach|redispatch|revise>
[if fix-only] fix-attempt: agentId=<X2>, fix_list=<N issues>, result=<R>
[if redispatched] attempt 2: model=sonnet, agentId=<Y>, ...
final: rating=<R>, file=<path>
```

This makes it possible to retrospectively analyze whether SendMessage coaching is more effective than re-dispatch, and to spot rule ambiguities.