//  SystemSettingsHelper.swift

import Foundation
import AppKit

struct SystemSettingsHelper {

    /// Attempts to open a specific pane in System Settings (macOS 13+) or System Preferences (older macOS).
    /// - Parameter paneID: A string identifier for the pane (e.g., "com.apple.Privacy-Settings.FullDiskAccess").
    static func openSystemSettings(paneID: String? = nil) {
        if #available(macOS 13.0, *) {
            // For macOS Ventura (13.0) and later
            if let paneID = paneID, let url = URL(string: "x-apple.systempreferences:com.apple.Privacy-Settings?\(paneID)") {
                // Specific pane/sub-pane
                NSWorkspace.shared.open(url)
            } else if let url = URL(string: "x-apple.systempreferences:com.apple.Privacy-Settings") {
                // Just the Privacy & Security section
                 NSWorkspace.shared.open(url)
            } else {
                // Fallback to general System Settings if URL invalid
                NSWorkspace.shared.open(URL(fileURLWithPath: "/System/Applications/Settings.app"))
            }
        } else {
            // For macOS Monterey (12.0) and earlier
            NSWorkspace.shared.open(URL(fileURLWithPath: "/System/Library/PreferencePanes/Security.prefPane"))
        }
    }

    /// Opens the Full Disk Access section directly if possible.
    static func openFullDiskAccessSettings() {
        if #available(macOS 13.0, *) {
            // On Ventura+, there isn't a direct deep link to the "Full Disk Access" *subsection* within Privacy & Security,
            // but opening Privacy & Security is the closest.
            // The specific pane ID is "com.apple.Privacy-Settings.FullDiskAccess" but often doesn't navigate to the specific sub-section automatically.
            openSystemSettings(paneID: "com.apple.Privacy-Settings.FullDiskAccess") // This will open Privacy & Security
        } else {
            // For older macOS, open Security & Privacy preference pane
            openSystemSettings() // No specific sub-pane ID for older versions to link directly to FDA.
        }
    }
}
