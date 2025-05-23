//  BottomActionBarView.swift

import SwiftUI

struct BottomActionBarView: View {
    @ObservedObject var viewModel: MainWindowViewModel

    var body: some View {
        HStack {
            Spacer() // Pushes buttons to the right

            Button("Remove") {
                viewModel.confirmAndDeleteSelectedFiles() // Action to confirm and delete
            }
            .buttonStyle(.borderedProminent) // Modern macOS prominent button
            .tint(.red) // Make the button red for a destructive action
            .disabled(viewModel.isDeleteButtonDisabled) // Disable if no files or no app selected

            Button("Cancel") {
                viewModel.clearList() // Action to clear the list and reset UI
            }
            .buttonStyle(.bordered) // Modern macOS bordered button
        }
        .padding(10) // Padding around the buttons
        .background(Color.primary.opacity(0.2)) // Background color for the action bar
        .cornerRadius(5) // Slightly rounded corners for the action bar
    }
}

// MARK: - Preview Provider
struct BottomActionBarView_Previews: PreviewProvider {
    static var previews: some View {
        // Provide a mock ViewModel for the preview
        BottomActionBarView(viewModel: MainWindowViewModel())
            .previewLayout(.sizeThatFits)
            .padding()
            .preferredColorScheme(.dark)
    }
}
