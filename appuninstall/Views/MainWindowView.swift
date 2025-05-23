// App Janitor/Views/MainWindowView.swift
import SwiftUI
import UniformTypeIdentifiers // For .fileURL type identifier

struct MainWindowView: View {
    // Instantiate the ViewModel as a StateObject. It will persist for the lifetime of the view.
    @StateObject private var viewModel = MainWindowViewModel()

    // State for drag and drop visual feedback.
    // This will be true when an acceptable item is dragged over the target zone.
    @State private var isDragTargeted: Bool = false

    var body: some View {
        ZStack { // Use ZStack for the loading overlay
            mainContent // The primary UI layout

            // MARK: - Loading Overlay
            if viewModel.isLoading {
                Color.black.opacity(0.6) // Semi-transparent dark overlay
                    .edgesIgnoringSafeArea(.all) // Extend across the entire window
                VStack {
                    if viewModel.scanProgress > 0.0 && viewModel.scanProgress < 1.0 {
                        // Show linear progress bar and current path during active scanning
                        ProgressView(value: viewModel.scanProgress) {
                            Text("Scanning Files...")
                                .font(.headline)
                        } currentValueLabel: {
                            Text(viewModel.currentScanPath)
                                .font(.caption)
                                .foregroundColor(.gray)
                                .lineLimit(2) // Prevent path from taking too much space
                        }
                        .progressViewStyle(.linear)
                        .padding(.horizontal) // Padding for the progress bar itself
                        .frame(width: 300) // Give it a fixed width for better appearance

                        // Optional: A small circular indicator below the linear bar
                        ProgressView()
                            .progressViewStyle(.circular)
                            .scaleEffect(0.8) // Make it smaller
                            .padding(.top, 5)

                    } else {
                        // Show generic circular progress for initial loading or finalization
                        ProgressView("Processing...") // Or "Loading..."
                            .progressViewStyle(.circular)
                            .scaleEffect(1.5) // Keep it larger for generic state
                    }
                }
                .padding(20) // Padding around the entire progress content
                .background(Color.white)
                .cornerRadius(10)
                .shadow(radius: 5)
            }
        }
        // MARK: - Alerts
        // Error Alert (for general errors)
        .alert(isPresented: $viewModel.showErrorAlert) {
            Alert(title: Text("Error"),
                  message: Text(viewModel.errorMessage),
                  dismissButton: .default(Text("OK")))
        }
        // NEW: Permission Required Alert (for specific permission issues)
        .alert("Permission Required", isPresented: $viewModel.showPermissionRequiredAlert) {
            Button("Go to Settings") {
                SystemSettingsHelper.openFullDiskAccessSettings() // Use the helper to deep link
            }
            Button("Not Now", role: .cancel) {
                // User chose not to open settings.
            }
        } message: {
            Text(viewModel.errorMessage) // Use errorMessage for the message content
        }
        // Confirmation Alert for Deletion
        .alert("Confirm Action", isPresented: $viewModel.showConfirmationAlert) {
            Button("Remove", role: .destructive) { // Red button for destructive action
                viewModel.confirmationAction?() // Execute the action stored in the ViewModel
            }
            Button("Cancel", role: .cancel) { // Default style for cancel button
                // No action needed, alert dismissal implies cancellation
            }
        } message: {
            Text(viewModel.confirmationMessage) // Display the confirmation message
        }
    }

    // MARK: - Main Content Layout (Simplified)
    private var mainContent: some View {
        HSplitView { // Use HSplitView to divide the window into two main columns
            DragDropColumnView(viewModel: viewModel, isDragTargeted: $isDragTargeted)
            FilesListColumnView(viewModel: viewModel)
        }
        .background(Color.primary.opacity(0.05).edgesIgnoringSafeArea(.all)) // Overall background color for the entire view
    }
}

// MARK: - Preview Provider for MainWindowView
struct MainWindowView_Previews: PreviewProvider {
    static var previews: some View {
        MainWindowView()
            .frame(width: 800, height: 500) // Provide a fixed size for the preview
            .preferredColorScheme(.dark) // Simulate the Electron app's dark theme
    }
}
