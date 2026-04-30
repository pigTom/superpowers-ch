---
name: translate-markdown
description: Translate English Markdown documents into Simplified Chinese. Use this skill whenever the user asks to translate a single Markdown file, or to batch-translate every Markdown file under a directory tree, into Chinese. Trigger this skill on phrases like "translate this doc to Chinese", "把这个markdown翻译成中文", "翻译目录下所有md", or when given a source folder/file and a target folder/file with translation intent.
---

# Translate Markdown to Chinese (v4)

Orchestrate translating English Markdown into Simplified Chinese. The orchestrator (you) does NOT translate prose itself — every per-file translation is delegated to a Haiku subagent. Your responsibilities: task discovery, dispatch, quality review, re-dispatch on failure.

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
   - **Skip hidden directories**: any path containing a segment that starts with `.` (e.g. `.github/`, `.codex/`, `.opencode/`, `.git/`). These hold platform/CI configuration, not human-readable docs the user wants translated.
   - Skip non-Markdown files (`.py`, `.json`, images, binaries, etc.).
3. For each surviving task, compute absolute source/target paths. Create parent dirs before writing.
4. Track via TaskCreate / TaskUpdate (status: pending / in_progress / done / needs_redo).

## Step 2 — Dispatch each file to a subagent (Haiku)

Spawn one subagent per file via the Agent tool with `subagent_type: general-purpose`, `model: haiku`. Use the prompt template in "Subagent prompt template" below, with source/target paths filled in. Cap parallelism at 4.

## Step 3 — Collect each subagent's report

Returns: `summary` (~50 Chinese words), `self_rating` (perfect/good/done with warning), `difficulties`, `target_path`, `evidence`, `forbidden_translation_check`.

## Step 4 — Review and re-dispatch decision

- Verify line count matches.
- Diff source vs target on high-risk regions: every fenced block (especially no-tag and text-tag), every `<...>` tag, every paragraph naming a proper noun, every paragraph with close synonyms.
- Inspect `forbidden_translation_check` — it lists every proper noun the subagent checked. Cross-reference against the actual file: if the subagent claimed `subagent: ✓ kept English` but the file actually has `子代理`, that is a violation.
- If you find ANY rule violation:
  - Diagnose: prompt issue (rule unclear / example missing) or model issue (rule clear but ignored).
  - Prompt issue → revise the relevant section and re-dispatch.
  - Model issue → re-dispatch with `model: sonnet`.
  - Mark `needs_redo`, dispatch again, re-review.
- Stop iterating on a file once your spot-check confirms `good` or `perfect`.

## Step 5 — Final summary

Total files, rating distribution, files re-dispatched, glossary of recurring terms.

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
- Inside frontmatter description you will often see embedded XML-like tags such as `<example>`, `</example>`, `<commentary>`, `</commentary>`, `<context>`. Keep every tag byte-for-byte. Translate ONLY the human prose between tags.
- Keep structural conversation labels in English: `Context:`, `user:`, `assistant:`, `Examples:`, `Example:`, `Note:`. Translate the prose that follows the colon.

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

Treat the inside as a small Markdown document and apply ALL these rules recursively:
- Translate prose-like content: heading text, bracketed placeholders that read like instructions (`[Your skill content here]` → `[在此填入你的技能内容]`, `[condition]` → `[条件]`), free prose paragraphs.
- Keep verbatim: frontmatter field names and machine-identifier values (`name: my-skill` stays as-is), code/syntax-like tokens.
- When you genuinely cannot decide how to render a phrase, keep the English original verbatim rather than guessing.

### Case 3 — No language tag

The opening fence is just ``` with nothing after the backticks.

KEEP THE ENTIRE BLOCK CONTENT BYTE-FOR-BYTE. Do NOT translate anything inside. The orchestrator will diff this block against the source and reject any modification.

CRITICAL: even if the block contents look like they have programming-style comments (lines that start with `#`, `//`, `--`, `;`, `*`, etc.), or look like prose, they are STILL part of a no-tag block and must NOT be translated.

Concrete anti-example (DO NOT do this):
- Source (no-tag block):
```
tests/
├── claude-code/
│   ├── test-helpers.sh                    # Shared test utilities
│   ├── analyze-token-usage.py             # Token analysis tool
```
- WRONG (translates the `# Shared test utilities` because it looks like a comment).
- RIGHT (every byte identical to source).

### Case 4 — Text/output tag

Tags: ```text ```txt ```plain ```output ```console ```log ```shell-session

Same as case 3: keep the entire block contents byte-for-byte.

## D. Inline code spans
Backticked spans like `like_this`, `~/.claude/settings.json`, `--flag` are never translated.

## E. Acronyms

- **Expand on first use**: `TDD` → `测试驱动开发(TDD)`, `CLI` → `命令行界面(CLI)`, `API` → `应用程序接口(API)`, `LLM` → `大语言模型(LLM)`, `IDE` → `集成开发环境(IDE)`, `OS` → `操作系统(OS)`, `GUI` → `图形界面(GUI)`.
- **Keep verbatim, do NOT expand**: `SOLID`, `REST`, `JSON`, `YAML`, `XML`, `HTML`, `CSS`, `HTTP`, `HTTPS`, `URL`, `URI`, `SSH`, `TLS`, `SSL`, `ORM`, `DI`, `MVC`, `CRUD`, `SDK`, `JSONL`, `UUID`.
- **Product/brand**: `AWS`, `GCP`, `IBM`, `npm`, `pnpm`, `yarn`, `JVM`, `JIT`.
- `CLI` as part of a product name (`OpenAI Codex CLI`, `gh CLI`): keep whole product name English.

## F. Proper nouns — KEEP ENGLISH, NEVER TRANSLATE

This is the most violated rule. Read it carefully.

**Even if you know a perfectly natural Chinese rendering, KEEP THE ENGLISH FORM.** Examples of what NOT to do:

- ❌ `subagent` → 子代理   (WRONG — keep `subagent`)
- ❌ `hook` → 钩子          (WRONG — keep `hook`)
- ❌ `symlink` → 符号链接   (WRONG — keep `symlink`)
- ❌ `junction` → 连接 / 交接点 (WRONG — keep `junction`)
- ❌ `Gemini 3.0` → 双子星 3.0 (WRONG — keep `Gemini 3.0`)

The reason: these terms are part of the platform vocabulary the reader recognizes from English docs, code, CLI flags, and JSON config keys. Translating them creates a glossary mismatch that confuses readers and breaks search.

### Always-keep-English list

**Software / model / company names** (NEVER translate):
`Claude`, `Claude Code`, `Anthropic`, `OpenAI`, `Gemini`, `Gemini 3.0`, `ChatGPT`, `GitHub`, `GitLab`, `Bash`, `Python`, `Node.js`, `npm`, `Git`, `Docker`, `Kubernetes`, `macOS`, `Linux`, `Windows`, `WSL`, `MSYS2`, `Cygwin`, `PowerShell`, `Codex`, `Superpowers`.

**Domain / platform terms** (NEVER translate, even if a Chinese rendering exists):
`subagent`, `agent`, `hook`, `skill`, `plugin`, `prompt`, `frontmatter`, `TodoWrite`, `Task`, `Skill`, `Agent`, `polyglot`, `junction`, `symlink`, `here-document`, `here-doc`, `marketplace`, `headless`, `session`, `transcript`.

If the same term appears multiple times, use the SAME English rendering everywhere. Never mix `symlink` and `符号链接` in the same file.

File names, directory names, paths, env vars, JSON keys, command names, URLs, anchors: KEEP verbatim.

## G. Style

- Simplified Chinese, technical-document tone, neutral and concise.
- Chinese punctuation for Chinese sentences (，。：；！？「」), ASCII punctuation inside code/paths/commands.
- Around inline code, English words, numbers: prefer no extra spaces. Keep one space only if the source clearly relied on it.
- Translate by meaning, not word-for-word.
- Render close synonyms in the same passage as distinct Chinese terms (`scalability and extensibility` → `可伸缩性和可扩展性`, not collapsed).
- Render fixed English idioms naturally: `nice to have` → `锦上添花` or `可选改进`. `must fix` → `必须修复`. `should fix` → `应当修复`.

## H. Do NOT add, remove, or summarize content
Every paragraph, list item, code block, and tag in the source must appear in the same position in the target.

## I. Mandatory self-check with EVIDENCE (run before reporting)

After writing the file, RE-READ your output and produce a concrete evidence table. For each check, fetch the actual source line and target line at the SAME line number side by side. Do NOT just write "✓". n/a if absent.

### I.1 Structural evidence (`evidence` field)

- `line_count`: source line count vs target line count.
- `xml_tags`: first source line with an HTML/XML-like tag. n/a if absent.
- `structural_labels`: first source line containing `Context:`, `user:`, `assistant:`, `Examples:`, `Example:`, or `Note:`. n/a if absent.
- `no_tag_block`: first line inside a no-tag fenced block. Bytes must match. n/a if absent.
- `text_tag_block`: same for text/txt/plain/output/console/log/shell-session. n/a if absent.
- `code_block_comment`: first line inside a programming-language block with a comment. n/a if absent.
- `markdown_block`: first prose-like line inside a ```markdown block. n/a if absent.
- `synonym_pair`: close synonyms — n/a if absent.

### I.2 Forbidden-translation check (`forbidden_translation_check` field) — NEW

Walk the proper-noun list in section F. For EACH term that actually appears in the source, produce a row in this object:

```
{
  "subagent": {"appears_in_source": true, "first_source_line": 47, "first_source_text": "...subagent...", "first_target_line": 47, "first_target_text": "...subagent...", "all_target_occurrences_consistent": true, "verdict": "ok"},
  "hook": {"appears_in_source": false, "verdict": "n/a"},
  "symlink": {"appears_in_source": true, "first_source_line": 27, "first_source_text": "Create the skills symlink", "first_target_line": 27, "first_target_text": "创建技能 symlink", "all_target_occurrences_consistent": true, "verdict": "ok"},
  ...
}
```

Run this check for EVERY term in the section F lists that you find in the source. The verdict is:
- `"ok"` — appears, kept English, consistent across all occurrences.
- `"violation"` — appears in source but you translated it (e.g. `subagent` → 子代理) or rendered it inconsistently. If you discover this during self-check, FIX the file before reporting and re-run the check.
- `"n/a"` — does not appear in source.

You MUST NOT report `verdict: ok` while the actual target contains the Chinese rendering. The orchestrator will cross-verify.

### I.3 Self-rating

`self_rating` is set as follows (be honest):

- `perfect` — every `evidence` item is `ok`, every `forbidden_translation_check` item is `ok` or `n/a`, AND you made no non-trivial judgement calls.
- `good` — every `evidence` and `forbidden_translation_check` item is `ok` or `n/a`, BUT you made non-trivial judgement calls (terminology, idiom, ambiguous phrasing).
- `done with warning` — at least ONE evidence or forbidden-translation item is `violation` that you could not cleanly fix, OR you skipped/guessed a section. List the violation in `difficulties`.

If self-check shows ANY violation, fix the file BEFORE reporting; only escalate to `done with warning` if you genuinely cannot resolve it.

# Output

Return a JSON-shaped report:

- `summary`: ~50 Chinese words.
- `self_rating`.
- `difficulties`: list of `{phrase, why_hard, how_resolved}`.
- `target_path`.
- `evidence`: object as described in I.1.
- `forbidden_translation_check`: object as described in I.2.

Return only the report — the translated file should already be on disk.
```

---

## When all tasks finish

TaskUpdate each to `completed`. Print the Step 5 summary. If the user passed a directory, also print the target tree.
