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
        conn
        |> UserSession.delete
        |> put_flash(:info, "Logged out")
        |> redirect(to: "/")
      end
    end
  end
end
