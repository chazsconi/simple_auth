# SimpleAuth

Adds authentication and authorization to a Phoenix project.

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed as:

  1. Add simple_auth to your list of dependencies in `mix.exs`:

        def deps do
          [{:simple_auth, "~> 0.0.1"}]
        end
  2. If using `SimpleAuth.UserSession.Memory` api, add `:simple_auth` to your list of applications

## Use

### Add configuration
```elixir
config :simple_auth, :error_view, MyApp.ErrorView
config :simple_auth, :repo, MyApp.Repo
config :simple_auth, :user_model, MyApp.User
config :simple_auth, :user_session_api, SimpleAuth.UserSession.Memory

# The following two only apply for SimpleAuth.UserSession.Memory

# Optional callback to invoke when the session expires or is deleted
# It takes 1 parameter which is the user_id whose session has expired
# Sessions are checked periodically (every minute) to ensure they are not expired
config :simple_auth, :expiry_callback, {Zurich.LoginController, :session_expired }

# Time before a session expires
config :simple_auth, :session_expiry_seconds, 600

```
For the `:user_session_api` the choices are:
  * `SimpleAuth.UserSession.HTTPSession` - The user details are stored `Plug.Conn` session
  * `SimpleAuth.UserSession.Memory` - The details are stored in a GenServer with just the
    user_id stored in the `Plug.Conn` session.  Logging out for a given user will kill all
    that user's sessions and provides a callback that can be invoked on session expiry.
  * `SimpleAuth.UserSession.Assigns` - A version that can be used in tests which puts the user
    in `conn.assigns`.

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

  # optional callback
  def on_login_success(conn, user, password) do
    # additional login logic here
  end

  # optional callback
  def on_logout(conn, user) do
    # additional logout logic here
  end
end
```

The two callbacks `on_login_success/3` and `on_logout/2` can be optionally implemented if
additional logic is required - e.g. logging the user's login/logout times to a DB

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
