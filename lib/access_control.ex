defmodule SimpleAuth.AccessControl do
  @moduledoc """
  Plugs for authorization
  """
  alias SimpleAuth.UserSession
  require Logger
  import Plug.Conn
  alias Plug.Conn

  defp error_view, do: Application.get_env(:simple_auth, :error_view)
  defp login_path, do: Application.get_env(:simple_auth, :login_url) || "/login"

  @doc "Plug to authorize and redirect if not authorized"
  def authorize(conn, roles) do
    if !logged_in?(conn) do
      Logger.info "Not logged in"
      if conn.private[:simple_auth_no_redirect_on_unauthorized] do
        conn
        |> text_unauthorized()
      else
        conn
        |> redirect_to_login
        |> halt
      end
    else
      if any_granted?(conn, roles) do
        conn
      else
        Logger.info "Not authorized"
        if conn.private[:simple_auth_no_redirect_on_unauthorized] do
          conn
          |> text_unauthorized()
        else
          conn
          |> put_status(401)
          |> Phoenix.Controller.render(error_view(), "401.html")
          |> halt
        end
      end
    end
  end

  defp text_unauthorized(conn) do
    conn
    |> put_status(401)
    |> Phoenix.Controller.text("Unauthorized")
    |> halt
  end

  @doc "Plug to have unauthorized requests not redirect and just return a text response (for API usage)"
  def no_redirect_on_unauthorized(conn, _opts) do
    conn
    |> put_private(:simple_auth_no_redirect_on_unauthorized, true)
  end

  defp redirect_to_login(conn) do
    url = login_url(conn, login_path())
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

  @doc "Get remaining seconds for the session or nil if expired (if supported by the API)"
  def remaining_seconds(conn) do
    case UserSession.info(conn) do
      {:ok, %{remaining_seconds: secs}} -> secs
      _ -> nil
    end
  end

  def can_refresh?(conn) do
    case UserSession.info(conn) do
      {:ok, %{can_refresh?: can?}} -> can?
      _ -> nil
    end
  end

  @doc "True if user logged in"
  def logged_in?(conn), do: !!current_user(conn)

  @doc "Get the current user's roles as a MapSet"
  def roles(%Conn{} = conn), do: roles(current_user(conn))

  @doc "Get the user's roles as a MapSet"
  def roles(user) do
    case user do
      nil -> []
      user -> user.roles
    end
    |> MapSet.new
  end

  @doc """
  Returns true if the current user in the connection or the passed user
  has any of the given roles or the given role list is empty
  """
  def any_granted?(conn_or_user, check_roles)

  def any_granted?(%Conn{} = conn, check_roles), do: any_granted?(current_user(conn), check_roles)

  def any_granted?(_user, []), do: true
  def any_granted?(user, check_roles) when is_list(check_roles) do
    any_granted?(user, MapSet.new(check_roles))
  end

  def any_granted?(user, check_roles = %MapSet{}) do
    MapSet.size(MapSet.intersection(check_roles, roles(user))) > 0
  end
end
