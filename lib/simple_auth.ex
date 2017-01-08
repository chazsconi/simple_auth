defmodule SimpleAuth do
  use Application
  require Logger
  @user_session_api Application.get_env(:simple_auth, :user_session_api)

  def start(_type, _args) do
    import Supervisor.Spec

    children =
      case @user_session_api do
        SimpleAuth.UserSession.Memory ->
          [worker(SimpleAuth.UserSession.Memory, [])]
        _ ->
        Logger.warn "The SimpleAuth application does not need to be started for this API. "
                    <> "Remove it from your list of applications."
          []
      end

    opts = [strategy: :one_for_one, name: SimpleAuth.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
