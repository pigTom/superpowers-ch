---
name: translate-markdown
description: Translate English Markdown documents into Simplified Chinese. Use this skill whenever the user asks to translate a single Markdown file, or to batch-translate every Markdown file under a directory tree, into Chinese. Trigger this skill on phrases like "translate this doc to Chinese", "把这个markdown翻译成中文", "翻译目录下所有md", or when given a source folder/file and a target folder/file with translation intent.
---
# Translate Markdown to Chinese

Orchestrate translating English Markdown into Simplified Chinese. The orchestrator (you) does NOT translate prose itself — every per-file translation is delegated to the `markdown-translator` agent (Haiku-backed, defined at `.claude/agents/markdown-translator.md`). Your responsibilities: task discovery, dispatch with the right tool budget, post-completion review, and re-dispatch as needed.

The translation rules themselves live entirely inside the `markdown-translator` agent. This skill only handles orchestration. If the user wants to translate a single file directly, they can invoke the agent without going through this skill.

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

## Step 2 — Dispatch each file to the markdown-translator agent

Use the Agent tool with `subagent_type: markdown-translator`. The agent's system prompt already contains all translation rules; you just supply the parameters.

Dispatch message format:

```
SOURCE_PATH: <absolute source path>
TARGET_PATH: <absolute target path>
TOOL_BUDGET: <8 | 12 | 18>
TASK_NAME: <task identifier>
```

Construct `TASK_NAME` from SOURCE_PATH: take the basename of the parent directory and the filename, join with `-`, lowercase, replace non-alphanumeric characters with `-`. Examples:
- `/Dev/superpowers/README.md` → `superpowers-readme-md`
- `/Dev/superpowers/skills/brainstorming/SKILL.md` → `brainstorming-skill-md`

The agent uses TASK_NAME to register with the PostToolUse hook and write `/tmp/tool_audit_{TASK_NAME}` at the end of its run.

Tool-call budget by source line count:

| Source line count | Tool budget |
| ----------------- | ----------- |
| ≤ 200 lines       | 8           |
| 201 – 600 lines   | 12          |
| > 600 lines       | 18          |

The budget protects the agent from thrashing on a self-imposed conflict (e.g. trying to brute-force literal line-count parity that can't be achieved). The agent self-monitors and stops when the budget is exhausted, returning a partial-but-honest report.

Cap parallelism at 4 concurrent dispatches.

## Step 3 — Receive each agent's report

A clean report has: `summary`, `self_rating`, `difficulties`, `target_path`, `evidence`, `tool_calls_used`, `budget_check_count`, `budget_exhausted` (true/false).

`tool_calls_used` is read from the PostToolUse hook counter — accurate, not self-estimated. It includes: registration call (1) + actual work calls + budget-check calls. It excludes the audit-read Bash call itself (PostToolUse fires after, so the agent reads before that +1 lands).

```
true_total      = tool_calls_used + 1
actual_work     = tool_calls_used - 1 - budget_check_count
```

The audit file is also available at `/tmp/tool_audit_{TASK_NAME}` for offline inspection.

## Step 4 — Post-completion review

For every report, do the following IN ORDER:

### 4.1 Quick sanity scan

- Read the target file. Verify it exists and is non-empty.
- Spot-check structural anchors: heading lines align, code fence positions align, blank-line paragraph breaks align.
- Cross-verify the agent's evidence claims against the actual file: pick 2-3 entries from `evidence` and check that the quoted source/target snippets are really at the claimed positions, and that section F categorization (F.1 verbatim / F.2-F.3 `中文(英文)`) was applied correctly to the most prominent terms. Pay particular attention to **semantic accuracy** — the self-check is structural and cannot catch noun/verb substitutions (e.g. source says `skills` but target says `插件(plugin)`); spot-check at least one prose paragraph by reading source and target side by side.
- Note any of these struggle signals:
  - `tool_calls_used + 1 ≥ 0.8 × TOOL_BUDGET` (true_total approached budget limit).
  - `tool_calls_used - 1 - budget_check_count` (actual work calls) is suspiciously low relative to what the task required (agent may have bailed early).
  - `budget_exhausted: true`.
  - `duration_ms` > 5 × (lines / 100) seconds (heuristic for thrashing).
  - Self-rating `done with warning`.
  - Hack-shaped fixes (e.g. trailing blank-line padding to satisfy a line-count rule).

### 4.2 Decide the next action

Pick exactly one:

**(a) Accept** — file is clean, no struggle signals. Mark task `completed`.

**(b) Fix-only re-dispatch** — file has fixable issues that are localized (a finite list of specific lines, not a systemic translation problem). Spawn a NEW Agent (still `subagent_type: markdown-translator`) with a fix-only message:

```
SOURCE_PATH: <absolute source path>
TARGET_PATH: <absolute target path>
TOOL_BUDGET: 5
MODE: fix-only
FIX_LIST:
- line <N>: source = "<source snippet>", current = "<current target>", expected = "<expected target>"
- line <N>: source = "...", current = "...", expected = "..."
- ...
```

The agent's system prompt has a dedicated fix-only mode that reads both files, applies ONLY the listed corrections, and leaves every other line byte-identical. This is cheaper than re-translating and avoids regressions.

(Note: an earlier draft used `SendMessage` to the original agentId for follow-up coaching. SendMessage is NOT a tool available to the orchestrator in this environment; fix-only re-dispatch is the practical equivalent.)

**(c) Re-dispatch with stronger model** — file has SYSTEMIC issues that aren't localized to a few lines (whole sections mis-translated, structural anchors broken, or fix-only re-dispatch failed once). Spawn a new Agent with `subagent_type: markdown-translator` AND override the model to `sonnet` via the Agent tool's `model` parameter (the call-site `model` overrides the agent's frontmatter default).

**(d) Revise the agent prompt and re-dispatch** — the issue stems from rule ambiguity (multiple agents independently hit the same misinterpretation). Edit the agent's system prompt at `.claude/agents/markdown-translator.md`, then re-dispatch the affected files. This is the only action that touches the agent file itself.

### 4.3 Record the action

In TaskUpdate's metadata or a workspace log, note: which action was taken, why, and whether it resolved the issue. This makes failure modes traceable.

## Step 5 — Final summary

When all tasks are `completed`, report total files, rating distribution, files re-dispatched (fix-only / sonnet / prompt-revised), and a glossary of recurring terms.

## Orchestrator failure-mode log (sketch — for traceability)

For each file, record in workspace log:

```
file: <path>
attempt 1: agent=markdown-translator (haiku), agentId=<X>, tools=N, duration=Tms, rating=<R>, action=<accept|fix-only|sonnet|revise>
[if fix-only] fix-attempt: agentId=<X2>, fix_list=<N issues>, result=<R>
[if redispatched] attempt 2: model=sonnet, agentId=<Y>, ...
final: rating=<R>, file=<path>
```

This makes it possible to retrospectively analyze failure modes and spot rule ambiguities that should be folded back into the agent's system prompt.
