# 深度防御验证

## 概述

当你修复由无效数据引起的漏洞时，在一个地方添加验证似乎已经足够。但这个单一检查可能被不同的代码路径、重构或模拟绕过。

**核心原则：** 在数据经过的每一层都进行验证。让漏洞在结构上变得不可能。

## 为什么需要多层

单层验证："我们修复了漏洞"
多层验证："我们让漏洞变成不可能"

不同的层捕获不同的情况：
- 入口验证捕获大多数漏洞
- 业务逻辑捕获边界情况
- 环境守卫防止特定于上下文的危险
- 调试日志在其他层失败时提供帮助

## 四层结构

### 层1：入口点验证
**目的：** 在应用程序接口(API)边界拒绝明显无效的输入

```typescript
function createProject(name: string, workingDirectory: string) {
  if (!workingDirectory || workingDirectory.trim() === '') {
    throw new Error('workingDirectory cannot be empty');
  }
  if (!existsSync(workingDirectory)) {
    throw new Error(`workingDirectory does not exist: ${workingDirectory}`);
  }
  if (!statSync(workingDirectory).isDirectory()) {
    throw new Error(`workingDirectory is not a directory: ${workingDirectory}`);
  }
  // ... proceed
}
```

### 层2：业务逻辑验证
**目的：** 确保数据对该操作有意义

```typescript
function initializeWorkspace(projectDir: string, sessionId: string) {
  if (!projectDir) {
    throw new Error('projectDir required for workspace initialization');
  }
  // ... proceed
}
```

### 层3：环境守卫
**目的：** 防止在特定上下文中进行危险操作

```typescript
async function gitInit(directory: string) {
  // In tests, refuse git init outside temp directories
  if (process.env.NODE_ENV === 'test') {
    const normalized = normalize(resolve(directory));
    const tmpDir = normalize(resolve(tmpdir()));

    if (!normalized.startsWith(tmpDir)) {
      throw new Error(
        `Refusing git init outside temp dir during tests: ${directory}`
      );
    }
  }
  // ... proceed
}
```

### 层4：调试仪表

**目的：** 为取证捕获上下文

```typescript
async function gitInit(directory: string) {
  const stack = new Error().stack;
  logger.debug('About to git init', {
    directory,
    cwd: process.cwd(),
    stack,
  });
  // ... proceed
}
```

## 应用这个模式

当你发现漏洞时：

1. **跟踪数据流** - 坏值来自哪里？在哪里使用？
2. **映射所有检查点** - 列出数据经过的每个点
3. **在每一层添加验证** - 入口、业务、环境、调试
4. **测试每一层** - 尝试绕过第1层，验证第2层捕获它

## 会话中的示例

漏洞：空的`projectDir`导致在源代码中运行`git init`

**数据流：**
1. 测试设置 → 空字符串
2. `Project.create(name, '')`
3. `WorkspaceManager.createWorkspace('')`
4. `git init`在`process.cwd()`中运行

**添加的四层：**
- 层1：`Project.create()`验证不为空/存在/可写
- 层2：`WorkspaceManager`验证projectDir不为空
- 层3：`WorktreeManager`在测试中拒绝在tmpdir之外进行git init
- 层4：在git init之前的堆栈跟踪日志

**结果：** 所有1847个测试通过，漏洞不可能重现

## 关键洞察

所有四层都是必要的。在测试中，每一层都捕获了其他层遗漏的漏洞：
- 不同的代码路径绕过了入口验证
- 模拟绕过了业务逻辑检查
- 不同平台上的边界情况需要环境守卫
- 调试日志识别了结构性滥用

**不要只在一个验证点停止。** 在每一层添加检查。
