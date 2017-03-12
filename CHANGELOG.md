# Changelog

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
