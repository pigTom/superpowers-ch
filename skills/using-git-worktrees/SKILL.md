---
name: using-git-worktrees
description: 在需要与当前工作区隔离的特性工作或执行实施计划前使用 - 创建具有智能目录选择和安全验证的隔离 git 工作树
---

# 使用 Git 工作树

## 概述

Git 工作树创建共享同一版本库的隔离工作区，允许同时在多个分支上工作而无需切换。

**核心原则：** 系统化目录选择 + 安全验证 = 可靠隔离。

**在开始时声明：** "我正在使用 using-git-worktrees 技能(skill)来设置隔离工作区。"

## 目录选择过程

按照此优先级顺序：

### 1. 检查现有目录

```bash
# 按优先级顺序检查
ls -d .worktrees 2>/dev/null     # 首选（隐藏）
ls -d worktrees 2>/dev/null      # 备选
```

**如果找到：** 使用该目录。如果两者都存在，`.worktrees` 优先。

### 2. 检查 CLAUDE.md

```bash
grep -i "worktree.*director" CLAUDE.md 2>/dev/null
```

**如果指定了偏好：** 直接使用，无需询问。

### 3. 询问用户

如果不存在任何目录且 CLAUDE.md 中无偏好设置：

```
未找到工作树目录。我应该在哪里创建工作树？

1. .worktrees/（项目本地，隐藏）
2. ~/.config/superpowers/worktrees/<项目名>/（全局位置）

你更喜欢哪一个？
```

## 安全验证

### 对于项目本地目录（.worktrees 或 worktrees）

**必须验证目录被忽略后再创建工作树：**

```bash
# 检查目录是否被忽略（尊重本地、全局和系统 gitignore）
git check-ignore -q .worktrees 2>/dev/null || git check-ignore -q worktrees 2>/dev/null
```

**如果未被忽略：**

按照 Jesse 的规则"立即修复损坏的东西"：
1. 在 .gitignore 中添加适当的行
2. 提交更改
3. 继续创建工作树

**为什么关键：** 防止意外提交工作树内容到版本库。

### 对于全局目录（~/.config/superpowers/worktrees）

无需进行 .gitignore 验证 - 完全位于项目外部。

## 创建步骤

### 1. 检测项目名称

```bash
project=$(basename "$(git rev-parse --show-toplevel)")
```

### 2. 创建工作树

```bash
# 确定完整路径
case $LOCATION in
  .worktrees|worktrees)
    path="$LOCATION/$BRANCH_NAME"
    ;;
  ~/.config/superpowers/worktrees/*)
    path="~/.config/superpowers/worktrees/$project/$BRANCH_NAME"
    ;;
esac

# 创建带新分支的工作树
git worktree add "$path" -b "$BRANCH_NAME"
cd "$path"
```

### 3. 运行项目设置

自动检测并运行合适的设置：

```bash
# Node.js
if [ -f package.json ]; then npm install; fi

# Rust
if [ -f Cargo.toml ]; then cargo build; fi

# Python
if [ -f requirements.txt ]; then pip install -r requirements.txt; fi
if [ -f pyproject.toml ]; then poetry install; fi

# Go
if [ -f go.mod ]; then go mod download; fi
```

### 4. 验证清洁基线

运行测试以确保工作树从干净状态开始：

```bash
# 示例 - 使用项目适用的命令
npm test
cargo test
pytest
go test ./...
```

**如果测试失败：** 报告失败，询问是否继续或调查。

**如果测试通过：** 报告准备就绪。

### 5. 报告位置

```
工作树已就绪，位置为 <完整路径>
测试通过（<N> 个测试，0 个失败）
准备实施 <特性名>
```

## 快速参考

| 情形 | 操作 |
|-----------|--------|
| `.worktrees/` 存在 | 使用它（验证忽略） |
| `worktrees/` 存在 | 使用它（验证忽略） |
| 两者都存在 | 使用 `.worktrees/` |
| 都不存在 | 检查 CLAUDE.md → 询问用户 |
| 目录未被忽略 | 添加到 .gitignore + 提交 |
| 基线期间测试失败 | 报告失败 + 询问 |
| 没有 package.json/Cargo.toml | 跳过依赖项安装 |

## 常见错误

### 跳过忽略验证

- **问题：** 工作树内容被跟踪，污染 git 状态
- **修复：** 在创建项目本地工作树前始终使用 `git check-ignore`

### 假设目录位置

- **问题：** 产生不一致，违反项目约定
- **修复：** 按优先级跟随：现有目录 > CLAUDE.md > 询问

### 继续进行失败的测试

- **问题：** 无法区分新的错误和现有问题
- **修复：** 报告失败，获取明确的继续许可

### 硬编码设置命令

- **问题：** 在使用不同工具的项目上失效
- **修复：** 从项目文件自动检测（package.json 等）

## 示例工作流

```
你：我正在使用 using-git-worktrees 技能来设置隔离工作区。

[检查 .worktrees/ - 存在]
[验证忽略 - git check-ignore 确认 .worktrees/ 被忽略]
[创建工作树：git worktree add .worktrees/auth -b feature/auth]
[运行 npm install]
[运行 npm test - 47 个通过]

工作树已就绪，位置为 /Users/jesse/myproject/.worktrees/auth
测试通过（47 个测试，0 个失败）
准备实施身份验证特性
```

## 危险信号

**永远不要：**
- 在未验证其被忽略的情况下创建工作树（项目本地）
- 跳过基线测试验证
- 在未询问的情况下继续进行失败的测试
- 在有歧义时假设目录位置
- 跳过 CLAUDE.md 检查

**总是：**
- 按优先级跟随：现有目录 > CLAUDE.md > 询问
- 验证项目本地目录被忽略
- 自动检测并运行项目设置
- 验证清洁测试基线

## 集成

**被调用者：**
- **brainstorming（第 4 阶段）** - 当设计被批准且实施跟随时必需
- **subagent-driven-development** - 在执行任何任务前必需
- **executing-plans** - 在执行任何任务前必需
- 任何需要隔离工作区的技能

**配对于：**
- **finishing-a-development-branch** - 工作完成后清理必需
