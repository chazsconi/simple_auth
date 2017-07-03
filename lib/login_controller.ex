defmodule SimpleAuth.LoginController do
  @moduledoc """
  Macros for generating methods for a login controller
  """
  defmacro __using__(_options) do
    quote do
      alias SimpleAuth.UserSession
      @authenticate_api Application.get_env(:simple_auth, :authenticate_api) || SimpleAuth.Authenticate.Repo
      @username_field (Application.get_env(:simple_auth, :username_field) || :email) |> to_string

      @doc "Shows the login page"
      def show(conn, _params) do
        render conn, "login.html"
      end

      @doc "Handles submit to the login page with username/password"
      def login(conn, %{"credentials" => %{@username_field => username, "password" => password}}) do
        case @authenticate_api.login(username, password) do
          {:ok, user} ->
            :ok = on_login_success(conn, user, password)
            conn
            |> UserSession.put(user)
            |> put_flash(:info, "Logged in")
            |> redirect(to: "/")
          :error ->
            conn
            |> put_flash(:info, "Invalid credentials")
            |> render("login.html")
          :blocked ->
            conn
            |> put_flash(:info, "User is blocked")
            |> render("login.html")
        end
      end

      @doc "Refreshes the session"
      def refresh(conn, _) do
        conn
        |> respond_with_user_session_info(&UserSession.refresh/1)
      end

      @doc "Gets the remaining seconds available"
      def info(conn, _) do
        conn
        |> respond_with_user_session_info(&UserSession.info/1)
      end

      defp respond_with_user_session_info(conn, fun) do
        response =
          case fun.(conn) do
            :expired
              -> %{"status" => "expired"}
            {:ok, %{remaining_seconds: seconds, can_refresh?: can_refresh?}}
              -> %{"status" => "ok", "remainingSeconds" => seconds,
                "canRefresh" => can_refresh?}
          end
        conn
        |> json(response)
      end

      def logout(conn, _) do
        :ok = on_logout(conn, UserSession.get(conn))
        conn
        |> UserSession.delete
        |> put_flash(:info, "Logged out")
        |> redirect(to: "/")
      end

      @doc "Called when the user is successfully logged in"
      def on_login_success(_conn, _user, _password), do: :ok

      @doc "Called when the user is successfully logged in"
      def on_logout(_conn, _user), do: :ok

      defoverridable [on_login_success: 3, on_logout: 2]
    end
  end
end
