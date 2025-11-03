# ###################################################################
# 本书由 Jules (AI Software Engineer) 编写
# 章节: 第七部分 - Blockscout 源码解析
# 第22章: 二次开发要点与技巧
# ###################################################################

在理解了 Blockscout 的核心架构后，我们现在可以探讨如何对其进行二次开发了。本章将提供一些常见定制任务的切入点和基本步骤。

## 1. 开发环境配置要点

- **硬件要求**: Blockscout 是一个资源密集型应用。你需要一个性能较好的机器，特别是**大量的 RAM (建议 32GB+)** 和**高速的 SSD**。因为索引过程需要从节点同步海量数据并频繁写入数据库。
- **数据库**: 使用 PostgreSQL。你需要熟悉如何创建数据库和用户。
- **以太坊节点**: 你需要一个可访问的以太坊节点 RPC 端点。对于本地开发，可以使用 Geth, Erigon 等客户端在本地运行一个归档节点 (Archive Node)，或者使用 Infura, Alchemy 等第三方服务。
- **环境变量**: Blockscout 通过环境变量进行大量配置。你需要创建一个 `.env` 文件，并至少配置好数据库连接信息 (`DATABASE_URL`) 和节点 RPC 端点 (`ETHEREUM_JSONRPC_HTTP_URL`)。

## 2. 如何添加一个新页面？

假设我们要添加一个 `/stats` 页面，用于显示一些自定义的统计数据。

**步骤:**

1.  **定义路由 (在 `blockscout_web` 中)**:
    - 打开 `apps/blockscout_web/lib/blockscout_web/router.ex`。
    - 在 `:browser` 管道的作用域内，添加新路由：
      ```elixir
      get "/stats", StatsController, :index
      ```

2.  **创建控制器 (在 `blockscout_web` 中)**:
    - 创建文件 `apps/blockscout_web/lib/blockscout_web/controllers/stats_controller.ex`。
    - 在控制器中，调用业务逻辑模块获取数据，并渲染视图：
      ```elixir
      defmodule BlockscoutWeb.StatsController do
        use BlockscoutWeb, :controller
        alias Explorer.Stats # 我们的新业务模块

        def index(conn, _params) do
          # 从 Context 获取统计数据
          stats_data = Stats.get_chain_statistics()
          render(conn, :index, stats: stats_data)
        end
      end
      ```

3.  **创建业务逻辑 (在 `explorer` 中)**:
    - 创建文件 `apps/explorer/lib/explorer/stats.ex`。
    - 在这里编写获取数据的函数，封装所有 Ecto 查询：
      ```elixir
      defmodule Explorer.Stats do
        alias Explorer.Repo
        import Ecto.Query

        def get_chain_statistics do
          # 示例：查询总区块数和总交易数
          total_blocks = Repo.one(from b in "blocks", select: count(b.number))
          total_txs = Repo.one(from t in "transactions", select: count(t.hash))
          %{total_blocks: total_blocks, total_txs: total_txs}
        end
      end
      ```

4.  **创建视图和模板 (在 `blockscout_web` 中)**:
    - 创建视图模块 `apps/blockscout_web/lib/blockscout_web/views/stats_view.ex` (即使是空的)。
    - 创建模板文件 `apps/blockscout_web/lib/blockscout_web/templates/stats/index.html.heex`。
    - 在模板中渲染从控制器传来的 `@stats` 数据：
      ```eex
      <h1>链上统计</h1>
      <p>总区块数: <%= @stats.total_blocks %></p>
      <p>总交易数: <%= @stats.total_txs %></p>
      ```

## 3. 如何添加一个新的 API Endpoint？

步骤与添加新页面类似，但关键区别在于路由和控制器。

1.  **定义 API 路由 (在 `blockscout_web` 中)**:
    - 在 `router.ex` 中，找到 `scope "/api"` 的部分。
    - 将路由放在 `:api` 管道下，这会确保它经过正确的中间件（如 `plug :accepts, ["json"]`）。
      ```elixir
      scope "/api", BlockscoutWeb do
        pipe_through :api

        get "/stats", StatsController, :chain_summary
      end
      ```

2.  **在控制器中返回 JSON (在 `blockscout_web` 中)**:
    - 在 `StatsController` 中添加一个新的动作 `chain_summary`。
    - 使用 `json(conn, data)` 来返回 JSON 格式的响应。
      ```elixir
      defmodule BlockscoutWeb.StatsController do
        # ...
        def chain_summary(conn, _params) do
          stats_data = Explorer.Stats.get_chain_statistics()
          json(conn, %{data: stats_data})
        end
      end
      ```

## 4. 如何添加自定义的索引逻辑？

这是最复杂的二次开发。假设你需要索引某个特定智能合约的特定事件。

1.  **定位事件处理器**:
    - 深入 `indexer` 应用的代码，找到处理区块日志 (`logs`) 的地方。这很可能是一个名为 `Indexer.Log.Processor` 或类似的模块。

2.  **添加自定义的处理器模块**:
    - 你需要创建一个新的模块，例如 `MyCustomContract.EventHandler`。
    - 在这个模块中，定义一个函数，它接收一个日志作为参数。函数内部会检查该日志是否来自你的目标合约地址，并且主题 (topic) 是否匹配你关心的事件。

3.  **解析事件数据**:
    - 如果日志匹配，你需要使用 ABI 解码库（Blockscout 内置了相关工具）来解码 `log.data`，提取出事件的参数。

4.  **存储到新表**:
    - 你可能需要创建一个新的 Ecto Schema 和数据库表来存储你解析出的数据。
    - 在你的事件处理器中，调用 `Explorer.Repo.insert` 将数据存入新表。

5.  **集成到索引流程**:
    - 最后，你需要找到 `Indexer.Log.Processor` 的主循环，并在其中调用你的 `MyCustomContract.EventHandler.handle_event/1` 函数。
    - **重要**: 确保你的处理逻辑是**幂等**的。索引器可能会因为链重组 (reorg) 而重复处理同一个区块，你的代码需要能优雅地处理这种情况（例如，使用 `Repo.insert` 的 `on_conflict` 选项）。

## 总结

对 Blockscout 进行二次开发是一项复杂的工程，但其清晰的 Umbrella 架构为我们提供了明确的指导：
- **想改前端或 API？** -> `blockscout_web`
- **想改业务逻辑或数据模型？** -> `explorer`
- **想改数据获取和处理流程？** -> `indexer`
- **想添加通用工具？** -> `utils`

从修改 `blockscout_web` 开始，逐步深入到 `explorer` 和 `indexer`，是学习和掌握这个庞大代码库的最佳路径。

---
*这本《Elixir 学习手册》的 Blockscout 解析部分到此结束。祝你在 Elixir 的世界中探索愉快！*
---
