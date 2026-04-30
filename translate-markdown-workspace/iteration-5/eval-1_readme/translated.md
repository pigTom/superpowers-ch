# Superpowers

Superpowers 是一个完整的软件开发工作流程，为你的编码代理(agent)而构建，建立在一组可组合的"技能(skill)"和一些初始指令之上，确保你的代理有效使用它们。

## 工作原理

从你启动编码代理的那一刻起就开始了。一旦它看到你正在构建什么，它*不会*只是跳入尝试编写代码。相反，它会退一步，询问你真正想做什么。

一旦它从对话中理解了规范，它就会以足够短的块向你展示，让你能够实际阅读和理解。

在你签署设计后，你的代理会制定一个实现计划，清晰到足以让一个热情的初级工程师能够遵循——即使他品味差、没有判断力、没有项目背景、厌恶测试。它强调真正的红绿测试驱动开发(TDD)、你不会需要它(YAGNI)和不重复自己(DRY)。

接下来，一旦你说"开始"，它就启动一个*子代理驱动开发(subagent-driven-development)*流程，让代理完成每个工程任务，检查和审查他们的工作，并继续前进。Claude 通常能够在不偏离你制定的计划的情况下自主工作数小时。

还有很多其他的功能，但这是系统的核心。而且因为技能(skill)会自动触发，你不需要做任何特殊的事情。你的编码代理就拥有了超级能力。


## 赞助

如果 Superpowers 帮助你做了赚钱的事情，如果你愿意，我非常感谢你考虑[赞助我的开源工作](https://github.com/sponsors/obra)。

谢谢！

- Jesse


## 安装

**注意：** 安装因平台而异。Claude Code 或 Cursor 有内置的插件(plugin)市场(marketplace)。Codex 和 OpenCode 需要手动设置。

### Claude Code 官方市场

Superpowers 可通过[官方 Claude 插件市场](https://claude.com/plugins/superpowers)获取。

从 Claude 市场安装插件：

```bash
/plugin install superpowers@claude-plugins-official
```

### Claude Code（通过插件市场）

在 Claude Code 中，首先注册市场：

```bash
/plugin marketplace add obra/superpowers-marketplace
```

然后从此市场安装插件：

```bash
/plugin install superpowers@superpowers-marketplace
```

### Cursor（通过插件市场）

在 Cursor Agent 聊天中，从市场安装：

```text
/add-plugin superpowers
```

或在插件市场中搜索"superpowers"。

### Codex

告诉 Codex：

```
Fetch and follow instructions from https://raw.githubusercontent.com/obra/superpowers/refs/heads/main/.codex/INSTALL.md
```

**详细文档：** [docs/README.codex.md](docs/README.codex.md)

### OpenCode

告诉 OpenCode：

```
Fetch and follow instructions from https://raw.githubusercontent.com/obra/superpowers/refs/heads/main/.opencode/INSTALL.md
```

**详细文档：** [docs/README.opencode.md](docs/README.opencode.md)

### GitHub Copilot CLI

```bash
copilot plugin marketplace add obra/superpowers-marketplace
copilot plugin install superpowers@superpowers-marketplace
```

### Gemini CLI

```bash
gemini extensions install https://github.com/obra/superpowers
```

更新：

```bash
gemini extensions update superpowers
```

### 验证安装

在你选择的平台中启动新会话，并要求某些应该触发技能(skill)的内容（例如，"帮我规划这个功能"或"让我们调试这个问题"）。代理应该自动调用相关的超级能力技能(skill)。

## 基本工作流程

1. **头脑风暴(brainstorming)** - 在编写代码之前激活。通过问题细化粗略想法，探索替代方案，以部分呈现设计以供验证。保存设计文档。

2. **使用 Git 工作树(using-git-worktrees)** - 在设计批准后激活。在新分支上创建隔离工作区，运行项目设置，验证干净的测试基线。

3. **编写计划(writing-plans)** - 通过批准的设计激活。将工作分解为小任务（每个 2-5 分钟）。每个任务都有确切的文件路径、完整代码、验证步骤。

4. **子代理驱动开发(subagent-driven-development)**或**执行计划(executing-plans)** - 通过计划激活。为每个任务分派新的子代理(subagent)进行两阶段审查（规范合规性，然后代码质量），或分批执行并进行人工检查点。

5. **测试驱动开发(test-driven-development)** - 在实现期间激活。强制执行红绿重构：编写失败的测试，观察其失败，编写最少代码，观察其通过，提交。删除在测试之前编写的代码。

6. **请求代码审查(requesting-code-review)** - 在任务之间激活。根据计划进行审查，按严重程度报告问题。严重问题会阻止进度。

7. **完成开发分支(finishing-a-development-branch)** - 任务完成时激活。验证测试，呈现选项（合并/PR/保留/放弃），清理工作树。

**代理在任何任务之前检查相关技能(skill)。** 强制工作流程，而不是建议。

## 内容

### 技能(skill)库

**测试**
- **test-driven-development** - 红绿重构循环（包括测试反模式参考）

**调试**
- **systematic-debugging** - 4 阶段根本原因过程（包括根本原因追踪、深度防御、基于条件的等待技术）
- **verification-before-completion** - 确保确实已修复

**协作**
- **brainstorming** - 苏格拉底式设计细化
- **writing-plans** - 详细实现计划
- **executing-plans** - 带检查点的批量执行
- **分派并行代理(dispatching-parallel-agents)** - 并发子代理(subagent)工作流程
- **requesting-code-review** - 预审查清单
- **接收代码审查(receiving-code-review)** - 响应反馈
- **using-git-worktrees** - 平行开发分支
- **finishing-a-development-branch** - 合并/PR 决策工作流程
- **subagent-driven-development** - 通过两阶段审查进行快速迭代（规范合规性，然后代码质量）

**元**
- **编写技能(writing-skills)** - 创建遵循最佳实践的新技能(skill)（包括测试方法）
- **使用 Superpowers(using-superpowers)** - 技能(skill)系统简介

## 哲学

- **测试驱动开发(Test-Driven Development)** - 总是先写测试
- **系统性而非临时性(Systematic over ad-hoc)** - 过程而非猜测
- **复杂性简化(Complexity reduction)** - 简单性作为主要目标
- **证据而非声称(Evidence over claims)** - 在宣称成功之前验证

更多阅读：[Superpowers for Claude Code](https://blog.fsck.com/2025/10/09/superpowers/)

## 贡献

技能(skill)直接存在于此仓库中。要贡献：

1. Fork 该仓库
2. 为你的技能(skill)创建一个分支
3. 遵循`writing-skills`技能(skill)以创建和测试新技能(skill)
4. 提交 PR

见`skills/writing-skills/SKILL.md`获取完整指南。

## 更新

当你更新插件时，技能(skill)会自动更新：

```bash
/plugin update superpowers
```

## 许可证

MIT 许可证 - 详见 LICENSE 文件

## 社区

Superpowers 由 [Jesse Vincent](https://blog.fsck.com) 和 [Prime Radiant](https://primeradiant.com) 的其他人构建。

如需社区支持、问题和分享你用 Superpowers 构建的东西，请加入我们的 [Discord](https://discord.gg/Jd8Vphy9jq)。

## 支持

- **Discord**: [加入我们的 Discord](https://discord.gg/Jd8Vphy9jq)
- **Issues**: https://github.com/obra/superpowers/issues
- **Marketplace**: https://github.com/obra/superpowers-marketplace
