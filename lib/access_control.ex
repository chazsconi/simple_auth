defmodule SimpleAuth.AccessControl do
  alias SimpleAuth.UserSession
  require Logger
  import Plug.Conn

  @error_view Application.get_env(:simple_auth, :error_view)

  def authorize(conn, roles) do
    if !logged_in?(conn) do
      Logger.info "Not logged in"
      conn
      |> Phoenix.Controller.redirect(to: "/login")
      |> halt
    else
      if any_granted?(conn, roles) do
        conn
      else
        Logger.info "Not authorized"
        conn
        |> put_status(401)
        |> Phoenix.Controller.render(@error_view, "401.html")
        |> halt
      end
    end
  end

  @doc "Gets the current user"
  def current_user(conn), do: UserSession.get(conn)

  @doc "True if user logged in"
  def logged_in?(conn), do: !!current_user(conn)

  @doc "Get the current user's roles as a MapSet"
  def roles(conn) do
    case current_user(conn) do
      nil -> []
      user -> user.roles
    end
    |> MapSet.new
  end

  @doc "Returns true if the current user has any of the given roles"
  def any_granted?(conn, check_roles) when is_list(check_roles) do
      any_granted?(conn, MapSet.new(check_roles))
  end

  def any_granted?(conn, check_roles = %MapSet{}) do
    MapSet.size(MapSet.intersection(check_roles, roles(conn))) > 0
  end

end
