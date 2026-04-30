---
name: translate-markdown
description: Translate English Markdown documents into Simplified Chinese. Use this skill whenever the user asks to translate a single Markdown file, or to batch-translate every Markdown file under a directory tree, into Chinese. Trigger this skill on phrases like "translate this doc to Chinese", "把这个markdown翻译成中文", "翻译目录下所有md", or when given a source folder/file and a target folder/file with translation intent.
---

# Translate Markdown to Chinese (v3)

Orchestrate translating English Markdown into Simplified Chinese. The orchestrator (you) does NOT translate prose itself — every per-file translation is delegated to a subagent that runs the Haiku model. Your responsibilities: task discovery, dispatch, quality review, re-dispatch on failure.

## Inputs and outputs

The user provides one of:
- A single `.md` / `.MD` / `.markdown` file path (source), and optionally a target path.
- A directory (source root), and optionally a target directory.

If no target is specified, derive it by replacing the source root with its `-ch` sibling. Examples:
- `/Dev/superpowers/agents/code-reviewer.md` → `/Dev/superpowers-ch/agents/code-reviewer.md`
- `/Dev/superpowers/skills/brainstorming/SKILL.md` → `/Dev/superpowers-ch/skills/brainstorming/SKILL.md`

If the user explicitly specifies a target, use exactly what they specified.

## Step 1 — Discover translation tasks

1. If input is a file, the task list has one entry.
2. If input is a directory, recursively walk it and collect every file whose extension (case-insensitive) is `.md`, `.MD`, or `.markdown`. Skip everything else.
3. For each task, compute absolute source/target paths. Create parent dirs before writing.
4. Track via TaskCreate / TaskUpdate (status: pending / in_progress / done / needs_redo).

## Step 2 — Dispatch each file to a subagent (Haiku)

Spawn one subagent per file via the Agent tool with `subagent_type: general-purpose`, `model: haiku`. Use the prompt template in "Subagent prompt template" below, with source/target paths filled in. Cap parallelism at 4.

## Step 3 — Collect each subagent's report

The subagent returns:
1. `summary` — ~50 Chinese words, including key technical terms.
2. `self_rating` — `perfect` / `good` / `done with warning`.
3. `difficulties` — list of `{phrase, why_hard, how_resolved}`.
4. `target_path` — absolute path of the translated file.
5. `evidence` — concrete source-vs-target line snapshots proving each self-check item (see template).

## Step 4 — Review and re-dispatch decision

For every report:

- Verify line count matches source.
- Diff source vs target on the high-risk regions: every fenced block (especially no-tag and text-tag), every line containing `<...>`, every paragraph naming a proper noun, every paragraph containing close synonyms.
- If you find ANY rule violation in the produced file:
  - Diagnose: prompt issue (rule unclear / example missing) or model issue (rule clear but ignored).
  - Prompt issue → revise the relevant section of the subagent prompt and re-dispatch the same task with the revised prompt.
  - Model issue → re-dispatch with `model: sonnet` using the same prompt.
  - Mark `needs_redo`, dispatch again, re-review.
- Stop iterating on a file once your spot-check confirms `good` or `perfect`.

## Step 5 — Final summary

When all tasks done, report total files, rating distribution, files that needed re-dispatch, and a glossary of recurring terms.

---

## Subagent prompt template

When dispatching a subagent, send a prompt with this exact structure (fill in `<SOURCE_PATH>` and `<TARGET_PATH>`):

```
You are translating one English Markdown document into Simplified Chinese. Read the file at <SOURCE_PATH>. Write the translated file to <TARGET_PATH> (create parent dirs as needed). Then return a structured report with concrete evidence (described at the bottom).

# Translation rules

## A. Markdown structure
Preserve every syntactic marker exactly: headings, lists, tables, blockquotes, links, link anchors, image syntax, footnotes, frontmatter delimiters (`---`), HTML/XML-like tags. The translated file MUST have the same number of lines as the source. Translate only the human-language text inside these structures.

## B. Frontmatter (YAML between leading `---` lines)
- Translate human-prose values like `description`.
- Do NOT translate field names, the `name` value, file paths, model identifiers, or any value that looks like a machine identifier.
- Inside frontmatter description you will often see embedded XML-like tags such as `<example>`, `</example>`, `<commentary>`, `</commentary>`, `<context>`. Keep every tag byte-for-byte. Translate ONLY the human prose between tags. Do not rename, drop, or translate the tag names themselves.
- Keep the structural conversation labels in English: `Context:`, `user:`, `assistant:`, `Examples:`, `Example:`, `Note:`. Translate the prose that follows the colon, but keep the label English.

## C. Fenced code blocks — four cases (READ CAREFULLY)

The case is decided ONLY by the language tag on the opening fence. The CONTENT of the block does not change the case — even if a no-tag block contains `#` characters that look like comments, it is still a no-tag block and case 3 applies.

### Case 1 — Programming-language tag

Tags: ```python ```bash ```js ```ts ```json ```yaml ```toml ```go ```rust ```html ```css ```sh ```bat ```sql ```powershell ```diff (and similar).

- Keep all code byte-for-byte.
- The ONLY thing you may translate is human-language text inside line comments.
- Do not translate string literals, identifiers, keywords, numeric values.

Example:
- Source: ```python\nx = 1  # this is a comment```
- Target: ```python\nx = 1  # 这是一段注释```

### Case 2 — Markdown / docs tag

Tags: ```markdown ```md

Treat the inside as a small Markdown document and apply ALL these rules recursively. In particular:
- Translate prose-like content. This includes:
  - Heading text: `# My Skill` stays `# My Skill` if `My Skill` is a proper noun, otherwise the prose part is translated.
  - Bracketed placeholders that read like instructions: `[Your skill content here]` → `[在此填入你的技能内容]`. `[condition]` → `[条件]`. `[what it does]` → `[做什么]`.
  - Free prose paragraphs.
- Keep verbatim:
  - Frontmatter field names and machine-identifier values: `name: my-skill` stays as-is.
  - Code/syntax-like tokens: `description:` stays as field name.
- When you genuinely cannot decide how to render a phrase, keep the English original verbatim rather than guessing.

Example:
- Source line inside a ```markdown block: `description: Use when [condition] - [what it does]`
- Target: `description: Use when [条件] - [做什么]`
- Source line: `[Your skill content here]`
- Target: `[在此填入你的技能内容]`
- Source line: `name: my-skill`
- Target: `name: my-skill`  (kept verbatim — field name and identifier value)

### Case 3 — No language tag

The opening fence is just ``` with nothing after the backticks.

KEEP THE ENTIRE BLOCK CONTENT BYTE-FOR-BYTE. Do NOT translate anything inside. This rule overrides any visual cue inside the block. The orchestrator will diff this block against the source and reject any modification.

CRITICAL: even if the block contents look like they have programming-style comments (lines that start with `#`, `//`, `--`, `;`, `*`, etc.), or look like prose, they are STILL part of a no-tag block and must NOT be translated. The presence of `#` does not make this a programming-language block.

Concrete anti-example (DO NOT do this):
- Source (no-tag block):
```
tests/
├── claude-code/
│   ├── test-helpers.sh                    # Shared test utilities
│   ├── analyze-token-usage.py             # Token analysis tool
```
- WRONG target (translates the `# Shared test utilities` because it looks like a comment):
```
tests/
├── claude-code/
│   ├── test-helpers.sh                    # 共享测试工具
│   ├── analyze-token-usage.py             # 令牌分析工具
```
- RIGHT target (every byte identical to source):
```
tests/
├── claude-code/
│   ├── test-helpers.sh                    # Shared test utilities
│   ├── analyze-token-usage.py             # Token analysis tool
```

### Case 4 — Text/output tag

Tags: ```text ```txt ```plain ```output ```console ```log ```shell-session

Same as case 3: keep the entire block contents byte-for-byte. Do NOT translate.

## D. Inline code spans
Backticked spans like `like_this`, `~/.claude/settings.json`, `--flag` are never translated.

## E. Acronyms

- **Expand on first use** (Chinese full name + English acronym in parens), then either form is fine: `TDD` → `测试驱动开发(TDD)`, `CLI` → `命令行界面(CLI)`, `API` → `应用程序接口(API)`, `LLM` → `大语言模型(LLM)`, `IDE` → `集成开发环境(IDE)`, `OS` → `操作系统(OS)`, `GUI` → `图形界面(GUI)`.
- **Keep verbatim, do NOT expand** — industry-standard short names where expansion harms readability: `SOLID`, `REST`, `JSON`, `YAML`, `XML`, `HTML`, `CSS`, `HTTP`, `HTTPS`, `URL`, `URI`, `SSH`, `TLS`, `SSL`, `ORM`, `DI`, `MVC`, `CRUD`, `SDK`, `JSONL`, `UUID`.
- **Product/brand acronyms** keep verbatim: `AWS`, `GCP`, `IBM`, `npm`, `pnpm`, `yarn`, `JVM`, `JIT`.
- When `CLI` appears as part of a product name (`OpenAI Codex CLI`, `gh CLI`), keep the whole product name in English without expansion.

## F. Proper nouns — KEEP ORIGINAL, NEVER TRANSLATE

Software / model / company names: `Claude`, `Claude Code`, `Anthropic`, `OpenAI`, `Gemini`, `Gemini 3.0` (NEVER `双子星 3.0`), `ChatGPT`, `GitHub`, `GitLab`, `Bash`, `Python`, `Node.js`, `npm`, `Git`, `Docker`, `Kubernetes`, `macOS`, `Linux`, `Windows`, `WSL`, `MSYS2`, `Cygwin`, `PowerShell`, `Codex`.

Domain terms used as proper nouns in this codebase, KEEP English: `subagent`, `agent`, `hook`, `skill`, `plugin`, `prompt`, `frontmatter`, `TodoWrite`, `Task`, `Skill`, `Agent`, `polyglot`, `junction`, `symlink`, `here-document`, `here-doc`.

Pick ONE rendering for the whole document and use it consistently. If you decide to render `symlink` as `symlink` once, render every other occurrence as `symlink` too — never mix `symlink` and `符号链接` in the same file.

File names, directory names, paths, env vars, JSON keys, command names, URLs, anchors: KEEP verbatim.

## G. Style

- Simplified Chinese, technical-document tone, neutral and concise.
- Chinese punctuation for Chinese sentences (，。：；！？「」), ASCII punctuation inside code/paths/commands.
- Around inline code, English words, numbers: prefer no extra spaces (Chinese tech-doc convention). Keep one space only if the source clearly relied on it.
- Translate by meaning, not word-for-word. Reorder phrases for natural Chinese, but keep the technical claim identical.
- Watch out for close synonyms in the same passage. If the source says `scalability and extensibility`, render them as two distinct Chinese terms (e.g. `可伸缩性和可扩展性`), not one. Same applies to `correctness vs accuracy`, `latency vs throughput`, `simple vs easy`, `validate vs verify`.
- Render fixed English idioms naturally: `nice to have` → `锦上添花` or `可选改进`, NOT `很好有`. `must fix` → `必须修复`. `should fix` → `应当修复`.

## H. Do NOT add, remove, or summarize content
Every paragraph, list item, code block, and tag in the source must appear in the same position in the target.

## I. Mandatory self-check with EVIDENCE (run before reporting)

After writing the file, RE-READ your output and produce a concrete evidence table proving compliance. For each check below, fetch the actual source line and the actual target line at the SAME line number, and put them side by side in your evidence list. Do NOT just write "✓" — that does not count. If a check has no relevant lines (e.g. file has no fenced blocks), say "n/a — no such construct in source" and that is fine.

The required evidence items:

- `line_count`: source line count vs target line count.
- `xml_tags`: pick the FIRST line in the source that contains an HTML/XML-like tag (anything matching `<word>` or `</word>`). Provide source line N + target line N. They must contain the same tags. If no such line, say n/a.
- `structural_labels`: pick the FIRST line in the source containing `Context:`, `user:`, `assistant:`, `Examples:`, `Example:`, or `Note:`. Provide source line N + target line N. Labels must remain English. n/a if absent.
- `no_tag_block`: pick the FIRST line that lies INSIDE a no-tag fenced block (the line right after a ` ``` ` opener with no language). Provide source line N + target line N. They must be byte-identical. n/a if no such block.
- `text_tag_block`: same as above but for ```text / ```txt / ```plain / ```output / ```console / ```log / ```shell-session. n/a if absent.
- `code_block_comment`: pick the FIRST line inside a programming-language block that contains a comment. Show source line N + target line N. Code identical, comment may be translated. n/a if absent.
- `markdown_block`: pick the FIRST prose-like line inside a ```markdown block (e.g. a placeholder, a heading, or a description value). Show source N + target N. Field names like `name:` should be unchanged; placeholders like `[Your skill content here]` should be translated. n/a if absent.
- `proper_noun_consistency`: pick a proper noun that appears 2+ times in the source (e.g. `subagent`, `Claude Code`, `symlink`). Show two source occurrences and the corresponding two target occurrences. Both target occurrences must use the SAME rendering.
- `synonym_pair`: if the source contains close synonyms in one passage (`scalability and extensibility`, `validate / verify`, etc.), show source N + target N. The two synonyms must map to two distinct Chinese terms. n/a if no such pair.

After producing this evidence, decide your `self_rating`:
- `perfect` — every evidence item passes AND no judgement calls were needed.
- `good` — every evidence item passes BUT you made non-trivial judgement calls (terminology choices, idiom rendering, etc.).
- `done with warning` — at least ONE evidence item shows a violation you could not cleanly fix, OR you skipped/guessed a section. List the violation in `difficulties`.

If your self-check evidence shows a clean violation (e.g. no_tag_block source and target differ), you MUST fix the file BEFORE reporting; only escalate to `done with warning` if you genuinely cannot resolve it.

# Output

Return a JSON-shaped report:

- `summary`: ~50 Chinese words summarizing the doc and its key technical terms.
- `self_rating`: `perfect` / `good` / `done with warning` (per criteria above).
- `difficulties`: list of `{phrase, why_hard, how_resolved}`.
- `target_path`: absolute path you wrote.
- `evidence`: object with the keys listed in section I, each value being either `{source_line: N, source: "...", target_line: N, target: "...", verdict: "ok" | "violation"}` OR the string `"n/a — <reason>"`.

Return only the report — the translated file should already be on disk.
```

---

## When all tasks finish

TaskUpdate each to `completed`. Print the Step 5 summary. If the user passed a directory, also print the target tree.
