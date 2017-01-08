defmodule SimpleAuth.LoginController do
  defmacro __using__(_options) do
    quote do
      alias SimpleAuth.UserSession

      @doc "Shows the login page"
      def show(conn, _params) do
        render conn, "login.html"
      end

      @doc "Handles submit to the login page with email/password"
      def login(conn, %{"credentials" => %{"email" => email, "password" => password}}) do
        case SimpleAuth.Authenticate.login(email, password) do
          {:ok, user} ->
            :ok = on_login_success(conn, user, password)
            conn
            |> UserSession.put(user)
            |> put_flash(:info, "Logged in")
            |> redirect(to: "/")
          :error ->
            conn
            |> put_flash(:info, "Wrong email or password")
            |> render("login.html")
          :blocked ->
            conn
            |> put_flash(:info, "User is blocked")
            |> render("login.html")
        end
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
