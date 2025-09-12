# ###################################################################
# 本书由 Jules (AI Software Engineer) 编写
# 章节: 第一部分 - Elixir 基础
# 第2章: 基础运算符与控制流
# ###################################################################

# --- 1. 基础运算符 (Basic Operators) ---

# --- 1.1 算术运算符 (Arithmetic Operators) ---
IO.puts("--- 1.1 算术运算符 ---")
a = 10
b = 4
IO.puts("#{a} + #{b} = #{a + b}")   # 加法
IO.puts("#{a} - #{b} = #{a - b}")   # 减法
IO.puts("#{a} * #{b} = #{a * b}")   # 乘法
IO.puts("#{a} / #{b} = #{a / b}")   # 除法，结果总是浮点数

# Elixir 提供了两个特殊的函数来处理整数除法
IO.puts("div(#{a}, #{b}) = #{div(a, b)}") # 整数除法
IO.puts("rem(#{a}, #{b}) = #{rem(a, b)}") # 取余数


# --- 1.2 比较运算符 (Comparison Operators) ---
# 比较运算符可以比较不同的数据类型。Elixir 对所有类型都有一个预定义的排序规则。
# number < atom < reference < function < port < pid < tuple < map < list < bitstring
IO.puts("\n--- 1.2 比较运算符 ---")
IO.puts("1 > 5 is #{1 > 5}")
IO.puts("1 < 5 is #{1 < 5}")
IO.puts(":apple > :banana is #{:apple > :banana}") # 原子按字母顺序比较

# 特别注意: Elixir 使用 `==` 进行值比较，使用 `===` 进行严格的类型和值比较。
IO.puts("1 == 1.0 is #{1 == 1.0}")     # true, 因为它们在数值上相等
IO.puts("1 === 1.0 is #{1 === 1.0}")   # false, 因为它们是不同的数据类型 (Integer vs Float)
IO.puts("1 != 1.0 is #{1 != 1.0}")     # false
IO.puts("1 !== 1.0 is #{1 !== 1.0}")   # true


# --- 1.3 逻辑运算符 (Boolean Operators) ---
# `and`, `or`, `not`。这些运算符要求第一个参数必须是布尔值。
IO.puts("\n--- 1.3 逻辑运算符 ---")
IO.puts("true and false is #{true and false}")
IO.puts("true or false is #{true or false}")
IO.puts("not true is #{not true}")
# IO.puts("1 and true") # 如果取消注释，会抛出 BadArgumentError


# --- 1.4 短路运算符 (Short-circuit Operators) ---
# `&&`, `||`, `!`。这些运算符不要求第一个参数是布尔值。
# 它们会根据 "truthy" 或 "falsy" 来判断。在 Elixir 中，只有 `false` 和 `nil` 是 "falsy" 的，其他一切都是 "truthy"。
IO.puts("\n--- 1.4 短路运算符 ---")
IO.puts("1 && true is #{1 && true}")           # 右边的值: true
IO.puts("nil && 20 is #{inspect(nil && 20)}")   # 左边的值: nil
IO.puts("1 || false is #{1 || false}")         # 左边的值: 1
IO.puts("false || 2 is #{false || 2}")       # 右边的值: 2
IO.puts("!true is #{!true}")                 # false
IO.puts("!1 is #{!1}")                       # false, 因为 1 是 truthy
IO.puts("!nil is #{!nil}")                   # true, 因为 nil 是 falsy


# --- 2. 控制流 (Control Flow) ---

# --- 2.1 `if` 和 `unless` ---
# 这是 Elixir 中最基础的条件判断。
# `if` 在条件为 truthy (非 false 或 nil) 时执行。
# `unless` 与 `if` 相反，在条件为 falsy (false 或 nil) 时执行。
IO.puts("\n--- 2.1 if/unless ---")
age = 18
if age >= 18 do
  IO.puts("你已经是成年人了。")
end

is_logged_in = false
unless is_logged_in do
  IO.puts("请先登录。")
end

# `if` 也是一个表达式，它有返回值。
message = if is_logged_in do
  "欢迎回来！"
else
  "访客你好！"
end
IO.puts(message)


# --- 2.2 `cond` ---
# 当有多个条件分支时，`cond` 非常有用。它会执行第一个结果为 truthy 的分支。
IO.puts("\n--- 2.2 cond ---")
score = 85
grade = cond do
  score >= 90 -> "A"
  score >= 80 -> "B"
  score >= 60 -> "C"
  true -> "D" # 最后的 `true` 分支确保总有一个分支被匹配，类似其他语言的 `else`。
end
IO.puts("你的成绩等级是: #{grade}")

# 如果没有任何分支匹配，`cond` 会抛出 CondClauseError。所以 `true` 分支是个好习惯。


# --- 2.3 `case` ---
# `case` 允许你对一个值进行模式匹配，并根据匹配的模式执行不同的代码块。
# 这是 Elixir 中比 `if` 和 `cond` 更常用的结构，因为它利用了模式匹配的强大能力。
IO.puts("\n--- 2.3 case ---")
value = {:ok, "一些有用的数据"}

result_message = case value do
  {:ok, data} ->
    "操作成功，数据是: #{data}"
  {:error, reason} ->
    "操作失败，原因是: #{reason}"
  _ -> # 使用下划线 _ 匹配任何其他情况，防止 MatchError
    "收到了未知结构的值: #{inspect(value)}"
end
IO.puts(result_message)


# --- 面试常见陷阱 (Interview Pitfall) ---

# 问：`and`/`or` 和 `&&`/`||` 有什么区别？
# 答：
# `and`/`or` 是严格的布尔运算符，它们的第一个参数必须是 `true` 或 `false`，否则会报错。
# `&&`/`||` 是短路运算符，它们可以接受任何类型的值。它们根据 "truthiness" (除了 `false` 和 `nil` 之外都为 true) 来工作。
# 在实际开发中，`&&` 和 `||` 更常用，因为它们更灵活。而 `and`/`or` 主要用于需要明确布尔逻辑的场景。

# 问：`if`, `cond`, `case` 之间如何选择？
# 答：
# `if/unless`: 用于只有一两个简单条件分支的场景。
# `cond`: 用于需要检查多个不同条件（这些条件不一定基于同一个变量）的场景。
# `case`: 当你需要对同一个值或表达式进行多种模式匹配时，这是首选。在 Elixir 中，由于模式匹配的强大功能，`case` 的使用频率非常高，通常比 `cond` 更受欢迎。它能让代码更清晰、更具声明性。

# --- 练习 (Exercise) ---
# 1. 编写一个 `case` 语句，检查一个列表。
#    - 如果列表为空 `[]`，打印 "列表是空的"。
#    - 如果列表只有一个元素 `[x]`，打印 "列表只有一个元素: [元素的值]"。
#    - 如果列表的头部是 `:start`，例如 `[:start, ...]`，打印 "列表以 :start 开头"。
#    - 对于任何其他情况，打印 "这是一个普通的列表"。

IO.puts("\n--- 练习 ---")
def check_list(list) do
  case list do
    [] ->
      IO.puts("列表是空的")
    [x] ->
      IO.puts("列表只有一个元素: #{inspect(x)}")
    [:start | _tail] ->
      IO.puts("列表以 :start 开头")
    _ ->
      IO.puts("这是一个普通的列表")
  end
end

check_list([])
check_list([100])
check_list([:start, :middle, :end])
check_list(["hello", "world"])

# --- End of Chapter 2 ---
