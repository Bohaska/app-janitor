import SwiftUI
import UniformTypeIdentifiers

struct DragDropZoneContent: View {
    @ObservedObject var viewModel: MainWindowViewModel
    @Binding var isDragTargeted: Bool

    // Helper computed property for the image view
    private var dragDropImage: some View {
        viewModel.dragDropZoneImage
            .resizable()
            .scaledToFit()
            .frame(width: 100, height: 100)
            .foregroundColor(isDragTargeted ? .accentColor : .secondary)
            .animation(.easeOut(duration: 0.2), value: isDragTargeted)
    }

    // Extracted content of the VStack
    private var dropZoneMainContent: some View {
        VStack(spacing: 15) {
            dragDropImage // Use the helper property here
            Text(viewModel.dragDropZoneText)
                .font(.title2)
                .fontWeight(.medium)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .padding(.horizontal)

            Button("Select App...") {
                Task { @MainActor in
                    if let appURL = await AppPickerHelper.pickApp() { // Assuming AppPickerHelper exists
                        await viewModel.handleAppSelection(appURL: appURL)
                    }
                }
            }
            .buttonStyle(.borderedProminent)
        }
    }

    var body: some View {
        // Apply the complex modifiers to the extracted content
        dropZoneMainContent
            .padding(20)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(isDragTargeted ? Color.gray.opacity(0.2) : Color.primary.opacity(0.1))
            .cornerRadius(20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .strokeBorder(
                        isDragTargeted ? Color.accentColor : Color.white.opacity(0.6),
                        style: StrokeStyle(lineWidth: 3, dash: [10, 15])
                    )
            )
            .padding(20) // Second padding
            .onDrop(of: [.fileURL], isTargeted: $isDragTargeted) { providers in
                Task { @MainActor in
                    guard let item = providers.first else { return false }
                    
                    // Use modern async/await for loadItem
                    do {
                        let data = try await item.loadItem(forTypeIdentifier: UTType.fileURL.identifier)
                        if let urlData = data as? Data,
                           let url = URL(dataRepresentation: urlData, relativeTo: nil) {
                            if url.pathExtension.lowercased() == "app" {
                                await viewModel.handleAppSelection(appURL: url)
                                return true // Successfully handled
                            }
                        }
                    } catch {
                        // Handle or log error if necessary
                        print("Error loading dropped item: \(error)")
                    }
                    return false // Item not an app or error occurred
                }
                // The onDrop closure itself must return a Bool.
                // Returning 'true' indicates the drop operation was successfully initiated (even if async processing later fails).
                // Returning 'false' might indicate the view cannot handle this type of drop at all.
                // Given the Task, it's generally better to return true here and handle success/failure within the Task.
                return true
            }
    }
}

// MARK: - Preview Provider
struct DragDropZoneContent_Previews: PreviewProvider {
    @State static var isTargeted = false
    // Assuming MainWindowViewModel has a default initializer
    static var previews: some View {
        // Make sure AppPickerHelper and MainWindowViewModel are defined for the preview to work
        // For example, you might need a mock MainWindowViewModel
        DragDropZoneContent(viewModel: MainWindowViewModel(), isDragTargeted: $isTargeted)
            .frame(width: 300, height: 400)
            .preferredColorScheme(.dark)
    }
}
