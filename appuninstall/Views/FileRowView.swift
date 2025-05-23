//  FileRowView.swift

import SwiftUI
import AppKit // For NSWorkspace.shared.selectFile

struct FileRowView: View {
    // @Binding allows this view to directly modify the 'isSelected' property of the FoundFile
    @Binding var file: FoundFile

    var body: some View {
        HStack {
            Toggle(isOn: $file.isSelected) { // Checkbox for selection
                VStack(alignment: .leading) {
                    Text(file.fileName)
                        .font(.body)
                        .lineLimit(1) // Keep name on one line
                        .truncationMode(.middle) // Use ellipsis in middle if too long
                        .help(file.fileName) // Tooltip for the full filename

                    Text(file.parentDirectoryPath)
                        .font(.footnote)
                        .foregroundColor(.gray)
                        .lineLimit(1) // Keep path on one line
                        .truncationMode(.middle)
                        .help(file.parentDirectoryPath) // Tooltip for the full path
                }
            }
            .toggleStyle(.checkbox) // Use macOS native checkbox style

            Spacer() // Pushes content to the left, and button to the right

            Button {
                // Action to open the file's parent directory in Finder
                NSWorkspace.shared.selectFile(file.url.path, inFileViewerRootedAtPath: "")
            } label: {
                Image(systemName: "folder.fill") // System icon for folder
                    .resizable()
                    .scaledToFit()
                    .frame(width: 20, height: 20)
                    .foregroundColor(.accentColor) // Use system accent color
            }
            .buttonStyle(.plain) // Make it look like an icon button, no background/border
            .help("Show in Finder") // Tooltip for the button
        }
        .padding(.vertical, 5) // Add some vertical padding to each row
    }
}

// MARK: - Preview Provider for FileRowView (for isolated development/testing)
struct FileRowView_Previews: PreviewProvider {
    // Example of a mock FoundFile binding for preview
    @State static var mockFile1 = FoundFile(url: URL(fileURLWithPath: "/Applications/Safari.app"))
    @State static var mockFile2 = FoundFile(url: URL(fileURLWithPath: "/Users/john/Library/Caches/com.john.app/cache.data"))
    @State static var mockFile3 = FoundFile(url: URL(fileURLWithPath: "/Users/john/Desktop/LongAppNameExampleWithManyWordsAndNumbers.app/Contents/Resources/SomeReallyLongFilenameThatMightWrap.plist"))

    static var previews: some View {
        VStack(alignment: .leading) {
            FileRowView(file: $mockFile1)
            FileRowView(file: $mockFile2)
            FileRowView(file: $mockFile3)
        }
        .padding()
        .background(Color(.windowBackgroundColor)) // Use a typical window background for context
        .previewLayout(.sizeThatFits)
    }
}
