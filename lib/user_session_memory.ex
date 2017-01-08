defmodule SimpleAuth.UserSession.Memory do
  @moduledoc "Real version of API storing user details in a GenServer"
  @behaviour SimpleAuth.UserSessionAPI

  def start_link do
    {:ok, _} = GenServer.start_link(SimpleAuth.UserSession.MemoryGenServer, nil, name: __MODULE__)
  end

  def get(conn) do
    case SimpleAuth.UserSession.HTTPSession.get(conn) do
      nil -> nil
      user ->
        GenServer.call(__MODULE__, {:get, user.id})
        case GenServer.call(__MODULE__, {:get, user.id}) do
           nil -> nil
           _session -> user
        end
    end
  end

  def put(conn, user) do
    :ok = GenServer.call(__MODULE__, {:put, user.id})
    SimpleAuth.UserSession.HTTPSession.put(conn, user)
  end

  def delete(conn) do
    user = SimpleAuth.UserSession.HTTPSession.get(conn)
    :ok = GenServer.call(__MODULE__, {:delete, user.id})
    SimpleAuth.UserSession.HTTPSession.delete(conn)
  end
end

defmodule SimpleAuth.UserSession.MemoryGenServer do
  use GenServer
  require Logger
  @expiry_callback Application.get_env(:simple_auth, :expiry_callback)
  @session_expiry_seconds Application.get_env(:simple_auth, :session_expiry_seconds)

  defstruct expiry: nil, requests: 0

  def init(_opts) do
    Logger.info "Starting session server expiry_callback: #{inspect @expiry_callback}"
    sessions =
      %{}
      |> check_expired_sessions
    {:ok, sessions}
  end

  def handle_call({:get, user_id}, _from, sessions) do
    session = sessions[user_id]
    {:reply, session, sessions}
  end

  def handle_call({:put, user_id}, _from, sessions) do
    expiry = (DateTime.utc_now |> DateTime.to_unix) + @session_expiry_seconds
    sessions = Map.put(sessions, user_id, %__MODULE__{ expiry: expiry})
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

    Process.send_after(self, :check_expired_sessions, 10000)
    sessions
  end

  defp invoke_expiry_callback({module, function}, user_id), do: apply(module, function, [user_id])
  defp invoke_expiry_callback(nil, _), do: :ok
end
