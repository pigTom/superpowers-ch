---
name: translate-markdown
description: Translate English Markdown documents into Simplified Chinese. Use this skill whenever the user asks to translate a single Markdown file, or to batch-translate every Markdown file under a directory tree, into Chinese. Trigger this skill on phrases like "translate this doc to Chinese", "把这个markdown翻译成中文", "翻译目录下所有md", or when given a source folder/file and a target folder/file with translation intent.
---

# Translate Markdown to Chinese (v2)

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
4. Track each task via TaskCreate / TaskUpdate (status: pending / in_progress / done / needs_redo).

## Step 2 — Dispatch each file to a subagent (Haiku)

For each pending task spawn one subagent via the Agent tool with `subagent_type: general-purpose` and `model: haiku`. Pass the prompt template in "Subagent prompt template" below, with the source/target paths filled in. Cap parallelism at 4.

## Step 3 — Collect each subagent's report

The subagent returns:
1. `summary` — ~50 Chinese words about the document, including key technical terms (Chinese with English in parentheses where useful).
2. `self_rating` — `perfect` / `good` / `done with warning`.
3. `difficulties` — list of `{phrase, why_hard, how_resolved}` for hard/ambiguous cases.
4. `target_path` — absolute path of the translated file.

## Step 4 — Review and re-dispatch decision

For every report:

- Spot-check non-trivial passages by diffing source vs target.
- Verify line count matches source (Markdown structure preserved).
- Look for these failure modes:
  - Proper nouns/product/model names mistranslated (e.g. `Gemini 3.0` → `双子星 3.0`).
  - Acronym handling inconsistent.
  - Code inside language-tagged code blocks was modified beyond comments.
  - `<example>`, `<commentary>`, `<context>` or any HTML/XML-like tag was dropped, renamed, or translated.
  - `Context:`, `user:`, `assistant:`, `Examples:` structural labels were translated to Chinese (they should stay English).
  - Untagged ```` ``` ```` block contents were modified (they must stay verbatim).
  - Close synonyms collapsed onto same Chinese word in one passage (e.g. `scalability` and `extensibility` both rendered as `可扩展性`).
- Decide root cause:
  - Prompt issue → revise the subagent prompt and re-dispatch.
  - Model issue → re-dispatch with a stronger model (Sonnet) using same prompt.
- Mark `needs_redo` and dispatch again. Stop iterating on a file once `good`/`perfect` and your spot-check agrees.

## Step 5 — Final summary

When all tasks are done, report total files, rating distribution, files that needed re-dispatch, and a glossary of how recurring terms were rendered.

---

## Subagent prompt template

When dispatching a subagent, send a prompt with this exact structure (fill in `<SOURCE_PATH>` and `<TARGET_PATH>`):

```
You are translating one English Markdown document into Simplified Chinese. Read the file at <SOURCE_PATH>. Write the translated file to <TARGET_PATH> (create parent dirs as needed). Then return a structured report.

# Translation rules

## A. Markdown structure
Preserve every syntactic marker exactly: headings, lists, tables, blockquotes, links, link anchors, image syntax, footnotes, frontmatter delimiters (`---`), HTML tags. The translated file MUST have the same number of lines as the source. Translate only the human-language text inside these structures.

## B. Frontmatter (YAML between leading `---` lines)
- Translate human-prose values like `description`.
- Do NOT translate field names, the `name` value, file paths, model identifiers, or any value that looks like a machine identifier.
- Inside frontmatter description, you will often see embedded XML-like tags such as `<example>`, `</example>`, `<commentary>`, `</commentary>`, `<context>`. Keep every tag byte-for-byte. Translate ONLY the human prose between tags. Do not rename, drop, or translate the tag names themselves.
- Keep the structural conversation labels in English: `Context:`, `user:`, `assistant:`, `Examples:`, `Example:`, `Note:`. Translate the prose that follows the colon, but keep the label English.

## C. Fenced code blocks — four cases

1. **Programming-language tag** (```python, ```bash, ```js, ```ts, ```json, ```yaml, ```toml, ```go, ```rust, ```html, ```css, ```sh, ```bat, ```sql, ```powershell, ```diff, etc.):
   - Keep all code byte-for-byte. The ONLY thing you may translate is human-language text inside line comments. Examples:
     - ```python\nx = 1  # this is a comment``` → ```python\nx = 1  # 这是一段注释```
     - String literals, identifiers, keywords, numeric values: NEVER translate.

2. **Markdown / docs tag** (```markdown, ```md):
   - Treat the inside as a small Markdown document and apply ALL these rules recursively to its contents (headings, prose, nested code blocks, etc.).
   - When you genuinely cannot decide how to render a phrase, keep the English original verbatim rather than guessing.

3. **No language tag** (```` ``` ```` with nothing after the opening backticks):
   - Keep the entire block contents verbatim. Do NOT translate anything inside, even if it looks like prose. The orchestrator's spot-check will reject any modification to no-tag blocks.

4. **Text/output tag** (```text, ```txt, ```plain, ```output, ```console, ```log, ```shell-session):
   - Same as case 3: keep the entire block contents verbatim. Do NOT translate.

## D. Inline code spans
Backticked spans like `like_this`, `~/.claude/settings.json`, `--flag` are never translated.

## E. Acronyms

- **Expand on first use** (Chinese full name + English acronym in parens), then either form is fine: `TDD` → `测试驱动开发(TDD)`, `CLI` → `命令行界面(CLI)`, `API` → `应用程序接口(API)`, `LLM` → `大语言模型(LLM)`, `IDE` → `集成开发环境(IDE)`, `OS` → `操作系统(OS)`, `GUI` → `图形界面(GUI)`.
- **Keep verbatim, do NOT expand** — these are industry-standard short names where expansion harms readability: `SOLID`, `REST`, `JSON`, `YAML`, `XML`, `HTML`, `CSS`, `HTTP`, `HTTPS`, `URL`, `URI`, `SSH`, `TLS`, `SSL`, `ORM`, `DI`, `MVC`, `CRUD`, `SDK`, `JSONL`, `UUID`.
- **Product/brand acronyms** keep verbatim: `AWS`, `GCP`, `IBM`, `npm`, `pnpm`, `yarn`, `JVM`, `JIT`.

## F. Proper nouns — KEEP ORIGINAL, NEVER TRANSLATE

Software / model / company names: `Claude`, `Claude Code`, `Anthropic`, `OpenAI`, `Gemini`, `Gemini 3.0` (NEVER `双子星 3.0`), `ChatGPT`, `GitHub`, `GitLab`, `Bash`, `Python`, `Node.js`, `npm`, `Git`, `Docker`, `Kubernetes`, `macOS`, `Linux`, `Windows`, `WSL`, `MSYS2`, `Cygwin`, `PowerShell`, `Codex`.

Domain terms used as proper nouns in this codebase, KEEP English: `subagent`, `agent`, `hook`, `skill`, `plugin`, `prompt`, `frontmatter`, `TodoWrite`, `Task`, `Skill`, `Agent`, `polyglot`, `junction`, `symlink`, `here-document`, `here-doc`.

File names, directory names, paths, env vars, JSON keys, command names, URLs, anchors: KEEP verbatim.

## G. Style

- Simplified Chinese, technical-document tone, neutral and concise.
- Chinese punctuation for Chinese sentences (，。：；！？「」), ASCII punctuation inside code/paths/commands.
- Around inline code, English words, numbers: prefer no extra spaces (Chinese tech-doc convention). Keep one space only if the source clearly relied on it.
- Translate by meaning, not word-for-word. Reorder phrases for natural Chinese, but keep the technical claim identical.
- Watch out for close synonyms in the same passage. If the source says `scalability and extensibility`, you MUST render them as two distinct Chinese terms (e.g. `可伸缩性和可扩展性`), not collapse to one. The same applies to `correctness vs accuracy`, `latency vs throughput`, `simple vs easy`, `validate vs verify`, etc.
- Render fixed English idioms naturally:
  - `nice to have` → `锦上添花` or `可选改进`, NOT `很好有`.
  - `must fix` → `必须修复`, `should fix` → `应当修复`, `nice to have` → `锦上添花`.

## H. Do NOT add, remove, or summarize content
Every paragraph, list item, code block, and tag in the source must appear in the same position in the target.

## I. Mandatory self-check (run before reporting)

After writing the file, RE-READ your output and verify each of these. If ANY check fails, fix the issue and re-write before reporting.

1. Line count: target line count == source line count.
2. Tag preservation: every `<...>` HTML/XML-like tag from the source appears at the same position in the target, byte-for-byte.
3. Structural labels in English: `Context:`, `user:`, `assistant:`, `Examples:`, `Example:`, `Note:` are still English in the target.
4. No-tag and text-tag code blocks: identical to source byte-for-byte.
5. Language-tagged code blocks: code is identical except line comments may be translated.
6. Inline code spans, paths, URLs, env vars: identical to source.
7. Proper-noun list (section F): every occurrence is preserved in English.
8. Close synonyms in the same passage: rendered as distinct Chinese terms.
9. Frontmatter `name`, `model`, and other identifier fields unchanged.

Any rule violation discovered during self-check that you cannot cleanly fix → self_rating MUST be `done with warning` and the violation MUST appear in `difficulties`.

# Output

Return a JSON-shaped report:

- `summary`: ~50 Chinese words summarizing the doc and its key technical terms.
- `self_rating`: `perfect` only if every self-check passed and there were no judgement calls; `good` if there were judgement calls but no rule violations; `done with warning` if any self-check failed or you skipped/guessed something you could not resolve.
- `difficulties`: list of `{phrase, why_hard, how_resolved}` objects.
- `target_path`: absolute path you wrote.

Return only the report — the translated file should already be on disk.
```

---

## When all tasks finish

TaskUpdate each task to `completed`. Print the Step 5 summary. If the user passed a directory, also print the target tree so the user can confirm nothing was missed.
