# ###################################################################
# 本书由 Jules (AI Software Engineer) 编写
# 章节: 第一部分 - Elixir 基础
# 第4章: 集合类型与枚举 (Collection Types & Enums)
# ###################################################################

# Elixir 提供了多种集合类型来处理一组数据。`Enum` 模块则提供了统一的、强大的 API 来操作这些集合。

# --- 1. 列表 (Lists) ---
# 我们在第一章已经见过列表。它们是链表，适用于头部操作和递归。
IO.puts("--- 1. 列表 ---")
my_list = [1, 2, 3, 4, 5]
IO.puts("列表: #{inspect my_list}")


# --- 2. 关键字列表 (Keyword Lists) ---
# 关键字列表是特殊的列表，其元素是包含两个元素的元组，且第一个元素必须是原子。
# 它们在 Elixir 中被广泛用于函数的可选参数。
IO.puts("\n--- 2. 关键字列表 ---")
keyword_list = [name: "Jules", age: 3, language: :elixir]
# 上面的语法是下面的简写：
# keyword_list = [{:name, "Jules"}, {:age, 3}, {:language, :elixir}]

IO.puts("关键字列表: #{inspect keyword_list}")

# 可以通过括号语法访问关键字列表的值。
IO.puts("名字是: #{keyword_list[:name]}")
IO.puts("年龄是: #{keyword_list[:age]}")

# 关键字列表的特点:
# 1. 键必须是原子。
# 2. 键可以重复。
# 3. 键的顺序被保留。


# --- 3. 图 (Maps) ---
# 图是 Elixir 中首选的键值对存储结构。它们非常高效，特别是对于大量的键值对。
# 它们使用 `%{}` 语法创建。
IO.puts("\n--- 3. 图 ---")
my_map = %{:name => "Jules", "age" => 3, 123 => :id}
# 如果键是原子，可以使用更简洁的语法：
my_map_simple = %{name: "Jules", age: 3, language: :elixir}

IO.puts("图: #{inspect my_map_simple}")

# 访问图中的值，可以使用点 `.` 语法（仅限原子键）或括号 `[]` 语法。
IO.puts("名字是 (点语法): #{my_map_simple.name}")
IO.puts("年龄是 (括号语法): #{my_map_simple[:age]}")

# 更新图中的值（因为数据是不可变的，这会返回一个新的图）
updated_map = Map.put(my_map_simple, :location, "Cyberspace")
IO.puts("更新后的图: #{inspect updated_map}")
IO.puts("原始图保持不变: #{inspect my_map_simple}")

# 图的特点:
# 1. 键可以是任何类型。
# 2. 键是唯一的。
# 3. 对于 32 个以上的键，它们在内部是高效的哈希映射树。


# --- 4. Enum 模块 ---
# `Enum` 模块提供了超过100个函数来处理可枚举的（enumerable）数据类型，如列表、图、范围等。
# 这是 Elixir 中进行数据处理的核心工具。
IO.puts("\n--- 4. Enum 模块 ---")
numbers = [1, 2, 3, 4, 5, 6]

# `Enum.map/2`: 对集合中的每个元素应用一个函数，返回一个新的列表。
doubled_numbers = Enum.map(numbers, fn(n) -> n * 2 end)
# 使用 & 简写:
doubled_numbers_short = Enum.map(numbers, &(&1 * 2))
IO.puts("map (每个元素乘以2): #{inspect doubled_numbers}")
IO.puts("map (简写版本): #{inspect doubled_numbers_short}")

# `Enum.filter/2`: 返回集合中所有使函数返回 truthy 值的元素。
even_numbers = Enum.filter(numbers, fn(n) -> rem(n, 2) == 0 end)
IO.puts("filter (只保留偶数): #{inspect even_numbers}")

# `Enum.reduce/3`: 将集合缩减为一个单一的值。
sum = Enum.reduce(numbers, 0, fn(n, acc) -> n + acc end)
IO.puts("reduce (计算总和): #{sum}")

# `Enum.any?/2`: 检查集合中是否有至少一个元素满足条件。
has_even_number = Enum.any?(numbers, &(rem(&1, 2) == 0))
IO.puts("any? (是否存在偶数): #{has_even_number}")

# `Enum.all?/2`: 检查集合中是否所有元素都满足条件。
all_positive = Enum.all?(numbers, &(&1 > 0))
IO.puts("all? (是否所有数都为正): #{all_positive}")

# `Enum.each/2`: 对集合中的每个元素执行一个函数，主要用于产生副作用（如打印），返回原子 `:ok`。
Enum.each(numbers, fn(n) -> IO.puts("正在打印: #{n}") end)


# --- 面试常见陷阱 (Interview Pitfall) ---

# 问：关键字列表 (Keyword List) 和图 (Map) 有什么区别，应该如何选择？
# 答：
# 1.  **键的类型**: 关键字列表的键必须是原子。图的键可以是任何类型。
# 2.  **唯一性**: 关键字列表的键可以重复。图的键必须是唯一的。
# 3.  **顺序**: 关键字列表保留插入顺序。图在 Elixir 1.4 之后也保留顺序，但之前的版本不保证。
# 4.  **性能**: 对于少量键值对，两者性能相当。但对于大量数据（>32个键），图的访问和插入性能远超关键字列表。
# **选择**:
# -   当给函数传递可选参数时，使用**关键字列表**。这是 Elixir 的惯例，例如 `MyFun.create_user("Jules", [age: 3, admin: true])`。
# -   当需要一个键值数据结构，特别是键不是原子、键需要唯一、或者数据量可能很大时，使用**图**。在绝大多数情况下，图是更通用和高效的选择。

# 问：`Enum.map/2` 和 `Enum.each/2` 有什么不同？
# 答：
# -   `Enum.map/2` 的核心目的是**数据转换**。它遍历集合，对每个元素应用一个函数，然后将**返回值**收集到一个**新的列表**中。
# -   `Enum.each/2` 的核心目的是**执行副作用** (side effects)。它遍历集合，对每个元素应用一个函数，但**丢弃返回值**，并最终返回原子 `:ok`。
# -   简单说：如果你需要转换后的结果，用 `map`。如果你只是想对每个元素做点事（比如打印到屏幕、写入文件），用 `each`。

# --- 练习 (Exercise) ---
# 1. 有一个用户列表，每个用户是一个图。
users = [
  %{name: "Alice", age: 28, skills: ["Elixir", "Ruby"]},
  %{name: "Bob", age: 35, skills: ["JavaScript", "Python"]},
  %{name: "Charlie", age: 22, skills: ["Elixir", "Go"]}
]

# 2. 使用 `Enum` 模块和管道操作符 `|>` 完成以下任务：
#    a. 找到所有会 Elixir 的用户的名字。
#    b. 计算所有用户的平均年龄。
#    c. 创建一个新的列表，其中每个元素是形如 "Alice is 28 years old" 的字符串。

IO.puts("\n--- 练习 ---")

# a. 找到所有会 Elixir 的用户的名字
elixir_users_names = users
|> Enum.filter(fn(user) -> "Elixir" in user.skills end) # 筛选出技能包含 "Elixir" 的用户
|> Enum.map(fn(user) -> user.name end)                  # 提取这些用户的名字
IO.puts("会 Elixir 的用户: #{inspect elixir_users_names}")

# b. 计算所有用户的平均年龄
total_age = Enum.reduce(users, 0, &(&1.age + &2))
user_count = Enum.count(users)
average_age = total_age / user_count
IO.puts("用户的平均年龄: #{average_age}")

# c. 创建一个新的列表，其中每个元素是形如 "Alice is 28 years old" 的字符串
user_descriptions = Enum.map(users, fn(user) ->
  "#{user.name} is #{user.age} years old"
end)
IO.puts("用户描述: #{inspect user_descriptions}")

# --- End of Chapter 4 & Part 1 ---
