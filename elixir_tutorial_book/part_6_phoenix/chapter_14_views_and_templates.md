# ###################################################################
# 本书由 Jules (AI Software Engineer) 编写
# 章节: 第六部分 - Phoenix 框架实战
# 第14章: 视图与模板 (Views & Templates)
# ###################################################################

在 Phoenix 中，当控制器处理完业务逻辑后，就轮到视图 (View) 和模板 (Template) 登场了。它们共同负责将数据渲染成最终要发送给浏览器的 HTML 页面。

## 1. 职责分离

Phoenix 对视图层有清晰的职责划分：

- **视图 (View)**: 一个 Elixir 模块。它的主要职责是**准备数据**和提供**辅助函数**给模板使用。它不包含任何 HTML 标记。
- **模板 (Template)**: 一个 `.html.heex` 文件。它的主要职责是**展示数据**，包含 HTML 标记和简单的 Elixir 表达式。

这种分离使得逻辑和展示各司其职，代码更清晰。

## 2. 视图模块 (The View)

视图模块通常位于 `lib/your_app_web/views/` 目录下，并与对应的控制器同名。例如，`PageController` 对应 `PageView`。

```elixir
# path: lib/your_app_web/views/page_view.ex

defmodule YourAppWeb.PageView do
  use YourAppWeb, :view

  # 我们可以定义一些只在模板中使用的辅助函数
  def page_title(assigns) do
    # assigns 是一个图，包含了从控制器传递过来的所有变量
    "My App - " <> assigns[:page_title]
  end
end
```

在控制器中，当我们调用 `render(conn, :index, message: "Hello")` 时，Phoenix 会：
1. 找到 `PageView` 模块。
2. 找到 `index.html.heex` 模板文件。
3. 将 `message: "Hello"` 作为 `assigns` 传递给视图和模板。

## 3. HEEx 模板 (Templates)

Phoenix 使用一种名为 HEEx (HTML EEx) 的模板引擎。它非常强大，因为它能理解 HTML 结构，从而在编译时提供验证，防止你写出无效的 HTML（如 `<p><div></p>`)。

模板文件位于 `lib/your_app_web/templates/` 下，按控制器名分子目录。

```eex
<%# path: lib/your_app_web/templates/page/index.html.heex %>

<%# 使用 @ 语法可以方便地访问 assigns 中的变量 %>
<h1><%= @message %></h1>

<p>这是一个 HEEx 模板。</p>

<%# Elixir 表达式 %>
<p>2 + 2 等于: <%= 2 + 2 %></p>

<%# 条件渲染 %>
<%= if @user do %>
  <p>欢迎, <%= @user.name %></p>
<% else %>
  <p>请先<a href="/login">登录</a>。</p>
<% end %>

<%# 循环渲染 %>
<ul>
  <%= for item <- @items do %>
    <li><%= item %></li>
  <% end %>
</ul>
```

- `<%= ... %>`: 用于**输出**表达式的结果（会对结果进行 HTML 转义以防 XSS 攻击）。
- `<% ... %>`: 用于执行 Elixir 代码，但**不输出**结果（如 `if`, `for`）。
- `<%# ... %>`: 用于注释。

## 4. 布局 (Layouts)

大多数网站的页面都有相同的页头、页脚和导航栏。在 Phoenix 中，这是通过布局来实现的。

布局文件位于 `lib/your_app_web/layouts/`。默认情况下，所有页面都会使用 `root.html.heex` 布局。

```eex
<%# path: lib/your_app_web/layouts/root.html.heex %>

<!DOCTYPE html>
<html lang="en">
  <head>
    <meta charset="utf-8"/>
    <title>My App</title>
    <link phx-track-static rel="stylesheet" href={~p"/assets/app.css"}/>
  </head>
  <body>
    <header>
      <h1>我的网站</h1>
      <nav>...</nav>
    </header>
    <main>
      <%# @inner_content 会被替换为具体页面的模板内容 %>
      <%= @inner_content %>
    </main>
  </body>
</html>
```
`@inner_content` 是一个特殊的 `assign`，Phoenix 会自动将 `index.html.heex` (或任何其他页面模板) 的渲染结果注入到这里。

## 5. 函数组件 (Function Components)

HEEx 最强大的功能之一是函数组件。它允许你将可复用的 UI 块封装成一个纯函数。这使得构建复杂的、组件化的界面变得异常简单。

一个函数组件就是一个接收 `assigns` 作为参数并返回 `~H` (HEEx Sigil) 结果的函数。

**示例：创建一个用户头像组件**

```elixir
# 可以在任何视图模块或专门的组件模块中定义
# path: lib/your_app_web/components.ex

defmodule YourAppWeb.Components do
  use Phoenix.Component

  # 定义一个名为 user_avatar 的函数组件
  # `@` 宏用于声明 assigns 和它们的类型、默认值
  attr :user, :map, required: true
  attr :class, :string, default: "avatar"

  def user_avatar(assigns) do
    ~H"""
    <img src={@user.avatar_url} class={@class} title={@user.name} />
    """
  end
end
```

**在模板中使用它：**

首先，在模板中导入组件模块：`alias YourAppWeb.Components`

```eex
<%# path: lib/your_app_web/templates/user/show.html.heex %>
alias YourAppWeb.Components

<h1>用户信息</h1>

<%# 使用 <.component_name /> 语法调用组件 %>
<.user_avatar user={@user} class="avatar-large" />

<p>名字: <%= @user.name %></p>
```
`<.user_avatar ... />` 语法清晰地表明我们正在渲染一个组件，并将 `@user` 和 `"avatar-large"` 作为 `assigns` 传递给它。

## 常见坑与使用技巧

- **坑: 在模板中执行复杂的数据库查询**
    - **原因**: 这违反了职责分离原则，使得模板难以测试和理解，并且可能导致严重的性能问题（N+1 查询）。
    - **技巧**: 所有的数据预加载和查询都应该在**控制器**或其调用的**业务模块 (Context)** 中完成。模板只负责展示已经准备好的数据。

- **坑: 忘记 `@` 符号**
    - **原因**: 在模板中访问 `assigns` 时，必须使用 `@` 前缀 (如 `@user`)。如果写成 `user`，HEEx 会认为它是一个普通的局部变量，通常会报错。
    - **技巧**: 记住这个约定。`@` 是 "assigns" 的简写。

- **技巧: 使用 `.html.leex` 进行调试**
    - Phoenix 1.6 之前的模板引擎是 LEEx (`.html.leex`)，它不会在编译时检查 HTML 结构。如果你遇到一个 HEEx 编译错误但看不懂，可以临时将文件后缀改为 `.leex`，它可能会给你一个更清晰的运行时错误信息。调试完后再改回 `.heex`。

- **技巧: 大量使用函数组件**
    - 不要害怕创建函数组件，即使它只被使用一次。将页面分解成小的、有明确职责的组件，会让你的代码库更易于导航和维护。一个好的经验法则是，任何 `for` 循环或复杂的 `if` 语句块，都是一个创建组件的好机会。

---
*在下一章，我们将深入 Phoenix 的数据层，学习如何使用 Ecto 来与数据库交互。*
---
