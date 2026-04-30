# Iteration 1 测试结果（v1 prompt）

## 测试集

| ID | 源文件 | 行数 | 特点 |
|---|---|---|---|
| eval-0 | /Volumes/Dev/superpowers/agents/code-reviewer.md | 47 | frontmatter + 结构化清单 |
| eval-1 | /Volumes/Dev/superpowers/docs/README.codex.md | 126 | 含 bash/markdown/powershell/无 tag 代码块 |
| eval-2 | /Volumes/Dev/superpowers/docs/testing.md | 303 | 长文档，多代码块、含程序输出块 |

模型：claude-haiku-4-5（每个 subagent 独立调用）。

## Subagent 自评

| eval | self_rating | 主要难点（其自述） |
|---|---|---|
| eval-0 | **good** | "alignment / 对齐"，"defensive programming"，"loose coupling"，SOLID 是否展开 |
| eval-1 | **good** | "native skill discovery"，"skill usage discipline"，"junction"，"subagent skills" |
| eval-2 | **good** | subagent-driven-development 作为专名，TodoWrite，JSONL |

3 篇全部自评 **good** —— 没有 perfect，也没有 warning。按您的判定标准这意味着「subagent 知道有判断点，但可能没意识到自己犯的错」，需要主审复查。

## 我作为 orchestrator 的复查（找到的实际缺陷）

### eval-0 code-reviewer.md

- ❌ **真错误**：第 28 行 `scalability and extensibility considerations` 被译为 `可扩展性和可扩展性考虑` —— 两个不同概念（可伸缩性 vs 可扩展性）合并成同一个词。Haiku 词汇冲突。
- ⚠️ **生硬**：第 36 行 `Suggestions (nice to have)` → `建议（很好有）`，应为 `锦上添花` 或 `可选改进`。
- ⚠️ **不一致**：`agent` 在 frontmatter 里保留英文，正文混用「agent」。v1 prompt 没明确说 `agent` 是否当专名。
- ⚠️ **判断点**：`SOLID` 没展开（subagent 选择保留），但这与 v1 规则「缩写要展开」冲突。其实 SOLID 是行业标准词，保留更对——是 prompt 规则定得太死。

### eval-1 README.codex.md

- ❌ **规则违反**：第 9-11 行的 ```` ``` ```` 无语言 tag 代码块里写的是 `Fetch and follow instructions from URL`（自然语言），按 v1 第 3 条规则应当翻译，但被原样留英文。
- ⚠️ **边界情况**：第 77-86 行的 ```` ```markdown ```` 块包含 SKILL.md 模板示例（`description: Use when [condition]` / `[Your skill content here]`），整块未翻译。语言 tag 是 `markdown`，按规则应当代码看，但里面其实是给用户填充的中文友好提示。规则没覆盖这种情况。
- ⚠️ **专名歧义**：`subagent skills` 译为 `子代理技能`。Claude Code 生态里 `subagent` 通常保留英文。v1 没把 subagent 列入专名清单。
- ⚠️ **标题**：`# Superpowers for Codex` 完全保留英文。`for` 应译为「适用于」。

### eval-2 testing.md

- ⚠️ **代码块判断混乱**：第 68-135 行是测试程序输出块（无 tag），里面 `[PASS] subagent-driven-development skill was invoked` 等大量英文未翻译。这块到底算 "prose-like" 还是 "console output"？v1 规则把 "无 tag" 一律划为 prose，过于粗糙——程序输出/log 应当保留原文。
- ⚠️ **专名一致性**：`subagent` → `子代理`（同 eval-1）。
- ⚠️ **token**：译为「令牌」。可接受，但中文技术文档普遍直接用 `Token`。
- ✅ 整体结构、frontmatter、bash 代码块注释翻译正确。

## 根因分析

1. **prompt 问题**（占主导）：
   - 无 tag 代码块的处理粗糙（应区分 `prose` / `command output` / `program log`）。
   - 专名清单不完整（缺 `subagent`、`agent`、`hook`、`skill`、`plugin`、`prompt`、`frontmatter`）。
   - 缩写展开规则太死（应只对常见缩写展开，行业标准词保留）。
   - 没让 subagent 在写完后做自检（→ 自评偏宽松）。

2. **模型问题**（次要）：
   - eval-0 的 `scalability/extensibility` 词汇冲突是 Haiku 的真错误。但若 prompt 明确加一条「检查同段内的近义词翻译是否互相区分」可以缓解。
   - 整体看 Haiku 完全胜任此类技术文档翻译，无须升级模型。

## 建议下一步（v2 方向）

1. 把代码块规则改成三类：`代码（语言 tag）`／`程序输出/日志（无 tag 但内容是 console）`／`自然语言文本（无 tag 或 text/plain）`。
2. 加专名清单：subagent / agent / hook / skill / plugin / prompt / frontmatter / TodoWrite / Codex / 等。
3. 缩写规则改为「常见可读 → 展开（TDD/CLI/API/LLM）；行业固定缩写 → 保留（SOLID/REST/JSON/YAML/CSS/HTML）」。
4. subagent 写完后自检三步：检查近义词冲突、检查 markdown 结构、检查代码块未翻译/已翻译位置是否合规。
5. 让 self_rating 更严格：见到一处规则违反就要自降为 `done with warning`。

— 等待用户确认是否进入 iteration 2 —
