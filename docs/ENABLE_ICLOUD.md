# iCloud sync (CloudKit)

iCloud sync makes HabitGrid sync across your devices and back up to iCloud. It needs the
paid **Apple Developer Program** (same membership the real-device widget needs).

## What's already done in code
- **Models are CloudKit-compatible** (`Shared/Models.swift`): no `@Attribute(.unique)`, every
  property has a default, and the `completions` relationship is **optional** (CloudKit requires
  to-many relationships to be optional — read it via the `completionsList` helper).
- **The store auto-enables CloudKit** (`Shared/HabitStore.swift`): it uses the private CloudKit
  database `iCloud.com.m7soliman.HabitGrid` whenever the device is signed into iCloud, and stays
  local-only otherwise — so it never crashes on a device/simulator without iCloud.
- **Entitlements** include iCloud + CloudKit on both the app and widget targets.

## What you do in Xcode (one-time)
1. Open `HabitGrid.xcodeproj` → select the **HabitGrid** target → **Signing & Capabilities**.
2. Turn on **Automatically manage signing** and pick your **Team**.
3. Confirm the **iCloud** capability is present with **CloudKit** checked and the container
   **`iCloud.com.m7soliman.HabitGrid`**. If it's not listed, click **+ Capability → iCloud**,
   check CloudKit, and add that container (this registers it in your account).
4. Repeat the **Team** selection for the **HabitWidgetExtension** target.
5. Pick your iPhone as the run destination and **Run**. The first launch creates the CloudKit
   schema in the **Development** environment.

> Tip: set your Team once in `project.yml` (`DEVELOPMENT_TEAM: <TEAMID>`) so `xcodegen generate`
> keeps it. Find the 10-char Team ID at developer.apple.com → Membership.

## Verify it's syncing
- Add/edit a habit on one device → it appears on another device signed into the same iCloud.
- Or check records in the **CloudKit Dashboard** (developer.apple.com → CloudKit).

## Before sharing it more widely
- In the CloudKit Dashboard, **deploy the schema to Production**.

## Notes
- Existing local data uploads to iCloud on first sync; no manual migration needed.
- The widget reads the same shared store, so it reflects synced data too.
