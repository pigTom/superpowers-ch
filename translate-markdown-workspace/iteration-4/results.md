# Iteration 4 测试结果（v4 prompt + 全新测试集）

## 测试集（全新）

| ID | 文件 | 行数 |
|---|---|---|
| eval-0 | /Volumes/Dev/superpowers/CODE_OF_CONDUCT.md | 128 |
| eval-1 | /Volumes/Dev/superpowers/README.md | 194 |
| eval-2 | /Volumes/Dev/superpowers/tests/subagent-driven-dev/go-fractals/plan.md | 172 |

新测试集的多样性：纯散文（行为准则）+ 项目主 README + 含 Go 代码的实施计划。无一文件出现在 v1-v3 的训练历史中。

## Subagent 自评 vs 主审实际评

| eval | 自评 | 主审实际评 |
|---|---|---|
| eval-0 | good | **good** |
| eval-1 | perfect | **good** |
| eval-2 | perfect | **perfect** |

虚高率：1/3，与 v3 持平。证据机制依然部分有效。

## v4 关键修复（vs v3）

`forbidden_translation_check` 强制 subagent 列出每个出现的专名 + verdict。eval-1 / eval-2 的检查表都列了 10+ 个专名，每项有 source/target 行号 + 文本快照。

## v4 仍存在的问题

### eval-1（README.md）—— 真错误

**1. 复合标识符被拆开译**（v4 没覆盖的边界）：
- 第 13 行：`subagent-driven-development` → `subagent驱动开发`
- subagent 在自检里报 `"first_target_text": "subagent驱动开发"` 还**自评 verdict: ok**，因为它把 `subagent` 这个词单独看作"保留英文"了，没意识到完整标识符 `subagent-driven-development` 是一个不可分割的 token。

**2. 二级标题（##）翻译不一致**：
| 行号 | 源 | 译 |
|---|---|---|
| L5 | `## How it works` | `## How it works` |
| L18 | `## Sponsorship` | `## 赞助` ← 唯一翻译 |
| L27 | `## Installation` | `## Installation` |
| L108 | `## The Basic Workflow` | `## The Basic Workflow` |
| L126 | `## What's Inside` | `## What's Inside` |
| L152 | `## Philosophy` | `## Philosophy` |
| L161 | `## Contributing` | `## Contributing` |
| L184 | `## Community` | `## Community` |

8 个 `##` 级标题里 7 个保留英文、1 个译中。明显不一致。

**3. 缩写的「中文(英文)」顺序反了**：
- 规则示例：`TDD` → `测试驱动开发(TDD)`（中文在前）
- subagent 实际译：`TDD(测试驱动开发)`（英文在前）
- 同样问题：`YAGNI(你不会需要它)`、`DRY(不重复自己)`
- 同文档内三处一致，但与规则方向相反。

### eval-0（CODE_OF_CONDUCT.md）—— 小问题

- subagent 在 evidence 里报告的 source_line / target_line 数字对不上（claimed source line 117 → target line 108），但实际文件行数和内容是一致的（128/128，对位正确）。说明 subagent 对自己的报告写得草率，不影响最终译文。
- "Contributor Covenant" 译为「贡献者契约」（不在 F 清单里，但其实是个文档名/品牌）。判断点。

### eval-2（go-fractals plan.md）—— 干净

- 行数对齐（172/172）✅
- `subagent-driven-development` 在 inline code 里完整保留 ✅
- `Go`, `Cobra`, `Sierpinski`, `Mandelbrot` 全保留 ✅
- `## Context` 保留英文（合规则），`## Tasks` 译中（合常理）
- **执行：** / **验证：** 译中（合理）
- 整体最干净。

## 综合对比 v3 → v4（在不同测试集上）

| 维度 | v3（旧测试集） | v4（新测试集） |
|---|---|---|
| 平均虚高率 | 1/3 | 1/3 |
| 严重违规（block 完整性 / 专名翻译） | 0 | 0 |
| 中度问题（一致性 / 边界 token） | symlink/junction 翻译 | 复合标识符拆分 + heading 不一致 |
| 轻微问题 | acronym 已展开 | acronym 顺序反了 |

v4 的 `forbidden_translation_check` 解决了 v3 的「我已知中文译法但不该用」问题（eval-1 / eval-2 里的 subagent / hook / skill 全保留英文），但暴露了新边界：

1. **复合标识符**：`A-B-C` 形式不能被拆成「A 的中文 + B-C 的英文」。
2. **同类元素一致性**：所有 `##` 应同译或同留，不能混。
3. **acronym 顺序**：规则示例的方向需要更明确。

## v5 候选改进

1. **复合标识符规则**（加进规则 D 或 F）：
   > 形如 `subagent-driven-development`、`using-superpowers`、`claude-code` 这种用连字符连接的多词标识符（通常出现在 inline code 或被引用为 skill / module / package 名）整体保留英文，**不可拆分翻译**——`subagent-driven-development` 永远不能出现 `subagent驱动开发` 这样的形式。
2. **标题一致性规则**（加进规则 A 或 G）：
   > 文档内同级别标题（`##` / `###`）必须采用同一种处理方式（全译 or 全留英文）。如果选择保留英文，整篇统一；如果选择翻译，整篇统一。
3. **acronym 顺序明确化**（更新规则 E 示例）：
   > 首次出现采用「中文全称(英文缩写)」格式，如 `测试驱动开发(TDD)`、`命令行界面(CLI)`、`你不会需要它(YAGNI)`——**中文在括号外，英文在括号内**。
4. **forbidden_translation_check 增强**：subagent 不仅查 keyword，还要把 keyword 周围的连字符上下文一并贴出，例如查 `subagent` 时如果 source 是 `subagent-driven-development`，应贴完整 token 而不是单词。

— 等用户决定 —
