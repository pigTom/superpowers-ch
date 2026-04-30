# 测试Superpowers Skills

本文档描述了如何测试Superpowers skills，特别是复杂skills（如`subagent-driven-development`）的集成测试。

## 概述

涉及subagents、工作流和复杂交互的skills测试需要在无头模式下运行实际的Claude Code会话，并通过会话转录来验证其行为。

## 测试结构

```
tests/
├── claude-code/
│   ├── test-helpers.sh                    # 共享测试工具
│   ├── test-subagent-driven-development-integration.sh
│   ├── analyze-token-usage.py             # 令牌分析工具
│   └── run-skill-tests.sh                 # 测试运行器（如果存在）
```

## 运行测试

### 集成测试

集成测试执行带有实际skills的真实Claude Code会话：

```bash
# 运行subagent-driven-development集成测试
cd tests/claude-code
./test-subagent-driven-development-integration.sh
```

**注意：** 集成测试可能需要10-30分钟，因为它们执行具有多个subagents的实际实现计划。

### 需求

- 必须从**superpowers插件目录**运行（不能从临时目录）
- Claude Code必须已安装并可作为`claude`命令使用
- 本地开发marketplace必须启用：`~/.claude/settings.json`中的`"superpowers@superpowers-dev": true`

## 集成测试：subagent-driven-development

### 测试内容

集成测试验证`subagent-driven-development` skill是否正确：

1. **计划加载**：在开始时读取计划一次
2. **完整任务文本**：向subagents提供完整的任务描述（不让它们读取文件）
3. **自审查**：确保subagents在报告前进行自审查
4. **审查顺序**：在代码质量审查之前运行规范合规性审查
5. **审查循环**：发现问题时使用审查循环
6. **独立验证**：规范审查员独立阅读代码，不信任实现者报告

### 工作方式

1. **设置**：使用最小实现计划创建临时Node.js项目
2. **执行**：使用该skill在无头模式下运行Claude Code
3. **验证**：解析会话转录（`.jsonl`文件）以验证：
   - Skill工具已调用
   - Subagents已分派（Task工具）
   - 使用了TodoWrite进行跟踪
   - 实现文件已创建
   - 测试通过
   - Git提交显示正确的工作流
4. **令牌分析**：按subagent显示令牌使用情况细目

### 测试输出

```
========================================
 Integration Test: subagent-driven-development
========================================

Test project: /tmp/tmp.xyz123

=== Verification Tests ===

Test 1: Skill tool invoked...
  [PASS] subagent-driven-development skill was invoked

Test 2: Subagents dispatched...
  [PASS] 7 subagents dispatched

Test 3: Task tracking...
  [PASS] TodoWrite used 5 time(s)

Test 6: Implementation verification...
  [PASS] src/math.js created
  [PASS] add function exists
  [PASS] multiply function exists
  [PASS] test/math.test.js created
  [PASS] Tests pass

Test 7: Git commit history...
  [PASS] Multiple commits created (3 total)

Test 8: No extra features added...
  [PASS] No extra features added

=========================================
 Token Usage Analysis
=========================================

Usage Breakdown:
----------------------------------------------------------------------------------------------------
Agent           Description                          Msgs      Input     Output      Cache     Cost
----------------------------------------------------------------------------------------------------
main            Main session (coordinator)             34         27      3,996  1,213,703 $   4.09
3380c209        implementing Task 1: Create Add Function     1          2        787     24,989 $   0.09
34b00fde        implementing Task 2: Create Multiply Function     1          4        644     25,114 $   0.09
3801a732        reviewing whether an implementation matches...   1          5        703     25,742 $   0.09
4c142934        doing a final code review...                    1          6        854     25,319 $   0.09
5f017a42        a code reviewer. Review Task 2...               1          6        504     22,949 $   0.08
a6b7fbe4        a code reviewer. Review Task 1...               1          6        515     22,534 $   0.08
f15837c0        reviewing whether an implementation matches...   1          6        416     22,485 $   0.07
----------------------------------------------------------------------------------------------------

TOTALS:
  Total messages:         41
  Input tokens:           62
  Output tokens:          8,419
  Cache creation tokens:  132,742
  Cache read tokens:      1,382,835

  Total input (incl cache): 1,515,639
  Total tokens:             1,524,058

  Estimated cost: $4.67
  (at $3/$15 per M tokens for input/output)

========================================
 Test Summary
========================================

STATUS: PASSED
```

## 令牌分析工具

### 用法

分析任何Claude Code会话的令牌使用情况：

```bash
python3 tests/claude-code/analyze-token-usage.py ~/.claude/projects/<project-dir>/<session-id>.jsonl
```

### 查找会话文件

会话转录存储在`~/.claude/projects/`中，工作目录路径已编码：

```bash
# 示例：/Users/jesse/Documents/GitHub/superpowers/superpowers
SESSION_DIR="$HOME/.claude/projects/-Users-jesse-Documents-GitHub-superpowers-superpowers"

# 查找最近的会话
ls -lt "$SESSION_DIR"/*.jsonl | head -5
```

### 显示内容

- **主会话使用情况**：协调者（你或主Claude实例）的令牌使用情况
- **按subagent的细目**：每个Task调用包括：
  - Agent ID
  - 描述（从提示中提取）
  - 消息计数
  - 输入/输出令牌
  - 缓存使用情况
  - 预估成本
- **总计**：总体令牌使用情况和成本估计

### 理解输出

- **高缓存读取**：好的迹象，表示提示缓存正在工作
- **主会话中的高输入令牌**：预期现象，协调者拥有完整的上下文
- **每个subagent的相似成本**：预期现象，每个都获得类似的任务复杂性
- **每个任务的成本**：典型范围是每个subagent $0.05-$0.15，取决于任务

## 故障排除

### Skills未加载

**问题**：运行无头测试时未找到skill

**解决方案**：
1. 确保从superpowers目录运行：`cd /path/to/superpowers && tests/...`
2. 检查`~/.claude/settings.json`的`enabledPlugins`中是否有`"superpowers@superpowers-dev": true`
3. 验证skill是否存在于`skills/`目录中

### 权限错误

**问题**：Claude被阻止写入文件或访问目录

**解决方案**：
1. 使用`--permission-mode bypassPermissions`标志
2. 使用`--add-dir /path/to/temp/dir`授予对测试目录的访问权限
3. 检查测试目录的文件权限

### 测试超时

**问题**：测试耗时过长并超时

**解决方案**：
1. 增加超时时间：`timeout 1800 claude ...`（30分钟）
2. 检查skill逻辑中的无限循环
3. 检查subagent任务复杂性

### 会话文件未找到

**问题**：测试运行后找不到会话转录

**解决方案**：
1. 检查`~/.claude/projects/`中的正确项目目录
2. 使用`find ~/.claude/projects -name "*.jsonl" -mmin -60`查找最近的会话
3. 验证测试实际运行（检查测试输出中的错误）

## 编写新的集成测试

### 模板

```bash
#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/test-helpers.sh"

# 创建测试项目
TEST_PROJECT=$(create_test_project)
trap "cleanup_test_project $TEST_PROJECT" EXIT

# 设置测试文件...
cd "$TEST_PROJECT"

# 使用skill运行Claude
PROMPT="Your test prompt here"
cd "$SCRIPT_DIR/../.." && timeout 1800 claude -p "$PROMPT" \
  --allowed-tools=all \
  --add-dir "$TEST_PROJECT" \
  --permission-mode bypassPermissions \
  2>&1 | tee output.txt

# 查找并分析会话
WORKING_DIR_ESCAPED=$(echo "$SCRIPT_DIR/../.." | sed 's/\\//-/g' | sed 's/^-//')
SESSION_DIR="$HOME/.claude/projects/$WORKING_DIR_ESCAPED"
SESSION_FILE=$(find "$SESSION_DIR" -name "*.jsonl" -type f -mmin -60 | sort -r | head -1)

# 通过解析会话转录验证行为
if grep -q '"name":"Skill".*"skill":"your-skill-name"' "$SESSION_FILE"; then
    echo "[PASS] Skill was invoked"
fi

# 显示令牌分析
python3 "$SCRIPT_DIR/analyze-token-usage.py" "$SESSION_FILE"
```

### 最佳实践

1. **始终清理**：使用trap清理临时目录
2. **解析转录**：不要grep用户界面输出，解析`.jsonl`会话文件
3. **授予权限**：使用`--permission-mode bypassPermissions`和`--add-dir`
4. **从插件目录运行**：Skills仅在从superpowers目录运行时加载
5. **显示令牌使用情况**：始终包含令牌分析以提供成本可见性
6. **测试真实行为**：验证实际创建的文件、通过的测试、提交的代码

## 会话转录格式

会话转录是JSONL（JSON Lines）文件，其中每一行是表示消息或工具结果的JSON对象。

### 关键字段

```json
{
  "type": "assistant",
  "message": {
    "content": [...],
    "usage": {
      "input_tokens": 27,
      "output_tokens": 3996,
      "cache_read_input_tokens": 1213703
    }
  }
}
```

### 工具结果

```json
{
  "type": "user",
  "toolUseResult": {
    "agentId": "3380c209",
    "usage": {
      "input_tokens": 2,
      "output_tokens": 787,
      "cache_read_input_tokens": 24989
    },
    "prompt": "You are implementing Task 1...",
    "content": [{"type": "text", "text": "..."}]
  }
}
```

`agentId`字段链接到subagent会话，`usage`字段包含该特定subagent调用的令牌使用情况。
