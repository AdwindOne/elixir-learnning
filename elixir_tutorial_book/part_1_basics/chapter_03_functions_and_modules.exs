# ###################################################################
# 本书由 Jules (AI Software Engineer) 编写
# 章节: 第一部分 - Elixir 基础
# 第3章: 函数与模块
# ###################################################################

# 在 Elixir 中，代码被组织在模块 (Module) 中。模块是具名函数 (named functions) 的集合。

# --- 1. 模块定义 (Defining a Module) ---
# 使用 `defmodule` 关键字来定义一个模块。模块名通常使用大驼峰命名法 (CamelCase)。
defmodule MyMath do
  # 在模块内部，你可以定义函数。

  # --- 2. 具名函数 (Named Functions) ---
  # 使用 `def` 来定义一个公共函数，使用 `defp` 定义私有函数。
  # 函数名通常使用蛇形命名法 (snake_case)。
  # `add/2` 表示函数名为 `add` 且接受 2 个参数 (arity)。

  @doc """
  计算两个数的和。这是一个公共函数。
  可以使用 `h MyMath.add` 在 iex 中查看此文档。

  ## 示例

      iex> MyMath.add(1, 2)
      3
  """
  def add(a, b) do
    a + b # Elixir 中函数的最后一行表达式的值就是返回值，不需要显式的 `return`
  end

  # 这是一个私有函数，只能在 `MyMath` 模块内部被调用。
  defp secret_multiplier do
    10
  end

  # --- 3. 函数重载与模式匹配 (Function Overloading & Pattern Matching) ---
  # Elixir 允许定义多个同名但参数模式不同的函数。
  # 这是一种强大的特性，可以让代码非常具有声明性。

  @doc "计算一个列表所有元素的和。如果列表为空，和为0。"
  def sum_list([]), do: 0 # 当输入为空列表时，直接返回0。

  def sum_list([head | tail]) do
    # 当输入为非空列表时，递归地计算 head 与 tail 的和。
    head + sum_list(tail)
  end

  # --- 4. 守卫子句 (Guard Clauses) ---
  # 守卫子句允许你在函数定义中添加额外的检查。使用 `when` 关键字。
  # 它们必须返回 `true`，函数体才会执行。

  @doc "检查一个数字是否为正数、负数或零。"
  def check_sign(x) when is_number(x) and x > 0, do: :positive
  def check_sign(x) when is_number(x) and x < 0, do: :negative
  def check_sign(0), do: :zero
  # 如果没有守卫子句匹配，将会抛出 FunctionClauseError。

  # --- 5. 默认参数 (Default Arguments) ---
  # 使用 `\\` 操作符为函数参数提供默认值。

  @doc "发出问候。如果没有提供名字，就问候“世界”。"
  def greet(name \\ "世界") do
    "你好, #{name}!"
  end
end


# --- 使用模块和函数 ---
IO.puts("--- 调用模块函数 ---")
IO.puts("MyMath.add(5, 3) = #{MyMath.add(5, 3)}")

# MyMath.secret_multiplier() # 如果取消注释，会编译失败，因为私有函数不能从外部调用。

IO.puts("\n--- 函数重载与模式匹配示例 ---")
IO.puts("MyMath.sum_list([1, 2, 3, 4, 5]) = #{MyMath.sum_list([1, 2, 3, 4, 5])}")
IO.puts("MyMath.sum_list([]) = #{MyMath.sum_list([])}")

IO.puts("\n--- 守卫子句示例 ---")
IO.puts("MyMath.check_sign(10) = #{inspect MyMath.check_sign(10)}")
IO.puts("MyMath.check_sign(-5) = #{inspect MyMath.check_sign(-5)}")
IO.puts("MyMath.check_sign(0) = #{inspect MyMath.check_sign(0)}")

IO.puts("\n--- 默认参数示例 ---")
IO.puts("MyMath.greet() = #{MyMath.greet()}")
IO.puts("MyMath.greet(\"Jules\") = #{MyMath.greet("Jules")}")


# --- 6. 匿名函数 (Anonymous Functions) ---
# 匿名函数，也叫 lambda，使用 `fn` 和 `end` 关键字创建。
# 它们可以被赋值给变量，并像其他值一样传递。
IO.puts("\n--- 匿名函数 ---")

add_two = fn(a, b) -> a + b end
IO.puts("调用匿名函数 add_two.(3, 4) = #{add_two.(3, 4)}") # 注意调用匿名函数时的 `.` 语法

# 匿名函数也支持多子句和守卫。
check_sign_anon = fn
  (x) when x > 0 -> :positive
  (x) when x < 0 -> :negative
  (0) -> :zero
end
IO.puts("调用匿名函数 check_sign_anon.(10) = #{inspect check_sign_anon.(10)}")

# --- 7. 捕获操作符 & (Capture Operator) ---
# `&` 是创建匿名函数的简写形式。
# `&1`, `&2` 等表示函数的第一个、第二个参数。
IO.puts("\n--- 捕获操作符 ---")

# `fn(a, b) -> a + b end` 的简写形式
add_shortcut = &(&1 + &2)
IO.puts("调用简写匿名函数 add_shortcut.(5, 6) = #{add_shortcut.(5, 6)}")

# 也可以用来捕获具名函数。
sum_list_fun = &MyMath.sum_list/1 # 捕获 MyMath 模块中名为 sum_list，参数数量为 1 的函数
IO.puts("调用捕获的具名函数: #{sum_list_fun.([10, 20, 30])}")


# --- 8. 管道操作符 |> (Pipe Operator) ---
# 管道操作符是 Elixir 中最受欢迎的特性之一。
# 它将一个表达式的结果作为下一个函数的第一个参数。
# 这使得数据转换的流程非常清晰易读。
IO.puts("\n--- 管道操作符 ---")

# 假设我们想对一个数字：乘以3，然后转为字符串，最后加上感叹号。
# 不用管道：
result_without_pipe = "结果是: " <> (to_string(MyMath.add(5, 5) * 3))
IO.puts("不使用管道: #{result_without_pipe}")

# 使用管道：
result_with_pipe =
  5
  |> MyMath.add(5)      # 5 成为 add 的第一个参数 -> MyMath.add(5, 5) -> 10
  |> Kernel.*(3)        # 10 成为 * 的第一个参数 -> 10 * 3 -> 30
  |> to_string()        # 30 成为 to_string 的第一个参数 -> "30"
  |> Kernel.<>("结果是: ", &1) # "30" 成为 <> 的第二个参数 -> "结果是: 30"

IO.puts("使用管道: #{result_with_pipe}")


# --- 面试常见陷阱 (Interview Pitfall) ---

# 问：什么是函数的 arity？为什么它很重要？
# 答：Arity 是指函数接受的参数数量。在 Elixir (和 Erlang) 中，函数由它的名字和 arity 共同唯一确定。
# 例如，`MyMath.add/2` 和 `MyMath.add/3` 被认为是两个完全不同的函数。
# 这对于函数重载、递归定义以及使用捕获操作符 `&MyModule.my_fun/1` 时至关重要。

# 问：管道操作符 `|>` 的工作原理是什么？
# 答：它将左边表达式的结果，作为右边函数调用的第一个参数。
# `x |> fun(y)` 等价于 `fun(x, y)`。
# 这使得从左到右、从上到下的数据转换流程变得非常自然和可读，是函数式编程中组合函数的利器。

# --- 练习 (Exercise) ---
# 1. 创建一个名为 `StringHelper` 的模块。
# 2. 在模块中，定义一个公共函数 `spacify/1`，它接受一个字符串，并在字符串的每个字符之间添加一个空格。
#    例如: `StringHelper.spacify("hello")`应该返回 `"h e l l o"`。
#    提示: 使用 `String.split/2` 和 `Enum.join/2` 函数。
# 3. 使用管道操作符来重写 `spacify/1` 的实现。

IO.puts("\n--- 练习 ---")

defmodule StringHelper do
  def spacify(string) do
    string
    |> String.split("", trim: true) # "hello" -> ["h", "e", "l", "l", "o"]
    |> Enum.join(" ")               # ["h", "e", "l", "l", "o"] -> "h e l l o"
  end
end

IO.puts("StringHelper.spacify(\"elixir\") = \"#{StringHelper.spacify("elixir")}\"")

# --- End of Chapter 3 ---
