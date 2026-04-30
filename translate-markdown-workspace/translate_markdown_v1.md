---
name: translate-markdown
description: Translate English Markdown documents into Simplified Chinese. Use this skill whenever the user asks to translate a single Markdown file, or to batch-translate every Markdown file under a directory tree, into Chinese. Trigger this skill on phrases like "translate this doc to Chinese", "把这个markdown翻译成中文", "翻译目录下所有md", or when given a source folder/file and a target folder/file with translation intent.
---

# Translate Markdown to Chinese

This skill orchestrates translating English Markdown into Simplified Chinese. The orchestrator (you) does NOT translate any prose itself — every per-file translation is delegated to a subagent that runs the Haiku model. Your job is task discovery, dispatch, quality review, and re-dispatch when needed.

## Inputs and outputs

The user provides one of:

- A single `.md` / `.MD` / `.markdown` file path (source), and optionally a target file path.
- A directory (source root), and optionally a target directory.

If the user does not specify a target:

- For a single source file `<src>/path/to/file.md`, derive a target path by replacing the source root with the conventional "<src>-ch" sibling. Examples:
  - `/Dev/superpowers/agents/code-reviewer.md` → `/Dev/superpowers-ch/agents/code-reviewer.md`
  - `/Dev/superpowers/skills/brainstorming/SKILL.md` → `/Dev/superpowers-ch/skills/brainstorming/SKILL.md`
- For a directory `<src>`, the conventional target is the sibling directory with `-ch` appended, preserving every relative subpath.

If the user explicitly specifies a target path or directory, use exactly what the user specified.

## Step 1 — Discover translation tasks

1. If the input is a file, the task list has exactly one entry.
2. If the input is a directory, recursively walk it and collect every file whose extension (case-insensitive) is `.md`, `.MD`, or `.markdown`. Skip everything else (`.py`, `.json`, images, binaries, etc.).
3. For each task, compute the absolute source path and the absolute target path. Create parent directories as needed before writing.
4. Track each task with a status of `pending`, `in_progress`, `done`, or `needs_redo`. Use the TaskCreate / TaskUpdate tools so the user can see progress.

## Step 2 — Dispatch each file to a subagent (Haiku)

For every pending task, spawn one subagent. Use the Agent tool with `subagent_type: general-purpose` and `model: haiku`. Pass the prompt in the "Subagent prompt template" section below, with the source path filled in. The subagent reads the source file itself and writes the translated file to the target path.

You can dispatch multiple subagents in parallel when files are independent. Cap parallelism at 4 concurrent subagents to avoid overwhelming the host.

## Step 3 — Collect each subagent's report

Each subagent must return a structured report containing:

1. `summary` — about 50 words describing what the document is about, including the key technical terms it covered (in Chinese, with original English in parentheses where useful).
2. `self_rating` — one of `perfect`, `good`, or `done with warning`.
3. `difficulties` — a list of specific phrases, terms, code/text-block edge cases, or sentences that were hard or ambiguous, with how the subagent resolved each.
4. `target_path` — the absolute path the translated file was written to.

## Step 4 — Review reports and decide whether to re-dispatch

For every report, you must:

- Spot-check a few non-trivial passages by reading the produced target file alongside the source.
- Detect classic failure modes:
  - Proper nouns or product names translated incorrectly (e.g., "Gemini 3.0" rendered as "双子星 3.0").
  - Acronyms expanded inconsistently or without keeping the original acronym in parentheses.
  - Code inside fenced code blocks that was translated when it should have been preserved as code.
  - Comment text inside code blocks left in English when it should have been translated.
  - Plain-text fenced blocks (e.g., ```text or no language) left in English when they are prose.
  - Markdown structure damaged: headings, lists, links, anchors, code fences, frontmatter, HTML, image alt text mishandled.
- Decide root cause:
  - Prompt issue → revise the subagent prompt for this case and re-dispatch the same task with the new prompt.
  - Model capacity issue → re-dispatch the same task with a stronger model (e.g., Sonnet) using the same prompt.
- Mark the task `needs_redo` and dispatch again, then re-review. Stop iterating on a single file once it is `good` or `perfect` and your spot-check agrees.

## Step 5 — Final summary to the user

When all tasks are `done`, report:
- Total files translated.
- Distribution of self-ratings.
- Any files that required a re-dispatch and why.
- A list of the most common technical terms encountered and how they were rendered.

---

## Subagent prompt template

When dispatching a subagent, send a prompt with this exact structure (fill in `<SOURCE_PATH>` and `<TARGET_PATH>`):

```
You are translating one English Markdown document into Simplified Chinese. Read the file at <SOURCE_PATH>. Write the translated file to <TARGET_PATH>, creating parent directories if needed. Then return a structured report.

# Translation rules

1. Preserve Markdown structure exactly: headings, lists, tables, blockquotes, links, link anchors, image syntax, HTML tags, frontmatter keys, footnotes. Translate the human-readable text inside, but never the syntactic markers.

2. Frontmatter (YAML between leading `---` lines): translate the values of human-prose fields like `description`. Do NOT translate field names, the `name` field, file paths, model identifiers, or any value that looks like a machine identifier. If unsure, leave it.

3. Fenced code blocks:
   - If the fence has a programming-language tag (```python, ```bash, ```js, ```json, ```yaml, ```ts, ```go, ```rust, ```html, ```css, ```sh, ```bat, ```sql, ```toml, etc.): keep all code identical, byte-for-byte. Only translate human-language COMMENTS inside (e.g. `# this is a comment` → `# 这是一段注释`). Do not translate string literals, identifiers, keywords, or anything else.
   - If the fence has no tag, or has ```text / ```txt / ```plain / ```output / ```console: treat the contents as prose and translate the natural-language sentences. Keep file paths, command names, environment variable names, URLs, and example identifiers as-is.

4. Inline code spans (`like_this`): never translate. Keep verbatim.

5. Acronyms and abbreviations: render as `中文全称(英文缩写)` on first occurrence in the document, then either form thereafter is fine. Examples:
   - `TDD` → `测试驱动开发(TDD)`
   - `API` → `应用程序接口(API)`
   - `CLI` → `命令行界面(CLI)`
   - `LLM` → `大语言模型(LLM)`
   If an acronym is also a product name (e.g. `AWS`, `GCP`, `OpenAI`), keep it as-is without expansion.

6. Proper nouns and product/model names: KEEP THE ORIGINAL. Never translate. Examples:
   - `Gemini 3.0` stays `Gemini 3.0`, never `双子星 3.0`.
   - `Claude`, `Claude Code`, `Anthropic`, `OpenAI`, `GitHub`, `npm`, `Bash`, `Python`, `macOS`, `Linux`, `Windows`, `WSL`, `MSYS2`, `Cygwin` all stay verbatim.
   - File names, directory names, and paths stay verbatim (e.g. `hooks.json`, `~/.claude/settings.json`).

7. URLs, anchors, file paths, environment variables, shell commands, JSON keys: keep verbatim.

8. Translation style:
   - Use Simplified Chinese, technical-document tone, neutral and concise.
   - Use Chinese punctuation for Chinese sentences (，。：；！？「」), but keep ASCII punctuation inside code, paths, and command lines.
   - Around inline code, English words, and numbers, prefer no extra spaces (so the rendered Markdown matches typical Chinese tech docs). Exception: keep one space if the source clearly relied on it.
   - Translate by meaning, not word-for-word. Reorder phrases for natural Chinese where needed, but keep the technical claim identical.

9. Do NOT add, remove, or summarize content. Every paragraph, list item, and code block in the source must appear in the same position in the target.

10. If you are unsure how to render a term (jargon, neologism, ambiguous phrase), pick your best translation, keep the original in parentheses on first use, and list the case in your `difficulties` report.

# Output

After writing the target file, return a JSON-shaped report with these fields:

- summary: ~50 words in Chinese summarizing the document, including the main technical terms it covered.
- self_rating: one of "perfect", "good", "done with warning". Be honest. Use "good" if there were any non-trivial judgement calls. Use "done with warning" if you had to skip something, guess at terminology, or the source had ambiguous content you could not fully resolve.
- difficulties: a list of {phrase, why_hard, how_resolved} objects for each tricky case. Empty list is fine if everything was straightforward.
- target_path: the absolute path you wrote.

Return only the report — the translated file should already be on disk.
```

---

## When you finish all tasks

Use TaskUpdate to mark each task `completed`. Print the final summary as described in Step 5. If the user passed a directory, also print the target directory tree so the user can verify nothing was missed.
