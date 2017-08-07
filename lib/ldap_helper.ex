defmodule SimpleAuth.LdapHelperAPI do
  @moduledoc "API for authentication"

  @doc """
  Builds the LDAP user to be passed to ldap from the username.  This should be a very simple
  function that just returns for example "myorg\\<username>"
  """
  @callback build_ldap_user(username :: term) :: term

  @doc """
  Invoked when adding a new user.  The user struct can be enhanced with extra properties if required
  Returns the enhanced user struct
  """
  @type option :: {:new_user, boolean}
  @callback enhance_user(user :: term, connection :: term, [option]) :: term
end
