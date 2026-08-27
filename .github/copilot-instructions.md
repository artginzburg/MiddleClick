# GitHub Copilot Instructions

## Project overview

MiddleClick is a macOS menu-bar app that emulates a middle-click from a multi-finger trackpad tap or press. It uses Apple's private `MultitouchSupport` framework and the `CGEvent` tap API.

See [`CONTRIBUTING.md`](../CONTRIBUTING.md) for build instructions and project structure.

## Documentation conventions

- **`docs/CHANGELOG.md`** — Record every user-visible fix or behaviour change in the `[Unreleased]` section. Follow the [Keep a Changelog](https://keepachangelog.com/en/1.1.0/) format (`### Fixed`, `### Added`, `### Changed`, `### Removed`). Do not bump version numbers manually — use `make bump-patch`, `make bump-minor`, or `make bump-major` at release time (see `docs/maintain.md`).
- **Semantic versioning** — choose the bump level by impact: `patch` for bug fixes, `minor` for new backwards-compatible features, `major` for breaking changes. Version components are always integers; the bump script enforces this so comparisons like `3.9 → 3.10` are always correct. Never compare or sort version strings lexicographically.
- **`docs/`** — Topic-specific docs (e.g. `three-finger-drag.md`, `troubleshooting.md`). Update or add a file here when a change affects user-visible behaviour, known limitations, or workarounds.
- **`CONTRIBUTING.md`** — Update when the build process, project structure, or contribution workflow changes.

## Code conventions

- Shared mutable state lives in `GlobalState.swift`. Both the multitouch C callback (`TouchHandler.swift`) and the CGEvent tap callback (`Controller+Mouse.swift`) access it from non-main-actor threads — keep additions minimal and be aware of the implicit data race.
- Gesture detection state in `TouchHandler` must be fully reset in `TouchHandler.reset()` (called from `unregisterTouchCallback()`), and `GlobalState` must be reset via `GlobalState.reset()` (called from `Controller.stopUnstableListeners()`). Any new stateful fields must be included in the corresponding `reset()` method.
- The tap-to-click middle click is gated by `middleClickArmed` — it only fires after the right finger count is detected on at least two consecutive touch frames. New conditions that gate emulation should be added to `handleTouchEnd()`, not scattered across the callback.
- SwiftLint runs as a build phase. Keep new code lint-clean (install via `brew bundle`).
