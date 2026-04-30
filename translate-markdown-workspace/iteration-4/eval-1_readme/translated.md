# Superpowers

Superpowers是为编码agent打造的完整软件开发工作流，基于一系列可组合的"skills"和一些初始指令构建，确保你的agent能够使用它们。

## How it works

从启动编码agent的那一刻开始。当它发现你在构建某些东西时，它*不会*直接跳入代码编写。相反，它会退一步，问你真正想做什么。

一旦它从对话中梳理出规格说明，它会分块展示给你，每块都短到足以让你真正阅读和理解。

在你批准设计后，你的agent会整理出一份实施计划，清晰到一个热情的初级工程师（品味差、没有判断力、缺乏项目背景、厌恶测试）都能遵循。它强调真正的红/绿TDD(测试驱动开发)、YAGNI(你不会需要它)和DRY(不重复自己)。

接下来，一旦你说"开始"，它就启动一个*subagent驱动开发*过程，让agents逐个完成每项工程任务，检查和审查他们的工作，然后继续向前推进。Claude能够自主工作几个小时而不偏离你制定的计划并不罕见。

还有很多其他的东西，但这是系统的核心。由于skills会自动触发，你不需要做任何特殊的事情。你的编码agent已经拥有Superpowers。


## 赞助

如果Superpowers帮助你赚到了钱，而你也愿意的话，我会非常感激如果你能考虑[赞助我的开源工作](https://github.com/sponsors/obra)。

谢谢！

- Jesse


## Installation

**Note:** 安装因平台而异。Claude Code或Cursor有内置的plugin marketplace。Codex和OpenCode需要手动设置。

### Claude Code Official Marketplace

Superpowers可通过[官方Claude plugin marketplace](https://claude.com/plugins/superpowers)获得

从Claude marketplace安装plugin：

```bash
/plugin install superpowers@claude-plugins-official
```

### Claude Code (via Plugin Marketplace)

在Claude Code中，首先注册marketplace：

```bash
/plugin marketplace add obra/superpowers-marketplace
```

然后从此marketplace安装plugin：

```bash
/plugin install superpowers@superpowers-marketplace
```

### Cursor (via Plugin Marketplace)

在Cursor Agent chat中，从marketplace安装：

```text
/add-plugin superpowers
```

或在plugin marketplace中搜索"superpowers"。

### Codex

告诉Codex：

```
Fetch and follow instructions from https://raw.githubusercontent.com/obra/superpowers/refs/heads/main/.codex/INSTALL.md
```

**详细文档：** [docs/README.codex.md](docs/README.codex.md)

### OpenCode

告诉OpenCode：

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

在你选择的平台中启动新session，并请求应该触发skill的内容（例如，"帮我规划这个feature"或"让我们调试这个问题"）。agent应该自动调用相关的superpowers skill。

## The Basic Workflow

1. **brainstorming** - 在编写代码前激活。通过问题精化粗略想法，探索替代方案，以部分形式呈现设计进行验证。保存设计文档。

2. **using-git-worktrees** - 设计批准后激活。在新branch上创建隔离工作区，运行项目设置，验证干净的测试基线。

3. **writing-plans** - 与批准的设计一起激活。将工作分解成易于管理的任务（每个2-5分钟）。每项任务都有精确的文件路径、完整代码、验证步骤。

4. **subagent-driven-development**或**executing-plans** - 与计划激活。每个任务分派新的subagent进行两阶段审查（规格符合性，然后代码质量），或以batch方式执行并进行人工检查点。

5. **test-driven-development** - 在实施过程中激活。强制实行红/绿/重构：编写失败测试、看它失败、编写最少代码、看它通过、提交。删除在测试前编写的代码。

6. **requesting-code-review** - 在任务之间激活。根据计划审查，按严重程度报告问题。关键问题会阻止进度。

7. **finishing-a-development-branch** - 任务完成时激活。验证测试，呈现选项（merge/PR/保留/丢弃），清理worktree。

**agent在任何任务前检查相关skills。** 强制性工作流，不是建议。

## What's Inside

### Skills Library

**Testing**
- **test-driven-development** - 红/绿/重构循环(包括测试反模式参考)

**Debugging**
- **systematic-debugging** - 4阶段根因分析过程(包括根因追踪、纵深防御、基于条件的等待技术)
- **verification-before-completion** - 确保它真的被修复了

**Collaboration** 
- **brainstorming** - 苏格拉底式设计精化
- **writing-plans** - 详细实施计划
- **executing-plans** - 带检查点的batch执行
- **dispatching-parallel-agents** - 并发subagent工作流
- **requesting-code-review** - 预审清单
- **receiving-code-review** - 对反馈的响应
- **using-git-worktrees** - 平行开发branches
- **finishing-a-development-branch** - merge/PR决策工作流
- **subagent-driven-development** - 快速迭代，具有两阶段审查(规格符合性，然后代码质量)

**Meta**
- **writing-skills** - 按照最佳实践创建新skills(包括测试方法论)
- **using-superpowers** - skills系统介绍

## Philosophy

- **Test-Driven Development** - 始终先编写测试
- **系统化优于临时性** - 流程优于猜测
- **复杂性简化** - 简洁作为首要目标
- **证据优于声明** - 验证后再宣布成功

阅读更多：[Superpowers for Claude Code](https://blog.fsck.com/2025/10/09/superpowers/)

## Contributing

Skills直接存在于此repository。要贡献：

1. Fork该repository
2. 为你的skill创建一个branch
3. 按照`writing-skills` skill来创建和测试新skills
4. 提交PR

更多信息请见`skills/writing-skills/SKILL.md`。

## Updating

当你更新plugin时，Skills会自动更新：

```bash
/plugin update superpowers
```

## License

MIT License - 详见LICENSE文件

## Community

Superpowers由[Jesse Vincent](https://blog.fsck.com)和[Prime Radiant](https://primeradiant.com)的其他人构建。

如需社区支持、提问和分享你用Superpowers构建的东西，请加入我们的[Discord](https://discord.gg/Jd8Vphy9jq)。

## Support

- **Discord**: [加入我们的Discord](https://discord.gg/Jd8Vphy9jq)
- **Issues**: https://github.com/obra/superpowers/issues
- **Marketplace**: https://github.com/obra/superpowers-marketplace
