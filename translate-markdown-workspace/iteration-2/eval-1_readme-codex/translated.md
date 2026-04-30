# 面向Codex的Superpowers

通过原生技能发现使用OpenAI Codex的Superpowers指南。

## 快速安装

告诉Codex：

```
Fetch and follow instructions from https://raw.githubusercontent.com/obra/superpowers/refs/heads/main/.codex/INSTALL.md
```

## 手动安装

### 前置条件

- OpenAI Codex命令行界面(CLI)
- Git

### 步骤

1. 克隆仓库：
   ```bash
   git clone https://github.com/obra/superpowers.git ~/.codex/superpowers
   ```

2. 创建技能符号链接：
   ```bash
   mkdir -p ~/.agents/skills
   ln -s ~/.codex/superpowers/skills ~/.agents/skills/superpowers
   ```

3. 重启Codex。

4. **对于subagent技能**（可选）：诸如`dispatching-parallel-agents`和`subagent-driven-development`之类的技能需要Codex的多代理功能。添加到您的Codex配置：
   ```toml
   [features]
   multi_agent = true
   ```

### Windows

使用junction而不是symlink（无需开发者模式即可工作）：

```powershell
New-Item -ItemType Directory -Force -Path "$env:USERPROFILE\.agents\skills"
cmd /c mklink /J "$env:USERPROFILE\.agents\skills\superpowers" "$env:USERPROFILE\.codex\superpowers\skills"
```

## 工作原理

Codex具有原生技能发现功能——它在启动时扫描`~/.agents/skills/`，解析SKILL.md frontmatter，并按需加载技能。Superpowers技能通过单个符号链接可见：

```
~/.agents/skills/superpowers/ → ~/.codex/superpowers/skills/
```

`using-superpowers`技能会自动被发现并强制实施技能使用规范——无需额外配置。

## 使用

技能会自动被发现。Codex在以下情况下激活它们：
- 您按名称提及一个技能（例如，"使用brainstorming"）
- 任务与技能的描述匹配
- `using-superpowers`技能指导Codex使用一个

### 个人技能

在`~/.agents/skills/`中创建您自己的技能：

```bash
mkdir -p ~/.agents/skills/my-skill
```

创建`~/.agents/skills/my-skill/SKILL.md`：

```markdown
---
name: my-skill
description: Use when [condition] - [what it does]
---

# My Skill

[Your skill content here]
```

`description`字段是Codex决定何时自动激活技能的方式——将其写成清晰的触发条件。

## 更新

```bash
cd ~/.codex/superpowers && git pull
```

技能通过符号链接即时更新。

## 卸载

```bash
rm ~/.agents/skills/superpowers
```

**Windows (PowerShell):**
```powershell
Remove-Item "$env:USERPROFILE\.agents\skills\superpowers"
```

可选择删除克隆：`rm -rf ~/.codex/superpowers`（Windows：`Remove-Item -Recurse -Force "$env:USERPROFILE\.codex\superpowers"`）。

## 故障排查

### 技能未显示

1. 验证符号链接：`ls -la ~/.agents/skills/superpowers`
2. 检查技能是否存在：`ls ~/.codex/superpowers/skills`
3. 重启Codex——技能在启动时被发现

### Windows junction问题

Junction通常无需特殊权限即可工作。如果创建失败，请尝试以管理员身份运行PowerShell。

## 获取帮助

- 报告问题：https://github.com/obra/superpowers/issues
- 主要文档：https://github.com/obra/superpowers
