# SimpleAuth

Adds authentication and authorization to a Phoenix project.

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed as:

  1. Add simple_auth to your list of dependencies in `mix.exs`:

        def deps do
          [{:simple_auth, "~> 0.0.1"}]
        end
## Use

### Add configuration
```elixir
TODO: tidy up config
```

### Create a user model

```elixir
defmodule MyProject.User do
  use MyProject.Web, :model

  schema "users" do
    field :email, :string
    field :crypted_password, :string
    field :password, :string, virtual: true
    field :roles, {:array, :string}
    field :attempts, :integer, default: 0
    field :attempted_at, Ecto.DateTime

    timestamps
  end

  @required_fields ~w(email crypted_password attempts)
  @optional_fields ~w(attempted_at)

  def changeset(model, params \\ :empty) do
    model
    |> cast(params, @required_fields, @optional_fields)
    |> unique_constraint(:email)
    |> validate_format(:email, ~r/@/)
    |> validate_length(:password, min: 5)
  end

end
```
### Create a migration
`mix ecto.gen.migration create_user`
and then set the change function to:


```elixir
def change do
  create table(:users) do
    add :email, :string
    add :crypted_password, :string
    add :roles, {:array, :string}
    add :attempts, :integer
    add :attempted_at, :datetime, null: true

    timestamps
  end
  create unique_index(:users, [:email])
end
```

### Add a login controller

```elixir
defmodule MyProject.LoginController do
  use MyProject.Web, :controller
  # Import login methods
  use SimpleAuth.LoginController
end
```

### Add the routes to the router
```elixir
get    "/login",  LoginController, :show
post   "/login",  LoginController, :login
delete "/logout", LoginController, :logout
```

### Add a login view
```elixir
defmodule MyProject.LoginView do
  use MyProject.Web, :view
end
```

### Create a login template
In `login/login.html.eex`
```elixir
<%= form_for @conn, login_path(@conn, :login), [as: :credentials], fn f -> %>
  <div class="form-group">
    <label>Email</label>
    <%= text_input f, :email, class: "form-control" %>
  </div>

  <div class="form-group">
    <label>Password</label>
    <%= password_input f, :password, class: "form-control" %>
  </div>

  <div class="form-group">
    <%= submit "Login", class: "btn btn-primary" %>
  </div>
<% end %>
```

### Protect controllers
```elixir
import SimpleAuth.AccessControl
plug :authorize, ["ROLE_ADMIN"] when action in [:action_1, :action_2]
```

### Give access to helper functions in view
In `web.ex` add this in the view macro:
```elixir
import SimpleAuth.AccessControl, only: [current_user: 1, logged_in?: 1, any_granted?: 2]
```

### Check roles in web pages
```html
<%= if any_granted?(@conn, ["ROLE_ADMIN"]) do %>
<li class="<%=menu_class @conn, :admin %>"><a href="/admin/students">Admin</a></li>
<% end %>
```

### Check logged in
```html
<%= if logged_in?(@conn) do %>
  <p>Signed in as <%= current_user(@conn).email %></p>
  <%= link "Logout", to: "/logout", method: :delete %>
<% else %>
  <%= link "Login", to: "/login" %>
<% end %>
```

### Add users to DB
This can be done from iex
```elixir
  %MyProject.User{email: "joe@bloggs.com",
  crypted_password: Comeonin.Bcrypt.hashpwsalt("password"),
  roles: ["ROLE_ADMIN"]} |> MyProject.Repo.insert
```
