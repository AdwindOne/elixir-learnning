# ###################################################################
# 本书由 Jules (AI Software Engineer) 编写
# 章节: 第四部分 - 实战案例
# 第10章: 构建一个容错的键值存储服务
# ###################################################################

# 在本章，我们将综合运用 GenServer 和 Supervisor 来构建一个键值(KV)存储服务。
#
# 我们的目标:
# 1. 容错性: 单个存储单元的崩溃不应影响整个服务。
# 2. 分布式: 我们将通过键的哈希值将请求路由到不同的 GenServer 进程，模拟数据分片(sharding)。
# 3. 简洁的 API: 提供简单的 `get/1`, `put/2`, `delete/1` 接口。

# --- 项目结构 ---
# 我们将定义三个核心模块:
# 1. `KVStore.Worker`: 一个 GenServer，负责实际存储一小部分键值对。
# 2. `KVStore.Supervisor`: 一个监督者，负责启动和监督多个 Worker 进程。
# 3. `KVStore`: 一个门面(Facade)模块，提供公共 API，并将请求路由到正确的 Worker。

# --- 1. KVStore.Worker ---
# 这是我们的基本存储单元。
defmodule KVStore.Worker do
  use GenServer

  # --- Client API (内部使用) ---
  def start_link(_opts) do
    GenServer.start_link(__MODULE__, %{})
  end

  def get(pid, key), do: GenServer.call(pid, {:get, key})
  def put(pid, key, value), do: GenServer.cast(pid, {:put, key, value})
  def delete(pid, key), do: GenServer.cast(pid, {:delete, key})

  # --- Server Callbacks ---
  @impl true
  def init(state), do: {:ok, state}

  @impl true
  def handle_call({:get, key}, _from, state) do
    value = Map.get(state, key)
    {:reply, value, state}
  end

  @impl true
  def handle_cast({:put, key, value}, state) do
    new_state = Map.put(state, key, value)
    {:noreply, new_state}
  end

  def handle_cast({:delete, key}, state) do
    new_state = Map.delete(state, key)
    {:noreply, new_state}
  end
end


# --- 2. KVStore.Supervisor ---
# 这个监督者负责启动一组 Worker。
defmodule KVStore.Supervisor do
  use Supervisor

  def start_link(opts) do
    Supervisor.start_link(__MODULE__, opts, name: __MODULE__)
  end

  @impl true
  def init(_opts) do
    # 我们将启动 4 个 Worker 进程。
    # 在真实应用中，这个数量应该是可配置的。
    children =
      Enum.map(1..4, fn i ->
        # 每个 Worker 都需要一个唯一的 ID。
        # 我们使用 `Supervisor.child_spec/2` 来定义子进程规范。
        Supervisor.child_spec(%{
          id: :"worker_#{i}", # 子进程的唯一ID
          start: {KVStore.Worker, :start_link, [[]]},
          type: :worker
        })
      end)

    # 使用 :one_for_one 策略，一个 worker 崩溃不会影响其他 worker。
    Supervisor.init(children, strategy: :one_for_one)
  end
end


# --- 3. KVStore - 公共 API 与路由 ---
# 这是我们服务的入口。
defmodule KVStore do
  @num_workers 4 # 与监督者中的数量保持一致

  def start_link(opts \\ []) do
    KVStore.Supervisor.start_link(opts)
  end

  def get(key) do
    # 根据 key 找到对应的 worker，然后调用它的 get 函数
    worker_pid = key |> get_worker_pid()
    KVStore.Worker.get(worker_pid, key)
  end

  def put(key, value) do
    worker_pid = key |> get_worker_pid()
    KVStore.Worker.put(worker_pid, key, value)
  end

  def delete(key) do
    worker_pid = key |> get_worker_pid()
    KVStore.Worker.delete(worker_pid, key)
  end

  # --- 私有辅助函数 ---

  # 这是我们的路由逻辑。
  # 它将一个 key 转换为一个 worker 的 PID。
  defp get_worker_pid(key) do
    # 1. 使用 Erlang 内置的哈希函数计算 key 的哈希值。
    # 2. 取模，将其映射到我们的 worker 数量范围内。
    # 3. 构建 worker 的 ID。
    # 4. 使用 `Supervisor.lookup_child/2` 查找该 ID 对应的 PID。
    worker_index = :erlang.phash2(key, @num_workers) + 1
    worker_id = :"worker_#{worker_index}"

    case Supervisor.lookup_child(KVStore.Supervisor, worker_id) do
      {:ok, pid} -> pid
      # 如果在 worker 启动完成前调用，可能会找不到
      :undefined ->
        Process.sleep(10) # 稍作等待
        get_worker_pid(key) # 重试
    end
  end
end

# --- 4. 使用我们的 KVStore ---
IO.puts("--- 启动和使用 KVStore ---")

# 启动整个服务 (监督者会自动启动所有 workers)
{:ok, _pid} = KVStore.start_link()
IO.puts("KVStore 服务已启动。")

# 存放一些数据
IO.puts("\n正在存放数据...")
KVStore.put("elixir", "is awesome")
KVStore.put("otp", "is powerful")
KVStore.put(123, "is a number")
KVStore.put({:a, :tuple}, "is a tuple")

# 读取数据
IO.puts("\n正在读取数据...")
IO.puts("get(\"elixir\") -> #{inspect KVStore.get("elixir")}")
IO.puts("get(\"otp\") -> #{inspect KVStore.get("otp")}")
IO.puts("get(123) -> #{inspect KVStore.get(123)}")
IO.puts("get(\"nonexistent\") -> #{inspect KVStore.get("nonexistent")}")

# 删除数据
IO.puts("\n正在删除数据...")
KVStore.delete("otp")
IO.puts("删除 'otp' 后，get(\"otp\") -> #{inspect KVStore.get("otp")}")

# 演示容错性
IO.puts("\n--- 演示容错性 ---")
key_to_crash = "a_key_to_test_crash"
KVStore.put(key_to_crash, "initial value")

# 找到这个 key 所在的 worker
crashing_worker_pid = KVStore.get_worker_pid(key_to_crash)
IO.puts("#{inspect key_to_crash} 被存储在 Worker #{inspect crashing_worker_pid}")
IO.puts("在它崩溃前，值为: #{inspect KVStore.get(key_to_crash)}")

# 手动让这个 worker 进程退出
IO.puts("\n>>> 手动让 Worker #{inspect crashing_worker_pid} 崩溃...")
Process.exit(crashing_worker_pid, :kill)
Process.sleep(100) # 等待监督者重启它
IO.puts("<<< Worker 已被监督者重启\n")

# 检查 key 的值
# 因为 worker 被重启了，它的状态被重置为空的 Map，所以之前存的值丢失了。
# 在真实世界中，我们会需要持久化存储（如数据库或磁盘文件）来防止数据丢失。
# 这个例子主要演示了服务的“自愈”能力。
IO.puts("Worker 重启后，get(#{inspect key_to_crash}) -> #{inspect KVStore.get(key_to_crash)}")
IO.puts("服务仍然可用，其他 key 不受影响: get(\"elixir\") -> #{inspect KVStore.get("elixir")}")

# --- End of Chapter 10 & Part 4 ---
