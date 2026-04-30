# Gemini 命令行工具映射

技能(skill)使用 Claude Code 工具名。当您在技能中遇到这些工具时，请使用您所在平台的等价工具：

| 技能(skill)引用 | Gemini 命令行等价工具 |
|-----------------|----------------------|
| `Read`（文件读取） | `read_file` |
| `Write`（文件创建） | `write_file` |
| `Edit`（文件编辑） | `replace` |
| `Bash`（运行命令） | `run_shell_command` |
| `Grep`（搜索文件内容） | `grep_search` |
| `Glob`（按名称搜索文件） | `glob` |
| `TodoWrite`（任务跟踪） | `write_todos` |
| `Skill` 工具（调用技能(skill)） | `activate_skill` |
| `WebSearch` | `google_web_search` |
| `WebFetch` | `web_fetch` |
| `Task` 工具（分发子代理(subagent)） | 无等价工具 — Gemini 命令行不支持子代理(subagent) |

## 无子代理(subagent)支持

Gemini 命令行没有与 Claude Code 的 `Task` 工具等价的工具。依赖于子代理(subagent)分发的技能(skill)（`subagent-driven-development`、`dispatching-parallel-agents`）将通过 `executing-plans` 回退到单会话(session)执行。

## 其他 Gemini 命令行工具

这些工具在 Gemini 命令行中可用，但在 Claude Code 中没有等价工具：

| 工具 | 用途 |
|------|---------|
| `list_directory` | 列出文件和子目录 |
| `save_memory` | 在会话(session)间将事实持久化到 GEMINI.md |
| `ask_user` | 从用户请求结构化输入 |
| `tracker_create_task` | 丰富的任务管理（创建、更新、列出、可视化） |
| `enter_plan_mode` / `exit_plan_mode` | 在做出更改前切换到只读研究模式 |
