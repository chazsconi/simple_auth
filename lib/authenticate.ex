defmodule SimpleAuth.AuthenticateAPI do
  @moduledoc "API for authentication"

  @doc "Checks login details. Returns {:ok, user} or :error.  Can also return :blocked if user is blocked"
  @callback login(user :: term, password :: term) :: term
end
