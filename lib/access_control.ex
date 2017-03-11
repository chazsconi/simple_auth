defmodule SimpleAuth.AccessControl do
  alias SimpleAuth.UserSession
  require Logger
  import Plug.Conn

  @error_view Application.get_env(:simple_auth, :error_view)
  @login_url Application.get_env(:simple_auth, :login_url) || "/login"

  def authorize(conn, roles) do
    if !logged_in?(conn) do
      Logger.info "Not logged in"
      conn
      |> redirect_to_login
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

  defp redirect_to_login(conn) do
    url = login_url(conn, @login_url)
    if String.first(url) == "/" do
      Phoenix.Controller.redirect(conn, to: url)
    else
      Phoenix.Controller.redirect(conn, external: url)
    end
  end

  def login_url(_conn, url) when is_binary(url), do: url
  def login_url(_conn, {module, function}), do: apply(module, function, [])

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
