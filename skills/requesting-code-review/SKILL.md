---
name: requesting-code-review
description: 在完成任务、实现主要功能或合并前使用，验证工作成果满足需求
---

# 请求代码审查

分派 superpowers:code-reviewer 子代理(subagent)来在问题扩散之前捕获它们。审查者获得经过精心设计的上下文进行评估——绝不是你的会话(session)历史。这能使审查者专注于工作成果，而不是你的思考过程，并为你继续工作保留自己的上下文。

**核心原则：** 及早审查，频繁审查。

## 何时请求审查

**强制：**
- 在子代理驱动开发(subagent-driven-development)中的每个任务后
- 完成主要功能后
- 合并到主分支前

**可选但有价值：**
- 遇到困难时（获得新视角）
- 重构前（基准检查）
- 修复复杂漏洞后

## 如何请求

**1. 获取 git SHA：**
```bash
BASE_SHA=$(git rev-parse HEAD~1)  # or origin/main
HEAD_SHA=$(git rev-parse HEAD)
```

**2. 分派 code-reviewer 子代理(subagent)：**

使用任务(Task)工具，指定类型为 superpowers:code-reviewer，填充位于 `code-reviewer.md` 的模板

**占位符：**
- `{WHAT_WAS_IMPLEMENTED}` - 你刚刚构建的内容
- `{PLAN_OR_REQUIREMENTS}` - 它应该做什么
- `{BASE_SHA}` - 起始提交
- `{HEAD_SHA}` - 结束提交
- `{DESCRIPTION}` - 简要摘要

**3. 针对反馈采取行动：**
- 立即修复关键(Critical)问题
- 在继续前修复重要(Important)问题
- 记录次要(Minor)问题供后续处理
- 如果审查者错误，推回（附带理由）

## 示例

```
[刚完成任务 2：添加验证函数]

你：让我在继续前请求代码审查。

BASE_SHA=$(git log --oneline | grep "Task 1" | head -1 | awk '{print $1}')
HEAD_SHA=$(git rev-parse HEAD)

[分派 superpowers:code-reviewer 子代理(subagent)]
  WHAT_WAS_IMPLEMENTED: 对话索引的验证和修复函数
  PLAN_OR_REQUIREMENTS: 来自 docs/superpowers/plans/deployment-plan.md 的任务 2
  BASE_SHA: a7981ec
  HEAD_SHA: 3df7661
  DESCRIPTION: 添加了 verifyIndex() 和 repairIndex()，包含 4 种问题类型

[子代理(subagent)返回]：
  优势：清洁架构，真实测试
  问题：
    重要：缺少进度指示符
    次要：魔数（100）用于报告间隔
  评估：可以继续

你：[修复进度指示符]
[继续任务 3]
```

## 与工作流的集成

**子代理驱动开发(Subagent-Driven Development)：**
- 在每个任务后审查
- 在问题复合之前捕获它们
- 在移动到下一个任务前修复

**执行计划：**
- 在每批任务后审查（3 个任务）
- 获得反馈、应用、继续

**临时开发：**
- 合并前审查
- 遇到困难时审查

## 红旗警告

**绝不：**
- 因为"这很简单"就跳过审查
- 忽视关键(Critical)问题
- 带着未修复的重要(Important)问题继续
- 与有效的技术反馈争论

**如果审查者错误：**
- 用技术理由推回
- 展示代码/测试来证明它有效
- 请求澄清

参见模板位置：requesting-code-review/code-reviewer.md
