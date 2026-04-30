# 技能(Skill)创作最佳实践

> 了解如何编写有效的技能(Skill)，使 Claude 能够发现并成功使用。

优秀的技能(Skill)应该简洁、结构清晰、并通过实际使用进行测试。本指南提供实用的创作决策，帮助你编写 Claude 能够发现并有效使用的技能(Skill)。

关于技能(Skill)如何运作的概念背景，请参阅[技能(Skill)概述](/en/docs/agents-and-tools/agent-skills/overview)。

## 核心原则

### 简洁是关键

[上下文窗口(context window)](https://platform.claude.com/docs/en/build-with-claude/context-windows)是一种公共资源。你的技能(Skill)与 Claude 需要了解的其他所有内容共享上下文窗口，包括：

* 系统提示
* 对话历史
* 其他技能(Skill)的元数据
* 你的实际请求

你的技能(Skill)中的每个标记并不都会立即产生成本。在启动时，只有所有技能(Skill)的元数据（名称和描述）被预加载。Claude 只在技能(Skill)变得相关时才读取 SKILL.md，并根据需要读取其他文件。但是，在 SKILL.md 中保持简洁仍然很重要：一旦 Claude 加载它，每个标记都会与对话历史和其他上下文竞争。

**默认假设**：Claude 已经非常聪慧

只添加 Claude 还没有的上下文。对每条信息进行挑战：

* "Claude 真的需要这个解释吗？"
* "我能假设 Claude 知道这个吗？"
* "这个段落证明了它的标记成本吗？"

**优秀的例子：简洁**（约 50 个标记）：

````markdown  theme={null}
## 提取 PDF 文本

使用 pdfplumber 进行文本提取：

```python
import pdfplumber

with pdfplumber.open("file.pdf") as pdf:
    text = pdf.pages[0].extract_text()
```
````

**不好的例子：过于冗长**（约 150 个标记）：

```markdown  theme={null}
## 提取 PDF 文本

PDF（Portable Document Format）文件是一种常见的文件格式，包含文本、图像和其他内容。要从 PDF 提取文本，你需要使用一个库。有许多库可用于 PDF 处理，但我们推荐 pdfplumber，因为它易于使用且能处理大多数情况。首先，你需要使用 pip 安装它。然后，你可以使用下面的代码...
```

简洁的版本假设 Claude 知道 PDF 是什么以及库的工作原理。

### 设置适当的自由度水平

将具体性水平与任务的脆弱性和变异性相匹配。

**高自由度**（基于文本的指令）：

使用场景：

* 多种方法都有效
* 决策取决于上下文
* 启发式指导方法

例子：

```markdown  theme={null}
## 代码审查流程

1. 分析代码结构和组织
2. 检查潜在的错误或边界情况
3. 建议改进可读性和可维护性的方法
4. 验证是否遵守项目约定
```

**中等自由度**（伪代码或带参数的脚本）：

使用场景：

* 存在首选模式
* 某些变化是可接受的
* 配置影响行为

例子：

````markdown  theme={null}
## 生成报告

使用此模板并根据需要自定义：

```python
def generate_report(data, format="markdown", include_charts=True):
    # 处理数据
    # 以指定格式生成输出
    # 可选地包含可视化
```
````

**低自由度**（特定脚本，参数少或没有参数）：

使用场景：

* 操作易于出错
* 一致性至关重要
* 必须遵循特定序列

例子：

````markdown  theme={null}
## 数据库迁移

运行这个脚本：

```bash
python scripts/migrate.py --verify --backup
```

不要修改命令或添加其他标志。
````

**类比**：将 Claude 想象为一个探索路径的机器人：

* **两边是悬崖的狭窄桥梁**：只有一条安全的前进方式。提供具体的防护栏和精确的指令（低自由度）。例子：必须按确切顺序运行的数据库迁移。
* **没有危险的开阔田野**：许多路径通向成功。给出大致方向并相信 Claude 能找到最佳路线（高自由度）。例子：代码审查，其中上下文决定了最佳方法。

### 用你计划使用的所有模型进行测试

技能(Skill)作为模型的附加功能，所以效果取决于底层模型。用你计划使用的所有模型测试你的技能(Skill)。

**按模型考虑的测试因素**：

* **Claude Haiku**（快速、经济）：技能(Skill)提供了足够的指导吗？
* **Claude Sonnet**（平衡）：技能(Skill)清晰且高效吗？
* **Claude Opus**（强大的推理）：技能(Skill)避免过度解释吗？

对 Opus 完美有效的东西可能需要为 Haiku 提供更多细节。如果你计划跨多个模型使用你的技能(Skill)，目标是使说明对所有模型都有效。

## 技能(Skill)结构

<Note>
  **YAML 前置元数据(Frontmatter)**：SKILL.md 的前置元数据需要两个字段：

  * `name` - 技能(Skill)的人类可读名称（最多 64 个字符）
  * `description` - 技能(Skill)的功能和何时使用的单行描述（最多 1024 个字符）

  关于完整的技能(Skill)结构详情，请参阅[技能(Skill)概述](/en/docs/agents-and-tools/agent-skills/overview#skill-structure)。
</Note>

### 命名约定

使用一致的命名模式使技能(Skill)更容易引用和讨论。我们建议对技能(Skill)名称使用**动名词形式**（动词 + -ing），因为这清楚地描述了技能(Skill)提供的活动或能力。

**优秀的命名示例（动名词形式）**：

* "Processing PDFs"（处理 PDF）
* "Analyzing spreadsheets"（分析电子表格）
* "Managing databases"（管理数据库）
* "Testing code"（测试代码）
* "Writing documentation"（编写文档）

**可接受的替代方案**：

* 名词短语："PDF Processing"（PDF 处理）、"Spreadsheet Analysis"（电子表格分析）
* 行动导向："Process PDFs"（处理 PDF）、"Analyze Spreadsheets"（分析电子表格）

**避免**：

* 模糊的名称："Helper"（帮助程序）、"Utils"（实用程序）、"Tools"（工具）
* 过于通用："Documents"（文档）、"Data"（数据）、"Files"（文件）
* 在你的技能(Skill)集合中不一致的模式

一致的命名使得更容易：

* 在文档和对话中引用技能(Skill)
* 快速了解技能(Skill)的作用
* 组织和搜索多个技能(Skill)
* 保持专业、凝聚的技能(Skill)库

### 编写有效的描述

`description` 字段启用技能(Skill)发现，应该包括技能(Skill)的功能和何时使用。

<Warning>
  **总是用第三人称写**。描述被注入到系统提示中，不一致的观点视角可能会导致发现问题。

  * **优秀的**："处理 Excel 文件并生成报告"
  * **避免**："我可以帮你处理 Excel 文件"
  * **避免**："你可以用这个处理 Excel 文件"
</Warning>

**具体并包括关键术语**。包括技能(Skill)的功能和何时使用的具体触发器/上下文。

每个技能(Skill)只有一个描述字段。描述对技能(Skill)选择至关重要：Claude 使用它从可能的 100 多个可用技能(Skill)中选择正确的技能(Skill)。你的描述必须提供足够的细节，使 Claude 知道何时选择此技能(Skill)，而 SKILL.md 的其余部分提供实现细节。

有效的示例：

**PDF 处理技能(Skill)**：

```yaml  theme={null}
description: 从 PDF 文件提取文本和表格、填写表单、合并文档。在处理 PDF 文件或用户提及 PDF、表单或文档提取时使用。
```

**Excel 分析技能(Skill)**：

```yaml  theme={null}
description: 分析 Excel 电子表格、创建数据透视表、生成图表。在分析 Excel 文件、电子表格、表格数据或 .xlsx 文件时使用。
```

**Git 提交助手技能(Skill)**：

```yaml  theme={null}
description: 通过分析 git 差异生成描述性的提交消息。当用户要求帮助编写提交消息或审查暂存更改时使用。
```

避免含糊的描述，例如：

```yaml  theme={null}
description: 帮助处理文档
```

```yaml  theme={null}
description: 处理数据
```

```yaml  theme={null}
description: 用文件做东西
```

### 渐进式披露模式

SKILL.md 充当概览，指向 Claude 根据需要查找详细材料，就像入门指南中的目录。关于渐进式披露如何工作的解释，请参阅概述中的[技能(Skill)如何工作](/en/docs/agents-and-tools/agent-skills/overview#how-skills-work)。

**实用指南**：

* 将 SKILL.md 正文保持在 500 行以下以获得最佳性能
* 接近此限制时将内容分割成单独的文件
* 使用下面的模式有效地组织说明、代码和资源

#### 视觉概览：从简单到复杂

基本的技能(Skill)仅包含一个 SKILL.md 文件，其中包含元数据和说明：

<img src="https://mintcdn.com/anthropic-claude-docs/4Bny2bjzuGBK7o00/images/agent-skills-simple-file.png?fit=max&auto=format&n=4Bny2bjzuGBK7o00&q=85&s=87782ff239b297d9a9e8e1b72ed72db9" alt="Simple SKILL.md file showing YAML frontmatter and markdown body" data-og-width="2048" width="2048" data-og-height="1153" height="1153" data-path="images/agent-skills-simple-file.png" data-optimize="true" data-opv="3" srcset="https://mintcdn.com/anthropic-claude-docs/4Bny2bjzuGBK7o00/images/agent-skills-simple-file.png?w=280&fit=max&auto=format&n=4Bny2bjzuGBK7o00&q=85&s=c61cc33b6f5855809907f7fda94cd80e 280w, https://mintcdn.com/anthropic-claude-docs/4Bny2bjzuGBK7o00/images/agent-skills-simple-file.png?w=560&fit=max&auto=format&n=4Bny2bjzuGBK7o00&q=85&s=90d2c0c1c76b36e8d485f49e0810dbfd 560w, https://mintcdn.com/anthropic-claude-docs/4Bny2bjzuGBK7o00/images/agent-skills-simple-file.png?w=840&fit=max&auto=format&n=4Bny2bjzuGBK7o00&q=85&s=ad17d231ac7b0bea7e5b4d58fb4aeabb 840w, https://mintcdn.com/anthropic-claude-docs/4Bny2bjzuGBK7o00/images/agent-skills-simple-file.png?w=1100&fit=max&auto=format&n=4Bny2bjzuGBK7o00&q=85&s=f5d0a7a3c668435bb0aee9a3a8f8c329 1100w, https://mintcdn.com/anthropic-claude-docs/4Bny2bjzuGBK7o00/images/agent-skills-simple-file.png?w=1650&fit=max&auto=format&n=4Bny2bjzuGBK7o00&q=85&s=0e927c1af9de5799cfe557d12249f6e6 1650w, https://mintcdn.com/anthropic-claude-docs/4Bny2bjzuGBK7o00/images/agent-skills-simple-file.png?w=2500&fit=max&auto=format&n=4Bny2bjzuGBK7o00&q=85&s=46bbb1a51dd4c8202a470ac8c80a893d 2500w" />

随着你的技能(Skill)增长，你可以捆绑在需要时只由 Claude 加载的其他内容：

<img src="https://mintcdn.com/anthropic-claude-docs/4Bny2bjzuGBK7o00/images/agent-skills-bundling-content.png?fit=max&auto=format&n=4Bny2bjzuGBK7o00&q=85&s=a5e0aa41e3d53985a7e3e43668a33ea3" alt="Bundling additional reference files like reference.md and forms.md." data-og-width="2048" width="2048" data-og-height="1327" height="1327" data-path="images/agent-skills-bundling-content.png" data-optimize="true" data-opv="3" srcset="https://mintcdn.com/anthropic-claude-docs/4Bny2bjzuGBK7o00/images/agent-skills-bundling-content.png?w=280&fit=max&auto=format&n=4Bny2bjzuGBK7o00&q=85&s=f8a0e73783e99b4a643d79eac86b70a2 280w, https://mintcdn.com/anthropic-claude-docs/4Bny2bjzuGBK7o00/images/agent-skills-bundling-content.png?w=560&fit=max&auto=format&n=4Bny2bjzuGBK7o00&q=85&s=dc510a2a9d3f14359416b706f067904a 560w, https://mintcdn.com/anthropic-claude-docs/4Bny2bjzuGBK7o00/images/agent-skills-bundling-content.png?w=840&fit=max&auto=format&n=4Bny2bjzuGBK7o00&q=85&s=82cd6286c966303f7dd914c28170e385 840w, https://mintcdn.com/anthropic-claude-docs/4Bny2bjzuGBK7o00/images/agent-skills-bundling-content.png?w=1100&fit=max&auto=format&n=4Bny2bjzuGBK7o00&q=85&s=56f3be36c77e4fe4b523df209a6824c6 1100w, https://mintcdn.com/anthropic-claude-docs/4Bny2bjzuGBK7o00/images/agent-skills-bundling-content.png?w=1650&fit=max&auto=format&n=4Bny2bjzuGBK7o00&q=85&s=d22b5161b2075656417d56f41a74f3dd 1650w, https://mintcdn.com/anthropic-claude-docs/4Bny2bjzuGBK7o00/images/agent-skills-bundling-content.png?w=2500&fit=max&auto=format&n=4Bny2bjzuGBK7o00&q=85&s=3dd4bdd6850ffcc96c6c45fcb0acd6eb 2500w" />

完整的技能(Skill)目录结构可能如下所示：

```
pdf/
├── SKILL.md              # 主要说明（触发时加载）
├── FORMS.md              # 表单填充指南（根据需要加载）
├── reference.md          # API 参考（根据需要加载）
├── examples.md           # 使用示例（根据需要加载）
└── scripts/
    ├── analyze_form.py   # 实用脚本（执行，不加载）
    ├── fill_form.py      # 表单填充脚本
    └── validate.py       # 验证脚本
```

#### 模式 1：高级指南与参考

````markdown  theme={null}
---
name: PDF Processing
description: 从 PDF 文件提取文本和表格、填写表单、合并文档。在处理 PDF 文件或用户提及 PDF、表单或文档提取时使用。
---

# PDF 处理

## 快速开始

使用 pdfplumber 提取文本：
```python
import pdfplumber
with pdfplumber.open("file.pdf") as pdf:
    text = pdf.pages[0].extract_text()
```

## 高级功能

**表单填充**：见 [FORMS.md](FORMS.md) 的完整指南
**API 参考**：见 [REFERENCE.md](REFERENCE.md) 的所有方法
**示例**：见 [EXAMPLES.md](EXAMPLES.md) 的常见模式
````

Claude 只在需要时加载 FORMS.md、REFERENCE.md 或 EXAMPLES.md。

#### 模式 2：领域特定的组织

对于有多个域的技能(Skill)，按域组织内容以避免加载无关的上下文。当用户询问销售指标时，Claude 只需要读取销售相关的架构，而不需要财务或市场营销数据。这保持了标记使用的低水平和上下文的聚焦。

```
bigquery-skill/
├── SKILL.md (概览和导航)
└── reference/
    ├── finance.md (收入，计费指标)
    ├── sales.md (机会，管道)
    ├── product.md (API 使用，功能)
    └── marketing.md (活动，归因)
```

````markdown SKILL.md theme={null}
# BigQuery 数据分析

## 可用数据集

**财务**：收入、ARR、计费 → 见 [reference/finance.md](reference/finance.md)
**销售**：机会、管道、账户 → 见 [reference/sales.md](reference/sales.md)
**产品**：API 使用、功能、采用 → 见 [reference/product.md](reference/product.md)
**市场营销**：活动、归因、电子邮件 → 见 [reference/marketing.md](reference/marketing.md)

## 快速搜索

使用 grep 查找特定指标：

```bash
grep -i "revenue" reference/finance.md
grep -i "pipeline" reference/sales.md
grep -i "api usage" reference/product.md
```
````

#### 模式 3：条件细节

显示基本内容，链接到高级内容：

```markdown  theme={null}
# DOCX 处理

## 创建文档

使用 docx-js 创建新文档。见 [DOCX-JS.md](DOCX-JS.md)。

## 编辑文档

对于简单编辑，直接修改 XML。

**对于跟踪更改**：见 [REDLINING.md](REDLINING.md)
**对于 OOXML 详情**：见 [OOXML.md](OOXML.md)
```

Claude 只在用户需要这些功能时读取 REDLINING.md 或 OOXML.md。

### 避免深层嵌套的参考

Claude 可能会在从其他被引用的文件中引用文件时部分读取文件。遇到嵌套引用时，Claude 可能会使用 `head -100` 等命令来预览内容，而不是读取整个文件，导致信息不完整。

**将参考保持在 SKILL.md 下一级深度**。所有参考文件应直接从 SKILL.md 链接，以确保在需要时 Claude 读取完整文件。

**不好的例子：太深**：

```markdown  theme={null}
# SKILL.md
见 [advanced.md](advanced.md)...

# advanced.md
见 [details.md](details.md)...

# details.md
这是实际信息...
```

**优秀的例子：一级深度**：

```markdown  theme={null}
# SKILL.md

**基本使用**：[SKILL.md 中的说明]
**高级功能**：见 [advanced.md](advanced.md)
**API 参考**：见 [reference.md](reference.md)
**示例**：见 [examples.md](examples.md)
```

### 用目录结构更长的参考文件

对于长度超过 100 行的参考文件，在顶部包括目录。这确保 Claude 即使在部分读取时也能看到完整的可用信息范围。

**例子**：

```markdown  theme={null}
# API 参考

## 内容
- 身份验证和设置
- 核心方法（创建、读取、更新、删除）
- 高级功能（批量操作、网络钩子）
- 错误处理模式
- 代码示例

## 身份验证和设置
...

## 核心方法
...
```

Claude 然后可以读取完整文件或根据需要跳转到特定部分。

关于此基于文件系统的架构如何启用渐进式披露的详细信息，请参阅下面高级部分中的[运行时环境](#runtime-environment)。

## 工作流和反馈循环

### 对复杂任务使用工作流

将复杂操作分解为清晰的顺序步骤。对于特别复杂的工作流，提供一个清单，Claude 可以将其复制到其响应中并在推进时检查。

**示例 1：研究综合工作流**（适用于没有代码的技能(Skill)）：

````markdown  theme={null}
## 研究综合工作流

复制此清单并跟踪你的进度：

```
研究进度：
- [ ] 步骤 1：阅读所有源文档
- [ ] 步骤 2：确定关键主题
- [ ] 步骤 3：交叉引用声明
- [ ] 步骤 4：创建结构化摘要
- [ ] 步骤 5：验证引用
```

**步骤 1：阅读所有源文档**

查看 `sources/` 目录中的每份文档。注意主要论点和支持证据。

**步骤 2：确定关键主题**

寻找跨源的模式。什么主题反复出现？源何处一致或不同？

**步骤 3：交叉引用声明**

对于每项主要声明，验证它出现在源材料中。注意哪个源支持每个点。

**步骤 4：创建结构化摘要**

按主题组织发现。包括：
- 主要声明
- 来自源的支持证据
- 冲突的观点（如果有）

**步骤 5：验证引用**

检查每项声明是否引用了正确的源文档。如果引用不完整，返回步骤 3。
````

此示例展示工作流如何适用于不需要代码的分析任务。清单模式适用于任何复杂的多步骤过程。

**示例 2：PDF 表单填充工作流**（适用于有代码的技能(Skill)）：

````markdown  theme={null}
## PDF 表单填充工作流

复制此清单并在完成时检查项目：

```
任务进度：
- [ ] 步骤 1：分析表单（运行 analyze_form.py）
- [ ] 步骤 2：创建字段映射（编辑 fields.json）
- [ ] 步骤 3：验证映射（运行 validate_fields.py）
- [ ] 步骤 4：填充表单（运行 fill_form.py）
- [ ] 步骤 5：验证输出（运行 verify_output.py）
```

**步骤 1：分析表单**

运行：`python scripts/analyze_form.py input.pdf`

这提取表单字段及其位置，保存到 `fields.json`。

**步骤 2：创建字段映射**

编辑 `fields.json` 为每个字段添加值。

**步骤 3：验证映射**

运行：`python scripts/validate_fields.py fields.json`

继续之前修复任何验证错误。

**步骤 4：填充表单**

运行：`python scripts/fill_form.py input.pdf fields.json output.pdf`

**步骤 5：验证输出**

运行：`python scripts/verify_output.py output.pdf`

如果验证失败，返回步骤 2。
````

清晰的步骤防止 Claude 跳过关键验证。清单帮助 Claude 和你通过多步骤工作流跟踪进度。

### 实现反馈循环

**常见模式**：运行验证器 → 修复错误 → 重复

这个模式大大改善了输出质量。

**示例 1：风格指南符合性**（适用于没有代码的技能(Skill)）：

```markdown  theme={null}
## 内容审查流程

1. 按照 STYLE_GUIDE.md 中的指南起草你的内容
2. 根据清单审查：
   - 检查术语一致性
   - 验证示例遵循标准格式
   - 确认所有必需部分都存在
3. 如果发现问题：
   - 用具体部分参考注意每个问题
   - 修改内容
   - 再次审查清单
4. 仅在满足所有要求时继续
5. 最终确定并保存文档
```

这展示了使用参考文档而不是脚本的验证循环模式。"验证器"是 STYLE_GUIDE.md，Claude 通过阅读和比较进行检查。

**示例 2：文档编辑流程**（适用于有代码的技能(Skill)）：

```markdown  theme={null}
## 文档编辑流程

1. 编辑 `word/document.xml`
2. **立即验证**：`python ooxml/scripts/validate.py unpacked_dir/`
3. 如果验证失败：
   - 仔细审查错误消息
   - 修复 XML 中的问题
   - 再次运行验证
4. **仅在验证通过时继续**
5. 重新构建：`python ooxml/scripts/pack.py unpacked_dir/ output.docx`
6. 测试输出文档
```

验证循环及早捕获错误。

## 内容指南

### 避免时间敏感的信息

不要包括会过时的信息：

**不好的例子：时间敏感的**（会变错）：

```markdown  theme={null}
如果你在 2025 年 8 月之前进行此操作，请使用旧 API。在 2025 年 8 月之后，使用新 API。
```

**优秀的例子**（使用"旧模式"部分）：

```markdown  theme={null}
## 当前方法

使用 v2 API 端点：`api.example.com/v2/messages`

## 旧模式

<details>
<summary>旧版 v1 API（已弃用 2025-08）</summary>

v1 API 使用：`api.example.com/v1/messages`

此端点不再支持。
</details>
```

旧模式部分提供历史背景而不会使主内容混乱。

### 使用一致的术语

选择一个术语并在整个技能(Skill)中使用它：

**优秀的 - 一致的**：

* 总是"API 端点"
* 总是"字段"
* 总是"提取"

**不好的 - 不一致的**：

* 混合"API 端点"、"URL"、"API 路由"、"路径"
* 混合"字段"、"框"、"元素"、"控制"
* 混合"提取"、"拉"、"获取"、"检索"

一致性帮助 Claude 理解和遵循说明。

## 常见模式

### 模板模式

为输出格式提供模板。将严格程度与你的需求相匹配。

**对于严格要求**（如 API 响应或数据格式）：

````markdown  theme={null}
## 报告结构

总是使用这个精确的模板结构：

```markdown
# [分析标题]

## 执行摘要
[关键发现的一段概述]

## 关键发现
- 带有支持数据的发现 1
- 带有支持数据的发现 2
- 带有支持数据的发现 3

## 建议
1. 具体可操作的建议
2. 具体可操作的建议
```
````

**对于灵活指导**（当适应很有用时）：

````markdown  theme={null}
## 报告结构

这是一个合理的默认格式，但根据分析使用你最好的判断：

```markdown
# [分析标题]

## 执行摘要
[概览]

## 关键发现
[根据你的发现调整部分]

## 建议
[针对具体上下文定制]
```

根据特定分析类型的需要调整部分。
````

### 示例模式

对于输出质量取决于看到示例的技能(Skill)，提供输入/输出对，就像在常规提示中一样：

````markdown  theme={null}
## 提交消息格式

按照这些示例生成提交消息：

**示例 1：**
输入：使用 JWT 令牌添加了用户身份验证
输出：
```
feat(auth): implement JWT-based authentication

Add login endpoint and token validation middleware
```

**示例 2：**
输入：修复了报告中日期显示不正确的错误
输出：
```
fix(reports): correct date formatting in timezone conversion

Use UTC timestamps consistently across report generation
```

**示例 3：**
输入：更新了依赖项并重构了错误处理
输出：
```
chore: update dependencies and refactor error handling

- Upgrade lodash to 4.17.21
- Standardize error response format across endpoints
```

遵循这种风格：type(scope)：简短描述，然后是详细说明。
````

示例帮助 Claude 比单独描述更清楚地理解所需的风格和细节水平。

### 条件工作流模式

通过决策点引导 Claude：

```markdown  theme={null}
## 文档修改工作流

1. 确定修改类型：

   **创建新内容？** → 遵循下面的"创建工作流"
   **编辑现有内容？** → 遵循下面的"编辑工作流"

2. 创建工作流：
   - 使用 docx-js 库
   - 从头开始构建文档
   - 导出为 .docx 格式

3. 编辑工作流：
   - 解包现有文档
   - 直接修改 XML
   - 每次更改后验证
   - 完成时重新打包
```

<Tip>
  如果工作流变得大型或复杂，有许多步骤，考虑将其推送到单独的文件中，并告诉 Claude 根据手头的任务读取适当的文件。
</Tip>

## 评估和迭代

### 首先构建评估

**在编写广泛的文档之前创建评估**。这确保你的技能(Skill)解决实际问题，而不是记录想象中的问题。

**评估驱动的开发**：

1. **确定差距**：在没有技能(Skill)的情况下对代表性任务运行 Claude。记录具体的失败或缺失上下文
2. **创建评估**：构建三个测试这些差距的场景
3. **建立基线**：衡量 Claude 在没有技能(Skill)情况下的性能
4. **编写最少说明**：仅创建足以满足差距和通过评估的内容
5. **迭代**：执行评估，与基线比较，并改进

这种方法确保你在解决实际问题而不是预期可能永远不会实现的要求。

**评估结构**：

```json  theme={null}
{
  "skills": ["pdf-processing"],
  "query": "从这个 PDF 文件提取所有文本并将其保存到 output.txt",
  "files": ["test-files/document.pdf"],
  "expected_behavior": [
    "使用适当的 PDF 处理库或命令行工具成功读取 PDF 文件",
    "从文档中所有页面提取文本内容，不遗漏任何页面",
    "将提取的文本保存到名为 output.txt 的文件，采用清晰、可读的格式"
  ]
}
```

<Note>
  此示例演示了使用简单测试框架的数据驱动评估。我们目前不提供运行这些评估的内置方式。用户可以创建自己的评估系统。评估是衡量技能(Skill)有效性的事实来源。
</Note>

### 使用 Claude 迭代开发技能(Skill)

最有效的技能(Skill)开发过程涉及 Claude 本身。与一个 Claude 实例（"Claude A"）合作创建一个将被其他实例（"Claude B"）使用的技能(Skill)。Claude A 帮助你设计和完善说明，而 Claude B 在实际任务中测试它们。这之所以有效是因为 Claude 模型既理解如何编写有效的代理(agent)说明，也理解代理(agent)需要什么信息。

**创建新技能(Skill)**：

1. **不使用技能(Skill)完成任务**：使用正常提示与 Claude A 解决问题。工作时，你自然会提供背景、解释偏好和共享程序知识。注意你反复提供的信息。

2. **识别可重复使用的模式**：完成任务后，识别你提供的对于类似未来任务会有用的内容。

   **示例**：如果你通过了 BigQuery 分析，你可能提供了表名、字段定义、过滤规则（如"始终排除测试账户"）和常见查询模式。

3. **要求 Claude A 创建技能(Skill)**："创建一个捕获我们刚刚使用的 BigQuery 分析模式的技能(Skill)。包括表架构、命名约定和关于过滤测试账户的规则。"

   <Tip>
     Claude 模型本身理解技能(Skill)格式和结构。你不需要特殊的系统提示或"编写技能(Skill)"技能(Skill)来让 Claude 帮助创建技能(Skill)。只需要求 Claude 创建技能(Skill)，它就会生成适当的前置元数据(frontmatter)和正文内容的 SKILL.md 内容。
   </Tip>

4. **审查简洁性**：检查 Claude A 是否没有添加不必要的解释。询问："删除关于赢率是什么意思的解释 - Claude 已经知道了。"

5. **改进信息架构**：要求 Claude A 更有效地组织内容。例如："组织这个使表架构在单独的参考文件中。我们稍后可能添加更多表。"

6. **测试相似任务**：使用技能(Skill)与 Claude B（一个加载了技能(Skill)的新实例）进行相关用例。观察 Claude B 是否找到了正确的信息，正确应用了规则，并成功处理了任务。

7. **基于观察迭代**：如果 Claude B 遇到困难或遗漏了什么，用具体信息返回到 Claude A："当 Claude 使用此技能(Skill)时，它忘记按 Q4 日期过滤。我们是否应该添加一个关于日期过滤模式的部分？"

**迭代现有技能(Skill)**：

相同的分层模式在改进技能(Skill)时继续。你在以下两者之间交替：

* **与 Claude A 合作**（帮助完善技能(Skill)的专家）
* **用 Claude B 测试**（代理(agent)使用技能(Skill)执行真实工作）
* **观察 Claude B 的行为**并将见解带回给 Claude A

1. **在真实工作流中使用技能(Skill)**：给 Claude B（加载了技能(Skill)）实际任务，而不是测试场景

2. **观察 Claude B 的行为**：注意它在哪里遇到困难、成功或做出意外选择

   **示例观察**："当我要求 Claude B 提供区域销售报告时，它写了查询但忘记了过滤出测试账户，即使技能(Skill)提到了这条规则。"

3. **返回给 Claude A 进行改进**：共享当前 SKILL.md 并描述你的观察。询问："我注意到当我要求区域报告时 Claude B 忘记了过滤测试账户。技能(Skill)提到了过滤，但也许它还不够突出？"

4. **审查 Claude A 的建议**：Claude A 可能建议重新组织以使规则更突出，使用更强的语言（如"必须过滤"而不是"总是过滤"），或重构工作流部分。

5. **应用并测试更改**：用 Claude A 的改进更新技能(Skill)，然后在相似请求上用 Claude B 再次测试

6. **根据使用情况重复**：继续这个观察-细化-测试循环，当你遇到新的场景时。每次迭代都基于真实代理(agent)行为而不是假设改进了技能(Skill)。

**收集团队反馈**：

1. 与队友分享技能(Skill)并观察他们的使用
2. 询问：技能(Skill)在预期时激活吗？说明清晰吗？缺少什么？
3. 结合反馈以解决你自己使用模式中的盲点

**为什么这种方法有效**：Claude A 理解代理(agent)需求，你提供领域专业知识，Claude B 通过真实使用揭示差距，迭代改进改进基于观察行为而不是假设的技能(Skill)。

### 观察 Claude 如何导航技能(Skill)

当你在技能(Skill)上迭代时，注意 Claude 实际上在实践中如何使用它们。观察：

* **意外的探索路径**：Claude 读文件的顺序与你预期的不同？这可能表明你的结构不如你想象的那样直观
* **错过的连接**：Claude 是否无法遵循重要文件的参考？你的链接可能需要更明确或突出
* **对某些部分的过度依赖**：如果 Claude 反复读同一文件，考虑是否应该将该内容移到主 SKILL.md 中
* **忽视的内容**：如果 Claude 从不访问捆绑文件，它可能是不必要的或在主说明中信号不好

基于这些观察而不是假设进行迭代。你的技能(Skill)元数据中的"名称"和"描述"特别关键。Claude 在决定是否响应当前任务触发技能(Skill)时使用这些。确保它们清楚地描述了技能(Skill)的功能和何时应使用。

## 反模式回避

### 避免 Windows 风格的路径

总是在文件路径中使用前向斜杠，即使在 Windows 上：

* ✓ **优秀的**：`scripts/helper.py`、`reference/guide.md`
* ✗ **避免**：`scripts\helper.py`、`reference\guide.md`

Unix 风格的路径跨所有平台工作，而 Windows 风格的路径在 Unix 系统上导致错误。

### 避免提供太多选项

不要呈现多个方法，除非必要：

````markdown  theme={null}
**不好的例子：太多选择**（困惑）：
"你可以使用 pypdf、或 pdfplumber、或 PyMuPDF、或 pdf2image、或..."

**优秀的例子：提供默认值**（带逃生舱口）：
"使用 pdfplumber 进行文本提取：
```python
import pdfplumber
```

对于需要 OCR 的扫描 PDF，使用 pdf2image 和 pytesseract。"
````

## 高级：带有可执行代码的技能(Skill)

下面的部分关注包括可执行脚本的技能(Skill)。如果你的技能(Skill)仅使用 markdown 说明，请跳到[有效技能(Skill)的清单](#checklist-for-effective-skills)。

### 解决问题，不要推卸

在为技能(Skill)编写脚本时，处理错误条件，而不是推卸给 Claude。

**优秀的例子：明确处理错误**：

```python  theme={null}
def process_file(path):
    """处理一个文件，如果不存在则创建它。"""
    try:
        with open(path) as f:
            return f.read()
    except FileNotFoundError:
        # 创建具有默认内容的文件，而不是失败
        print(f"找不到文件 {path}，正在创建默认值")
        with open(path, 'w') as f:
            f.write('')
        return ''
    except PermissionError:
        # 提供替代方案，而不是失败
        print(f"无法访问 {path}，使用默认值")
        return ''
```

**不好的例子：推卸给 Claude**：

```python  theme={null}
def process_file(path):
    # 只是失败并让 Claude 解决
    return open(path).read()
```

配置参数也应该被证明和记录以避免"巫术常数"（Ousterhout 定律）。如果你不知道正确的值，Claude 如何确定它？

**优秀的例子：自文档化**：

```python  theme={null}
# HTTP 请求通常在 30 秒内完成
# 更长的超时时间考虑到慢连接
REQUEST_TIMEOUT = 30

# 三次重试平衡可靠性和速度
# 大多数间歇性故障在第二次重试时解决
MAX_RETRIES = 3
```

**不好的例子：魔数**：

```python  theme={null}
TIMEOUT = 47  # 为什么是 47？
RETRIES = 5   # 为什么是 5？
```

### 提供实用脚本

即使 Claude 可以编写脚本，预制脚本也提供优势：

**实用脚本的好处**：

* 比生成的代码更可靠
* 节省标记（无需将代码包含在上下文中）
* 节省时间（无需代码生成）
* 确保跨使用的一致性

<img src="https://mintcdn.com/anthropic-claude-docs/4Bny2bjzuGBK7o00/images/agent-skills-executable-scripts.png?fit=max&auto=format&n=4Bny2bjzuGBK7o00&q=85&s=4bbc45f2c2e0bee9f2f0d5da669bad00" alt="Bundling executable scripts alongside instruction files" data-og-width="2048" width="2048" data-og-height="1154" height="1154" data-path="images/agent-skills-executable-scripts.png" data-optimize="true" data-opv="3" srcset="https://mintcdn.com/anthropic-claude-docs/4Bny2bjzuGBK7o00/images/agent-skills-executable-scripts.png?w=280&fit=max&auto=format&n=4Bny2bjzuGBK7o00&q=85&s=9a04e6535a8467bfeea492e517de389f 280w, https://mintcdn.com/anthropic-claude-docs/4Bny2bjzuGBK7o00/images/agent-skills-executable-scripts.png?w=560&fit=max&auto=format&n=4Bny2bjzuGBK7o00&q=85&s=e49333ad90141af17c0d7651cca7216b 560w, https://mintcdn.com/anthropic-claude-docs/4Bny2bjzuGBK7o00/images/agent-skills-executable-scripts.png?w=840&fit=max&auto=format&n=4Bny2bjzuGBK7o00&q=85&s=954265a5df52223d6572b6214168c428 840w, https://mintcdn.com/anthropic-claude-docs/4Bny2bjzuGBK7o00/images/agent-skills-executable-scripts.png?w=1100&fit=max&auto=format&n=4Bny2bjzuGBK7o00&q=85&s=2ff7a2d8f2a83ee8af132b29f10150fd 1100w, https://mintcdn.com/anthropic-claude-docs/4Bny2bjzuGBK7o00/images/agent-skills-executable-scripts.png?w=1650&fit=max&auto=format&n=4Bny2bjzuGBK7o00&q=85&s=48ab96245e04077f4d15e9170e081cfb 1650w, https://mintcdn.com/anthropic-claude-docs/4Bny2bjzuGBK7o00/images/agent-skills-executable-scripts.png?w=2500&fit=max&auto=format&n=4Bny2bjzuGBK7o00&q=85&s=0301a6c8b3ee879497cc5b5483177c90 2500w" />

上面的图表展示了可执行脚本如何与说明文件配合工作。说明文件（forms.md）引用脚本，Claude 可以执行它而不将其内容加载到上下文中。

**重要区别**：在你的说明中明确 Claude 应该：

* **执行脚本**（最常见）："运行 `analyze_form.py` 提取字段"
* **作为参考读取**（对于复杂逻辑）："见 `analyze_form.py` 了解字段提取算法"

对于大多数实用脚本，执行是首选，因为它更可靠且有效。关于脚本执行如何工作的详情，请参阅下面[运行时环境](#runtime-environment)部分。

**例子**：

````markdown  theme={null}
## 实用脚本

**analyze_form.py**：从 PDF 提取所有表单字段

```bash
python scripts/analyze_form.py input.pdf > fields.json
```

输出格式：
```json
{
  "field_name": {"type": "text", "x": 100, "y": 200},
  "signature": {"type": "sig", "x": 150, "y": 500}
}
```

**validate_boxes.py**：检查重叠的边界框

```bash
python scripts/validate_boxes.py fields.json
# 返回："OK"或列出冲突
```

**fill_form.py**：应用字段值到 PDF

```bash
python scripts/fill_form.py input.pdf fields.json output.pdf
```
````

### 使用视觉分析

当输入可以呈现为图像时，让 Claude 分析它们：

````markdown  theme={null}
## 表单布局分析

1. 将 PDF 转换为图像：
   ```bash
   python scripts/pdf_to_images.py form.pdf
   ```

2. 分析每个页面图像以标识表单字段
3. Claude 可以在视觉上看到字段位置和类型
````

<Note>
  在此示例中，你需要编写 `pdf_to_images.py` 脚本。
</Note>

Claude 的视觉能力帮助理解布局和结构。

### 创建可验证的中间输出

当 Claude 执行复杂的开放式任务时，它可能犯错。"计划-验证-执行"模式通过让 Claude 首先以结构化格式创建计划，然后在执行之前用脚本验证该计划，来及早捕获错误。

**示例**：想象要求 Claude 根据电子表格更新 PDF 中的 50 个表单字段。不进行验证，Claude 可能引用不存在的字段、创建冲突值、遗漏必需字段或错误地应用更新。

**解决方案**：使用上面显示的工作流模式（PDF 表单填充），但添加一个中间 `changes.json` 文件，在应用更改之前获得验证。工作流变为：分析 → **创建计划文件** → **验证计划** → 执行 → 验证。

**为什么这个模式有效：**

* **及早捕获错误**：验证在应用更改之前查找问题
* **机器可验证**：脚本提供客观验证
* **可逆的计划**：Claude 可以迭代计划而不接触原件
* **清晰的调试**：错误消息指向特定问题

**何时使用**：批量操作、破坏性更改、复杂验证规则、高风险操作。

**实现提示**：使用详细的错误消息（如"字段'signature_date'未找到。可用字段：customer_name、order_total、signature_date_signed"）使验证脚本详细，以帮助 Claude 修复问题。

### 打包依赖项

技能(Skill)在具有平台特定限制的代码执行环境中运行：

* **claude.ai**：可以从 npm 和 PyPI 安装包并从 GitHub 仓库拉取
* **Anthropic API**：没有网络访问，也没有运行时包安装

在你的 SKILL.md 中列出必需的包，并验证它们在[代码执行工具文档](/en/docs/agents-and-tools/tool-use/code-execution-tool)中可用。

### 运行时环境

技能(Skill)在具有文件系统访问、bash 命令和代码执行能力的代码执行环境中运行。关于此架构的概念解释，请参阅概述中的[技能(Skill)架构](/en/docs/agents-and-tools/agent-skills/overview#the-skills-architecture)。

**这如何影响你的创作：**

**Claude 如何访问技能(Skill)**：

1. **预加载元数据**：启动时，所有技能(Skill)的 YAML 前置元数据中的名称和描述被加载到系统提示中
2. **按需读取文件**：Claude 在需要时使用 bash 读工具从文件系统访问 SKILL.md 和其他文件
3. **有效执行脚本**：实用脚本可以通过 bash 执行而不将其完整内容加载到上下文中。只有脚本的输出消耗标记
4. **没有大文件的上下文惩罚**：参考文件、数据或文档不消耗上下文标记，直到实际读取

* **文件路径重要**：Claude 像文件系统一样导航你的技能(Skill)目录。使用前向斜杠（`reference/guide.md`），而不是反斜杠
* **描述性地命名文件**：使用表示内容的名称：`form_validation_rules.md`，而不是 `doc2.md`
* **按发现组织**：按域或功能构建目录
  * 优秀的：`reference/finance.md`、`reference/sales.md`
  * 不好的：`docs/file1.md`、`docs/file2.md`
* **捆绑全面的资源**：包括完整的 API 文档、广泛的示例、大型数据集；在访问之前没有上下文惩罚
* **对确定性操作首选脚本**：编写 `validate_form.py` 而不是要求 Claude 生成验证代码
* **明确执行意图**：
  * "运行 `analyze_form.py` 提取字段"（执行）
  * "见 `analyze_form.py` 了解提取算法"（作为参考读取）
* **测试文件访问模式**：通过用真实请求测试验证 Claude 可以导航你的目录结构

**例子**：

```
bigquery-skill/
├── SKILL.md (概览，指向参考文件)
└── reference/
    ├── finance.md (收入指标)
    ├── sales.md (管道数据)
    └── product.md (使用分析)
```

当用户询问收入时，Claude 读取 SKILL.md，看到对 `reference/finance.md` 的参考，并调用 bash 仅读取该文件。sales.md 和 product.md 文件保留在文件系统上，消耗零上下文标记，直到需要。这个基于文件系统的模型就是启用渐进式披露的原因。Claude 可以导航并选择性地加载每个任务需要的正好内容。

关于技术架构的完整详情，请参阅技能(Skill)概述中的[技能(Skill)如何工作](/en/docs/agents-and-tools/agent-skills/overview#how-skills-work)。

### MCP 工具参考

如果你的技能(Skill)使用 MCP（模型上下文协议(Model Context Protocol)）工具，总是使用完全限定的工具名称以避免"工具未找到"错误。

**格式**：`ServerName:tool_name`

**例子**：

```markdown  theme={null}
使用 BigQuery:bigquery_schema 工具检索表架构。
使用 GitHub:create_issue 工具创建问题。
```

哪里：

* `BigQuery` 和 `GitHub` 是 MCP 服务器名称
* `bigquery_schema` 和 `create_issue` 是这些服务器中的工具名称

没有服务器前缀，Claude 可能无法定位工具，特别是当多个 MCP 服务器可用时。

### 避免假设工具被安装

不要假设包可用：

````markdown  theme={null}
**不好的例子：假设安装**：
"使用 pdf 库处理文件。"

**优秀的例子：明确关于依赖项**：
"安装必需的包：`pip install pypdf`

然后使用它：
```python
from pypdf import PdfReader
reader = PdfReader("file.pdf")
```"
````

## 技术说明

### YAML 前置元数据要求

SKILL.md 前置元数据需要 `name`（最多 64 个字符）和 `description`（最多 1024 个字符）字段。关于完整的技能(Skill)结构详情，请参阅[技能(Skill)概述](/en/docs/agents-and-tools/agent-skills/overview#skill-structure)。

### 标记预算

为了获得最佳性能，将 SKILL.md 正文保持在 500 行以下。如果你的内容超过此限制，使用之前描述的渐进式披露模式将其分割成单独的文件。关于架构详情，请参阅[技能(Skill)概述](/en/docs/agents-and-tools/agent-skills/overview#how-skills-work)。

## 有效技能(Skill)的清单

在分享技能(Skill)之前，验证：

### 核心质量

* [ ] 描述具体且包括关键术语
* [ ] 描述包括技能(Skill)的功能和何时使用
* [ ] SKILL.md 正文少于 500 行
* [ ] 其他详情在单独的文件中（如果需要）
* [ ] 没有时间敏感的信息（或在"旧模式"部分）
* [ ] 贯穿始终的一致术语
* [ ] 示例是具体的，而不是抽象的
* [ ] 文件参考是一级深度
* [ ] 渐进式披露恰当使用
* [ ] 工作流有清晰的步骤

### 代码和脚本

* [ ] 脚本解决问题而不是推卸给 Claude
* [ ] 错误处理明确且有帮助
* [ ] 没有"巫术常数"（所有值都被证明）
* [ ] 必需的包在说明中列出并验证为可用
* [ ] 脚本有清晰的文档
* [ ] 没有 Windows 风格的路径（所有前向斜杠）
* [ ] 关键操作的验证/验证步骤
* [ ] 对质量关键任务包括反馈循环

### 测试

* [ ] 至少创建三个评估
* [ ] 用 Haiku、Sonnet 和 Opus 测试
* [ ] 用真实使用场景测试
* [ ] 团队反馈已纳入（如果适用）

## 后续步骤

<CardGroup cols={2}>
  <Card title="开始使用代理(Agent)技能(Skill)" icon="rocket" href="/en/docs/agents-and-tools/agent-skills/quickstart">
    创建你的第一个技能(Skill)
  </Card>

  <Card title="在 Claude Code 中使用技能(Skill)" icon="terminal" href="/en/docs/claude-code/skills">
    在 Claude Code 中创建和管理技能(Skill)
  </Card>

  <Card title="使用 API 的技能(Skill)" icon="code" href="/en/api/skills-guide">
    以编程方式上载和使用技能(Skill)
  </Card>
</CardGroup>
