defmodule SimpleAuth do
  use Application

  # The application is needed in case the UserSession.Memory is used. As the OTP behaviour
  # for the Application start callback requires the `{:ok, pid}` to be returned, the supervisor
  # is still started even if it has nothing to supervise.

  defp user_session_api(), do: Application.get_env(:simple_auth, :user_session_api)

  def start(_type, _args) do
    import Supervisor.Spec

    children =
      case user_session_api() do
        SimpleAuth.UserSession.Memory ->
          [worker(SimpleAuth.UserSession.Memory, [])]
        _ ->
          []
      end

    opts = [strategy: :one_for_one, name: SimpleAuth.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
