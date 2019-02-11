defmodule SimpleAuth.LoginController do
  @moduledoc """
  Macros for generating methods for a login controller
  """
  defmacro __using__(_options) do
    quote do
      alias SimpleAuth.UserSession
      defp authenticate_api(), do: Application.get_env(:simple_auth, :authenticate_api)
      defp username_field(), do: Application.get_env(:simple_auth, :username_field)

      @doc "Shows the login page"
      def show(conn, _params) do
        render(conn, "login.html")
      end

      @doc "Handles submit to the login page with username/password"
      def login(conn, %{"credentials" => credentials}) do
        username = Map.fetch!(credentials, to_string(username_field()))
        password = Map.fetch!(credentials, "password")

        case authenticate_api().login(username, password) do
          {:ok, user} ->
            :ok = on_login_success(conn, user, password)

            conn
            |> UserSession.put(transform_user(conn, user))
            |> put_flash(:info, "Logged in")
            |> redirect(to: post_login_path())

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
            :expired ->
              %{"status" => "expired"}

            {:ok, %{remaining_seconds: seconds, can_refresh?: can_refresh?}} ->
              %{"status" => "ok", "remainingSeconds" => seconds, "canRefresh" => can_refresh?}
          end

        conn
        |> json(response)
      end

      def logout(conn, _) do
        :ok = on_logout(conn, UserSession.get(conn))

        conn
        |> UserSession.delete()
        |> put_flash(:info, "Logged out")
        |> redirect(to: post_logout_path())
      end

      defp post_login_path, do: Application.get_env(:simple_auth, :post_login_path)
      defp post_logout_path, do: Application.get_env(:simple_auth, :post_logout_path)

      @doc "Called when the user is successfully logged in"
      def on_login_success(_conn, _user, _password), do: :ok

      @doc "Called when the user is successfully logged in"
      def on_logout(_conn, _user), do: :ok

      @doc "Allows the user struct/map to be transformed before saving in the session"
      def transform_user(_conn, user), do: user

      defoverridable on_login_success: 3, on_logout: 2, transform_user: 2
    end
  end
end
