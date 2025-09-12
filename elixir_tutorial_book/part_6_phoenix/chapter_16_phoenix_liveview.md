# ###################################################################
# 本书由 Jules (AI Software Engineer) 编写
# 章节: 第六部分 - Phoenix 框架实战
# 第16章: 实时应用与 LiveView
# ###################################################################

Phoenix LiveView 是 Phoenix 框架的革命性功能。它允许开发者仅使用 Elixir，就能构建出具有丰富实时交互体验的 Web 应用，而几乎不需要编写任何 JavaScript。

## 1. LiveView 是什么？

传统的 Web 应用中，要实现动态交互（如表单验证、计数器、自动补全），通常需要在前端编写大量的 JavaScript (使用 React, Vue, etc.) 与后端的 API 进行通信。

LiveView 颠覆了这一模式。它的工作原理如下：
1.  **初始请求**: 浏览器发起一个普通的 HTTP 请求。服务器渲染一个完整的 HTML 页面并返回，就像传统应用一样。这保证了良好的 SEO 和首屏加载速度。
2.  **建立连接**: 页面加载后，页面上的少量 JavaScript 会与服务器建立一个持久化的 WebSocket 连接。
3.  **有状态的进程**: 在服务器端，每个 LiveView 页面都由一个独立的、有状态的 Elixir 进程来驱动。
4.  **事件处理**: 当用户与页面交互时（如点击按钮、输入表单），事件通过 WebSocket 发送到服务器上的对应进程。
5.  **差量更新**: 进程处理事件后，会更新自己的状态。LiveView 会智能地重新渲染模板，并只将**最小的差异 (diff)** 通过 WebSocket 发送回浏览器。浏览器上的 JavaScript 会精确地更新 DOM 中发生变化的部分。

这种模式的优势是巨大的：你将大部分逻辑都保留在了 Elixir 中，享受函数式编程的简洁和 OTP 的强大，同时为用户提供了媲美单页应用 (SPA) 的流畅体验。

## 2. 一个 LiveView 的生命周期

一个 LiveView 模块主要由三个核心回调函数驱动：

- **`mount/3`**: 在 LiveView 进程启动时调用一次。类似于 `GenServer.init/1`。它的职责是设置 LiveView 的初始状态。
- **`handle_event/3`**: 当接收到来自客户端的事件时调用。这是处理用户交互的核心。
- **`render/1`**: 负责渲染模板。每当 LiveView 的状态发生变化时，它都会被调用。

## 3. 实战：构建一个实时计数器

让我们来构建一个最经典的 LiveView 示例：一个实时计数器。

### 3.1 添加路由

首先，在 `router.ex` 中为我们的 LiveView 添加一条路由。

```elixir
# path: lib/your_app_web/router.ex
...
import YourAppWeb.CounterLive # 导入我们的 LiveView 模块

scope "/", YourAppWeb do
  pipe_through :browser

  get "/", PageController, :index
  # 添加这条 live 路由
  live "/counter", CounterLive
end
```
`live` 宏告诉 Phoenix，`/counter` 这个路径将由 `CounterLive` 模块来处理。

### 3.2 创建 LiveView 模块

现在，创建我们的 LiveView 模块。

```elixir
# path: lib/your_app_web/live/counter_live.ex

defmodule YourAppWeb.CounterLive do
  # 引入 LiveView 的所有功能
  use YourAppWeb, :live_view

  # --- 1. 生命周期回调 ---

  # `mount` 设置初始状态
  @impl true
  def mount(_params, _session, socket) do
    # `socket` 是 LiveView 的核心数据结构，类似于控制器中的 `conn`。
    # 我们使用 `assign` 将状态存入 socket。
    # 初始计数值为 0。
    {:ok, assign(socket, :count, 0)}
  end

  # `handle_event` 处理用户事件
  # 这个函数会匹配 `phx-click="increment"` 事件
  @impl true
  def handle_event("increment", _value, socket) do
    # 使用 `update` 来安全地更新 socket 中的状态
    new_socket = update(socket, :count, fn current_count -> current_count + 1 end)
    {:noreply, new_socket}
  end

  # 这个函数会匹配 `phx-click="decrement"` 事件
  def handle_event("decrement", _value, socket) do
    {:noreply, update(socket, :count, &(&1 - 1))}
  end

  # --- 2. 渲染 ---

  # `render` 负责渲染模板。它接收 `assigns` 作为参数。
  # `assigns` 就是 socket 中存储的所有状态。
  @impl true
  def render(assigns) do
    # ~H sigil 用于定义 HEEx 模板
    ~H"""
    <div>
      <h1>Live Counter</h1>
      <p>Current count: <%= @count %></p>

      <%# phx-click 会在点击时向服务器发送一个事件 %>
      <button phx-click="increment">+</button>
      <button phx-click="decrement">-</button>
    </div>
    """
  end
end
```

### 3.3 运行它！

就是这样！现在访问 `http://localhost:4000/counter`，你就能看到一个功能完整的实时计数器。点击 `+` 或 `-` 按钮，你会发现数字实时变化，而页面完全没有刷新。

## 常见坑与使用技巧

- **坑: 在 `mount` 中执行耗时操作**
    - **原因**: `mount` 在初始的 HTTP 请求中是阻塞的。如果在这里执行耗时的数据库查询或 API 调用，会导致首屏加载非常慢。
    - **技巧**: 如果需要加载耗时数据，可以在 `mount` 中先设置一个加载状态 (`loading: true`)，然后使用 `send(self(), :load_data)` 给自己发送一个异步消息。在 `handle_info/2` 回调中处理这个消息并加载数据。这会让页面立即加载，然后在数据准备好后再更新 UI。

- **坑: 直接修改 `socket` 结构**
    - **原因**: `socket` 是一个复杂的结构体，直接用 `Map.put` 修改它可能会破坏其内部状态。
    - **技巧**: 永远使用 Phoenix 提供的函数来操作 `socket`，如 `assign/3`, `update/3`, `put_flash/3` 等。

- **技巧: 使用 Live Components**
    - 对于复杂的 LiveView 页面，可以将其分解为多个**有状态的** Live Components (`.live.ex` 模块)。这与我们之前学的无状态函数组件不同，Live Component 有自己的生命周期和事件处理能力，是构建可复用、可独立更新的 UI 单元的利器。

- **技巧: 利用 `phx-` 绑定**
    - LiveView 提供了一系列 `phx-` 属性来处理用户交互：
        - `phx-click`: 点击事件。
        - `phx-change`, `phx-submit`: 用于表单元素。
        - `phx-keydown`, `phx-keyup`: 键盘事件。
        - `phx-debounce`, `phx-throttle`: 对事件进行防抖和节流，防止过于频繁地向服务器发送事件。

---
*在下一章，我们将汇总 Phoenix 开发中的一些常见问题、技巧和最佳实践。*
---
