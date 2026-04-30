# Iteration 2 测试结果（v2 prompt）

## 测试集
与 iteration-1 完全相同的 3 个文件。

## Subagent 自评（vs iteration 1）

| eval | v1 自评 | v2 自评 |
|---|---|---|
| eval-0 | good | **perfect** |
| eval-1 | good | **perfect** |
| eval-2 | good | **perfect** |

3 篇全 perfect —— 按用户判定法这是「skill 执行效果不好」的危险信号：subagent 没有真正捕捉自己的违规。需要主审复查。

## 主审复查：v2 vs v1 对比

### eval-0 code-reviewer.md

| 问题 | v1 | v2 |
|---|---|---|
| `scalability and extensibility` 同一词 | ❌ 重复成「可扩展性」 | ✅ 「可伸缩性和可扩展性」 |
| `nice to have` | ❌ 「很好有」 | ✅ 「锦上添花」 |
| XML tags `<example>/<commentary>` | ✅ 保留 | ✅ 保留 |
| `Context:` / `user:` / `assistant:` 标签 | ❌ 译为「背景：/用户：/助手：」 | ✅ 保留英文 |
| `agent` 一致性 | ⚠️ 时英时中 | ✅ 保留英文 |
| `Critical/Important/Suggestions` | 译为中文 | 保留英文 + 中文括注（合理判断点）|

→ eval-0 **没有发现真错误**，自评 perfect 与实际质量基本一致。

### eval-1 README.codex.md

| 问题 | v1 | v2 |
|---|---|---|
| 第 9-11 行无 tag 块（URL 指令）| ❌ 未翻译，违反 v1 规则 | ✅ 保留原文（v2 规则改为 verbatim）|
| 第 77-86 行 ```` ```markdown ```` 块 | ❌ 整块未翻译 | ⚠️ 仍整块未翻译，包括 `[Your skill content here]` 这类应译的占位符 |
| `subagent skills` | ❌ 「子代理技能」 | ✅ 「subagent技能」 |
| `junction` | ⚠️ 译为「交接点」 | ✅ 保留英文 |
| `symlink` | 译为「符号链接」 | ⚠️ **不一致**：第 27、52、115 行「符号链接」，第 43 行「symlink」 |
| 标题 `# Superpowers for Codex` | ⚠️ 完全英文 | ✅ 「面向 Codex 的 Superpowers」|

→ eval-1 真错误：
- ❌ markdown 块内 `[Your skill content here]` 等占位符应译未译。规则说「markdown 块递归翻译，不确定时保留原文」——subagent 把整块当作"代码模板"全保留，理解偏差。
- ⚠️ symlink 中英不一致。

### eval-2 testing.md

| 问题 | v1 | v2 |
|---|---|---|
| 测试输出无 tag 块（68-135）| ⚠️ 部分翻译，混乱 | ✅ 全部保留原文 |
| **目录树无 tag 块（11-18）** | ❌ 注释翻译 | ❌ **仍翻译**了块内 `# Shared test utilities` → `# 共享测试工具` 等 |
| `subagent` / `subagents` | ❌ 「子代理」 | ✅ 保留英文 |
| `TodoWrite` | ✅ 保留 | ✅ 保留 |
| `JSONL` | ✅ 保留 | ✅ 保留 |

→ eval-2 真错误：第 11-18 行无 tag 代码块的 `#` 注释被翻译，违反 v2 「无 tag 块 verbatim」规则。

## 客观评估（实际应得评分）

| eval | subagent 自评 | 主审实际评 |
|---|---|---|
| eval-0 | perfect | **perfect**（与自评一致）|
| eval-1 | perfect | **good**（markdown 占位符未译 + symlink 不一致）|
| eval-2 | perfect | **done with warning**（无 tag 块违规）|

→ 自评偏宽（虚高）。v2 加的 self-check checklist 没起到把关作用。

## 根因分析（v2 → v3 改进）

1. **prompt 问题**：
   - **关键漏洞**：subagent 看到「无 tag 块」里有 `# 注释` 时，把它当成「代码注释」（按 case 1 翻译）而不是「无 tag 块的字面内容」（按 case 3/4 verbatim）。需要在 case 3/4 加显式反例。
   - **markdown 块的「prose vs literal」边界**：`[Your skill content here]` 这种方括号占位符是 prose，应该译；`name: my-skill` 这种字段名是 literal，应保留。需要更具体的例子。
   - **self-check 形同虚设**：subagent 只是打勾确认，没真去 diff。要改成「贴出可疑行的源文 vs 译文」要求。

2. **模型能力问题**：
   - 不是。所有真错误都源于 prompt 表述不够具体。Haiku 完全有能力执行更精准的规则。

## v3 修订方向

1. 在 case 3 / case 4（无 tag / text-tag 块）加一条**反例示例**：明示「即使你看到 `# comment` 也不要翻译，因为这是块外部的判断，不是块内规则」。
2. 在 case 2（markdown 块）加示例：`[占位文字]` 形式应译，`name: x` 形式保留。
3. self-check 改造：把每条 check 的「✓」改成强制要求「贴 1 行源 vs 1 行译」（差异/相同两种情况都要明示），避免 subagent 自欺。
4. 把 self_rating 改成「评分前必须填上述对比快照」，倒逼真做检查。

— 等用户确认后进入 iteration 3 —
