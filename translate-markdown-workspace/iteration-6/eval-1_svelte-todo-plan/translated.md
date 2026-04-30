# Svelte 待办列表 - 实现计划

使用 `superpowers:subagent-driven-development` 技能执行此计划。

## 上下文

使用 Svelte 构建待办列表应用。详细规范请参见 `design.md`。

## 任务

### 任务 1：项目设置

使用 Vite 创建 Svelte 项目。

**执行：**
- 运行 `npm create vite@latest . -- --template svelte-ts`
- 使用 `npm install` 安装依赖
- 验证开发服务器是否正常工作
- 从 App.svelte 中清理默认 Vite 模板内容

**验证：**
- `npm run dev` 启动服务器
- 应用显示最小化的 "Svelte Todos" 标题
- `npm run build` 成功

---

### 任务 2：待办列表存储

为待办列表状态管理创建 Svelte 存储。

**执行：**
- 创建 `src/lib/store.ts`
- 定义 `Todo` 接口，包含 id、text、completed
- 创建可写存储，初始值为空数组
- 导出函数：`addTodo(text)`、`toggleTodo(id)`、`deleteTodo(id)`、`clearCompleted()`
- 创建 `src/lib/store.test.ts`，为每个函数编写测试

**验证：**
- 测试通过：`npm run test`（如果需要，安装 vitest）

---

### 任务 3：localStorage 持久化

为待办列表添加持久化层。

**执行：**
- 创建 `src/lib/storage.ts`
- 实现 `loadTodos(): Todo[]` 和 `saveTodos(todos: Todo[])`
- 优雅处理 JSON 解析错误（返回空数组）
- 与存储集成：初始化时加载，更改时保存
- 为加载/保存/错误处理添加测试

**验证：**
- 测试通过
- 手动测试：添加待办事项，刷新页面，待办事项持久化

---

### 任务 4：TodoInput 组件

为添加待办事项创建输入组件。

**执行：**
- 创建 `src/lib/TodoInput.svelte`
- 文本输入绑定到本地状态
- 添加按钮调用 `addTodo()` 并清空输入框
- Enter 键也可提交
- 输入框为空时禁用添加按钮
- 添加组件测试

**验证：**
- 测试通过
- 组件渲染输入框和按钮

---

### 任务 5：TodoItem 组件

创建单个待办事项组件。

**执行：**
- 创建 `src/lib/TodoItem.svelte`
- 属性：`todo: Todo`
- 复选框切换完成状态（调用 `toggleTodo`）
- 完成时带删除线的文本
- 删除按钮（X）调用 `deleteTodo`
- 添加组件测试

**验证：**
- 测试通过
- 组件渲染复选框、文本、删除按钮

---

### 任务 6：TodoList 组件

创建列表容器组件。

**执行：**
- 创建 `src/lib/TodoList.svelte`
- 属性：`todos: Todo[]`
- 为每个待办事项渲染 TodoItem
- 列表为空时显示 "No todos yet"
- 添加组件测试

**验证：**
- 测试通过
- 组件渲染 TodoItems 列表

---

### 任务 7：FilterBar 组件

创建过滤和状态栏组件。

**执行：**
- 创建 `src/lib/FilterBar.svelte`
- 属性：`todos: Todo[]`、`filter: Filter`、`onFilterChange: (f: Filter) => void`
- 显示计数："X items left"（未完成计数）
- 三个过滤按钮：All、Active、Completed
- 活跃过滤按钮被视觉突出显示
- "Clear completed" 按钮（无完成的待办事项时隐藏）
- 添加组件测试

**验证：**
- 测试通过
- 组件渲染计数、过滤器、清空按钮

---

### 任务 8：应用集成

在 App.svelte 中连接所有组件。

**执行：**
- 导入所有组件和存储
- 添加过滤状态（默认：'all'）
- 根据过滤状态计算过滤后的待办事项
- 渲染：标题、TodoInput、TodoList、FilterBar
- 向每个组件传递适当的属性

**验证：**
- 应用渲染所有组件
- 添加待办事项有效
- 切换有效
- 删除有效

---

### 任务 9：过滤功能

确保过滤端到端工作。

**执行：**
- 验证过滤按钮是否改变显示的待办事项
- 'all' 显示所有待办事项
- 'active' 仅显示未完成的待办事项
- 'completed' 仅显示已完成的待办事项
- 清空已完成的项目会移除已完成项目，如果需要则重置过滤
- 添加集成测试

**验证：**
- 过滤测试通过
- 手动验证所有过滤状态

---

### 任务 10：样式和优化

添加 CSS 样式以提高可用性。

**执行：**
- 对应用进行样式设计，以匹配设计模型
- 已完成的待办事项具有删除线和暗淡颜色
- 活跃过滤按钮被突出显示
- 输入框具有焦点样式
- 删除按钮在悬停时出现（或始终在移动设备上显示）
- 响应式布局

**验证：**
- 应用视觉上可用
- 样式不破坏功能

---

### 任务 11：端到端测试

为完整的用户流程添加 Playwright 测试。

**执行：**
- 安装 Playwright：`npm init playwright@latest`
- 创建 `tests/todo.spec.ts`
- 测试流程：
  - 添加待办事项
  - 完成待办事项
  - 删除待办事项
  - 过滤待办事项
  - 清空已完成的
  - 持久化（添加、重新加载、验证）

**验证：**
- `npx playwright test` 通过

---

### 任务 12：README

记录项目。

**执行：**
- 创建 `README.md`，包含：
  - 项目描述
  - 设置：`npm install`
  - 开发：`npm run dev`
  - 测试：`npm test` 和 `npx playwright test`
  - 构建：`npm run build`

**验证：**
- README 准确描述项目
- 说明有效

