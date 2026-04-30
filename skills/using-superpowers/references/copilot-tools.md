# Copilot CLI 工具映射

技能(skill)使用 Claude Code 工具名称。当您在技能中遇到这些工具时，请使用您的平台对应的工具：

| 技能引用 | Copilot CLI 对应工具 |
|-----------------|----------------------|
| `Read`（文件读取） | `view` |
| `Write`（文件创建） | `create` |
| `Edit`（文件编辑） | `edit` |
| `Bash`（运行命令） | `bash` |
| `Grep`（搜索文件内容） | `grep` |
| `Glob`（按名称搜索文件） | `glob` |
| `Skill`工具（调用技能） | `skill` |
| `WebFetch` | `web_fetch` |
| `Task`工具（调度子代理） | `task`（见[代理类型](#agent-types)） |
| 多个`Task`调用（并行） | 多个`task`调用 |
| 任务状态/输出 | `read_agent`、`list_agents` |
| `TodoWrite`（任务跟踪） | `sql`与内置`todos`表 |
| `WebSearch` | 无对应工具——使用`web_fetch`配合搜索引擎URL |
| `EnterPlanMode` / `ExitPlanMode` | 无对应工具——保持在主会话中 |

## 代理类型

Copilot CLI 的`task`工具接受`agent_type`参数：

| Claude Code 代理 | Copilot CLI 对应工具 |
|-------------------|----------------------|
| `general-purpose` | `"general-purpose"` |
| `Explore` | `"explore"` |
| 命名插件代理（例如`superpowers:code-reviewer`） | 从已安装插件自动发现 |

## 异步shell会话

Copilot CLI 支持持久化异步shell会话，这些会话在 Claude Code 中没有直接对应：

| 工具 | 用途 |
|------|---------|
| `bash`配合`async: true` | 在后台启动长运行命令 |
| `write_bash` | 向运行中的异步会话发送输入 |
| `read_bash` | 从异步会话读取输出 |
| `stop_bash` | 终止异步会话 |
| `list_bash` | 列出所有活跃shell会话 |

## 其他 Copilot CLI 工具

| 工具 | 用途 |
|------|---------|
| `store_memory` | 为将来的会话持久化有关代码库的事实 |
| `report_intent` | 使用当前意图更新UI状态行 |
| `sql` | 查询会话的SQLite数据库（todos、metadata） |
| `fetch_copilot_cli_documentation` | 查找 Copilot CLI 文档 |
| GitHub MCP 工具（`github-mcp-server-*`） | 原生GitHub API 访问（问题、PR、代码搜索） |
