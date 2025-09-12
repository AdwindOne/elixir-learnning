# ###################################################################
# 本书由 Jules (AI Software Engineer) 编写
# 章节: 第三部分 - 项目与生态
# 第9章: 高级主题
# ###################################################################

# 本章我们将接触一些 Elixir 中更高级、更强大的特性。
# 理解它们将让你能编写出更灵活、更具表现力的代码。

# --- 1. Sigils ---
# Sigil 是 Elixir 中一种语法糖，用于处理文本表示。它们以波浪号 `~` 开头，后跟一个字符。
# Elixir 内置了一些 Sigil，你也可以自定义。

IO.puts("--- 1. Sigils ---")

# `~s` 和 `~S`: 用于创建字符串，区别在于是否处理转义字符和插值。
# `~s` (小写) 会处理转义和插值。
str1 = ~s(你好, "Jules"!) # 在这里使用括号可以避免与字符串内的引号冲突
IO.puts("~s(你好, \"Jules\"!) -> #{str1}")
# `~S` (大写) 不会处理它们。
str2 = ~S(你好, "Jules"! \#{1+1})
IO.puts("~S(...) -> #{str2}")

# `~w` 和 `~W`: 用于创建单词列表 (list of strings)。
# `~w` (小写) 是最常用的，它会按空格分割。
word_list = ~w(elixir is awesome)
IO.puts("~w(elixir is awesome) -> #{inspect word_list}")
# `~W` (大写) 也支持插值。

# `~r`: 用于创建正则表达式。
regex = ~r/hello/i # i 表示不区分大小写
is_match = "Hello, World!" =~ regex
IO.puts("'Hello, World!' =~ ~r/hello/i -> #{is_match}")

# `~D`: 用于创建日期。
date = ~D[2025-09-11]
IO.puts("~D[2025-09-11] -> #{inspect date}")


# --- 2. Behaviours (行为) ---
# Behaviour 类似于其他语言中的接口 (Interface)。它定义了一组必须被模块实现的回调函数规范。
# GenServer 就是一个典型的 Behaviour，它要求你实现 `init/1`, `handle_call/3` 等回调。

IO.puts("\n--- 2. Behaviours ---")

# 定义一个 Behaviour
defmodule Parser do
  @doc "解析一个二进制数据"
  # `@callback` 定义了需要被实现的回调函数规范。
  # `::` 用于类型标注 (typespec)。
  @callback parse(binary) :: {:ok, map} | {:error, atom}

  @doc "将一个 map 编码为二进制数据"
  @callback encode(map) :: {:ok, binary} | {:error, atom}
end

# 实现这个 Behaviour
defmodule JsonParser do
  # `@behaviour` 宏声明本模块实现了指定的 Behaviour。
  # 如果没有完全实现，编译器会发出警告。
  @behaviour Parser

  # 实现 parse 回调
  @impl Parser
  def parse(binary) do
    # 伪代码，实际应使用一个 JSON 库
    IO.puts("正在使用 JsonParser 解析: #{binary}")
    {:ok, %{data: binary}}
  end

  # 实现 encode 回调
  @impl Parser
  def encode(map) do
    IO.puts("正在使用 JsonParser 编码: #{inspect(map)}")
    {:ok, "{...json...}"}
  end
end

defmodule MsgpackParser do
  @behaviour Parser
  @impl Parser
  def parse(binary), do: {:ok, %{data: binary, format: :msgpack}}
  @impl Parser
  def encode(map), do: {:ok, "<<...msgpack...>>"}
end

# 使用实现了 Behaviour 的模块
def process_data(parser_module, data) do
  # 我们可以依赖 Behaviour 定义的接口，而不关心具体实现
  parser_module.parse(data)
end

IO.puts("使用 JsonParser: #{inspect process_data(JsonParser, "<<json>>")}")
IO.puts("使用 MsgpackParser: #{inspect process_data(MsgpackParser, "<<msgpack>>")}")


# --- 3. Protocols (协议) ---
# Protocol 实现了 Elixir 中的多态。它允许你为不同的数据类型定义相同的函数名。
# `Enum` 模块就是基于 Protocol 实现的，`Enum.map/2` 之所以能同时用于列表和图，就是因为它们都实现了 `Enumerable` 协议。

IO.puts("\n--- 3. Protocols ---")

# 定义一个协议
defprotocol Size do
  @doc "计算数据结构的“大小”"
  def size(data)
end

# 为不同的数据类型实现协议
defimpl Size, for: BitString do
  # 为字符串 (二进制) 实现 Size 协议
  def size(string), do: String.length(string)
end

defimpl Size, for: List do
  # 为列表实现 Size 协议
  def size(list), do: length(list)
end

defimpl Size, for: Map do
  # 为图实现 Size 协议
  def size(map), do: map_size(map)
end

# 使用协议
IO.puts("Size.size(\"hello\") -> #{Size.size("hello")}")
IO.puts("Size.size([1, 2, 3]) -> #{Size.size([1, 2, 3])}")
IO.puts("Size.size(%{a: 1, b: 2}) -> #{Size.size(%{a: 1, b: 2})}")


# --- 4. Metaprogramming (元编程) & Macros (宏) ---
# 元编程是“编写能够编写代码的代码”。宏是 Elixir 实现元编程的主要工具。
# 宏在编译时执行，它们接收 AST (抽象语法树) 作为输入，并返回 AST 作为输出。
# `if`, `def`, `defmodule` 等 Elixir 的核心构件，实际上都是用宏实现的。

# **警告: 宏非常强大，但也非常复杂，容易被滥用。你应该只在没有其他选择时才使用它。**

IO.puts("\n--- 4. 元编程与宏 ---")

defmodule MyMacros do
  # 定义一个宏
  defmacro assert_equal(left, right) do
    # `quote` 用于生成 AST
    quote do
      # `unquote` 用于将变量的值注入到 AST 中
      left_val = unquote(left)
      right_val = unquote(right)
      if left_val != right_val do
        raise "断言失败! 左侧: #{inspect left_val}, 右侧: #{inspect right_val}"
      else
        IO.puts("断言成功: #{inspect left_val} == #{inspect right_val}")
      end
    end
  end
end

defmodule MacroTest do
  # `require` 使得我们可以不带模块前缀地调用宏
  require MyMacros

  def run_tests do
    MyMacros.assert_equal(1 + 1, 2)
    MyMacros.assert_equal(String.length("hi"), 2)
    # 下面的调用会在编译时就因为断言失败而报错
    # MyMacros.assert_equal(2 * 2, 5)
  end
end

MacroTest.run_tests()


# --- 面试常见陷阱 (Interview Pitfall) ---

# 问：Behaviour 和 Protocol 有什么区别？
# 答：
# -   **Behaviour (行为)**: 解决的是“一组模块有相同的 API”的问题。它定义了一个**接口规范**，由**模块**来实现。例如，不同的解析器模块（`JsonParser`, `XmlParser`）都实现了 `Parser` 行为。调用时你需要明确指定模块：`JsonParser.parse(data)`。
# -   **Protocol (协议)**: 解决的是“为不同数据类型实现同样的功能”的问题（多态）。它定义了一个**函数**，可以根据传入的**数据类型**分发到不同的实现。例如，`size("hello")` 和 `size([1,2])` 调用的是同一个函数 `Size.size/1`，但 Elixir 会根据第一个参数的类型（字符串或列表）自动选择正确的实现。
# -   **总结**: Behaviour 是关于**模块**的，Protocol 是关于**数据类型**的。

# 问：宏和函数有什么区别？
# 答：
# -   **执行时机**: 函数在**运行时**执行。宏在**编译时**执行。
# -   **输入输出**: 函数接收和返回**值**。宏接收和返回**代码的抽象语法树 (AST)**。
# -   **能力**: 宏可以做函数做不到的事情，比如定义新函数（`def` 就是一个宏）、控制代码是否被编译（如 `if`）、或者在编译时抛出错误。因为宏可以“重写”代码，所以它们的能力要强大得多，也危险得多。

# --- End of Chapter 9 ---
