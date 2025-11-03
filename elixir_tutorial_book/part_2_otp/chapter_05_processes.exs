# ###################################################################
# 本书由 Jules (AI Software Engineer) 编写
# 章节: 第二部分 - 并发编程与 OTP
# 第5章: 进程 (Processes)
# ###################################################################

# Elixir 的并发模型构建在 Erlang VM (BEAM) 的“进程”之上。
# 这些不是操作系统的进程，而是由 BEAM 管理的极其轻量级的“绿色线程”。
# 它们启动速度极快，内存占用极小，可以轻易地同时运行数十万个。

# 核心理念:
# 1. 隔离 (Isolated): 每个进程都有自己独立的内存和垃圾回收，一个进程的崩溃不会影响其他进程。
# 2. 并发 (Concurrent): 进程可以同时运行。在多核 CPU 上，它们可以并行运行。
# 3. 通信 (Communication): 进程之间不共享内存，通过发送和接收消息进行通信。

# --- 1. `spawn` - 创建一个新进程 ---
# `spawn/1` 或 `spawn/3` 用于创建一个新的进程。它会立即返回一个进程标识符 (PID)。
# 新进程会并发地执行指定的函数。

IO.puts("--- 1. spawn ---")
# `spawn` 接受一个匿名函数
pid = spawn(fn ->
  # 这部分代码将在一个新的进程中执行
  IO.puts("你好，我是一个新进程! 我的 PID 是: #{inspect(self())}")
  # self() 返回当前进程的 PID
  Process.sleep(1000) # 让进程“工作”一秒钟
  IO.puts("新进程执行完毕。")
end)

IO.puts("主进程 (#{inspect(self())}) 创建了一个新进程，其 PID 是: #{inspect(pid)}")
IO.puts("主进程会继续执行，不会等待新进程结束。")
# 为了演示，我们让主进程等待一下，以便看到新进程的输出
Process.sleep(1500)


# --- 2. `send` 和 `receive` - 进程间通信 ---
# `send/2` 用于向一个 PID 发送消息。这是一个异步、非阻塞的操作。
# `receive/1` 用于在一个进程中等待并接收消息。这是一个阻塞操作。

IO.puts("\n--- 2. send 和 receive ---")

# 创建一个“回声”进程，它会接收消息并将其打印出来
echo_pid = spawn(fn ->
  # `receive` 块会检查进程的“邮箱”
  receive do
    # 它使用模式匹配来处理消息
    {:ping, message, from_pid} ->
      IO.puts("回声进程收到了: #{message}")
      # 我们可以回发一条消息
      send(from_pid, {:pong, "我收到了你的消息: '#{message}'"})

    # 可以有多个 `after` 子句，但只有最后一个会执行
    unexpected_message ->
      IO.puts("回声进程收到了一个意料之外的消息: #{inspect(unexpected_message)}")
  end
end)

# 获取主进程的 PID
main_pid = self()

# 向回声进程发送消息
IO.puts("主进程正在向 #{inspect(echo_pid)} 发送消息...")
send(echo_pid, {:ping, "你好呀!", main_pid})

# 主进程现在等待回复
IO.puts("主进程正在等待回复...")
receive do
  {:pong, reply_message} ->
    IO.puts("主进程收到了回复: #{reply_message}")
  # `after` 子句用于设置超时
after
  2000 -> IO.puts("主进程等待超时了！")
end


# --- 3. 进程状态管理 ---
# 由于进程不共享内存，那么如何管理状态呢？
# 答案是：通过递归循环。一个进程可以持有一个状态，处理一条消息，然后用新状态再次调用自己。

IO.puts("\n--- 3. 进程状态管理 (计数器示例) ---")

# 定义一个模块来封装我们的计数器逻辑
defmodule Counter do
  # 启动一个新的计数器进程，初始值为 0
  def start do
    spawn(fn -> Counter.loop(0) end)
  end

  # 进程的循环函数，持有当前状态 `count`
  def loop(count) do
    receive do
      {:increment, from_pid} ->
        new_count = count + 1
        send(from_pid, {:ok, new_count})
        loop(new_count) # 使用新状态递归调用 loop

      {:get, from_pid} ->
        send(from_pid, {:ok, count})
        loop(count) # 状态不变，继续循环

      :stop ->
        IO.puts("计数器进程已停止。")

      _ ->
        loop(count) # 忽略未知消息，继续循环
    end
  end
end

# 启动计数器
counter_pid = Counter.start()
IO.puts("计数器进程已启动: #{inspect(counter_pid)}")

# 发送指令
send(counter_pid, {:increment, self()})
receive do
  {:ok, new_count} -> IO.puts("计数器值增加到: #{new_count}")
end

send(counter_pid, {:increment, self()})
receive do
  {:ok, new_count} -> IO.puts("计数器值增加到: #{new_count}")
end

send(counter_pid, {:get, self()})
receive do
  {:ok, current_count} -> IO.puts("当前计数器值为: #{current_count}")
end

# 停止计数器
send(counter_pid, :stop)
Process.sleep(100) # 等待停止消息打印


# --- 面试常见陷阱 (Interview Pitfall) ---

# 问：Elixir 进程和操作系统的进程/线程有什么区别？
# 答：
# 1.  **轻量级**: Elixir 进程由 BEAM 虚拟机管理，而非操作系统。它们极其轻量，只有几 KB 的内存开销，启动速度是微秒级别。一个普通的笔记本可以轻松运行数十万个 Elixir 进程。操作系统的进程/线程则重得多。
# 2.  **隔离性**: Elixir 进程之间不共享内存，完全隔离。这使得系统非常健壮，一个进程的错误不会拖垮其他进程。操作系统线程通常共享内存，这使得并发编程容易出错（如竞态条件、死锁）。
# 3.  **调度**: BEAM 有一个高效的、抢占式的调度器，确保每个进程都能获得公平的运行时间，防止某个进程长时间霸占 CPU，从而保证系统的低延迟和响应性。

# 问：`send` 是同步还是异步的？
# 答：`send` 是完全**异步**和**非阻塞**的。调用 `send` 后，消息被放入目标进程的邮箱，然后调用者立即继续执行，不会等待消息被处理。这被称为“发后不理”(fire and forget)。

# 问：`receive` 会永远等下去吗？
# 答：不一定。`receive` 块可以包含一个 `after` 子句来指定一个超时时间。如果在指定时间内没有匹配到任何消息，`after` 子句的代码就会被执行。如果没有 `after` 子句，它才会永远等待。

# --- 警告 ---
# 直接使用 `spawn`, `send`, `receive` 来构建应用被称为“裸进程编程”。
# 虽然这对于理解并发模型很有帮助，但在实际生产项目中，我们几乎总是使用 OTP (Open Telecom Platform) 提供的更高级别的抽象，如 `GenServer`。
# `GenServer` 为我们封装了标准的进程循环、状态管理、同步/异步调用等逻辑，使得代码更健壮、更易于维护和调试。我们将在下一章学习它。

# --- End of Chapter 5 ---
