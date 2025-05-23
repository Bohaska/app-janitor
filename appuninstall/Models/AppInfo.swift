//  AppInfo.swift

import SwiftUI // Required for the 'Image' type
import Foundation // Required for 'URL' and 'Bundle'

/// Represents information about the selected macOS application.
struct AppInfo {
    let name: String            // The human-readable name of the app (e.g., "Safari")
    let bundleIdentifier: String // The unique bundle ID (e.g., "com.apple.Safari")
    var icon: Image?            // The app's icon, if successfully loaded (SwiftUI Image)
    let appURL: URL             // The original URL of the .app bundle itself
}
