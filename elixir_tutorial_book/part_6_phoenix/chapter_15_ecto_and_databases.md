# ###################################################################
# 本书由 Jules (AI Software Engineer) 编写
# 章节: 第六部分 - Phoenix 框架实战
# 第15章: Ecto 与数据库
# ###################################################################

Ecto 是 Elixir 生态中用于数据库交互和数据映射的首选库。它与传统的 ORM (对象关系映射) 有所不同，Ecto 强调明确性、组合性和数据转换的纯粹性。

Ecto 主要由三个核心组件构成：
1.  **Repo (仓库)**: 数据库操作的入口。
2.  **Schema (模式)**: 将 Elixir 结构体映射到数据库表。
3.  **Changeset (变更集)**: 数据验证、过滤和转换的管道。

## 1. Repo (仓库)

Repo 模块是与数据库通信的唯一接口。它封装了数据库连接的细节，并提供了一套函数来执行 CRUD 操作，如 `Repo.insert/1`, `Repo.get/3`, `Repo.update/1`, `Repo.delete/1` 等。

在一个标准的 Phoenix 应用中，你可以在 `lib/your_app/repo.ex` 找到它的定义。

```elixir
# 典型的 Repo 操作
alias YourApp.Repo
alias YourApp.Accounts.User

# 获取一个用户
user = Repo.get(User, 1)

# 获取所有用户
users = Repo.all(User)

# 插入一个新用户 (需要一个 changeset)
{:ok, user} = Repo.insert(changeset)
```

## 2. Schema (模式)

Schema 是一个 Elixir 模块，它使用 `Ecto.Schema` 来定义一个结构体以及它与数据库表的映射关系。

**示例：定义一个用户 Schema**

```elixir
# path: lib/your_app/accounts/user.ex

defmodule YourApp.Accounts.User do
  use Ecto.Schema
  import Ecto.Changeset

  # @primary_key 和 @foreign_key_type 是 Phoenix 1.7+ 的新实践
  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id

  # `schema/2` 宏定义了表名和字段
  schema "users" do
    field :name, :string
    field :email, :string
    field :age, :integer
    field :is_admin, :boolean, default: false

    # 定义与 Post 的一对多关联
    has_many :posts, YourApp.Blog.Post

    # timestamps() 会自动为你添加 :inserted_at 和 :updated_at 字段
    timestamps()
  end

  # ... changeset 函数定义在这里 ...
end
```
- `schema "users" do ... end`: 定义了该模块映射到数据库的 `users` 表。
- `field :name, :string`: 定义了一个字段，`name` 是字段名，`:string` 是它的 Ecto 类型。
- `has_many`, `belongs_to`, `many_to_many`: 用于定义表之间的关联关系。

## 3. Changeset (变更集) - Ecto 的灵魂

Changeset 是 Ecto 最核心、最强大的概念。它是一个数据转换的管道，用于：
1.  **过滤 (Filtering)**: 只允许特定的参数进入。
2.  **类型转换 (Casting)**: 将外部参数（通常是字符串）转换为正确的 Elixir 类型。
3.  **验证 (Validation)**: 检查数据是否符合业务规则（如必填、唯一性、格式等）。
4.  **追踪变更 (Tracking Changes)**: 记录哪些字段被修改了。

Changeset 是一个纯函数，它接收数据和参数，返回一个 `Ecto.Changeset` 结构体。

**示例：为 User Schema 添加一个 changeset 函数**

```elixir
# 在 YourApp.Accounts.User 模块中
def changeset(user \\ %__MODULE__{}, attrs) do
  user
  # 1. 将数据和参数“投射”到 changeset 中
  |> cast(attrs, [:name, :email, :age])
  # 2. 进行验证
  |> validate_required([:name, :email])
  |> validate_length(:name, min: 2)
  |> validate_format(:email, ~r/@/)
  |> unique_constraint(:email)
end
```

**工作流程:**
1.  `changeset(user, attrs)`:
    - `user`: 要修改的原始数据结构（创建时是一个空的 `%User{}`）。
    - `attrs`: 从外部（如 HTML 表单）传入的参数，例如 `%{ "name" => "Jules", "email" => "test@example.com" }`。
2.  `cast(attrs, [:name, :email, :age])`:
    - 这是第一道防线，它**只允许** `:name`, `:email`, `:age` 这三个字段的参数通过。任何其他参数（如 `is_admin`）都会被忽略，这是非常重要的安全特性。
    - 它还会将参数从字符串转换为 Schema 中定义的类型。
3.  `validate_required([:name, :email])`: 验证 `:name` 和 `:email` 字段必须存在。
4.  `validate_...`: 执行其他各种验证。
5.  `unique_constraint(:email)`: 添加一个唯一性约束检查（需要数据库中有唯一索引配合）。

**在控制器中使用 Changeset:**

```elixir
# path: lib/your_app_web/controllers/user_controller.ex

def create(conn, %{"user" => user_params}) do
  case Accounts.create_user(user_params) do
    {:ok, user} ->
      # 创建成功
      redirect(conn, to: Routes.user_path(conn, :show, user))
    {:error, %Ecto.Changeset{} = changeset} ->
      # 创建失败，changeset 中包含了错误信息
      # 重新渲染表单，并将 changeset 传回，以便向用户显示错误
      render(conn, :new, changeset: changeset)
  end
end

# 在你的业务模块 (Context) 中:
# path: lib/your_app/accounts.ex
def create_user(attrs) do
  %User{}
  |> User.changeset(attrs)
  |> Repo.insert()
end
```

## 4. 查询 (Queries)

Ecto 提供了一套优雅、可组合的查询 DSL，用于从数据库读取数据。

```elixir
import Ecto.Query

# 基础查询
query = from u in User, where: u.is_admin == true, select: u.name
# => Repo.all(query) 会返回所有管理员的名字列表

# 带有关联的查询
query = from u in User, where: u.age > 18, preload: [:posts]
# => Repo.all(query) 会返回所有年龄大于18岁的用户，并预加载他们所有的文章

# 组合查询
young_users = from u in User, where: u.age < 30
active_users = from u in young_users, where: u.status == "active"
# => Repo.all(active_users)
```
- **可组合性**: 你可以构建一个基础查询，然后根据条件动态地向其添加更多的 `where`, `join`, `order_by` 等子句。
- **预加载 (`preload`)**: 这是解决 N+1 查询问题的关键。`preload: [:posts]` 会让 Ecto 在一次额外的查询中加载所有相关用户的文章，而不是在循环中为每个用户单独执行一次查询。

## 常见坑与使用技巧

- **坑: 在 Changeset 中忘记 `cast`**
    - **原因**: 如果你直接将外部参数传给 `validate_...` 函数，可能会因为类型不匹配（如期望整数却得到字符串）而出错。
    - **技巧**: 永远将 `cast` 作为 changeset 管道的第一步。

- **坑: 信任外部参数**
    - **原因**: 直接将 `user_params` 全部传入 `changeset`，而没有通过 `cast` 或 `put_change` 进行过滤，可能导致恶意用户修改他们不应修改的字段（如 `is_admin`）。
    - **技巧**: 始终使用 `cast` 来明确指定允许用户修改的字段列表。这是 Ecto 设计 changeset 的核心安全理念。

- **坑: N+1 查询**
    - **原因**: 在循环中访问一个未预加载的关联。例如，获取了100个用户，然后在循环中分别访问 `user.posts`，会导致 1 (获取用户) + 100 (获取文章) 次数据库查询。
    - **技巧**: 在主查询中，总是使用 `Repo.preload/3` 或 `Ecto.Query.preload/3` 来预加载你需要用到的关联数据。

- **技巧: 使用 `Repo.transaction/1`**
    - 当你需要执行多个数据库操作，并希望它们要么全部成功、要么全部失败时，将它们包裹在 `Repo.transaction/1` 中。这能保证数据库层面的原子性。

---
*在下一章，我们将探索 Phoenix 的王牌功能 LiveView，学习如何构建实时、交互式的 Web 应用。*
---
