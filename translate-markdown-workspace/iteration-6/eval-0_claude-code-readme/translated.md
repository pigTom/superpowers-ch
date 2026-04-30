# Claude Code 技能(skill)测试

使用 Claude Code 命令行界面(CLI)对 superpowers 插件(plugin)进行自动化测试。

## 概述

此测试套件验证技能(skill)是否正确加载以及 Claude 是否按预期遵循它们。测试以无头(headless)模式(`claude -p`)调用 Claude Code 并验证行为。

## 需求

- 已安装 Claude Code 命令行界面(CLI)并在 PATH 中(`claude --version` 应该有效)
- 已安装本地 superpowers 插件(plugin)(详见主 README 的安装说明)

## 运行测试

### 运行所有快速测试(推荐):
```bash
./run-skill-tests.sh
```

### 运行集成测试(速度慢，10-30 分钟):
```bash
./run-skill-tests.sh --integration
```

### 运行特定测试:
```bash
./run-skill-tests.sh --test test-subagent-driven-development.sh
```

### 运行详细输出:
```bash
./run-skill-tests.sh --verbose
```

### 设置自定义超时:
```bash
./run-skill-tests.sh --timeout 1800  # 30 minutes for integration tests
```

## 测试结构

### test-helpers.sh
技能(skill)测试的通用函数:
- `run_claude "prompt" [timeout]` - 使用 prompt 运行 Claude
- `assert_contains output pattern name` - 验证 pattern 存在
- `assert_not_contains output pattern name` - 验证 pattern 不存在
- `assert_count output pattern count name` - 验证精确计数
- `assert_order output pattern_a pattern_b name` - 验证顺序
- `create_test_project` - 创建临时测试目录
- `create_test_plan project_dir` - 创建示例 plan 文件

### 测试文件

每个测试文件:
1. 导入 `test-helpers.sh`
2. 用特定的 prompt 运行 Claude Code
3. 使用 assertions 验证预期行为
4. 成功时返回 0，失败时返回非零

## 示例测试

```bash
#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/test-helpers.sh"

echo "=== Test: My Skill ==="

# Ask Claude about the skill
output=$(run_claude "What does the my-skill skill do?" 30)

# Verify response
assert_contains "$output" "expected behavior" "Skill describes behavior"

echo "=== All tests passed ==="
```

## 当前测试

### 快速测试(默认运行)

#### test-subagent-driven-development.sh
测试技能(skill)内容和需求(约 2 分钟):
- 技能(skill)加载和可访问性
- 工作流排序(规范合规性优于代码质量)
- 自审查要求已记录
- 计划读取效率已记录
- 规范合规性审查者怀疑态度已记录
- 审查循环已记录
- 任务上下文提供已记录

### 集成测试(使用 --integration 标志)

#### test-subagent-driven-development-integration.sh
完整工作流执行测试(约 10-30 分钟):
- 使用 Node.js 设置创建真实测试项目
- 使用 2 个任务创建实现计划
- 使用子代理驱动开发(subagent-driven-development)执行计划
- 验证实际行为:
  - 在开始时读取一次计划(不是每个任务)
  - 在子代理(subagent)提示中提供完整任务文本
  - 子代理(subagent)在报告前执行自审查
  - 规范合规性审查发生在代码质量审查之前
  - 规范审查者独立读取代码
  - 生成有效的实现
  - 测试通过
  - 创建适当的 git 提交

**它测试的内容:**
- 工作流实际上端到端工作
- 我们的改进实际上已应用
- 子代理(subagent)正确遵循技能(skill)
- 最终代码是有效的和经过测试的

## 添加新测试

1. 创建新测试文件: `test-<skill-name>.sh`
2. 导入 test-helpers.sh
3. 使用 `run_claude` 和 assertions 编写测试
4. 添加到 `run-skill-tests.sh` 中的测试列表
5. 使其可执行: `chmod +x test-<skill-name>.sh`

## 超时考虑

- 默认超时: 每个测试 5 分钟
- Claude Code 可能需要时间响应
- 如果需要，使用 `--timeout` 调整
- 测试应该集中以避免长时间运行

## 调试失败的测试

使用 `--verbose`，您将看到完整的 Claude 输出:
```bash
./run-skill-tests.sh --verbose --test test-subagent-driven-development.sh
```

没有详细模式，只有失败会显示输出。

## 持续集成/持续部署(CI/CD)集成

在 CI 中运行:
```bash
# Run with explicit timeout for CI environments
./run-skill-tests.sh --timeout 900

# Exit code 0 = success, non-zero = failure
```

## 备注

- 测试验证技能(skill)*说明*，不是完整执行
- 完整工作流测试会非常慢
- 重点验证关键技能(skill)需求
- 测试应该是确定性的
- 避免测试实现细节
