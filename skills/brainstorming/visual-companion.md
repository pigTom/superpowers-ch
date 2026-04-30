# 可视化助手指南

基于浏览器的可视化头脑风暴助手，用于展示原型、图表和选项。

## 何时使用

逐个问题决定，而非按会话决定。测试标准：**用户通过看到它而不是读取它能更好地理解吗？**

**在以下情况使用浏览器**（内容本身是可视化的）：

- **UI 原型** — 线框图、布局、导航结构、组件设计
- **架构图** — 系统组件、数据流、关系图
- **并列可视化比较** — 比较两个布局、两个配色方案、两个设计方向
- **设计润饰** — 当问题涉及外观、间距、视觉层级时
- **空间关系** — 状态机、流程图、以图表形式呈现的实体关系

**在以下情况使用终端**（内容是文本或表格）：

- **需求和范围问题** — "X 是什么意思？"、"哪些功能在范围内？"
- **概念 A/B/C 选择** — 在用文字描述的方法之间选择
- **权衡列表** — 优点/缺点、比较表格
- **技术决策** — API 设计、数据建模、架构方法选择
- **澄清问题** — 任何答案是文字而非可视化偏好的情况

关于 UI 主题的问题不一定是可视化问题。"你想要什么样的向导？"是概念问题 — 使用终端。"这些向导布局中哪个感觉合适？"是可视化问题 — 使用浏览器。

## 工作原理

服务器监视目录中的 HTML 文件，并将最新的文件提供给浏览器。你将 HTML 内容写入 `screen_dir`，用户在浏览器中看到它并可以点击选择选项。选择被记录到 `state_dir/events` 中，你可以在下一轮读取。

**内容片段与完整文档：** 如果你的 HTML 文件以 `<!DOCTYPE` 或 `<html` 开头，服务器会按原样提供（只注入助手脚本）。否则，服务器会自动将内容包装在框架模板中 — 添加页头、CSS 主题、选择指示器和所有交互基础设施。**默认写入内容片段。** 只有在需要完全控制页面时才写入完整文档。

## 启动会话

```bash
# 使用持久化启动服务器（模型保存到项目）
scripts/start-server.sh --project-dir /path/to/project

# 返回：{"type":"server-started","port":52341,"url":"http://localhost:52341",
#           "screen_dir":"/path/to/project/.superpowers/brainstorm/12345-1706000000/content",
#           "state_dir":"/path/to/project/.superpowers/brainstorm/12345-1706000000/state"}
```

从响应中保存 `screen_dir` 和 `state_dir`。告诉用户打开 URL。

**查找连接信息：** 服务器将启动 JSON 写入 `$STATE_DIR/server-info`。如果你在后台启动了服务器但未捕获 stdout，读取该文件以获取 URL 和端口。使用 `--project-dir` 时，检查 `<project>/.superpowers/brainstorm/` 中的会话目录。

**注意：** 将项目根目录作为 `--project-dir` 传递，以便模型在 `.superpowers/brainstorm/` 中持久化并在服务器重新启动时存活。否则，文件会进入 `/tmp` 并被清理。提醒用户将 `.superpowers/` 添加到 `.gitignore`（如果还没有的话）。

**按平台启动服务器：**

**Claude Code（macOS / Linux）：**
```bash
# 默认模式有效 — 脚本自身后台运行服务器
scripts/start-server.sh --project-dir /path/to/project
```

**Claude Code（Windows）：**
```bash
# Windows 自动检测并使用前台模式，这会阻塞工具调用。
# 在 Bash 工具调用中设置 run_in_background: true，使服务器在
# 对话轮之间存活。
scripts/start-server.sh --project-dir /path/to/project
```
调用此工具时，设置 `run_in_background: true`。然后在下一轮读取 `$STATE_DIR/server-info` 获取 URL 和端口。

**Codex：**
```bash
# Codex 会回收后台进程。脚本自动检测 CODEX_CI 并
# 切换到前台模式。正常运行它 — 不需要额外标志。
scripts/start-server.sh --project-dir /path/to/project
```

**Gemini CLI：**
```bash
# 使用 --foreground 并在 shell 工具调用中设置 is_background: true
# 使进程在轮之间存活
scripts/start-server.sh --project-dir /path/to/project --foreground
```

**其他环境：** 服务器必须在后台运行以在对话轮之间保持运行。如果你的环境会回收分离的进程，使用 `--foreground` 并使用平台的后台执行机制启动命令。

如果浏览器无法访问 URL（在远程/容器化设置中很常见），绑定非环回主机：

```bash
scripts/start-server.sh \
  --project-dir /path/to/project \
  --host 0.0.0.0 \
  --url-host localhost
```

使用 `--url-host` 来控制在返回的 URL JSON 中打印什么主机名。

## 循环

1. **检查服务器是否活跃**，然后**将 HTML 写入** `screen_dir` 中的新文件：
   - 在每次写入前，检查 `$STATE_DIR/server-info` 是否存在。如果不存在（或存在 `$STATE_DIR/server-stopped`），服务器已关闭 — 继续前先用 `start-server.sh` 重新启动。服务器在 30 分钟无活动后自动退出。
   - 使用语义文件名：`platform.html`、`visual-style.html`、`layout.html`
   - **永不重用文件名** — 每个屏幕都需要一个新文件
   - 使用 Write 工具 — **永远不要使用 cat/heredoc**（向终端倾倒噪音）
   - 服务器自动提供最新文件

2. **告诉用户期望什么并结束你的轮：**
   - 提醒他们 URL（每一步，而不仅仅是第一步）
   - 简要总结屏幕上的内容（例如，"显示主页的 3 个布局选项"）
   - 询问他们在终端中回应："看一下，让我知道你的想法。如果你想要，点击选择一个选项。"

3. **在下一轮** — 在用户在终端中回应后：
   - 如果存在，读取 `$STATE_DIR/events` — 这包含用户的浏览器交互（点击、选择）为 JSON 行
   - 与用户的终端文本合并以获得全面理解
   - 终端消息是主要反馈；`state_dir/events` 提供结构化交互数据

4. **迭代或前进** — 如果反馈改变当前屏幕，写一个新文件（例如，`layout-v2.html`）。仅当当前步骤得到验证时才移动到下一个问题。

5. **返回终端时卸载** — 当下一步不需要浏览器时（例如，澄清问题、权衡讨论），推送等待屏幕以清除陈旧内容：

   ```html
   <!-- 文件名：waiting.html（或 waiting-2.html 等） -->
   <div style="display:flex;align-items:center;justify-content:center;min-height:60vh">
     <p class="subtitle">在终端中继续...</p>
   </div>
   ```

   这可防止用户在对话已经进行下去时盯着已解决的选择。当下一个可视化问题出现时，像往常一样推送新的内容文件。

6. 重复直到完成。

## 编写内容片段

只编写进入页面的内容。服务器会自动将其包装在框架模板中（页头、主题 CSS、选择指示器和所有交互基础设施）。

**最小示例：**

```html
<h2>哪个布局更合适？</h2>
<p class="subtitle">考虑可读性和视觉层级</p>

<div class="options">
  <div class="option" data-choice="a" onclick="toggleSelect(this)">
    <div class="letter">A</div>
    <div class="content">
      <h3>单列</h3>
      <p>清晰、专注的阅读体验</p>
    </div>
  </div>
  <div class="option" data-choice="b" onclick="toggleSelect(this)">
    <div class="letter">B</div>
    <div class="content">
      <h3>双列</h3>
      <p>侧边栏导航和主要内容</p>
    </div>
  </div>
</div>
```

就是这样。不需要 `<html>`、CSS 或 `<script>` 标签。服务器提供所有这些。

## 可用的 CSS 类

框架模板为你的内容提供这些 CSS 类：

### 选项（A/B/C 选择）

```html
<div class="options">
  <div class="option" data-choice="a" onclick="toggleSelect(this)">
    <div class="letter">A</div>
    <div class="content">
      <h3>标题</h3>
      <p>描述</p>
    </div>
  </div>
</div>
```

**多选：** 在容器中添加 `data-multiselect` 以让用户选择多个选项。每次点击切换项。指示器条显示计数。

```html
<div class="options" data-multiselect>
  <!-- 相同的选项标记 — 用户可以选择/取消选择多个 -->
</div>
```

### 卡片（可视化设计）

```html
<div class="cards">
  <div class="card" data-choice="design1" onclick="toggleSelect(this)">
    <div class="card-image"><!-- 模型内容 --></div>
    <div class="card-body">
      <h3>名称</h3>
      <p>描述</p>
    </div>
  </div>
</div>
```

### 模型容器

```html
<div class="mockup">
  <div class="mockup-header">预览：仪表板布局</div>
  <div class="mockup-body"><!-- 你的模型 HTML --></div>
</div>
```

### 分割视图（并排）

```html
<div class="split">
  <div class="mockup"><!-- 左侧 --></div>
  <div class="mockup"><!-- 右侧 --></div>
</div>
```

### 优点/缺点

```html
<div class="pros-cons">
  <div class="pros"><h4>优点</h4><ul><li>优势</li></ul></div>
  <div class="cons"><h4>缺点</h4><ul><li>劣势</li></ul></div>
</div>
```

### 模型元素（线框构建块）

```html
<div class="mock-nav">标志 | 主页 | 关于 | 联系</div>
<div style="display: flex;">
  <div class="mock-sidebar">导航</div>
  <div class="mock-content">主要内容区域</div>
</div>
<button class="mock-button">操作按钮</button>
<input class="mock-input" placeholder="输入字段">
<div class="placeholder">占位符区域</div>
```

### 排版和部分

- `h2` — 页面标题
- `h3` — 部分标题
- `.subtitle` — 标题下的次要文本
- `.section` — 底部有空白的内容块
- `.label` — 小型大写标签文本

## 浏览器事件格式

当用户在浏览器中点击选项时，他们的交互被记录到 `$STATE_DIR/events`（每行一个 JSON 对象）。推送新屏幕时文件会自动清除。

```jsonl
{"type":"click","choice":"a","text":"选项 A - 简单布局","timestamp":1706000101}
{"type":"click","choice":"c","text":"选项 C - 复杂网格","timestamp":1706000108}
{"type":"click","choice":"b","text":"选项 B - 混合","timestamp":1706000115}
```

完整事件流显示了用户的探索路径 — 他们可能在最终确定之前点击多个选项。最后一个 `choice` 事件通常是最终选择，但点击模式可能揭示值得提问的犹豫或偏好。

如果 `$STATE_DIR/events` 不存在，用户没有与浏览器互动 — 仅使用他们的终端文本。

## 设计提示

- **根据问题调整保真度** — 布局用线框，润饰问题用润饰
- **在每个页面解释问题** — "哪个布局看起来更专业？"而不只是"选一个"
- **迭代后再前进** — 如果反馈改变当前屏幕，写一个新版本
- **每个屏幕最多 2-4 个选项**
- **需要时使用真实内容** — 对于摄影组合，使用实际图像（Unsplash）。占位符内容会掩盖设计问题。
- **保持模型简单** — 专注于布局和结构，而不是像素完美的设计

## 文件命名

- 使用语义名称：`platform.html`、`visual-style.html`、`layout.html`
- 永远不要重用文件名 — 每个屏幕都必须是一个新文件
- 对于迭代：追加版本后缀，如 `layout-v2.html`、`layout-v3.html`
- 服务器按修改时间提供最新文件

## 清理

```bash
scripts/stop-server.sh $SESSION_DIR
```

如果会话使用了 `--project-dir`，模型文件在 `.superpowers/brainstorm/` 中持久化，供以后参考。仅 `/tmp` 会话在停止时被删除。

## 参考

- 框架模板（CSS 参考）：`scripts/frame-template.html`
- 助手脚本（客户端）：`scripts/helper.js`
