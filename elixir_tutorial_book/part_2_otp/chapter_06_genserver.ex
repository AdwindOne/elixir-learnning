# ###################################################################
# 本书由 Jules (AI Software Engineer) 编写
# 章节: 第二部分 - 并发编程与 OTP
# 第6章: 通用服务器 GenServer
# ###################################################################

# `GenServer` (Generic Server) 是 Elixir/OTP 中用于实现客户端-服务器模式的最核心的抽象。
# 它封装了上一章我们手动编写的进程状态管理、消息循环、同步/异步调用等所有标准逻辑。
# 使用 GenServer 可以让我们编写出更健壮、更易于理解和维护的并发代码。

# 一个 GenServer 模块需要实现一系列的回调函数 (callbacks)。

# --- 我们将重构上一章的计数器为 GenServer ---

defmodule GenServerCounter do
  # 引入 GenServer 的行为。这会告诉编译器本模块需要实现 GenServer 的回调。
  use GenServer

  # --- 1. 客户端 API (Client API) ---
  # 这是模块的公共接口，供其他进程调用。它们通常会隐藏 GenServer 的内部实现细节。

  @doc "启动计数器 GenServer"
  def start_link(initial_value \\ 0) do
    # `GenServer.start_link/3` 会创建一个新的 GenServer 进程并链接到当前进程。
    # 它会调用下面的 `init/1` 回调。
    # 第一个参数是本模块名，第二个是传给 `init` 的参数，第三个是选项。
    GenServer.start_link(__MODULE__, initial_value, name: __MODULE__)
  end

  @doc "同步获取当前计数值"
  def get() do
    # `GenServer.call/2` 用于同步调用。它会向 GenServer 发送请求，并阻塞等待回复。
    # 第一个参数是 GenServer 的 PID 或名字，第二个是请求消息。
    # 这个调用会触发下面的 `handle_call/3` 回调。
    GenServer.call(__MODULE__, :get)
  end

  @doc "异步增加计数值"
  def increment() do
    # `GenServer.cast/2` 用于异步调用。它会向 GenServer 发送消息，然后立即返回 :ok，不等待回复。
    # 这个调用会触发下面的 `handle_cast/2` 回调。
    GenServer.cast(__MODULE__, :increment)
  end

  @doc "停止 GenServer"
  def stop() do
    GenServer.cast(__MODULE__, :stop)
  end


  # --- 2. 服务器回调 (Server Callbacks) ---
  # 这些是 GenServer 的核心逻辑，由 GenServer 进程自身执行。

  @impl true # `@impl true` 明确表示这是 GenServer 行为的一个实现。
  # `init/1` 在 GenServer 启动时被调用一次，用于初始化状态。
  # 它必须返回 `{:ok, initial_state}` 或 `{:stop, reason}`。
  def init(initial_value) do
    IO.puts("GenServerCounter 正在初始化，初始值为: #{initial_value}")
    {:ok, initial_value}
  end

  @impl true
  # `handle_call/3` 用于处理同步的 `GenServer.call/2` 请求。
  # 它接收请求消息、调用者信息和当前状态。
  # 必须返回一个形如 `{:reply, a_reply, new_state}` 的元组。
  def handle_call(:get, _from, state) do
    # `_from` 是调用者的信息，我们这里用不到，所以用下划线忽略。
    # `state` 是 GenServer 的当前状态，这里就是计数值。
    {:reply, state, state} # 回复当前状态，并且状态保持不变。
  end

  @impl true
  # `handle_cast/2` 用于处理异步的 `GenServer.cast/2` 请求。
  # 它接收请求消息和当前状态。
  # 必须返回一个形如 `{:noreply, new_state}` 的元组。
  def handle_cast(:increment, state) do
    new_state = state + 1
    {:noreply, new_state} # 不回复，但更新状态为 new_state。
  end

  def handle_cast(:stop, state) do
    {:stop, :normal, state} # 返回 :stop 元组来正常终止 GenServer。
  end
end


# --- 使用我们的 GenServerCounter ---
IO.puts("--- 启动和使用 GenServerCounter ---")

# 启动 GenServer
{:ok, pid} = GenServerCounter.start_link(10)
IO.puts("GenServerCounter 已启动，PID 是: #{inspect(pid)}")

# 进行调用
IO.puts("当前值是: #{GenServerCounter.get()}")

GenServerCounter.increment()
IO.puts("执行 increment (异步)...")
# 由于 increment 是异步的，我们稍微等待一下以确保它被处理
Process.sleep(100)
IO.puts("执行 increment 后，当前值是: #{GenServerCounter.get()}")

GenServerCounter.increment()
IO.puts("再次执行 increment (异步)...")
Process.sleep(100)
IO.puts("再次执行后，当前值是: #{GenServerCounter.get()}")

# 停止服务器
GenServerCounter.stop()
IO.puts("GenServerCounter 已停止。")
Process.sleep(100) # 等待服务器完全关闭


# --- 面试常见陷阱 (Interview Pitfall) ---

# 问：`GenServer.call` 和 `GenServer.cast` 有什么区别？何时使用？
# 答：
# 1.  **`call` (同步调用)**:
#     -   **行为**: 阻塞的。客户端发送请求后会一直等待，直到服务器端返回一个回复。
#     -   **回调**: 在服务器端触发 `handle_call/3`。
#     -   **用途**: 当你需要从服务器获取一个值（如查询数据）或需要确认一个操作已经完成时使用。例如“获取当前用户”、“更新数据库并确认成功”。
# 2.  **`cast` (异步调用)**:
#     -   **行为**: 非阻塞的。客户端发送消息后立即返回 `:ok`，不等待服务器处理。
#     -   **回调**: 在服务器端触发 `handle_cast/2`。
#     -   **用途**: 当你只是想通知服务器做某件事，而不需要立即知道结果时使用。这是一种“发后不理”的操作。例如“记录一条日志”、“触发一个后台任务”。

# 问：`start_link` 和 `start` 有什么区别？
# 答：
# -   `start_link`: 创建一个 GenServer **并将其链接 (link)** 到调用它的进程（通常是监督者 Supervisor）。如果 GenServer 异常崩溃，链接到的进程也会收到一个退出信号。这是构建容错系统的基石，99% 的情况下都应该使用它。
# -   `start`: 只创建 GenServer，不建立链接。它很少被直接使用。

# --- 练习 (Exercise) ---
# 创建一个简单的键值存储 GenServer，名为 `KVStore`。
# 它应该有以下客户端 API:
# - `start_link()`: 启动服务。
# - `put(key, value)`: 存储一个键值对 (异步 `cast`)。
# - `get(key)`: 获取一个键对应的值 (同步 `call`)。
#
# 提示:
# - `init/1` 的初始状态应该是一个空的 Map: `{:ok, %{}}`。
# - `handle_cast({:put, key, value}, state)` 应该使用 `Map.put(state, key, value)` 来更新状态。
# - `handle_call({:get, key}, _from, state)` 应该使用 `Map.get(state, key)` 来获取值并回复。

IO.puts("\n--- 练习: KVStore GenServer ---")

defmodule KVStore do
  use GenServer

  # Client API
  def start_link, do: GenServer.start_link(__MODULE__, %{}, name: __MODULE__)
  def put(key, value), do: GenServer.cast(__MODULE__, {:put, key, value})
  def get(key), do: GenServer.call(__MODULE__, {:get, key})

  # Server Callbacks
  @impl true
  def init(state), do: {:ok, state}

  @impl true
  def handle_cast({:put, key, value}, state) do
    new_state = Map.put(state, key, value)
    {:noreply, new_state}
  end

  @impl true
  def handle_call({:get, key}, _from, state) do
    value = Map.get(state, key)
    {:reply, value, state}
  end
end

# 使用 KVStore
KVStore.start_link()
KVStore.put(:name, "Elixir Book")
KVStore.put(:chapter, 6)

IO.puts("获取 :name -> #{inspect KVStore.get(:name)}")
IO.puts("获取 :chapter -> #{inspect KVStore.get(:chapter)}")
IO.puts("获取 :author -> #{inspect KVStore.get(:author)}") # 应该返回 nil

# --- End of Chapter 6 ---
