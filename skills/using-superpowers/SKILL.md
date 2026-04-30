---
name: using-superpowers
description: 在任何对话开始时使用 - 建立如何找到和使用技能的方法，需要在任何响应之前（包括澄清问题）调用Skill工具
---

<SUBAGENT-STOP>
如果你是作为子代理(subagent)被派遣执行特定任务，请跳过这个技能(skill)。
</SUBAGENT-STOP>

<EXTREMELY-IMPORTANT>
如果你认为有哪怕1%的可能性某个技能可能适用于你正在做的事情，你绝对必须调用这个技能。

如果某个技能适用于你的任务，你没有选择的余地。你必须使用它。

这是不可商量的。这不是可选的。你不能为自己开脱。
</EXTREMELY-IMPORTANT>

## 指令优先级

Superpowers技能覆盖默认系统提示行为，但**用户指令始终优先**：

1. **用户明确的指令** (CLAUDE.md、GEMINI.md、AGENTS.md、直接请求) — 最高优先级
2. **Superpowers技能** — 在冲突时覆盖默认系统行为
3. **默认系统提示** — 最低优先级

如果CLAUDE.md、GEMINI.md或AGENTS.md说"不要使用TDD"，而技能说"总是使用TDD"，请遵循用户的指令。用户在掌控。

## 如何访问技能

**在Claude Code中：** 使用`Skill`工具。当你调用一个技能时，其内容会被加载并呈现给你 — 直接遵循它。永远不要在技能文件上使用Read工具。

**在Copilot CLI中：** 使用`skill`工具。技能从已安装的插件中自动发现。`skill`工具的工作方式与Claude Code的`Skill`工具相同。

**在Gemini CLI中：** 技能通过`activate_skill`工具激活。Gemini在会话开始时加载技能元数据，并按需激活完整内容。

**在其他环境中：** 查看你的平台文档了解技能如何加载。

## 平台适配

技能使用Claude Code工具名称。非CC平台：查看`references/copilot-tools.md` (Copilot CLI)、`references/codex-tools.md` (Codex) 了解工具等价物。Gemini CLI用户通过GEMINI.md自动获得工具映射。

# 使用技能

## 规则

**在任何响应或行动之前调用相关或被请求的技能。** 即使有1%的可能性某个技能可能适用，你也应该调用该技能来检查。如果一个被调用的技能对这种情况来说是错误的，你不需要使用它。

```dot
digraph skill_flow {
    "User message received" [shape=doublecircle];
    "About to EnterPlanMode?" [shape=doublecircle];
    "Already brainstormed?" [shape=diamond];
    "Invoke brainstorming skill" [shape=box];
    "Might any skill apply?" [shape=diamond];
    "Invoke Skill tool" [shape=box];
    "Announce: 'Using [skill] to [purpose]'" [shape=box];
    "Has checklist?" [shape=diamond];
    "Create TodoWrite todo per item" [shape=box];
    "Follow skill exactly" [shape=box];
    "Respond (including clarifications)" [shape=doublecircle];

    "About to EnterPlanMode?" -> "Already brainstormed?";
    "Already brainstormed?" -> "Invoke brainstorming skill" [label="no"];
    "Already brainstormed?" -> "Might any skill apply?" [label="yes"];
    "Invoke brainstorming skill" -> "Might any skill apply?";

    "User message received" -> "Might any skill apply?";
    "Might any skill apply?" -> "Invoke Skill tool" [label="yes, even 1%"];
    "Might any skill apply?" -> "Respond (including clarifications)" [label="definitely not"];
    "Invoke Skill tool" -> "Announce: 'Using [skill] to [purpose]'";
    "Announce: 'Using [skill] to [purpose]'" -> "Has checklist?";
    "Has checklist?" -> "Create TodoWrite todo per item" [label="yes"];
    "Has checklist?" -> "Follow skill exactly" [label="no"];
    "Create TodoWrite todo per item" -> "Follow skill exactly";
}
```

## 危险信号

这些想法意味着停止 — 你在合理化：

| 想法 | 现实 |
|---------|---------|
| "这只是一个简单问题" | 问题就是任务。检查技能。 |
| "我需要先获得更多背景信息" | 技能检查在澄清问题之前进行。 |
| "让我先浏览代码库" | 技能告诉你如何浏览。先检查。 |
| "我可以快速检查git/文件" | 文件缺乏对话背景。检查技能。 |
| "让我先收集信息" | 技能告诉你如何收集信息。 |
| "这不需要正式的技能" | 如果技能存在，就使用它。 |
| "我记得这个技能" | 技能会演变。阅读当前版本。 |
| "这不算是一个任务" | 行动=任务。检查技能。 |
| "这个技能太过度了" | 简单的事情会变得复杂。使用它。 |
| "我先做一件事" | 在做任何事之前检查。 |
| "这感觉很有成效" | 无纪律的行动浪费时间。技能防止这种情况。 |
| "我知道那是什么意思" | 知道概念≠使用技能。调用它。 |

## 技能优先级

当多个技能可能适用时，使用这个顺序：

1. **优先进行流程技能** (头脑风暴、调试) - 这些决定了你如何处理任务
2. **其次进行实施技能** (前端设计、mcp-builder) - 这些指导执行

"让我们构建X" → 先进行头脑风暴，然后是实施技能。
"修复这个bug" → 先调试，然后是特定领域的技能。

## 技能类型

**严格的** (TDD、调试)：完全遵循。不要让开走纪律。

**灵活的** (模式)：根据背景调整原则。

技能本身会告诉你是哪一种。

## 用户指令

指令说的是做什么，不是如何做。"添加X"或"修复Y"不意味着跳过工作流。
