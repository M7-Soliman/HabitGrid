import Foundation
import SwiftData

// The single SwiftData store, in a shared App Group container so the app and the widget
// read/write the same database. When an iCloud account is present (and the CloudKit container
// is provisioned), it also mirrors to iCloud to sync across devices.
enum HabitStore {
    static let appGroupID = "group.com.m7soliman.HabitGrid"
    static let cloudKitContainerID = "iCloud.com.m7soliman.HabitGrid"

    static let container: ModelContainer = {
        // Only use CloudKit when the device is signed into iCloud — otherwise stay purely local.
        // (Avoids enabling CloudKit history-tracking on a store that can't reach iCloud, which
        // would make the store unopenable.)
        let useCloud = FileManager.default.ubiquityIdentityToken != nil

        let configuration: ModelConfiguration = useCloud
            ? ModelConfiguration(groupContainer: .identifier(appGroupID),
                                  cloudKitDatabase: .private(cloudKitContainerID))
            : ModelConfiguration(groupContainer: .identifier(appGroupID))

        do {
            return try ModelContainer(for: HabitModel.self, CompletionModel.self, configurations: configuration)
        } catch {
            fatalError("Could not create the shared ModelContainer: \(error)")
        }
    }()
}
