defmodule SimpleAuth.Authenticate do
  @max_attempts 3
  @repo Application.get_env(:simple_auth, :repo)
  @user_model Application.get_env(:simple_auth, :user_model)

  # This indirection prevents compiler warnings
  defp repo, do: @repo
  defp user_model, do: @user_model

  @doc "Checks login details against user table.  Returns {:ok, user} or :error"
  def login(email, password) do

    user = repo().get_by(user_model(), email: String.downcase(email))
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
    repo().update!(user_model().changeset(user, %{attempts: user.attempts + 1, attempted_at: Ecto.DateTime.utc}))
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
