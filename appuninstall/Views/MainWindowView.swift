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
                ProgressView() // macOS native loading spinner
                    .scaleEffect(1.5) // Make the spinner a bit larger
            }
        }
        // MARK: - Alerts
        // Error Alert
        .alert(isPresented: $viewModel.showErrorAlert) {
            Alert(title: Text("Error"),
                  message: Text(viewModel.errorMessage),
                  dismissButton: .default(Text("OK")))
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
