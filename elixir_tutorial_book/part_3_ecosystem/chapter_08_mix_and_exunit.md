# ###################################################################
# 本书由 Jules (AI Software Engineer) 编写
# 章节: 第三部分 - 项目与生态
# 第8章: Mix 项目与测试 (Mix & ExUnit)
# ###################################################################

到目前为止，我们都在 `.exs` 脚本文件中编写代码。这对于学习和快速实验非常有用。但在真实世界中，Elixir 项目是使用构建工具 `mix` 来组织的。

## 1. Mix 是什么？

`mix` 是 Elixir 的官方构建工具，它集成了项目创建、编译、依赖管理、测试等多种功能。你可以把它看作是 Ruby 的 `Bundler` + `Rake`，或是 Node.js 的 `npm`/`yarn` + `scripts`。

## 2. 创建一个新项目

要创建一个新的 Elixir 项目，我们使用 `mix new` 命令。

```bash
# 在你的终端中运行 (这里只是演示，你不需要实际运行)
$ mix new my_greeter --sup
```

- `my_greeter` 是我们项目的名字。
- `--sup` 是一个非常重要的标志，它告诉 `mix` 为我们生成一个带有顶级监督者（Supervisor）的 OTP 应用骨架。

这个命令会创建一个名为 `my_greeter` 的目录，其结构如下：

```
my_greeter/
├── .formatter.exs      # 代码格式化工具的配置文件
├── .gitignore          # Git 忽略文件
├── README.md           # 项目说明
├── lib/                # 存放核心源代码的地方
│   ├── my_greeter
│   │   └── application.ex # 应用的回调模块
│   └── my_greeter.ex     # 项目的主模块
├── mix.exs             # 项目的配置文件！
└── test/               # 存放测试文件的地方
    ├── test_helper.exs   # 测试帮助文件，在所有测试前运行
    └── my_greeter_test.exs # 对主模块的测试文件
```

### `mix.exs` 文件详解

`mix.exs` 是项目的核心配置文件。让我们看看它的内容：

```elixir
# path: my_greeter/mix.exs

defmodule MyGreeter.MixProject do
  use Mix.Project

  def project do
    [
      app: :my_greeter,
      version: "0.1.0",
      elixir: "~> 1.14",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # 应用信息，在 `mix help` 中显示
  def application do
    [
      extra_applications: [:logger],
      # 指定应用启动时调用的模块和函数
      mod: {MyGreeter.Application, []}
    ]
  end

  # `deps` 函数用于定义项目依赖
  defp deps do
    [
      # {:dep_name, "~> 1.0"}
    ]
  end
end
```
- `project/0`: 定义了项目的基本信息，如应用名 `:my_greeter`，版本号，以及 Elixir 版本要求。
- `application/0`: 定义了这是一个 OTP 应用，并指定了入口点为 `MyGreeter.Application` 模块。
- `deps/0`: 用于管理第三方依赖包。我们可以从 [Hex.pm](https://hex.pm) (Elixir 的包管理器) 添加依赖。

## 3. 编写我们的代码

现在，让我们在项目中添加一些逻辑。我们将在 `lib/my_greeter/` 目录下创建一个新文件 `greeter.ex`。

```elixir
# path: my_greeter/lib/my_greeter/greeter.ex

defmodule MyGreeter.Greeter do
  @doc """
  生成一句问候语。

  ## 示例

      iex> MyGreeter.Greeter.hello("Jules")
      "Hello, Jules!"

      iex> MyGreeter.Greeter.hello()
      "Hello, Anonymous!"
  """
  def hello(name \\ "Anonymous") do
    "Hello, #{name}!"
  end
end
```

## 4. 使用 ExUnit 进行测试

`ExUnit` 是 Elixir 内置的测试框架。测试文件通常与源文件结构对应，位于 `test/` 目录下。

让我们为 `Greeter` 模块编写一个测试。我们将创建一个新文件 `test/my_greeter/greeter_test.exs`。

```elixir
# path: my_greeter/test/my_greeter/greeter_test.exs

defmodule MyGreeter.GreeterTest do
  # 引入 ExUnit 的 Case 行为
  use ExUnit.Case
  # 为测试用例起一个描述性的名字
  doctest MyGreeter.Greeter

  # `test/3` 宏用于定义一个测试用例
  test "hello/1 returns a proper greeting" do
    # `assert` 宏用于断言一个表达式为 truthy
    assert MyGreeter.Greeter.hello("World") == "Hello, World!"
  end

  test "hello/0 returns a greeting for Anonymous" do
    assert MyGreeter.Greeter.hello() == "Hello, Anonymous!"
  end
end
```
- `use ExUnit.Case`: 引入测试所需的所有宏，如 `test` 和 `assert`。
- `doctest MyGreeter.Greeter`: 这是一个非常有用的宏。它会自动执行 `MyGreeter.Greeter` 模块文档 (`@doc`) 中所有 `iex>` 开头的示例，并检查结果是否匹配。这确保了你的文档总是和代码同步的！

## 5. 运行测试

在项目的根目录下，我们可以使用 `mix test` 命令来运行所有测试。

```bash
# 在终端中运行
$ mix test
```

`mix` 会先编译你的项目，然后执行 `test/` 目录下的所有 `_test.exs` 文件。如果一切顺利，你会看到类似这样的输出：

```
..

Finished in 0.05 seconds
2 tests, 0 failures

Randomized with seed 12345
```

## 面试常见陷阱 (Interview Pitfall)

**问：`mix.exs` 中的 `application` 函数和 `lib/my_app/application.ex` 文件有什么关系？**
答：`mix.exs` 中的 `application` 函数是用来**配置** OTP 应用的。其中 `mod: {MyGreeter.Application, []}` 这一行，正是告诉 Mix，当这个 OTP 应用需要启动时，应该去调用 `MyGreeter.Application` 模块的 `start/2` 函数。而 `lib/my_app/application.ex` 文件就是 `MyGreeter.Application` 模块的**具体实现**，它定义了 `start/2` 回调函数，并在其中启动应用的顶级监督者。前者是声明，后者是实现。

**问：什么是 Doctests？使用它有什么好处？**
答：Doctests 是直接写在模块或函数文档注释 (`@doc`) 中的测试用例。`doctest MyModule` 宏会自动提取并运行这些测试。
**好处**:
1.  **保证文档的正确性**: 它确保你的代码示例永远不会过时或出错。
2.  **提供清晰的用例**: 它为函数的使用方式提供了最直观、最简单的示例。
3.  **鼓励编写文档**: 它让编写文档变得更有价值。

---
*下一章我们将介绍一些 Elixir 的高级主题。*
---
