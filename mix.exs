defmodule SimpleAuth.Mixfile do
  use Mix.Project

  def project do
    [
      app: :simple_auth,
      version: "1.6.0",
      elixir: "~> 1.3",
      build_embedded: Mix.env() == :prod,
      start_permanent: Mix.env() == :prod,
      description: description(),
      package: package(),
      deps: deps(),
      name: "SimpleAuth",
      source_url: "https://github.com/chazsconi/simple_auth",
      docs: docs()
    ]
  end

  # Configuration for the OTP application
  #
  # Type "mix help compile.app" for more information
  def application do
    [
      mod: {SimpleAuth, []},
      applications: [:logger],
      # Default config
      env: [
        login_url: "/login",
        post_login_path: "/",
        post_logout_path: "/",
        authenticate_api: SimpleAuth.Authenticate.Repo,
        username_field: :email,
        ldap_client: Exldap
      ]
    ]
  end

  defp deps do
    [
      {:phoenix, "~> 1.2.0 or ~> 1.3.0"},
      {:comeonin, "~> 3.0"},
      {:exldap, "~> 0.4", optional: true},
      {:ex_doc, ">= 0.0.0", only: :dev}
    ]
  end

  defp description do
    """
    Adds authentication and authorization to a Phoenix project.  A user can login
    with a username and password held in the DB or against an LDAP server.
    """
  end

  defp package do
    # These are the default files included in the package
    [
      name: :simple_auth,
      maintainers: ["Charles Bernasconi"],
      licenses: ["Apache 2.0"],
      links: %{"GitHub" => "https://github.com/chazsconi/simple_auth"}
    ]
  end

  defp docs do
    [
      extras: ["README.md"],
      main: "readme"
    ]
  end
end
