// App Janitor/Helpers/AppPickerHelper.swift
import AppKit // NSOpenPanel is an AppKit component
import Foundation // For URL

struct AppPickerHelper {

    /// Presents a file open panel to select a .app bundle.
    /// This function is asynchronous and will suspend until the user makes a selection or cancels.
    /// - Returns: The URL of the selected application, or nil if canceled or selection is invalid.
    static func pickApp() async -> URL? {
        // Ensure the AppKit UI operation runs on the main thread
        await withCheckedContinuation { continuation in
            DispatchQueue.main.async {
                let panel = NSOpenPanel()
                panel.canChooseFiles = true
                panel.canChooseDirectories = false
                panel.allowsMultipleSelection = false
                panel.allowedFileTypes = ["app"] // Filter for .app bundles
                panel.prompt = "Select App"
                panel.directoryURL = URL(fileURLWithPath: "/Applications") // Default to /Applications

                if panel.runModal() == .OK, let url = panel.url {
                    continuation.resume(returning: url)
                } else {
                    continuation.resume(returning: nil)
                }
            }
        }
    }
}
