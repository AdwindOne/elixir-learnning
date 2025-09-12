# ###################################################################
# 本书由 Jules (AI Software Engineer) 编写
# 章节: 第六部分 - Phoenix 框架实战
# 第13章: 路由与控制器 (Routing & Controllers)
# ###################################################################

在 Phoenix 应用中，请求的生命周期始于路由。路由器 (Router) 负责解析进来的 HTTP 请求，并将其分派给正确的控制器 (Controller) 动作 (Action) 去处理。

## 1. 路由器 (The Router)

Phoenix 项目的路由定义在 `lib/your_app_web/router.ex` 文件中。它是一个功能强大的 DSL (领域特定语言)，用于匹配 URL、HTTP 方法，并可以组织成多个作用域 (scope) 和管道 (pipeline)。

打开 `router.ex` 文件，你会看到类似这样的结构：

```elixir
# path: lib/your_app_web/router.ex

defmodule YourAppWeb.Router do
  use YourAppWeb, :router

  # 定义一个管道，它是一系列 Plug (中间件) 的集合
  pipeline :browser do
    plug :accepts, ["html"]
    plug :fetch_session
    plug :fetch_live_flash
    plug :put_root_layout, {YourAppWeb.Layouts, :root}
    plug :protect_from_forgery
    plug :put_secure_browser_headers
  end

  # 定义另一个管道，用于 API 请求
  pipeline :api do
    plug :accepts, ["json"]
  end

  # 定义一个作用域
  scope "/", YourAppWeb do
    # 将这个作用域内的所有路由都通过 :browser 管道
    pipe_through :browser

    # 定义一条路由
    # 当一个 GET 请求访问 "/" 时，将其分派到 PageController 的 index 动作
    get "/", PageController, :index
  end

  # 其他作用域，如 API
  # scope "/api", YourAppWeb do
  #   pipe_through :api
  # end
end
```

### 1.1 定义路由

最基础的路由定义包含三个部分：
1.  **HTTP 方法**: `get`, `post`, `put`, `patch`, `delete`。
2.  **URL 路径**: 一个字符串，如 `"/users"` 或 `"/users/:id"`。
3.  **控制器和动作**: `UserController` (模块) 和 `:show` (原子)。

**示例:**

```elixir
# GET /hello -> HelloController.index
get "/hello", HelloController, :index

# GET /users/123 -> UserController.show，并将 "123" 作为 :id 参数
get "/users/:id", UserController, :show

# POST /posts -> PostController.create
post "/posts", PostController, :create
```

### 1.2 资源路由 (Resources)

Phoenix 提供了一个强大的 `resources` 宏，可以帮你一次性生成所有标准的 CRUD (Create, Read, Update, Delete) 路由。

```elixir
# 这行代码...
resources "/articles", ArticleController

# ...会自动生成以下8条路由:
#
# 方法 | 路径                 | 控制器#动作  | 路由助手
#------|----------------------|----------------|-------------------
# GET  | /articles            | index          | article_path(:index)
# GET  | /articles/new        | new            | article_path(:new)
# POST | /articles            | create         | article_path(:create)
# GET  | /articles/:id        | show           | article_path(:show, id)
# GET  | /articles/:id/edit   | edit           | article_path(:edit, id)
# PATCH| /articles/:id        | update         | article_path(:update, id)
# PUT  | /articles/:id        | update         | article_path(:update, id)
# DELETE|/articles/:id        | delete         | article_path(:delete, id)
```

### 1.3 路由助手 (Path Helpers)

每当你定义一条路由，Phoenix 都会自动为你生成一个“路由助手”函数，用于在代码中（尤其是在模板里）生成 URL。例如，`get "/hello", HelloController, :index` 会生成 `hello_path/2` 函数。

```elixir
# 在控制器或视图中
YourAppWeb.Router.Helpers.hello_path(conn, :index)
# => "/hello"

YourAppWeb.Router.Helpers.article_path(conn, :show, 123)
# => "/articles/123"
```
使用路由助手是最佳实践，因为如果你以后修改了路由路径，只需要改动 `router.ex` 一处，所有生成的 URL 都会自动更新。

## 2. 控制器 (The Controller)

控制器是处理请求的核心。它是一个 Elixir 模块，包含多个函数，每个函数被称为一个“动作”(Action)。

让我们创建一个 `HelloController` 来响应上面定义的 `/hello` 路由。

```elixir
# path: lib/your_app_web/controllers/hello_controller.ex

defmodule YourAppWeb.HelloController do
  # 引入控制器相关的函数和宏
  use YourAppWeb, :controller

  # 这是一个动作。它接收 conn 和 params作为参数。
  def index(conn, _params) do
    # `conn` (Plug.Conn) 是一个非常重要的数据结构，它包含了请求的所有信息，
    # 并且在请求的生命周期中不断被转换。

    # `render/3` 用于渲染视图
    render(conn, :index, message: "你好，来自控制器的消息！")
  end

  # 对应路由: get "/hello/:name"
  def show(conn, %{"name" => name}) do
    # 我们可以直接在函数签名中对 params 进行模式匹配
    text(conn, "你好, #{name}!")
  end
end
```

### 2.1 动作 (Actions)

每个动作都是一个公共函数，它接收两个参数：
- **`conn`**: 一个 `Plug.Conn` 结构体，包含了关于请求的一切（方法、头信息、参数等），也包含了响应的信息。
- **`params`**: 一个图 (Map)，包含了所有请求参数（URL参数、查询参数、请求体参数）。

### 2.2 处理参数

Phoenix 会自动将所有类型的参数合并到 `params` 图中。

**路由:** `get "/users/:id"`
**请求URL:** `/users/123?admin=true`

对应的 `UserController.show` 动作接收到的 `params` 将是：
`%{"id" => "123", "admin" => "true"}`

### 2.3 发送响应

控制器动作的最终职责是发送一个响应。有多种方式可以做到：

- **`render(conn, template, assigns)`**: (最常用) 渲染一个视图模板。我们将 `message` 变量传递给了视图层。
- **`text(conn, "some text")`**: 直接返回纯文本响应。
- **`json(conn, %{key: "value"})`**: 返回 JSON 响应。
- **`redirect(conn, to: "/some/path")`**: 发送一个重定向响应。

## 常见坑与使用技巧

- **坑: 控制器变得臃肿 (Fat Controller)**
    - **原因**: 将过多的业务逻辑（数据库查询、数据转换等）直接写在控制器动作里。
    - **技巧**: 保持控制器“苗条”。控制器的职责应该是：1. 解析请求参数。2. 调用专门的业务模块（称为 **Context** 或 Service Layer）来处理业务逻辑。3. 根据业务模块的返回结果，调用 `render` 或 `redirect`。

- **坑: 忘记处理 `:id` 不存在的清况**
    - **原因**: `MyModule.get(id)` 返回 `nil`，但后续代码期望得到一个结构体，导致 `nil.field` 错误。
    - **技巧**: 总是使用 `case` 语句来处理业务模块可能返回 `nil` 或 `{:error, ...}` 的情况。

    ```elixir
    def show(conn, %{"id" => id}) do
      case Blog.get_post(id) do
        nil ->
          # 处理未找到的情况
          conn
          |> put_status(:not_found)
          |> render("404.html")
        post ->
          # 处理成功找到的情况
          render(conn, :show, post: post)
      end
    end
    ```

- **技巧: 使用 `with` 简化嵌套的 `case`**
    - 当你需要处理一系列可能失败的操作时，`with` 语句比多个嵌套的 `case` 更优雅。

    ```elixir
    def create(conn, %{"post" => post_params}) do
      with {:ok, user} <- Accounts.get_user_by_token(conn),
           {:ok, post} <- Blog.create_post(user, post_params) do
        # 只有当上面两步都成功时，才会执行这里
        redirect(conn, to: Routes.post_path(conn, :show, post))
      else
        # 任何一步失败，都会在这里匹配
        {:error, :not_found} -> # ...处理用户未找到...
        {:error, changeset} -> # ...处理文章创建失败...
      end
    end
    ```

---
*在下一章，我们将学习视图层 (Views) 和模板 (Templates)，看看 Phoenix 是如何将数据渲染成 HTML 页面的。*
---
