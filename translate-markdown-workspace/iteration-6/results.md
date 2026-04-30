# Iteration 6 测试结果（v5 prompt + 又一组全新测试集）

## 测试集（全新，与 iteration 1-5 完全不同）

| ID | 文件 | 行数 | tool 预算 |
|---|---|---|---|
| eval-0 | /Volumes/Dev/superpowers/tests/claude-code/README.md | 158 | 8 |
| eval-1 | /Volumes/Dev/superpowers/tests/subagent-driven-dev/svelte-todo/plan.md | 222 | **12（首次触发第二档）** |

## 性能指标

| eval | 用时 | 工具数 | budget_exhausted |
|---|---|---|---|
| eval-0 | 98 秒 | 6/8 | false |
| eval-1 | 99 秒 | 8/**12** | false |

12-tool budget 档位首次启用，subagent 用了 8/12，余裕充足。两轮都未 hack 文件、未 thrash。

## Subagent 自评 vs 主审实际评

| eval | 自评 | 主审实际 |
|---|---|---|
| eval-0 | perfect | **good**（虚高 1 处，详见下文）|
| eval-1 | good | **good** |

## 主要发现：v5 现存的盲点

### 🔴 eval-0 L3 语义替换错误（v5 自检无法捕捉）

**这是 iter 6 最重要的新发现。**

源（L3）：
```
Automated tests for superpowers skills using Claude Code CLI.
```

译（L3）：
```
使用 Claude Code 命令行界面(CLI)对 superpowers 插件(plugin)进行自动化测试。
```

问题：源说「skills」，译成了「插件(plugin)」。这是**语义替换**——subagent 把不同概念的词强行换了。
- 已 grep 验证：源 L3 没有 `plugin` 这个词；`plugin` 首次出现在源 L12。
- subagent 的「first-use 展开」逻辑把 plugin 提前到了 L3 上，连带把「skills」错译。
- self-check 的 `evidence` 检查的是结构锚点 / 术语一致性 / 缩写顺序——**没有检查 noun/verb 是否在源/译同位置对应**。所以这种错误对自检透明。
- self-check 设计上是结构性的，**对语义准确性天然无能**。

### ⚠️ eval-1 L3 F.2 first-use 漏展开

源（L3）：
```
Execute this plan using the `superpowers:subagent-driven-development` skill.
```

译（L3）：
```
使用 `superpowers:subagent-driven-development` 技能执行此计划。
```

问题：`skill` 首次出现，应为 `技能(skill)`，但只译为 `技能`。
- 这是 iter 5 同一类型的违规（密集列表/单句 prose 中漏首次展开）。

### ⚠️ eval-1 行数 +1（极轻微）

- 源 222 行 / 译 223 行，多 1 个空行
- 列表项数对齐（84/84），仅 blank 数 63→64
- 按 v5 rule A，行数无需精确匹配，但理论上空行应对齐。1 行差异不影响阅读。

## v5 跨 5 轮测试综合表现

| 维度 | iter 5（旧测试集）| iter 6（新测试集）|
|---|---|---|
| 严重违规（block/hack）| 0 | 0 |
| 中度问题 | F.2/F.3 漏首次（6 处）| 语义替换 1 处 + F.2 漏首次 1 处 |
| 工具效率 | 全 ≤ 8/8 | 全 ≤ 8/12 |
| 自评虚高 | 0/2 | **1/2**（eval-0 自评 perfect 但有语义错）|
| 12-tool 档位 | 未触发 | ✅ 首次触发，正常工作 |
| 整体质量 | 修复后 perfect | 修复后接近 perfect |

## v5 设计上的暴露盲点

1. **语义准确性自检缺失**：v5 的 self-check 全是结构性 / 一致性检查，subagent 把 `skills→插件(plugin)` 这种语义错误自评 perfect。本质是结构检查无法触达语义层。
   - 修法 A：在 subagent prompt 加一条「semantic_alignment」自检——逐句确认源主语/宾语/动词在译文同位置对应。但这本质等于「再翻译一遍并比对」，工具预算下不现实。
   - 修法 B：默认信任 Haiku 的自检，由 orchestrator 做语义抽样核查（已在做的 step 4.1 spot-check），用 fix-only re-dispatch 修。这是当前路径，**iter 6 已证明该路径能 catch 并修复**。
   - 推荐：保留现状（修法 B），不增加 prompt 重量。

2. **F.2 首次展开仍偶发漏看**：iter 5 多处、iter 6 一处。subagent 在长列表 / 单句 prose 中容易跳过 first-use rule。
   - 修法：在 subagent prompt 加一个 self-check item「f_2_first_use_audit」要求列出文档里所有 F.2 词的首次出现行号 + 是否带括号。
   - 这是个新 self-check 要求，可在 v6 加。

## 主审建议下一步动作

按 v5 Step 4.2：
- eval-0：action (b) **fix-only re-dispatch** 修 L3 语义错误（1 处）
- eval-1：action (b) **fix-only re-dispatch** 修 L3 漏 first-use + 处理 +1 空行（2 处）

或合并成一次派发，给 fix-only agent 一份 3 处的清单。

— 等用户决定 —
