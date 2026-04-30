# Iteration 3 测试结果（v3 prompt）

## Subagent 自评 vs 实际质量

| eval | v3 自评 | 主审实际评 |
|---|---|---|
| eval-0 | perfect | **perfect** |
| eval-1 | perfect | **good**（symlink 译为符号链接，违反规则 F，但一致）|
| eval-2 | perfect | **perfect** |

→ 自评准确率显著提高，3 个里只有 1 个虚高（v2 是 3 个全部虚高）。证据机制起到部分约束作用。

## v3 关键修复（vs v2）

### 1. eval-2 第 11-18 行无 tag 目录树块 → ✅ 完美保留

```
源 / 译（byte-for-byte 一致）：
tests/
├── claude-code/
│   ├── test-helpers.sh                    # Shared test utilities
│   ├── test-subagent-driven-development-integration.sh
│   ├── analyze-token-usage.py             # Token analysis tool
│   └── run-skill-tests.sh                 # Test runner (if exists)
```

v3 加的反例示例真起到效果——subagent 这次没把 `# Shared test utilities` 误当成可译注释。

### 2. eval-1 第 77-86 行 markdown 块 → ✅ 完全按 spec

```
源：description: Use when [condition] - [what it does]
译：description: Use when [条件] - [做什么]

源：[Your skill content here]
译：[在此填入你的技能内容]

源：name: my-skill            （字段名+标识）
译：name: my-skill            （保留）

源：# My Skill
译：# My Skill                （专名保留）
```

placeholders 译，字段名保留。v3 加的正反例示例起到效果。

### 3. self-check 证据机制 → ✅ 部分有效

subagent 现在给出真实的源/译行号对比，可以核对。例如 eval-1 报告中：
- `markdown_block`: 引用了 line 80 的具体源/译
- `proper_noun_consistency`: 列举了 Codex 出现的所有行号

但仍有一处虚高（eval-1 把 symlink 译了又自评 perfect）——证据机制能约束「block 完整性」类违规，但还不能阻止「术语选择」类违规自评 perfect。

## v3 仍存在的问题

### eval-1 symlink/junction 处理

subagent 把 `symlink` 一致译为「符号链接」、`junction` 译为「连接」。CONS：
- ❌ 违反规则 F：`junction`、`symlink` 应保留英文。
- ✅ 至少在文档内一致（4 个 symlink 都译为符号链接）。

subagent 在自己证据里坦率写出了译法 (`successfully rendered as 符号链接 and 连接`)，但仍自评 perfect——说明它没意识到规则 F 包含这两个词。

### eval-2 evidence 部分错位

subagent 把 line 27 标为 `code_block_comment`（line 27 在 bash 块里 `# Run the subagent-driven-development integration test`）然后说 `unchanged_as_required`——其实 case 1 允许翻译注释，但它选择不翻译。这点不算违规，但说明 subagent 对规则的理解还有保守倾向（多用「保留」而少用「翻译」）。

## 综合对比 v1 / v2 / v3

| 缺陷类别 | v1 | v2 | v3 |
|---|---|---|---|
| 词汇冲突（scalability/extensibility） | ❌ | ✅ | ✅ |
| nice-to-have 生硬 | ❌ | ✅ | ✅ |
| `<example>/<commentary>` tags | ✅ | ✅ | ✅ |
| 结构标签 `Context:/user:/assistant:` | ❌ | ✅ | ✅ |
| `subagent`/`agent` 一致 | ❌ | ✅ | ✅ |
| URL 无 tag 块（README.codex 9-11）| ❌ | ✅ | ✅ |
| 测试输出无 tag 块（testing 68-135）| ❌ | ✅ | ✅ |
| 目录树无 tag 块注释（testing 11-18）| ❌ | ❌ | ✅ |
| markdown 块 placeholders（README 77-86）| ❌ | ❌ | ✅ |
| symlink/junction 一致性 | n/a | ❌ 不一致 | ⚠️ 一致但译了 |
| 自评 vs 实际匹配 | 偏松 | 全 perfect 虚高 | 1/3 虚高 |

## v4 候选改进

如果用户想继续逼近 100%：
1. 在规则 F 里把 `junction` 和 `symlink` 单独**加粗**点名，避免被忽略；并加一句「即使你已知中文译法，也**坚持**用英文」。
2. self-check 加一项 `forbidden_translation_check`：subagent 在证据里**主动列出**它检查过的所有专名（subagent / hook / skill / symlink / junction…），逐个标记「保留英文 ✓」。这样它会被迫去看每一个。
3. 让 self_rating 升级条件：只有当所有 evidence 项 + 所有 forbidden_translation_check 项都 ok 才能 perfect；只要有 1 个非「ok」就最少 good。

但目前 v3 的整体质量已经很高，可能用户会觉得够用。

— 等用户决定 —
