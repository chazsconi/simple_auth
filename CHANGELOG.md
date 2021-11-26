# Changelog

## Unreleased

## v1.11.0

* Enhancements
  * Support Phoenix 1.6, remove Phoenix 1.3 support

## v1.10.1

* Bug fixes
  * Fix dialyzer issue in `AccessControl`
  * Fix duplicate docs for `AccessControl.roles`

## v1.10.0

* Enhancements
  * Support Phoenix 1.5

* Other
  * Updated docs for later Phoenix versions

## v1.9.0

* Enhancements
  * Add `:ldap_allow_unknown_users` setting

* Other
  * Change `applications` to `extra_applications` (needs Elixir >= 1.4)

* Deprecations
  * Elixir 1.3 support

## v1.8.0

* Enhancements
  * Support Phoenix 1.4, remove Phoenix 1.2 support

## v1.7.0

* Enhancements
  * Add `transform_user/2` callback to `LoginController`

## v1.6.1

* Enhancements
  * `UserSession.Memory.delete/1` now accepts `user_id` or `conn` as a parameter.

## v1.6.0

* Other
  * Make `exldap` an optional dependency.  If you use the `SimpleAuth.Authenticate.Ldap` authenticate_api you must include
 the dependency explicitly in your project. See `README.md` for details.
  * Document additional config parameters.

## v1.5.8

* Bug fixes
  * Resolve config options at runtime not compile time
* Other
  * Set default config in `mix.exs` not in code (If you have `runtime: false` in `mix.exs` this could be a breaking change as the default values will not used.)
  * Remove warning message logged at startup if not using UserSession.Memory

## v1.5.7

* Enhancements
  * Provide `:post_login_path` and `:post_logout_path` config options

## v1.5.6

* Enhancements
  * Provide `AccessControl.roles/1` and `AccessControl.any_granted?/2` that take a `User` struct

## v1.5.5

* Enhancements
  * Allow LDAP client to be overridden in config

## v1.5.4

* Enhancements
  * Resolve config settings as run time rather than compile time

## v1.5.3

* Enhancements
  * Provide additional parameter for LDAPHelper enhance_user to indicate if new user (breaking change)

## v1.5.2

* Enhancements
  * Support Phoenix 1.3

## v1.5.1

* Enhancements
  * Fixed documentation
  * Added requirements to publish as Hex package
* Other
  * Removed support for Phoenix 1.3.0 release candidate as cannot publish otherwise

## v1.5.0

* Enhancements
  * LDAP authentication support
  * Configurable username field (previously was 'email')
  * Configurable no redirection for ajax requests

## v1.4.0

* Enhancements
  * Session refresh and info endpoints

## v1.3.1

* Enhancements
  * Relax Phoenix version dependency to allow use with Phoenix 1.3.0 release candidates

## v1.3.0

* Enhancements
  * Use `NaiveDateTime` for `:attempted_at`
  * To upgrade, change the underlying datatype in the `User` schema from `:datetime` to `:naive_datetime`
  * Upgraded `comeonin` to 3.0
  * Update README to show model example without deprecated Phoenix methods

## v1.2.1

* Bug fixes
  * Fix compiler warnings

## v1.2.0

* Enhancements
  * Basic support for oauth and fixes for Elixir 1.4

## v1.1.1

* Bug fixes
  * Fix delete for UserSession.Memory

## v1.1.0

* Enhancements
  * Add memory session and login_controller callbacks

## v1.0.3

* Enhancements
  * Updated comeonin to 2.5.1

## v1.0.2

* Enhancements
  * Allow phoenix 2.0

## v1.0.1

* Enhancements
  * Updated README

## v1.0.0

* Original release
