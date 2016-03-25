defmodule SimpleAuth.UserSessionAPI do
  @moduledoc "API for storing user session"

  @type conn :: %Plug.Conn{}
  @callback get(conn) :: conn
  @callback put(conn, user :: term) :: conn
  @callback delete(conn) :: conn
end

defmodule SimpleAuth.UserSession do

  @after_compile __MODULE__

  @moduledoc "Wrapper to call the current implementation of the API"
  @behaviour SimpleAuth.UserSessionAPI
  @user_session_api Application.get_env(:simple_auth, :user_session_api)

  def get(conn),       do: @user_session_api.get(conn)
  def put(conn, user), do: @user_session_api.put(conn, user)
  def delete(conn),    do: @user_session_api.delete(conn)

  def __after_compile__(env, _bytecode) do
    IO.inspect "MIX_ENV=#{Mix.env}"
    IO.inspect "@user_session_api = #{@user_session_api}"
  end

end

defmodule SimpleAuth.UserSession.HTTPSession do
  @moduledoc "Real version of API storing user details in the HTTP session"
  @behaviour SimpleAuth.UserSessionAPI

  def get(conn),       do: Plug.Conn.get_session(conn, :current_user)
  def put(conn, user), do: Plug.Conn.put_session(conn, :current_user, user)
  def delete(conn),    do: Plug.Conn.delete_session(conn, :current_user)
end

defmodule SimpleAuth.UserSession.Assigns do
  @moduledoc "Version of the API that can be used for testing as the HTTP session is not easily accessible in tests"
  @behaviour SimpleAuth.UserSessionAPI

  def get(conn) do
    case conn.assigns do
      %{current_user: current_user} -> current_user
      _ -> nil
    end
  end

  def put(conn, user), do: Plug.Conn.assign(conn, :current_user, user)
  def delete(conn), do: %{conn | assigns: Map.delete(conn.assigns, :current_user) }
end
