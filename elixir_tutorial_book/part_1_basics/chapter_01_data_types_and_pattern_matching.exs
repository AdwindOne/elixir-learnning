# ###################################################################
# 本书由 Jules (AI Software Engineer) 编写
# 章节: 第一部分 - Elixir 基础
# 第1章: 数据类型与模式匹配
# ###################################################################

# --- 1. 基本数据类型 (Basic Data Types) ---

# Elixir 提供了丰富的基础数据类型。所有的值在 Elixir 中都是不可变的 (immutable)。

# --- 1.1 整型 (Integers) ---
# 整型数字，可以是正数或负数。
integer_example = 42
IO.puts("整型示例: " <> to_string(integer_example)) # to_string 用于将数字转换为字符串进行打印

# Elixir 支持二进制、八进制和十六进制表示法。
binary_example = 0b101010  # 0b 前缀表示二进制 (结果是 42)
octal_example = 0o52      # 0o 前缀表示八进制 (结果是 42)
hex_example = 0x2A      # 0x 前缀表示十六进制 (结果是 42)
IO.puts("二进制 0b101010 是: " <> to_string(binary_example))
IO.puts("八进制 0o52 是: " <> to_string(octal_example))
IO.puts("十六进制 0x2A 是: " <> to_string(hex_example))


# --- 1.2 浮点型 (Floats) ---
# 浮点数必须包含一个小数点，小数点后至少有一位数字。它们使用64位双精度。
float_example = 3.14159
IO.puts("浮点型示例: " <> to_string(float_example))

# 支持科学计数法
scientific_notation_example = 3.14e-2 # 等于 0.0314
IO.puts("科学计数法示例: " <> to_string(scientific_notation_example))


# --- 1.3 布尔型 (Booleans) ---
# 只有两个值: true 和 false。在 Elixir 中，nil 也被认为是 "falsy" 的。
true_bool = true
false_bool = false
IO.puts("布尔型 true: " <> to_string(true_bool))
IO.puts("布尔型 false: " <> to_string(false_bool))


# --- 1.4 原子 (Atoms) ---
# 原子是一个常量，其名称就是它的值。它们通常用于表示状态或特定的、不变的值。
# 它们以冒号 (:) 开头。
status_ok = :ok
status_error = :error
IO.puts("原子 :ok 的 inspect 结果: " <> inspect(status_ok)) # inspect 用于获取任何数据类型的文本表示

# true 和 false 实际上是原子 :true 和 :false 的简写。
is_true_an_atom = is_atom(true)
IO.puts("true 是一个原子吗? " <> to_string(is_true_an_atom))


# --- 1.5 字符串 (Strings) ---
# 字符串由双引号 (") 包裹，并以 UTF-8 编码。
string_example = "你好, Elixir! 👋"
IO.puts("字符串示例: " <> string_example)

# 字符串支持插值 (interpolation)，使用 #{} 语法。
name = "Jules"
greeting = "你好, #{name}!"
IO.puts("字符串插值: " <> greeting)

# 多行字符串可以使用三个双引号 (""")。
multiline_string = """
这是
一个多行
字符串。
"""
IO.puts("多行字符串示例:\n" <> multiline_string)

# 在 Elixir 内部，字符串实际上是二进制数据（binaries）。
is_string_a_binary = is_binary("hello")
IO.puts("字符串是二进制数据吗? " <> to_string(is_string_a_binary))


# --- 1.6 列表 (Lists) ---
# 列表由方括号 ([]) 包裹，值可以是任何类型。
# 列表在 Elixir 中是链表结构，意味着在头部添加元素非常快，但获取长度或在尾部添加元素较慢。
list_example = [1, "二", :three, 4.0, false]
IO.puts("列表示例: " <> inspect(list_example))

# 列表的拼接使用 ++ 操作符。
new_list = list_example ++ [5, 6]
IO.puts("列表拼接: " <> inspect(new_list))

# 在列表头部添加元素使用 [ head | tail ] 语法，效率很高。
prepended_list = [0 | new_list]
IO.puts("在头部添加元素: " <> inspect(prepended_list))


# --- 1.7 元组 (Tuples) ---
# 元组由花括号 ({}) 包裹，值可以是任何类型。
# 元组在内存中是连续存储的，这使得获取其大小或通过索引访问元素非常快。
# 它们通常用于函数返回多个值，特别是表示成功或失败。
tuple_example = {:ok, "操作成功", 123}
IO.puts("元组示例: " <> inspect(tuple_example))

# 通过 elem/2 函数访问元组中的元素（索引从0开始）。
element = elem(tuple_example, 1) # 获取第二个元素
IO.puts("元组的第二个元素是: " <> element)


# --- 2. 模式匹配 (Pattern Matching) ---

# 模式匹配是 Elixir 最强大的特性之一。= 在 Elixir 中不仅仅是赋值，更是“断言”或“匹配”操作符。

# --- 2.1 基础匹配 ---
x = 1       # 这里是赋值，因为 x 尚未绑定
IO.puts("x 的值: " <> to_string(x))
1 = x       # 这里是匹配。因为 x 的值是 1，所以 1 = 1 匹配成功。
# 2 = x     # 如果取消这行注释，程序会抛出 MatchError，因为 2 不等于 x(1)。

# --- 2.2 匹配元组 ---
# 这是模式匹配最常见的用途之一。
{:ok, result} = {:ok, "一些数据"}
IO.puts("从元组中匹配出的 result: " <> result)

# 如果模式不匹配，将会失败。
# {:ok, result} = {:error, "出错了"} # 这会抛出 MatchError

# 使用下划线 _ 来忽略不关心的值。
{:error, _reason} = {:error, "数据库超时"} # 我们只关心是错误，不关心具体原因
IO.puts("成功匹配到 :error 元组，忽略了原因。")


# --- 2.3 匹配列表 ---
# 列表匹配常用于递归和处理列表头部/尾部。
[head | tail] = [1, 2, 3, 4]
IO.puts("列表的头部 (head): " <> inspect(head)) # head 会是 1
IO.puts("列表的尾部 (tail): " <> inspect(tail)) # tail 会是 [2, 3, 4]

[a, b, c] = [:apple, :banana, :cherry]
IO.puts("匹配固定长度的列表: a=#{inspect a}, b=#{inspect b}, c=#{inspect c}")

# --- 面试常见陷阱 (Interview Pitfall) ---
# 问：= 在 Elixir 中是什么意思？
# 答：它不是赋值操作符，而是匹配操作符 (the match operator)。它会尝试将左边的模式与右边的值进行匹配。
# 只有当左边的变量未绑定时，它才表现得像传统语言中的赋值。

# 问：列表和元组有什么区别？应该在什么时候使用它们？
# 答：
# 列表 (List): 基于链表实现。在列表头部插入/读取元素 (O(1)) 非常快，但获取长度或随机访问 (O(n)) 很慢。适用于需要处理长度可变的元素序列的场景，特别是递归处理。
# 元组 (Tuple): 在内存中连续存储。获取长度或通过索引访问元素 (O(1)) 非常快，但修改（技术上是创建新元组）成本很高。适用于存储固定数量的元素，常用于函数返回多个值（如 {:ok, value}）。

# --- 练习 (Exercise) ---
# 1. 创建一个包含你的名字（字符串）、年龄（整数）和最喜欢的编程语言（原子）的元组。
my_profile = {"Jules", 3, :elixir}
IO.puts("我的简介元组: " <> inspect(my_profile))

# 2. 从上面的元组中，使用模式匹配提取出你的名字和年龄到两个不同的变量中，忽略编程语言。
{my_name, my_age, _} = my_profile
IO.puts("通过模式匹配提取: 名字=#{my_name}, 年龄=#{my_age}")

# 3. 创建一个包含数字 1 到 5 的列表。使用模式匹配和 ++ 操作符，创建一个新列表，它在旧列表的末尾添加数字 6。
original_list = [1, 2, 3, 4, 5]
extended_list = original_list ++ [6]
IO.puts("扩展后的列表: " <> inspect(extended_list))

# 4. 使用 [head | tail] 模式匹配，从 extended_list 中分离出头部和尾部。
[h | t] = extended_list
IO.puts("新列表的头部是 #{h}，尾部是 #{inspect t}")

# --- End of Chapter 1 ---
