defmodule SimpleAuth.Authenticate.Repo do
  @moduledoc """
  Implementation that checks authenticates user against a database with a username/password
  """
  @max_attempts 3

  defp repo, do: Application.get_env(:simple_auth, :repo)
  defp user_model, do: Application.get_env(:simple_auth, :user_model)
  defp username_field, do: Application.get_env(:simple_auth, :username_field)

  @behaviour SimpleAuth.AuthenticateAPI

  @doc "Checks login details against user table.  Returns {:ok, user} or :error"
  def login(username, password) do

    user = repo().get_by(user_model(), [{username_field(), username}])
    case authenticate(user, password) do
      true ->
        repo().update(user_model().changeset(user, %{attempts: 0}))
      :blocked ->
        increment_attempts(user)
        :blocked
      false ->
        increment_attempts(user)
        :error
      :no_user ->
        :error
    end
  end

  defp increment_attempts(user) do
    repo().update!(user_model().changeset(user, %{attempts: user.attempts + 1, attempted_at: NaiveDateTime.utc_now()}))
  end

  defp authenticate(user, password) do
    case user do
      nil -> :no_user
      _ ->
        if user.attempts >= @max_attempts do
          :blocked
        else
          Comeonin.Bcrypt.checkpw(password, user.crypted_password)
        end
    end
  end
end
