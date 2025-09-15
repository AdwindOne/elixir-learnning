# ###################################################################
# 本书由 Jules (AI Software Engineer) 编写
# 章节: 第七部分 - Blockscout 源码解析
# 第19章: 数据层核心 - Ecto 与数据库
# ###################################################################

Blockscout 的核心是将区块链上复杂、去中心化的数据，转换成可以在网页上快速查询和展示的关系型数据。这一章，我们将深入其 `explorer` 应用，分析其核心的数据模型，看看它是如何通过 Ecto Schema 来组织区块链数据的。

由于无法直接展示源码，我们将基于区块链的基本概念和 Ecto 的设计模式，来推断和分析其核心 Schema 的设计。

## 1. 核心实体与关系

一个区块链浏览器最核心的实体无外乎三个：**区块 (Blocks)**、**交易 (Transactions)** 和 **地址 (Addresses)**。它们之间的关系是：

- 一个 **区块** 包含多个 **交易**。
- 一个 **交易** 关联两个 **地址**（发送方和接收方），并属于一个 **区块**。
- 一个 **地址** 可以作为发送方或接收方参与多个 **交易**。

下面我们来分别解析这三个核心 Schema 的设计。

## 2. `Block` Schema (区块)

区块是区块链的基本单位。`Block` Schema 的职责就是将一个区块的所有链上信息映射到数据库的 `blocks` 表中。

**推断的 `Explorer.Repo.Schema.Block` 结构:**
```elixir
defmodule Explorer.Repo.Schema.Block do
  use Ecto.Schema

  schema "blocks" do
    # 核心字段
    field :number, :integer              # 区块高度，通常是主键
    field :hash, :binary                 # 区块的哈希值，唯一
    field :parent_hash, :binary           # 父区块的哈希值
    field :timestamp, :utc_datetime_usec  # 区块的出块时间
    field :gas_limit, :decimal            # 该区块的 Gas 上限
    field :gas_used, :decimal             # 该区块中所有交易消耗的总 Gas
    field :miner_hash, :binary            # 挖出该区块的矿工地址哈希

    # 其他元数据
    field :difficulty, :decimal           # 难度
    field :total_difficulty, :decimal     # 总难度
    field :nonce, :binary                 # 工作量证明的 Nonce
    field :size, :integer                 # 区块大小（字节）

    # 关联关系
    # 一个区块拥有多笔交易
    has_many :transactions, Explorer.Repo.Schema.Transaction, foreign_key: :block_number

    timestamps() # inserted_at, updated_at
  end
end
```
- **关键设计**:
    - 使用 `:binary` 类型来存储哈希值，这比字符串更高效。
    - `miner_hash` 字段存储了矿工的地址，它与 `addresses` 表形成了一个隐式的关联。
    - `has_many :transactions` 清晰地定义了区块与交易之间的一对多关系。

## 3. `Transaction` Schema (交易)

这是最核心、查询最频繁的表之一。`Transaction` Schema 负责存储每一笔交易的详细信息。

**推断的 `Explorer.Repo.Schema.Transaction` 结构:**
```elixir
defmodule Explorer.Repo.Schema.Transaction do
  use Ecto.Schema

  schema "transactions" do
    # 核心字段
    field :hash, :binary, primary_key: true # 交易哈希是唯一标识，适合做主键
    field :from_address_hash, :binary      # 发送方地址
    field :to_address_hash, :binary        # 接收方地址 (对于合约创建，可能为 nil)
    field :value, :decimal                 # 交易金额 (ETH 或主币)
    field :gas_price, :decimal             # Gas 价格
    field :gas_used, :decimal              # 该交易消耗的 Gas
    field :nonce, :integer                 # 发送方的 Nonce

    # 关联关系
    # 一笔交易属于一个区块
    belongs_to :block, Explorer.Repo.Schema.Block, foreign_key: :block_number, references: :number, type: :integer

    # 其他字段
    field :input, :binary                  # 交易的 input data
    field :status, :string                 # 交易状态 (e.g., "ok", "error")
    field :index, :integer                 # 交易在区块内的索引位置

    timestamps()
  end
end
```
- **关键设计**:
    - `hash` 作为主键，因为它是全局唯一的。
    - `from_address_hash` 和 `to_address_hash` 存储了地址的哈希，它们与 `addresses` 表形成关联。
    - `belongs_to :block` 定义了交易与区块的多对一关系。注意 `references: :number`，这表明外键 `block_number` 关联的是 `blocks` 表的 `number` 字段，而非默认的 `id` 字段。

## 4. `Address` Schema (地址)

`Address` Schema 存储了每个与链上发生过交互的地址的信息。

**推断的 `Explorer.Repo.Schema.Address` 结构:**
```elixir
defmodule Explorer.Repo.Schema.Address do
  use Ecto.Schema

  schema "addresses" do
    field :hash, :binary, primary_key: true # 地址哈希是唯一标识
    field :balance, :decimal                # 该地址的余额
    field :nonce, :integer                  # 该地址已发送的交易数

    # 如果是合约地址，还会有额外信息
    field :contract_code, :binary
    field :is_contract, :boolean, default: false

    # 虚拟字段，用于存储查询时的临时数据
    field :fetched_balance, :decimal, virtual: true

    timestamps()
  end
end
```
- **关键设计**:
    - 将外部账户 (EOA) 和合约账户 (Contract) 存储在同一张表中，通过 `is_contract` 字段来区分。
    - `virtual: true` 字段非常有用。它们是存在于 Elixir 结构体中，但不会被存入数据库的字段。常用于表单、计算或临时存放从查询中 `select` 出来的聚合数据。

## 总结与思考

通过将链上数据模型映射到关系型数据库，Blockscout 实现了以下目标：
1.  **快速查询**: 可以利用数据库的索引来快速查询交易、地址等信息，而无需每次都扫描区块链。
2.  **数据聚合**: 可以轻松地对数据进行聚合分析，例如计算一个地址的总交易额、统计每天的活跃地址数等。
3.  **关系清晰**: 利用 Ecto 的关联宏，清晰地表达了实体之间的关系，便于开发和维护。

这种设计是所有区块链浏览器的基石。理解这个数据模型，是理解 Blockscout 工作原理，并对其进行二次开发的第一步。

---
*在下一章，我们将分析 Blockscout 的心脏——索引器 (Indexer)，看看它是如何将链上数据填充到这些表中的。*
---
