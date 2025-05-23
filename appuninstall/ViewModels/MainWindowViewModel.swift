// App Janitor/ViewModels/MainWindowViewModel.swift
import SwiftUI
import AppKit // For NSWorkspace (trashing files, quitting apps, opening in Finder)
import Foundation

// Ensure Models and Utils (where Constants, Config, etc. are) are accessible to this file.
// If you placed them in separate frameworks, you'd need `import YourFrameworkName`.
// For now, assuming they are in the same main app target.

/// ViewModel for the main application window, managing UI state and business logic.
class MainWindowViewModel: ObservableObject {
    // MARK: - Published Properties (UI State)
    @Published var files: [FoundFile] = [] // List of files found, observed by SwiftUI List
    @Published var isLoading: Bool = false // Controls loading spinner visibility
    @Published var selectedAppInfo: AppInfo? // Information about the currently selected app
    @Published var statusText: String = "Related Files" // Text for file count/status
    @Published var dragDropZoneText: String = "Drag and Drop App Here" // Text for the drag zone
    @Published var dragDropZoneImage: Image = Image(systemName: "arrow.down.doc.fill") // Icon for the drag zone
    @Published var isDeleteButtonDisabled: Bool = true // Controls Remove button state

    // Alert properties for error/confirmation dialogs
    @Published var showErrorAlert: Bool = false
    @Published var errorMessage: String = ""
    @Published var showConfirmationAlert: Bool = false
    @Published var confirmationMessage: String = ""
    var confirmationAction: (() -> Void)? // Action to perform if confirmation is accepted

    private let fileFinder = AppFileFinder() // Instance of the core logic actor

    init() {
        // Initial setup for the ViewModel.
        // The AppFileFinder will load computer name on its init.
    }

    // MARK: - Actions

    /// Handles the selection of an application (e.g., from drag-and-drop or file picker).
    /// This method is `@MainActor` as it updates `@Published` properties.
    /// - Parameter appURL: The URL of the selected .app bundle.
    @MainActor
    func handleAppSelection(appURL: URL) async {
        isLoading = true
        clearList() // Reset UI for new selection

        guard appURL.pathExtension.lowercased() == "app" else {
            errorMessage = "Selected file is not a valid application (.app)."
            showErrorAlert = true
            isLoading = false
            return
        }

        do {
            let appName = await fileFinder.appNameFromPath(appURL) // Call actor method
            guard let bundleId = await fileFinder.getBundleIdentifier(forAppAt: appURL) else { // Call actor method
                errorMessage = "Could not retrieve bundle identifier for \(appName). Cannot proceed."
                showErrorAlert = true
                isLoading = false
                return
            }

            let appIcon = await fileFinder.getAppIcon(forAppAt: appURL) // Call actor method
            selectedAppInfo = AppInfo(name: appName, bundleIdentifier: bundleId, icon: appIcon, appURL: appURL)

            dragDropZoneText = appName
            // If appIcon is nil, use a default system icon, otherwise use the app's icon
            dragDropZoneImage = appIcon ?? Image(systemName: "app.fill")

            // Perform file finding on a background task managed by the actor
            let foundFiles = try await fileFinder.findAppFilesToRemove(appURL: appURL, appName: appName, bundleId: bundleId)
            self.files = foundFiles
            statusText = "\(files.count) Files Found"
            isDeleteButtonDisabled = files.isEmpty // Disable delete if no files found
        } catch {
            // MARK: - Permissions Error Handling Improvement
            let nsError = error as NSError
            if nsError.domain == NSCocoaErrorDomain && (nsError.code == NSFileReadNoPermissionError || nsError.code == NSFileReadUnknownError) {
                // NSFileReadUnknownError can also sometimes indicate permission issues
                errorMessage = """
                Permission Denied: App Janitor needs permission to access files in some system directories (e.g., your Library folders).
                
                Please grant "Full Disk Access" to App Janitor in System Settings > Privacy & Security > Full Disk Access.
                
                Alternatively, you can manually add specific folders under "Files and Folders."
                
                You can find more details in the "Permissions" section under the Help menu.
                """
            } else {
                errorMessage = "An unexpected error occurred while scanning for files: \(error.localizedDescription)"
            }
            showErrorAlert = true
        }
        isLoading = false
    }

    /// Presents a confirmation alert to the user before attempting to move files to trash.
    @MainActor
    func confirmAndDeleteSelectedFiles() {
        let filesToTrash = files.filter { $0.isSelected }

        guard !filesToTrash.isEmpty else { return }

        confirmationMessage = "Are you sure you want to move \(filesToTrash.count) file(s) to Trash?"
        confirmationAction = { [weak self] in
            guard let self = self else { return }
            // Use a Task for the async operation
            Task { @MainActor in
                await self.performTrashOperation(filesToTrash: filesToTrash)
            }
        }
        showConfirmationAlert = true
    }

    /// Performs the actual operation of moving selected files to trash.
    /// This method is `@MainActor` to update UI state, but heavy work is offloaded.
    /// - Parameter filesToTrash: An array of `FoundFile` objects to be trashed.
    @MainActor
    private func performTrashOperation(filesToTrash: [FoundFile]) async {
        isLoading = true
        var successfulTrashCount = 0

        do {
            // Attempt to close the running application if it's the main app
            // This is non-blocking and relies on user interaction (macOS prompt)
            if let selectedApp = selectedAppInfo,
               let runningApp = NSWorkspace.shared.runningApplications.first(where: { $0.bundleIdentifier == selectedApp.bundleIdentifier }) {
                print("Attempting to terminate running app: \(selectedApp.name)")
                runningApp.terminate() // This sends a request to quit the app
                // It's good practice to wait a bit if possible, but immediate trashing also works.
            }

            for file in filesToTrash {
                do {
                    try FileManager.default.trashItem(at: file.url, resultingItemURL: nil)
                    successfulTrashCount += 1
                } catch {
                    // Log error for individual file but continue to next
                    print("Failed to trash file \(file.url.lastPathComponent): \(error.localizedDescription)")
                    // Keep the overall error message generic or aggregate if many fail
                    errorMessage = "Failed to move some files to trash. Please update permissions or try manually. \(error.localizedDescription)"
                    showErrorAlert = true
                }
            }

            // Update the UI based on what was successfully trashed
            if successfulTrashCount == filesToTrash.count {
                clearList() // All files gone, reset completely
            } else if successfulTrashCount > 0 {
                // Some files were trashed, update the list to show remaining
                files.removeAll { f in filesToTrash.contains(where: { $0.id == f.id }) }
                statusText = "\(files.count) Files Remaining"
                isDeleteButtonDisabled = files.isEmpty
            }
        } catch {
            errorMessage = "A critical error occurred during trash operation: \(error.localizedDescription)"
            showErrorAlert = true
        }
        isLoading = false
    }

    /// Clears the current file list and resets all related UI states.
    @MainActor
    func clearList() {
        files = []
        selectedAppInfo = nil
        statusText = "Related Files"
        dragDropZoneText = "Drag and Drop App Here"
        dragDropZoneImage = Image(systemName: "arrow.down.doc.fill") // Reset to default icon
        isDeleteButtonDisabled = true
        // Also clear any pending alert states
        showErrorAlert = false
        showConfirmationAlert = false
        errorMessage = ""
        confirmationMessage = ""
        confirmationAction = nil
    }

    /// Toggles the selection state of a specific `FoundFile` in the `files` array.
    /// This method is called directly from the UI when a checkbox is toggled.
    /// - Parameter id: The unique ID of the `FoundFile` to toggle.
    @MainActor
    func toggleFileSelection(for id: UUID) {
        if let index = files.firstIndex(where: { $0.id == id }) {
            files[index].isSelected.toggle()
            // Optional: Re-evaluate isDeleteButtonDisabled if all selected items become deselected
            // isDeleteButtonDisabled = files.filter { $0.isSelected }.isEmpty
        }
    }
}
