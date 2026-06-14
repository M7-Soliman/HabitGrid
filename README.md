# HabitGrid

A personal iOS habit tracker with a GitHub-style contribution grid — and a home-screen
widget so the grid is always in sight.

Built as a learn-iOS-properly project: native **SwiftUI**, **SwiftData** for on-device
storage, and **WidgetKit** for the home-screen widget.

## Goals

- Track ~5–10 daily habits with one tap.
- Visualize consistency as a GitHub-style heatmap (the more you do, the greener the day).
- Surface the grid on the iOS home screen via a widget.
- Keep everything on-device — no accounts, no servers.

## Tech

| Concern            | Choice                                   |
| ------------------ | ---------------------------------------- |
| UI                 | SwiftUI                                   |
| Storage            | SwiftData (`@Model`, `@Query`)            |
| Widget             | WidgetKit extension                       |
| App ↔ widget data  | Shared App Group container                |

## Roadmap

- [ ] **1. Hello SwiftUI** — tap a list of habits to toggle "done today" (in-memory).
- [ ] **2. SwiftData** — habits + completions persist across launches.
- [ ] **3. The grid** — contribution heatmap (7 rows × ~52 weeks) per habit.
- [ ] **4. The widget** — draw the grid on the home screen via an App Group.
- [ ] **5. Polish** — multiple habits, streaks, optional Apple Health import.

## Status

Early days. Built on macOS with Xcode.
