# ###################################################################
# 本书由 Jules (AI Software Engineer) 编写
# 章节: 第二部分 - 并发编程与 OTP
# 第7章: 监督者与应用 (Supervisors & Applications)
# ###################################################################

# 监督者 (Supervisor) 是 OTP 的核心组件之一，它的唯一工作就是“监督”其他进程（称为子进程）。
# 如果一个子进程崩溃了，监督者会根据预设的重启策略 (restart strategy) 来重启它。
# 这种“让它崩溃”(Let it crash)的哲学是构建高容错系统的关键。

# --- 1. 一个会崩溃的 GenServer ---
# 为了演示监督者的作用，我们先创建一个可能会崩溃的 GenServer。
defmodule UnstableWorker do
  use GenServer

  # --- Client API ---
  def start_link(state), do: GenServer.start_link(__MODULE__, state)
  def get_state(pid), do: GenServer.call(pid, :get_state)
  def crash(pid), do: GenServer.cast(pid, :crash)

  # --- Server Callbacks ---
  @impl true
  def init(state), do: {:ok, state}

  @impl true
  def handle_call(:get_state, _from, state) do
    {:reply, state, state}
  end

  @impl true
  def handle_cast(:crash, state) do
    # 模拟一个无法处理的错误
    raise "我被要求崩溃了！"
    # GenServer 会捕获这个异常并退出，然后监督者就会介入
    {:noreply, state}
  end

  # 当进程终止时，这个回调会被调用
  @impl true
  def terminate(reason, state) do
    IO.puts("UnstableWorker 正在终止，原因: #{inspect(reason)}, 当前状态: #{inspect(state)}")
  end
end

# --- 2. 定义监督者 (Supervisor) ---
# 监督者本身也是一个进程，我们使用 `Supervisor` 行为来定义它。
defmodule MyApp.Supervisor do
  use Supervisor

  # 启动监督者
  def start_link(arg) do
    Supervisor.start_link(__MODULE__, arg, name: __MODULE__)
  end

  # `init/1` 回调是监督者的核心。它定义了要监督的子进程和重启策略。
  @impl true
  def init(_arg) do
    children = [
      # 定义一个子进程。这里我们使用 `worker/3` 宏。
      # 第一个参数是子进程的模块，第二个是启动参数，第三个是选项。
      # 在 Elixir 1.5+，推荐使用 `{Module, opts}` 的语法
      {UnstableWorker, "初始状态"}
    ]

    # 定义重启策略。
    # :one_for_one - 如果一个子进程崩溃，只重启那一个子进程。
    # 其他策略还有 :one_for_all, :rest_for_one。
    opts = [strategy: :one_for_one]

    Supervisor.init(children, opts)
  end
end

# --- 3. 演示监督过程 ---
IO.puts("--- 演示监督者 ---")

# 启动监督者。它会自动启动其下的子进程 (UnstableWorker)。
{:ok, sup_pid} = MyApp.Supervisor.start_link([])
IO.puts("监督者已启动: #{inspect(sup_pid)}")

# 查找由监督者启动的子进程的 PID
# `Supervisor.which_children/1` 返回一个列表，包含所有子进程的信息。
[{_id, worker_pid, :worker, _modules}] = Supervisor.which_children(MyApp.Supervisor)
IO.puts("监督者下的 UnstableWorker PID: #{inspect(worker_pid)}")

# 检查 worker 的初始状态
initial_state = UnstableWorker.get_state(worker_pid)
IO.puts("Worker 的初始状态: #{inspect(initial_state)}")

# 现在，让 worker 崩溃
IO.puts("\n>>> 让 Worker 崩溃...")
UnstableWorker.crash(worker_pid)

# 等待一下，让监督者有时间重启它
Process.sleep(100)
IO.puts("<<<\n")

# 再次查找子进程的 PID
# 注意！因为进程被重启了，它的 PID 会是一个全新的值。
[{_id, new_worker_pid, :worker, _modules}] = Supervisor.which_children(MyApp.Supervisor)
IO.puts("崩溃后，监督者重启了一个新的 Worker，其 PID 为: #{inspect(new_worker_pid)}")
IO.puts("旧的 PID #{inspect(worker_pid)} 已经不存在了。")

# 检查新 worker 的状态
# 因为是重启，它会用最初的启动参数重新初始化。
restarted_state = UnstableWorker.get_state(new_worker_pid)
IO.puts("新 Worker 的状态: #{inspect(restarted_state)}")
IO.puts("状态被重置回了初始状态，这就是监督系统的容错机制！")

# 停止监督者，它会负责优雅地关闭所有子进程
Supervisor.stop(MyApp.Supervisor)
Process.sleep(100)


# --- 4. 应用 (Application) ---
# 在 Elixir 中，一个完整的项目被称为一个“应用”。
# Application 模块是整个项目的入口点。它的主要职责是启动和停止项目的顶级监督者。
# 当我们使用 `mix new my_app --sup` 创建项目时，会自动生成应用和监督者文件。

# 一个典型的 Application 模块看起来像这样 (通常在 `lib/my_app/application.ex`):
defmodule MyApp.Application do
  use Application

  # `start/2` 是应用启动时的回调。
  @impl true
  def start(_type, _args) do
    # 在这里启动你的顶级监督者
    MyApp.Supervisor.start_link(:ok)
  end
end

# 当你运行 `iex -S mix` 或 `mix run` 时，Elixir 会自动调用这个 `start/2` 函数。
# 这就构成了整个 Elixir/OTP 应用的生命周期和监督树。

# --- 面试常见陷阱 (Interview Pitfall) ---

# 问：什么是监督树 (Supervision Tree)？
# 答：监督树是 Elixir/OTP 应用的骨架。它是一个由监督者和工作进程 (worker) 组成的层级结构。
# 树的顶层是一个顶级监督者，它负责监督一些核心的子监督者或工作进程。
# 这些子监督者又可以监督更下层的进程，以此类推，形成一棵树。
# 这种结构允许我们将应用的容错逻辑分层，隔离不同部分的故障，从而构建出极度健壮的系统。

# 问：解释一下常见的监督策略。
# 答：
# -   **:one_for_one**: 这是最常用的策略。如果一个子进程崩溃，只有**那一个**子进程会被重启。适用于子进程之间相互独立的场景。
# -   **:one_for_all**: 如果一个子进程崩溃，**所有**的兄弟子进程都会被先终止，然后再全部一起重启。适用于子进程之间有紧密依赖的场景。
# -   **:rest_for_one**: 如果一个子进程崩溃，在它**启动顺序之后**的那些兄弟进程会被终止并和它一起重启。适用于子进程有顺序依赖的场景。

# --- End of Chapter 7 & Part 2 ---
