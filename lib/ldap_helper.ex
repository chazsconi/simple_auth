defmodule SimpleAuth.LdapHelperAPI do
  @moduledoc "API for authentication"

  @doc """
  Builds the LDAP user to be passed to ldap from the username.  This should be a very simple
  function that just returns for example "myorg\\<username>"
  """
  @callback build_ldap_user(username :: term) :: term
end
