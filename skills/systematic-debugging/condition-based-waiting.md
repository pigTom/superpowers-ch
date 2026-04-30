# 基于条件的等待

## 概述

不稳定的测试经常用任意延迟来猜测时序，这会造成竞态条件，使得测试在快速机器上通过，但在负载下或CI环境中失败。

**核心原则：** 等待你真正关心的条件，而不是猜测它需要多长时间。

## 使用时机

```dot
digraph when_to_use {
    "Test uses setTimeout/sleep?" [shape=diamond];
    "Testing timing behavior?" [shape=diamond];
    "Document WHY timeout needed" [shape=box];
    "Use condition-based waiting" [shape=box];

    "Test uses setTimeout/sleep?" -> "Testing timing behavior?" [label="yes"];
    "Testing timing behavior?" -> "Document WHY timeout needed" [label="yes"];
    "Testing timing behavior?" -> "Use condition-based waiting" [label="no"];
}
```

**使用场景：**
- 测试包含任意延迟（`setTimeout`、`sleep`、`time.sleep()`）
- 测试不稳定（有时通过，负载下失败）
- 并行运行时测试超时
- 等待异步操作完成

**不适用于：**
- 测试实际的时序行为（防抖、节流间隔）
- 如果使用任意超时，总是要文档说明原因

## 核心模式

```typescript
// ❌ BEFORE: Guessing at timing
await new Promise(r => setTimeout(r, 50));
const result = getResult();
expect(result).toBeDefined();

// ✅ AFTER: Waiting for condition
await waitFor(() => getResult() !== undefined);
const result = getResult();
expect(result).toBeDefined();
```

## 快速模式

| 场景 | 模式 |
|----------|---------|
| 等待事件 | `waitFor(() => events.find(e => e.type === 'DONE'))` |
| 等待状态 | `waitFor(() => machine.state === 'ready')` |
| 等待计数 | `waitFor(() => items.length >= 5)` |
| 等待文件 | `waitFor(() => fs.existsSync(path))` |
| 复杂条件 | `waitFor(() => obj.ready && obj.value > 10)` |

## 实现

通用轮询函数：
```typescript
async function waitFor<T>(
  condition: () => T | undefined | null | false,
  description: string,
  timeoutMs = 5000
): Promise<T> {
  const startTime = Date.now();

  while (true) {
    const result = condition();
    if (result) return result;

    if (Date.now() - startTime > timeoutMs) {
      throw new Error(`Timeout waiting for ${description} after ${timeoutMs}ms`);
    }

    await new Promise(r => setTimeout(r, 10)); // Poll every 10ms
  }
}
```

参阅本目录中的 `condition-based-waiting-example.ts`，了解完整实现和域特定的助手函数（`waitForEvent`、`waitForEventCount`、`waitForEventMatch`），这些来自实际的调试会话。

## 常见错误

**❌ 轮询过于频繁：** `setTimeout(check, 1)` - 浪费CPU
**✅ 修复：** 每10ms轮询一次

**❌ 没有超时：** 如果条件永不满足，循环永不结束
**✅ 修复：** 始终包含超时，并清楚地报告错误

**❌ 数据过时：** 在循环前缓存状态
**✅ 修复：** 在循环内调用getter，获取新鲜数据

## 何时任意超时是正确的

```typescript
// Tool ticks every 100ms - need 2 ticks to verify partial output
await waitForEvent(manager, 'TOOL_STARTED'); // First: wait for condition
await new Promise(r => setTimeout(r, 200));   // Then: wait for timed behavior
// 200ms = 2 ticks at 100ms intervals - documented and justified
```

**要求：**
1. 首先等待触发条件
2. 基于已知的时序（而不是猜测）
3. 注释说明原因

## 真实世界的影响

来自调试会话（2025-10-03）：
- 修复了3个文件中的15个不稳定测试
- 通过率：60% → 100%
- 执行时间：快40%
- 不再有竞态条件
