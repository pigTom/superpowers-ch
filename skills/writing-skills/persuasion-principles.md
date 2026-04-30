# 技能设计中的说服原则

## 概述

大语言模型(LLM)对说服原则的反应与人类相同。了解这种心理学有助于设计更有效的技能——不是为了操纵，而是为了确保即使在压力下也遵循关键实践。

**研究基础：** Meincke等人(2025)用N=28,000次AI对话测试了7个说服原则。说服技术将遵从率提高了一倍以上(33% → 72%, p < .001)。

## 七个原则

### 1. 权威性
**含义：** 对专业知识、资格或官方来源的尊重。

**在技能中的运作方式：**
- 命令式语言："YOU MUST"、"Never"、"Always"
- 不可协商的框架："No exceptions"
- 消除决策疲劳和理由自洽化

**何时使用：**
- 规范执行技能(TDD、验证要求)
- 安全关键实践
- 既定最佳实践

**示例：**
```markdown
✅ Write code before test? Delete it. Start over. No exceptions.
❌ Consider writing tests first when feasible.
```

### 2. 承诺
**含义：** 与先前的行为、陈述或公开声明保持一致。

**在技能中的运作方式：**
- 要求公布："Announce skill usage"
- 强制明确选择："Choose A, B, or C"
- 使用跟踪：TodoWrite用于清单

**何时使用：**
- 确保技能得到实际遵循
- 多步骤流程
- 问责机制

**示例：**
```markdown
✅ When you find a skill, you MUST announce: "I'm using [Skill Name]"
❌ Consider letting your partner know which skill you're using.
```

### 3. 稀缺性
**含义：** 来自时间限制或可用性限制的紧迫感。

**在技能中的运作方式：**
- 时间限制要求："Before proceeding"
- 顺序依赖："Immediately after X"
- 防止拖延

**何时使用：**
- 即时验证要求
- 时间敏感的工作流
- 防止"我稍后会做"

**示例：**
```markdown
✅ After completing a task, IMMEDIATELY request code review before proceeding.
❌ You can review code when convenient.
```

### 4. 社会认可
**含义：** 符合他人所做的事或被认为是常态的东西。

**在技能中的运作方式：**
- 通用模式："Every time"、"Always"
- 失败模式："X without Y = failure"
- 建立规范

**何时使用：**
- 记录普遍实践
- 警告常见故障
- 强化标准

**示例：**
```markdown
✅ Checklists without TodoWrite tracking = steps get skipped. Every time.
❌ Some people find TodoWrite helpful for checklists.
```

### 5. 统一性
**含义：** 共同身份、"我们感"、群体归属感。

**在技能中的运作方式：**
- 协作语言："our codebase"、"we're colleagues"
- 共同目标："we both want quality"

**何时使用：**
- 协作工作流
- 建立团队文化
- 非等级制实践

**示例：**
```markdown
✅ We're colleagues working together. I need your honest technical judgment.
❌ You should probably tell me if I'm wrong.
```

### 6. 互惠
**含义：** 有义务回报所收到的好处。

**运作方式：**
- 谨慎使用——可能感觉操纵
- 很少在技能中需要

**何时避免：**
- 几乎总是(其他原则更有效)

### 7. 喜爱
**含义：** 倾向于与我们喜欢的人合作。

**运作方式：**
- **不要用于遵从** 
- 与诚实反馈文化冲突
- 造成谄媚

**何时避免：**
- 总是在规范执行中避免

## 按技能类型组合原则

| 技能类型 | 使用 | 避免 |
|---------|------|------|
| 规范执行 | Authority + Commitment + Social Proof | Liking, Reciprocity |
| 指导/技巧 | Moderate Authority + Unity | Heavy authority |
| 协作 | Unity + Commitment | Authority, Liking |
| 参考 | Clarity only | All persuasion |

## 为什么这有效：心理学

**清晰的规则减少理由自洽化：**
- "YOU MUST"消除决策疲劳
- 绝对语言消除"这是例外吗？"问题
- 明确的反理由自洽化论证对应特定漏洞

**实施意图创建自动行为：**
- 清晰的触发器 + 必需的行为 = 自动执行
- "When X, do Y"比"generally do Y"更有效
- 降低遵从的认知负荷

**LLM是类人的：**
- 在包含这些模式的人类文本上进行训练
- 权威语言先于训练数据中的遵从
- 承诺序列(陈述 → 行动)经常被建模
- 社会认可模式(每个人都做X)建立规范

## 伦理使用

**合法的：**
- 确保关键实践得到遵循
- 创建有效的文档
- 防止可预测的故障

**不合法的：**
- 为个人利益进行操纵
- 制造虚假的紧迫感
- 基于内疚的遵从

**测试：** 如果用户充分了解这种技术，它是否会服务于用户的真实利益？

## 研究引用

**Cialdini, R. B. (2021).** *Influence: The Psychology of Persuasion (New and Expanded).* Harper Business.
- 说服的七个原则
- 影响力研究的实证基础

**Meincke, L., Shapiro, D., Duckworth, A. L., Mollick, E., Mollick, L., & Cialdini, R. (2025).** Call Me A Jerk: Persuading AI to Comply with Objectionable Requests. University of Pennsylvania.
- 用N=28,000次LLM对话测试了7个原则
- 遵从率从33% → 72%，使用说服技术
- 权威、承诺、稀缺性最有效
- 验证了LLM行为的类人模型

## 快速参考

设计技能时，问自己：

1. **它是什么类型？** (规范 vs. 指导 vs. 参考)
2. **我试图改变什么行为？**
3. **哪个原则(们)适用？** (通常规范为 authority + commitment)
4. **我是否组合太多？** (不要使用全部七个)
5. **这是伦理的吗？** (服务于用户的真实利益？)
