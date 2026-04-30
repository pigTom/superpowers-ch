# 测试 Superpowers 技能

本文档介绍如何测试 Superpowers 技能，特别是复杂技能（如 `subagent-driven-development`）的集成测试。

## 概述

涉及 subagent、工作流和复杂交互的技能测试需要在无头模式下运行实际的 Claude Code 会话，并通过会话转录验证其行为。

## 测试结构

```
tests/
├── claude-code/
│   ├── test-helpers.sh                    # Shared test utilities
│   ├── test-subagent-driven-development-integration.sh
│   ├── analyze-token-usage.py             # Token analysis tool
│   └── run-skill-tests.sh                 # Test runner (if exists)
```

## 运行测试

### 集成测试

集成测试执行带有实际技能的真实 Claude Code 会话：

```bash
# Run the subagent-driven-development integration test
cd tests/claude-code
./test-subagent-driven-development-integration.sh
```

**注意：** 集成测试可能需要 10-30 分钟，因为它们执行带有多个 subagent 的真实实现计划。

### 需求

- 必须从 **superpowers 插件目录** 运行（不能从临时目录）
- Claude Code 必须已安装且可作为 `claude` 命令使用
- 本地开发市场必须启用：在 `~/.claude/settings.json` 中设置 `"superpowers@superpowers-dev": true`

## 集成测试：subagent-driven-development

### 测试内容

集成测试验证 `subagent-driven-development` 技能是否正确地：

1. **计划加载**：在开始时读取一次计划
2. **完整任务文本**：向 subagent 提供完整的任务描述（不让它们读取文件）
3. **自审查**：确保 subagent 在报告前进行自审查
4. **审查顺序**：在代码质量审查之前运行规范符合性审查
5. **审查循环**：在发现问题时使用审查循环
6. **独立验证**：规范审查者独立阅读代码，不信任实施者的报告

### 工作原理

1. **设置**：创建一个临时 Node.js 项目，包含最小的实现计划
2. **执行**：使用该技能在无头模式下运行 Claude Code
3. **验证**：解析会话转录（`.jsonl` 文件）以验证：
   - 技能工具被调用
   - subagent 被分发（Task 工具）
   - TodoWrite 被用于跟踪
   - 实现文件被创建
   - 测试通过
   - Git 提交显示正确的工作流
4. **令牌分析**：显示按 subagent 分解的令牌使用情况

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

分析来自任何 Claude Code 会话的令牌使用情况：

```bash
python3 tests/claude-code/analyze-token-usage.py ~/.claude/projects/<project-dir>/<session-id>.jsonl
```

### 查找会话文件

会话转录存储在 `~/.claude/projects/` 中，工作目录路径已编码：

```bash
# Example for /Users/jesse/Documents/GitHub/superpowers/superpowers
SESSION_DIR="$HOME/.claude/projects/-Users-jesse-Documents-GitHub-superpowers-superpowers"

# Find recent sessions
ls -lt "$SESSION_DIR"/*.jsonl | head -5
```

### 显示内容

- **主会话使用情况**：协调器（你或主 Claude 实例）的令牌使用情况
- **每个 subagent 分解**：每个 Task 调用，包含：
  - Agent ID
  - 描述（从 prompt 提取）
  - 消息计数
  - 输入/输出令牌
  - 缓存使用情况
  - 估计成本
- **总计**：整体令牌使用和成本估计

### 理解输出

- **高缓存读取**：好——意味着 prompt 缓存工作良好
- **主会话上的高输入令牌**：预期——协调器有完整上下文
- **每个 subagent 的成本相似**：预期——每个都获得相似的任务复杂性
- **每个任务的成本**：典型范围为 $0.05-$0.15 每个 subagent，取决于任务

## 故障排除

### 技能未加载

**问题**：运行无头测试时找不到技能

**解决方案**：
1. 确保从 superpowers 目录运行：`cd /path/to/superpowers && tests/...`
2. 检查 `~/.claude/settings.json` 的 `enabledPlugins` 中是否有 `"superpowers@superpowers-dev": true`
3. 验证技能存在于 `skills/` 目录中

### 权限错误

**问题**：Claude 被阻止写入文件或访问目录

**解决方案**：
1. 使用 `--permission-mode bypassPermissions` 标志
2. 使用 `--add-dir /path/to/temp/dir` 授予对测试目录的访问权限
3. 检查测试目录的文件权限

### 测试超时

**问题**：测试耗时太长而超时

**解决方案**：
1. 增加超时：`timeout 1800 claude ...`（30 分钟）
2. 检查技能逻辑中是否存在无限循环
3. 审查 subagent 任务复杂性

### 找不到会话文件

**问题**：测试运行后找不到会话转录

**解决方案**：
1. 检查 `~/.claude/projects/` 中的正确项目目录
2. 使用 `find ~/.claude/projects -name "*.jsonl" -mmin -60` 查找最近的会话
3. 验证测试实际运行（检查测试输出中的错误）

## 编写新的集成测试

### 模板

```bash
#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/test-helpers.sh"

# Create test project
TEST_PROJECT=$(create_test_project)
trap "cleanup_test_project $TEST_PROJECT" EXIT

# Set up test files...
cd "$TEST_PROJECT"

# Run Claude with skill
PROMPT="Your test prompt here"
cd "$SCRIPT_DIR/../.." && timeout 1800 claude -p "$PROMPT" \
  --allowed-tools=all \
  --add-dir "$TEST_PROJECT" \
  --permission-mode bypassPermissions \
  2>&1 | tee output.txt

# Find and analyze session
WORKING_DIR_ESCAPED=$(echo "$SCRIPT_DIR/../.." | sed 's/\\//-/g' | sed 's/^-//')
SESSION_DIR="$HOME/.claude/projects/$WORKING_DIR_ESCAPED"
SESSION_FILE=$(find "$SESSION_DIR" -name "*.jsonl" -type f -mmin -60 | sort -r | head -1)

# Verify behavior by parsing session transcript
if grep -q '"name":"Skill".*"skill":"your-skill-name"' "$SESSION_FILE"; then
    echo "[PASS] Skill was invoked"
fi

# Show token analysis
python3 "$SCRIPT_DIR/analyze-token-usage.py" "$SESSION_FILE"
```

### 最佳实践

1. **始终清理**：使用 trap 清理临时目录
2. **解析转录**：不要 grep 用户界面输出——解析 `.jsonl` 会话文件
3. **授予权限**：使用 `--permission-mode bypassPermissions` 和 `--add-dir`
4. **从插件目录运行**：技能只在从 superpowers 目录运行时加载
5. **显示令牌使用情况**：始终包含令牌分析以获得成本可见性
6. **测试真实行为**：验证实际创建的文件、通过的测试、创建的提交

## 会话转录格式

会话转录是 JSONL（JSON Lines）文件，其中每一行是代表消息或工具结果的 JSON 对象。

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

`agentId` 字段链接到 subagent 会话，`usage` 字段包含该特定 subagent 调用的令牌使用情况。
