defmodule SimpleAuth.UserSession.Memory do
  @moduledoc """
  Real version of API storing user details in a GenServer
  This allows sessions to expire automatically and a expiry callback to be triggered on expiry
  It also causes one user logout to logout all other users.
  """
  @behaviour SimpleAuth.UserSessionAPI

  def start_link do
    {:ok, _} = GenServer.start_link(SimpleAuth.UserSession.MemoryGenServer, nil, name: __MODULE__)
  end

  def get(conn) do
    case Plug.Conn.get_session(conn, :user_id) do
      nil -> nil
      user_id ->
        case GenServer.call(__MODULE__, {:get, user_id}) do
           nil -> nil
           session -> session.user
        end
    end
  end

  def put(conn, user) do
    :ok = GenServer.call(__MODULE__, {:put, user})
    Plug.Conn.put_session(conn, :user_id, user.id)
  end

  def delete(conn) do
    case Plug.Conn.get_session(conn, :user_id) do
      nil -> conn
      user_id ->
        :ok = GenServer.call(__MODULE__, {:delete, user_id})
        Plug.Conn.delete_session(conn, :user_id)
    end
  end
end

defmodule SimpleAuth.UserSession.MemoryGenServer do
  use GenServer
  require Logger
  @expiry_callback Application.get_env(:simple_auth, :expiry_callback)
  @session_expiry_seconds Application.get_env(:simple_auth, :session_expiry_seconds)
  @expired_check_interval_seconds 60

  defstruct user: nil, expiry: nil

  def init(_opts) do
    Logger.info "Starting session server expiry_callback: #{inspect @expiry_callback}"
    sessions =
      %{}
      |> check_expired_sessions # to cause the regular timer to start
    {:ok, sessions}
  end

  def handle_call({:get, user_id}, _from, sessions) do
    session = sessions[user_id]
    {:reply, session, sessions}
  end

  def handle_call({:put, %{id: user_id}=user}, _from, sessions) do
    expiry = (DateTime.utc_now |> DateTime.to_unix) + @session_expiry_seconds
    sessions = Map.put(sessions, user_id, %__MODULE__{user: user, expiry: expiry})
    Logger.info "Added session. sessions: #{inspect sessions}"
    {:reply, :ok, sessions}
  end

  def handle_call({:delete, user_id}, _from, sessions) do
    invoke_expiry_callback(@expiry_callback, user_id)
    sessions = Map.delete(sessions, user_id)
    Logger.info "Deleted session. sessions: #{inspect sessions}"
    {:reply, :ok, sessions}
  end

  def handle_info(:check_expired_sessions, sessions) do
    {:noreply, check_expired_sessions(sessions)}
  end

  defp check_expired_sessions(sessions) do
    sessions =
      sessions
      |> Enum.filter(fn({user_id,%__MODULE__{} = session}) ->
          now = DateTime.utc_now |> DateTime.to_unix
          if now > session.expiry do
            Logger.info "Session #{user_id} expired"
            invoke_expiry_callback(@expiry_callback, user_id)
            false
          else
            true
          end
        end)
      |> Map.new

    Process.send_after(self(), :check_expired_sessions, @expired_check_interval_seconds * 1000)
    sessions
  end

  defp invoke_expiry_callback({module, function}, user_id), do: apply(module, function, [user_id])
  defp invoke_expiry_callback(nil, _), do: :ok
end
