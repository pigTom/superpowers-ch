# Codex 工具映射

技能使用 Claude Code 工具名称。当你在技能中遇到这些名称时，使用你的平台等价物：

| 技能引用 | Codex 等价物 |
|-----------------|------------------|
| `Task` 工具（派遣子代理(subagent)） | `spawn_agent`（参见[命名代理(agent)派遣](#named-agent-dispatch)） |
| 多个 `Task` 调用（并行） | 多个 `spawn_agent` 调用 |
| Task 返回结果 | `wait` |
| Task 自动完成 | `close_agent` 释放槽位 |
| `TodoWrite`（任务追踪） | `update_plan` |
| `Skill` 工具（调用技能(skill)） | 技能(skill)本地加载 — 只需遵循说明 |
| `Read`、`Write`、`Edit`（文件） | 使用你的原生文件工具 |
| `Bash`（运行命令） | 使用你的原生 shell 工具 |

## 子代理派遣需要多代理支持

添加到你的 Codex 配置（`~/.codex/config.toml`）：

```toml
[features]
multi_agent = true
```

这启用了 `spawn_agent`、`wait` 和 `close_agent`，用于 `dispatching-parallel-agents` 和 `subagent-driven-development` 等技能。

## 命名代理派遣

Claude Code 技能引用命名代理(agent)类型，如 `superpowers:code-reviewer`。Codex 没有命名代理(agent)注册表 — `spawn_agent` 从内置角色（`default`、`explorer`、`worker`）创建通用代理(agent)。

当技能说要派遣一个命名代理(agent)类型时：

1. 找到代理(agent)的提示文件（例如 `agents/code-reviewer.md` 或技能的本地提示模板，如 `code-quality-reviewer-prompt.md`）
2. 读取提示内容
3. 填充任何模板占位符（`{BASE_SHA}`、`{WHAT_WAS_IMPLEMENTED}` 等）
4. 使用填充后的内容作为 `message` 参数派遣一个 `worker` 代理(agent)

| 技能说明 | Codex 等价物 |
|-------------------|------------------|
| `Task` 工具（`superpowers:code-reviewer`） | `spawn_agent(agent_type="worker", message=...)` 包含 `code-reviewer.md` 内容 |
| `Task` 工具（通用目的）包含内联提示 | `spawn_agent(message=...)` 包含相同的提示 |

### 消息框架

`message` 参数是用户级别的输入，不是系统提示。结构化它以获得最大指令遵循：

```
Your task is to perform the following. Follow the instructions below exactly.

<agent-instructions>
[filled prompt content from the agent's .md file]
</agent-instructions>

Execute this now. Output ONLY the structured response following the format
specified in the instructions above.
```

- 使用任务委派框架（"Your task is..."）而不是角色框架（"You are..."）
- 用 XML 标签包裹说明 — 模型将标签块视为权威
- 以明确的执行指令结束，防止说明摘要

### 何时可以移除此解决方案

此方法补偿了 Codex 的插件系统尚不支持 `plugin.json` 中的 `agents` 字段。当 `RawPluginManifest` 获得 `agents` 字段时，插件可以符号链接(symlink)到 `agents/`（镜像现有的 `skills/` 符号链接(symlink)），技能可以直接派遣命名代理(agent)类型。

## 环境检测

创建工作树(worktree)或完成分支的技能应在继续前用只读 git 命令检测它们的环境：

```bash
GIT_DIR=$(cd "$(git rev-parse --git-dir)" 2>/dev/null && pwd -P)
GIT_COMMON=$(cd "$(git rev-parse --git-common-dir)" 2>/dev/null && pwd -P)
BRANCH=$(git branch --show-current)
```

- `GIT_DIR != GIT_COMMON` → 已在链接的工作树(worktree)中（跳过创建）
- `BRANCH` 为空 → 分离的 HEAD（无法从沙箱分支/推送/PR）

参见 `using-git-worktrees` 第 0 步和 `finishing-a-development-branch` 第 1 步，了解每个技能如何使用这些信号。

## Codex 应用完成

当沙箱阻止分支/推送操作（在外部管理的工作树(worktree)中的分离 HEAD）时，代理(agent)提交所有工作并通知用户使用应用的原生控制：

- **"创建分支"** — 命名分支，然后通过应用 UI 提交/推送/PR
- **"移交给本地"** — 将工作转移到用户的本地检出

代理(agent)仍然可以运行测试、暂存文件以及输出建议的分支名、提交消息和 PR 描述供用户复制。
