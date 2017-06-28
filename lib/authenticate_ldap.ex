defmodule SimpleAuth.Authenticate.Ldap do
  @moduledoc """
    Authenticates using LDAP
  """
  @behaviour SimpleAuth.AuthenticateAPI
  require Logger

  @repo Application.get_env(:simple_auth, :repo)
  @user_model Application.get_env(:simple_auth, :user_model)
  @ldap_helper Application.get_env(:simple_auth, :ldap_helper_module)

  # This indirection prevents compiler warnings
  defp repo, do: @repo
  defp user_model, do: @user_model
  defp ldap_helper, do: @ldap_helper

  def login(username, password) do
    {:ok, connection} = Exldap.open()
    user = ldap_helper().build_ldap_user(username)
    Logger.info "Checking LDAP credentials for user: #{user}"
    case Exldap.verify_credentials(connection, user, password) do
      :ok ->
        user = get_or_insert_user(username)
        {:ok, user}
      {:error, _} ->
        :error
    end
  end

  defp get_or_insert_user(username) do
    case @repo.get_by(user_model(), username: username) do
      nil ->
        Logger.info "Adding user #{username}..."
        changeset = user_model().changeset(struct(user_model()), %{username: username})
        {:ok, user} = repo().insert(changeset)
        Logger.info "Done id: #{user.id}"
        user
      user ->
        Logger.info "User already exists: #{user.id} #{user.username}"
        user
    end
  end
end