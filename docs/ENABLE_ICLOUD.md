# Enabling iCloud sync (CloudKit)

This makes HabitGrid sync across your devices and back up to iCloud. It **requires the paid
Apple Developer Program ($99/yr)** — the same membership that lets the widget's App Group
work on a real phone. Do this once you've joined.

## 1. Capabilities (Xcode → target "HabitGrid" → Signing & Capabilities)
- Add **iCloud** → check **CloudKit**.
- Create/select a container: `iCloud.com.m7soliman.HabitGrid`.
- (App Groups should already be present.)

## 2. Entitlements
Add to `App/HabitGrid.entitlements` (and the widget's `Widget/HabitWidget.entitlements`
if the widget should also pull from CloudKit):

```xml
<key>com.apple.developer.icloud-services</key>
<array><string>CloudKit</string></array>
<key>com.apple.developer.icloud-container-identifiers</key>
<array><string>iCloud.com.m7soliman.HabitGrid</string></array>
```

## 3. Model changes (CloudKit constraints) — `Shared/Models.swift`
CloudKit-backed SwiftData has rules the current models break:
- **Remove `@Attribute(.unique)`** from `HabitModel.id` (CloudKit disallows unique constraints).
- **Give every non-optional stored property a default value** (CloudKit needs schema defaults).
  e.g. `var name: String = ""`, `var colorHex: String = "#A8C5F5"`, `var dailyTarget: Int = 1`,
  `var sortIndex: Int = 0`, `var createdAt: Date = .now`; and on `CompletionModel`:
  `var id: UUID = UUID()`, `var date: Date = .now`.
- Relationships are already fine (`completions` is to-many; `habit` is optional with an inverse).

## 4. Point the store at CloudKit — `Shared/HabitStore.swift`
```swift
let configuration = ModelConfiguration(
    groupContainer: .identifier(appGroupID),
    cloudKitDatabase: .private("iCloud.com.m7soliman.HabitGrid")
)
```

## 5. Run on a real device signed into iCloud
- Build to your iPhone (now possible with the paid account).
- First sync can take a moment; CloudKit creates the schema in the **Development** environment.
- Before shipping, deploy the CloudKit schema to **Production** in the CloudKit Dashboard.

## Notes
- The local App Group store keeps working; CloudKit mirrors it. No data migration needed for
  a fresh install, but existing on-device data will upload on first run.
- Keep `.unique` removed — enforce uniqueness in code if ever needed.
