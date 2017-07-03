defmodule SimpleAuth.Authenticate.Ldap do
  @moduledoc """
    Authenticates using LDAP
  """
  @behaviour SimpleAuth.AuthenticateAPI
  require Logger

  @repo Application.get_env(:simple_auth, :repo)
  @user_model Application.get_env(:simple_auth, :user_model)
  @username_field Application.get_env(:simple_auth, :username_field) || :email
  @ldap_helper Application.get_env(:simple_auth, :ldap_helper_module)

  # This indirection prevents compiler warnings
  defp repo, do: @repo
  defp user_model, do: @user_model
  defp ldap_helper, do: @ldap_helper

  @doc """
    Checks the user and password against the LDAP server.  If succeeds adds
    the user to the DB if it is not there already
  """
  def login(username, password) do
    {:ok, connection} = Exldap.open()
    user = ldap_helper().build_ldap_user(username)
    Logger.info "Checking LDAP credentials for user: #{user}"
    verify_result = Exldap.verify_credentials(connection, user, password)
    result = case verify_result do
      :ok ->
        user = get_or_insert_user(username, connection)
        {:ok, user}
      {:error, _} ->
        :error
    end
    Exldap.close(connection)
    result
  end

  defp get_or_insert_user(username, connection) do
    case repo().get_by(user_model(), [{@username_field, username}]) do
      nil ->
        Logger.info "Adding user: #{username}"
        {:ok, user} =
          struct(user_model())
          |> Map.put(@username_field, username)
          |> ldap_helper().enhance_user(connection)
          |> user_model().changeset(%{})
          |> repo().insert()
        Logger.info "Done id: #{user.id}"
        user
      user ->
        Logger.info "User already exists: #{user.id} #{username}"
        user
    end
  end
end
