# HabitGrid — Claude Code guide

Personal iOS habit tracker with a GitHub-style contribution grid and a home-screen
widget. Built to learn iOS properly: native **SwiftUI** + **SwiftData** + **WidgetKit**.
On-device only — no accounts, servers, or App Store.

## Repo layout

- `Packages/HabitCore/` — pure-Swift domain core: `Habit`/`Completion` models, daily-count
  aggregation, and the contribution-grid algorithm. **No Apple UI/persistence imports** —
  unit-testable without Xcode.
- _(coming)_ Xcode app target `HabitGrid` — SwiftUI app, SwiftData persistence.
- _(coming)_ Widget extension `HabitWidget` — WidgetKit; shares data with the app via an App Group.
- `.claude/` — local Claude Code scaffolding (skills, plan). Gitignored.

## Architecture rules

- **Keep `HabitCore` framework-free** (no `import SwiftData` / `import SwiftUI`). It is the
  testable core that both the app and the widget depend on. SwiftData `@Model` types live in
  the app target and map to/from these plain value types.
- The grid algorithm (`ContributionGridBuilder`) is deterministic — **always pass an explicit
  `Calendar`** in tests to avoid locale/timezone flakiness.
- Commit per milestone; tick the roadmap checkboxes in `README.md`.

## Commands

HabitCore (builds today with only Command Line Tools):

```sh
swift build --package-path Packages/HabitCore        # compile the core
swift test  --package-path Packages/HabitCore         # needs FULL Xcode (XCTest)
```

XCTest ships with Xcode, so `swift test` won't run until Xcode is installed. Until then,
verify logic with the ad-hoc runner pattern — see the `verify-core` skill in `.claude/skills/`.

## Status (2026-06-13)

- ✅ `HabitCore`: models + grid algorithm, 13 checks passing.
- ⏳ Blocker: install **Xcode** (Mac App Store) for the app, widget, Simulator, and XCTest.
- ▶️ Next: create the Xcode app project here, add `HabitCore` as a local package dependency,
  then build Today view → SwiftUI grid view → widget. Full plan in `.claude/plan/roadmap.md`.
