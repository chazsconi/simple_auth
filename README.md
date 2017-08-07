# SimpleAuth

Adds authentication and authorization to a Phoenix project.  It allows a user to login
with a username and password held in the DB or alternatively authenticate against an LDAP server.

The user can have one or more roles associated with them which are loaded from the DB and can
be checked within a controller using a plug or within a template.

## Installation

Add `simple_auth` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [{:simple_auth, "~> 1.5.1"}]
end
```

## Basic Use

### Add configuration
```elixir
config :simple_auth, :error_view, MyApp.ErrorView
config :simple_auth, :repo, MyApp.Repo
config :simple_auth, :user_model, MyApp.User
config :simple_auth, :username_field, :email  # field in User model and login form that user uses to login (default is :email)
config :simple_auth, :user_session_api, SimpleAuth.UserSession.HTTPSession # See Advanced section for more options
```

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
To protect an action in a controller from unauthorised access add the plug `authorize` for the required actions.
If the user is not logged in they will be redirected to the login page.  If they are are logged in but not authorized
for this role, they will be shown an unauthorized page.

```elixir
import SimpleAuth.AccessControl
plug :authorize, ["ROLE_ADMIN"] when action in [:action_1, :action_2]
```

#### API actions

For protecting API actions invoked with an AJAX request a redirection is not desirable.  Therefore for any API pipeline in
you app add the `no_redirect_on_unauthorized` plug. e.g.
```elixir
pipeline :api do
  plug :accepts, ["json"]
  plug :fetch_session # Needed to send the session cookie from the browser
  plug :no_redirect_on_unauthorized
end
```

This will return just a status code of 401 in the case the user is not logged in or not authorized.

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

## Advanced Use

### User Session Storage

The simplest storage for the User Session is
```elixir
config :simple_auth, :user_session_api, SimpleAuth.UserSession.HTTPSession
```
which stores the session in `Plug.Conn` session.  However the following other implementations
are available:
* `SimpleAuth.UserSession.Memory` - The details are stored in a GenServer with just the
  user_id stored in the `Plug.Conn` session.  Logging out for a given user will kill all
  that user's sessions and provides a callback that can be invoked on session expiry.
* `SimpleAuth.UserSession.Assigns` - A version that can be used in tests which puts the user
  in `conn.assigns`.

####  UserSession.Memory additional api endpoints
`SimpleAuth.UserSession.Memory` supports these additional endpoints.

```elixir
pipe_through :api
put "/login/refresh",  LoginController, :refresh
get "/login/info",  LoginController, :info
```
These can be used from the browser to refresh the session and also get information
about the session, for example to display the remaining session time in the menu bar, and a button
to refresh it.

These will both return:
```json
{"status": "ok", "remainingSeconds": 125, "canRefresh": true}
```
or if the session has expired
```json
{"status": "expired"}
```

These imports can also be added to the view: `remaining_seconds/1, can_refresh?/1`.
These allow checking the remaining seconds of the session and if the user can refresh the session.

#### UserSession.Memory configuration options
For `SimpleAuth.UserSession.Memory` the following additional configuration options are available:

##### Session Expiry Callback
```elixir
config :simple_auth, :expiry_callback, {MyApp.LoginController, :session_expired }
```

This is an optional callback to invoke when the session expires or is deleted.
It takes 1 parameter which is the user_id whose session has expired.
Sessions are checked periodically (every minute) to ensure they are not expired

##### Session expiry time
```elixir
config :simple_auth, :session_expiry_seconds, 600
```

##### Refresh limit
```elixir
config :simple_auth, :session_refresh_limit, 5
```
The number of times the user can refresh the session (setting the expiry back to the maximum)
0 = never, nil = infinitely.


### LDAP configuration

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
  def enhance_user(user, _connection, _opts), do: user
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

The `enhance_user/3` function allows applying a different logic depending on the received opts.  Currently only `:new_user` is sent back,
to allow distinguishing newly created users from already existent.

```elixir
def enhance_user(%User{username: username}=user, connection, opts) do
  new_user = Keyword.get(opts, :new_user, false)
  {:ok, search_results} = Exldap.search_field(connection, "dc=mycorp,dc=com", "sAMAccountName", username)
  {:ok, first_result} = search_results |> Enum.fetch(0)
  display_name = Exldap.search_attributes(first_result, "displayName")
  %User{user | display_name: display_name}
  unless new_user do
    # Something specific for already existing users
  end
end
```

Point to this module in the config:
```elixir
config :simple_auth, :ldap_helper_module, MyApp.LdapHelper
```
