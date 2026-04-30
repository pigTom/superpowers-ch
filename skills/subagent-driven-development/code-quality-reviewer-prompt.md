# 代码质量审查提示模板

在派遣代码质量审查子代理(subagent)时使用此模板。

**目的：** 验证实现是否构建完善（整洁、经过测试、可维护）

**仅在规范符合性审查通过后才进行派遣。**

```
Task tool (superpowers:code-reviewer):
  Use template at requesting-code-review/code-reviewer.md

  WHAT_WAS_IMPLEMENTED: [from implementer's report]
  PLAN_OR_REQUIREMENTS: Task N from [plan-file]
  BASE_SHA: [commit before task]
  HEAD_SHA: [current commit]
  DESCRIPTION: [task summary]
```

**除了标准代码质量问题，审查员还应检查：**
- 每个文件是否有一个清晰的职责和明确定义的接口？
- 单元是否分解使其可以独立理解和测试？
- 实现是否遵循计划中的文件结构？
- 此实现是否创建了已经很大的新文件，或显著增大了现有文件？（不要标记预先存在的文件大小 — 专注于此更改贡献了什么。）

**代码审查员返回：** 优势、问题（关键/重要/次要）、评估
