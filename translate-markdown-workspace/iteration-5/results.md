# Iteration 5 测试结果（v5 prompt）

## 测试集（沿用 v4，缩减为 2 个）

| ID | 文件 | 行数 |
|---|---|---|
| eval-0 | /Volumes/Dev/superpowers/CODE_OF_CONDUCT.md | 128 |
| eval-1 | /Volumes/Dev/superpowers/README.md | 194 |

## 性能指标（v4 → v5）

| eval | v4 用时 | v4 工具数 | v5 用时 | v5 工具数 |
|---|---|---|---|---|
| eval-0 | **19 分钟** | **46 次** | 40 秒 | 5/8 |
| eval-1 | 1 分钟 | 4 次 | 54 秒 | 5/8 |

eval-0 修复最显著——v4 因「行数必须一致」规则陷入死循环，v5 工具预算 + 结构锚点替代行数一致后**一次过**。`budget_exhausted: false`。

## Subagent 自评 vs 主审实际评

| eval | 自评 | 主审 |
|---|---|---|
| eval-0 | perfect | **perfect** |
| eval-1 | good | **good** |

主审与自评一致——v5 自评虚高问题消失。

## v5 关键修复确认

### eval-0（CODE_OF_CONDUCT）

- ✅ 行数从 128 自然压缩到 80，**无空行 padding hack**（v4 的根本错误已修复）
- ✅ 7 个 `##` 标题全部翻译且一致（我们的承诺/我们的标准/执法责任/范围/执法/执法指南/署名）
- ✅ 4 个 `###` 子标题（纠正/警告/临时禁令/永久禁令）一致
- ✅ Mozilla（F.1）保留英文 `[Mozilla 行为准则执法阶梯]`
- ✅ URL / email / `[homepage]` 引用链接全部 verbatim

### eval-1（README）

- ✅ **所有 11 个 `##` 标题统一译中**（v4 是 7 英 1 中混搭——已修复）
- ✅ `子代理驱动开发(subagent-driven-development)`（v4 的 `subagent驱动开发` 已修复）
- ✅ acronym 顺序正确：`测试驱动开发(TDD)`/`你不会需要它(YAGNI)`/`不重复自己(DRY)`（v4 反向已修复）
- ✅ 行数 194 = 194 自然对齐
- ✅ F.2 部分应用：`技能(skill)` 首次用展开 ✅
- ✅ F.3 部分应用：`头脑风暴(brainstorming)`、`使用 Git 工作树(using-git-worktrees)`、`编写计划(writing-plans)`、`子代理驱动开发(subagent-driven-development)`、`执行计划(executing-plans)`、`测试驱动开发(test-driven-development)`、`请求代码审查(requesting-code-review)`、`完成开发分支(finishing-a-development-branch)` 都首次展开 ✅

## v5 仍存在的问题（轻微，全在 eval-1）

F.2 / F.3 在「密集列表」场景里有几处首次出现没展开。subagent 似乎对正文段落里的首次出现处理得很好，但在大段 bullet 列表中容易跳过：

| 行号 | 问题 | 严重 |
|---|---|---|
| L3 | `编码代理` —— `agent` 首次用未带 `(agent)` | ⚠️ |
| L29 | `内置的插件市场` —— `plugin`/`marketplace` 首次用未展开 | ⚠️ |
| L141 | `**dispatching-parallel-agents**` —— F.3 首次用未展开 | ⚠️ |
| L143 | `**receiving-code-review**` —— F.3 首次用未展开 | ⚠️ |
| L149 | `**writing-skills**` —— F.3 首次用未展开 | ⚠️ |
| L150 | `**using-superpowers**` —— F.3 首次用未展开 | ⚠️ |

总计 5-6 处一致性「漏网」。规则正确但执行不彻底。

## v1-v5 综合演进

| 维度 | v1 | v2 | v3 | v4 | v5 |
|---|---|---|---|---|---|
| 严重违规（block 完整性 / hack 文件）| ❌ 多处 | ❌ 多处 | 0 | ❌ 19min thrash + pad 空行 | 0 |
| 中度问题（专名、一致性）| ❌ | ⚠️ | ⚠️ symlink 不一致 | ⚠️ 复合标识符拆分 + 标题混搭 | ⚠️ F.2/F.3 漏首次展开 |
| 自评虚高率 | 1/3 | 3/3 | 1/3 | 1/3 | 0/2 |
| 工具效率 | 正常 | 正常 | 正常 | eval-0 thrash | 全部 ≤ 8/8 |
| 整体可发布 | ❌ | ❌ | ⚠️ | ⚠️ | ✅ 接近可发布 |

## 主审下一步动作（按 v5 Step 4.2 决策）

- eval-0：action (a) 直接接受。
- eval-1：原计划 action (b) 通过 SendMessage 给同 agent 发指令——**但实测 SendMessage 不是 orchestrator 可调用的工具**（之前 Agent 工具结果里那行 "use SendMessage with to: 'agentId'" 是格式化提示，不是 API）。

修订 v5 中 action (b) 的语义为 **fix-only re-dispatch**：派一个新的 Haiku Agent，给一份明确的"修这 N 行"清单 + 禁止改其他行，效果等价。

## fix-only re-dispatch 实测结果（修复 eval-1）

派发：1 个 Haiku Agent，tool_budget = 5。

实际：5 工具调用、26 秒、194 行保持不变。6 处全部落地，主审 grep 验证：

| 行 | 现状 |
|---|---|
| L3 | `编码代理(agent)` ✅ |
| L29 | `插件(plugin)市场(marketplace)` ✅ |
| L141 | `**分派并行代理(dispatching-parallel-agents)**` ✅ |
| L143 | `**接收代码审查(receiving-code-review)**` ✅ |
| L149 | `**编写技能(writing-skills)**` ✅ |
| L150 | `**使用 Superpowers(using-superpowers)**` ✅ |

eval-1 修复后实际评：**perfect**。

## v5 同步更新

skill 里 Step 4.2 (b) 已改成「fix-only re-dispatch」描述（替换原 SendMessage 描述），并加了一行说明 SendMessage 不可用。

## iteration 5 最终评分

| eval | 自评 | 修复前主审 | 修复后主审 |
|---|---|---|---|
| eval-0 | perfect | perfect | perfect |
| eval-1 | good | good (6 处漏展开) | **perfect** |

— v5 在缩减测试集上达到 100% perfect。可考虑进入 finalize 流程 —
