// App Janitor/Views/Components/DragDropColumnView.swift

import SwiftUI
import UniformTypeIdentifiers // Still needed for .fileURL type identifier

struct DragDropColumnView: View {
    @ObservedObject var viewModel: MainWindowViewModel
    @Binding var isDragTargeted: Bool // Binding for visual feedback

    var body: some View {
        VStack {
            // Placeholder for title bar drag region if using a custom window style
            // For default window style, this isn't strictly necessary for dragging
            Rectangle()
                .fill(Color.clear)
                .frame(height: 30) // Reserves space, matching original title bar height
                .contentShape(Rectangle()) // Makes the area tappable/draggable if needed
                .allowsHitTesting(false) // Prevents it from blocking clicks to content below

            Spacer() // Pushes content to center vertically

            // Replaced the complex VStack with our new component
            DragDropZoneContent(viewModel: viewModel, isDragTargeted: $isDragTargeted)

            Spacer() // Pushes content to center vertically
        }
        .frame(minWidth: 300) // Set a minimum width for the left column
        .background(Color.clear) // Transparent background
        .layoutPriority(1) // Give this column a lower priority for horizontal space distribution
    }
}

// MARK: - Preview Provider
struct DragDropColumnView_Previews: PreviewProvider {
    @State static var isTargeted = false
    static var previews: some View {
        DragDropColumnView(viewModel: MainWindowViewModel(), isDragTargeted: $isTargeted)
            .frame(width: 400, height: 600)
            .preferredColorScheme(.dark)
    }
}
