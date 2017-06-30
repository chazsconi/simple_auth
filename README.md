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
config :simple_auth, :username_field, :email  # field in User model and login form that user uses to login (default is :email)
config :simple_auth, :user_session_api, SimpleAuth.UserSession.Memory


# The following options only apply for SimpleAuth.UserSession.Memory

# Optional callback to invoke when the session expires or is deleted
# It takes 1 parameter which is the user_id whose session has expired
# Sessions are checked periodically (every minute) to ensure they are not expired
config :simple_auth, :expiry_callback, {Zurich.LoginController, :session_expired }

# Time before a session expires
config :simple_auth, :session_expiry_seconds, 600

# Number of times the user can refresh the session (setting the expiry back to the maximum)
# 0 = never, nil = infinitely
config :simple_auth, :session_refresh_limit, 5

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
    field :email, :string # Must match the field name specified in :username_field config setting
    field :crypted_password, :string
    field :password, :string, virtual: true
    field :roles, {:array, :string}
    field :attempts, :integer, default: 0
    field :attempted_at, :naive_datetime

    timestamps
  end

  def changeset(model, params \\ :empty) do
    model
    |> cast(params, [:email, :crypted_password, :attempts, :attempted_at])
    |> validate_required([:email, :crypted_password, :attempts])
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
#### Optional additional api routes only for SimpleAuth.UserSession.Memory
```elixir
pipe_through :api
put "/login/refresh",  LoginController, :refresh
get "/login/info",  LoginController, :info
```
These can be used from the browser to refresh the session and also get information
about the session, for example to display the remaining session time in the header, and a button
to refresh it.

These will both return:
```json
{"status": "ok", "remainingSeconds": 125, "canRefresh": true}
```
or if the session has expired
```json
{"status": "expired"}
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
These imports can also be added to the view: `remaining_seconds/1, can_refresh?/1`.
These allow checking the remaining seconds of the session and if the user can refresh the session.

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

## Advanced Use

### LDAP

Instead of using passwords stored in the DB, an LDAP server can be used to authenticate users.
This uses the [exldap](https://github.com/jmerriweather/exldap) package.

A User DB table is still used, but rows are automatically inserted for any new users logging in.

To use LDAP do the same as the basic configuration (apart from the user model and migrations - see below)
and also do the following:

### Add configuration
To use LDAP add the following additional entry to the config:
```elixir
config :simple_auth, :authenticate_api, SimpleAuth.Authenticate.Ldap
```

Also add the `server`, `port` and `ssl` LDAP configuration for exldap.  For example:
```elixir
config :exldap, :settings,
  server: "my.ldap.server",
  port: 389,
  ssl: false
```

Add exldap to the list of deps in `mix.exs`:
```elixir
{:exldap, "~> 0.4"}
```

### User model and migrations differences
Create a user model and migrations (as above) but only include the `username`, `roles` and timestamp columns.
Passwords and blocking of users should be handled by the LDAP server.

### Create helper module
Typically the user will login using a username, e.g. `john.smith`, however the LDAP server
will probably expect usernames in a different format e.g. `mycorp\john.smith` or `CN=john.smith`.
Therefore a module must be provided with a `build_ldap_user/1` function to translate the username as entered by the user
to the user field expected by LDAP.

For example for the second example, create a module as follows:
```elixir
defmodule MyApp.LdapHelper do
  @behaviour SimpleAuth.LdapHelperAPI
  def build_ldap_user(username), do: "CN=#{username}"
  def enhance_user(user, _connection), do: user
end
```

The `enhance_user/2` function allows enhancing the user structure before it is added to the database.  The
function receives the user struct and a connection to LDAP allowing querying of other fields which can then
be populated in the struct.  For example to get the display name the following can be used (this example
uses an MS ActiveDirectory server):

```elixir
def enhance_user(%User{username: username}=user, connection) do
  {:ok, search_results} = Exldap.search_field(connection, "dc=mycorp,dc=com", "sAMAccountName", username)
  {:ok, first_result} = search_results |> Enum.fetch(0)
  display_name = Exldap.search_attributes(first_result, "displayName")
  %User{user | display_name: display_name}
end
```

Point to this module in the config:
```elixir
config :simple_auth, :ldap_helper_module, MyApp.LdapHelper
```
