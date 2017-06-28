defmodule SimpleAuth.AuthenticateAPI do
  @moduledoc "API for authentication"

  @callback login(user :: term, password :: term) :: term
end
