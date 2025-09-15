# ###################################################################
# 本书由 Jules (AI Software Engineer) 编写
# 章节: 第七部分 - Blockscout 源码解析
# 第21章: Web 接口 - Phoenix 框架的应用
# ###################################################################

`blockscout_web` 应用是整个 Blockscout 项目的门面。它是一个功能齐全的 Phoenix 应用，负责将 `indexer` 存入数据库的复杂数据，以用户友好的方式呈现出来。

这一章，我们将通过追踪一个典型页面的完整请求生命周期——**查看交易详情页面**——来理解 `blockscout_web` 是如何与其他应用协作的。

## 一个请求的生命周期：`GET /tx/:hash`

假设用户在浏览器中访问 `https://etherscan.io/tx/0xabc...`（Blockscout 实现了类似的功能）。让我们来分解这个请求在系统中的完整流程。

### 第1步: 路由 (Routing)

请求首先到达 Phoenix 的 Endpoint，然后被交给 Router (`apps/blockscout_web/lib/blockscout_web/router.ex`)。

**推断的路由定义:**
在 `router.ex` 文件中，几乎肯定有一条类似这样的路由规则：

```elixir
# In scope "/", BlockscoutWeb do
#   pipe_through :browser
#   ...
    get "/tx/:hash", TransactionController, :show
#   ...
# end
```
- `get "/tx/:hash"`: 这条规则匹配所有以 `/tx/` 开头的 GET 请求。
- `:hash`: URL 中 `tx` 之后的部分被捕获，并作为名为 `"hash"` 的参数。
- `TransactionController, :show`: 请求被分派到 `BlockscoutWeb.TransactionController` 模块的 `show` 动作。

### 第2步: 控制器 (Controller)

`TransactionController` 接收到请求，并执行 `show/2` 动作。

**推断的 `TransactionController.show/2` 实现:**
```elixir
# path: apps/blockscout_web/lib/blockscout_web/controllers/transaction_controller.ex

defmodule BlockscoutWeb.TransactionController do
  use BlockscoutWeb, :controller

  # 别名，方便调用 Explorer Context
  alias Explorer.Chain

  def show(conn, %{"hash" => hash}) do
    # `hash` 从路由参数中被模式匹配出来
    case Chain.get_transaction_by_hash(hash) do
      nil ->
        # 如果在数据库中找不到该交易
        conn
        |> put_status(:not_found)
        |> render("404.html")

      # 如果找到了交易
      %Explorer.Repo.Schema.Transaction{} = transaction ->
        # 调用 render，将交易数据传递给视图层
        render(conn, :show, transaction: transaction)
    end
  end
end
```
- **职责清晰**: 控制器的代码非常“瘦”。它只负责：1. 从参数中获取 `hash`。2. 调用业务逻辑模块 (`Explorer.Chain`)。3. 根据结果渲染不同的页面。它完全不关心数据库查询的细节。

### 第3步: 业务核心 (Context)

控制器调用了 `Explorer.Chain.get_transaction_by_hash/1`。这个函数定义在 `explorer` 应用中，是核心业务逻辑的一部分。

**推断的 `Explorer.Chain.get_transaction_by_hash/1` 实现:**
```elixir
# path: apps/explorer/lib/explorer/chain.ex

defmodule Explorer.Chain do
  alias Explorer.Repo
  import Ecto.Query

  def get_transaction_by_hash(hash_binary) do
    # 这里可能会做一些预处理，比如将十六进制字符串转为二进制

    # 调用 Repo 来执行数据库查询
    # 注意这里使用了 preload 来避免 N+1 查询问题
    Repo.one(
      from t in Explorer.Repo.Schema.Transaction,
      where: t.hash == ^hash_binary,
      preload: [:block] # 同时加载所属的区块信息
    )
  end
end
```
- **跨应用通信**: `blockscout_web` (Phoenix) 调用了 `explorer` (核心逻辑) 的函数。这是 Umbrella 架构的核心优势——不同的应用可以像调用普通 Elixir 模块一样相互调用。
- **封装查询**: `Chain` 模块封装了所有与数据库交互的细节。控制器不需要知道 Ecto 的存在。

### 第4步: 数据库 (Ecto)

`Explorer.Chain` 模块使用 Ecto 和 `Explorer.Repo` 来执行实际的数据库查询，并返回我们在第19章分析过的 `%Explorer.Repo.Schema.Transaction{}` 结构体。

### 第5步: 视图与模板 (View & Template)

控制器拿到 `transaction` 数据后，调用 `render(conn, :show, transaction: transaction)`。Phoenix 接下来会：
1.  找到 `BlockscoutWeb.TransactionView` 模块。
2.  找到 `apps/blockscout_web/lib/blockscout_web/templates/transaction/show.html.heex` 模板。
3.  在模板中，你可以使用 `@transaction` 来访问传递过来的数据，并将其渲染成用户最终看到的 HTML 页面。

**推断的 `show.html.heex` 模板片段:**
```eex
<%# path: apps/blockscout_web/lib/blockscout_web/templates/transaction/show.html.heex %>

<h1>Transaction Details</h1>

<div class="card">
  <p><strong>Hash:</strong> <%= @transaction.hash %></p>
  <p><strong>Block Number:</strong>
    <a href={~p"/block/#{@transaction.block.number}"}>
      <%= @transaction.block.number %>
    </a>
  </p>
  <p><strong>From:</strong> <%= @transaction.from_address_hash %></p>
  <p><strong>To:</strong> <%= @transaction.to_address_hash %></p>
  <p><strong>Value:</strong> <%= @transaction.value %></p>
</div>
```
- **预加载的威力**: 注意 `<%= @transaction.block.number %>`。因为我们在 Context 中预加载了 `:block`，所以在这里可以直接访问关联的区块数据，而不会触发额外的数据库查询。

## 总结

Blockscout 的 Web 接口完美地展示了 Phoenix 和 Umbrella 架构的最佳实践：
- **瘦控制器**: 控制器只做调度，不处理业务逻辑。
- **胖业务模块 (Context)**: `explorer` 应用是业务核心，封装了所有数据和规则。
- **应用间通信**: `blockscout_web` 通过清晰的函数接口与 `explorer` 通信，实现了高度解耦。
- **数据驱动视图**: 从数据库获取的 Ecto 结构体，经过层层传递，最终被渲染成页面。

理解这个流程，是进行 Blockscout 二次开发，例如添加新页面或修改现有页面的基础。

---
*在最后一章，我们将汇总所有分析，提炼出对 Blockscout 进行二次开发的要点和技巧。*
---
