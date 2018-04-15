defmodule SimpleAuth.Authenticate.Ldap do
  @moduledoc """
    Authenticates using LDAP
  """
  @behaviour SimpleAuth.AuthenticateAPI
  require Logger

  # Use functions to return values from runtime
  defp repo, do: Application.get_env(:simple_auth, :repo)
  defp user_model, do: Application.get_env(:simple_auth, :user_model)
  defp ldap_helper, do: Application.get_env(:simple_auth, :ldap_helper_module)
  defp username_field, do: Application.get_env(:simple_auth, :username_field)
  defp ldap_client, do: Application.get_env(:simple_auth, :ldap_client)

  @doc """
    Checks the user and password against the LDAP server.  If succeeds adds
    the user to the DB if it is not there already
  """
  def login(username, password) do
    {:ok, connection} = ldap_client().open()
    user = ldap_helper().build_ldap_user(username)
    Logger.info "Checking LDAP credentials for user: #{user}"
    verify_result = ldap_client().verify_credentials(connection, user, password)
    result = case verify_result do
      :ok ->
        user = get_or_insert_user(username, connection)
        {:ok, user}
      {:error, _} ->
        :error
    end
    ldap_client().close(connection)
    result
  end

  defp get_or_insert_user(username, connection) do
    case repo().get_by(user_model(), [{username_field(), username}]) do
      nil ->
        Logger.info "Adding user: #{username}"
        {:ok, user} =
          struct(user_model())
          |> Map.put(username_field(), username)
          |> ldap_helper().enhance_user(connection, new_user: true)
          |> user_model().changeset(%{})
          |> repo().insert()
        Logger.info "Done id: #{user.id}"
        user
      user ->
        Logger.info "User already exists: #{user.id} #{username}"
        user
        |> ldap_helper().enhance_user(connection, new_user: false)
    end
  end
end
