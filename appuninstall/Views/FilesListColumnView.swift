//  FilesListColumnView.swift

import SwiftUI

struct FilesListColumnView: View {
    @ObservedObject var viewModel: MainWindowViewModel

    var body: some View {
        VStack(spacing: 0) { // spacing:0 to ensure no extra space between header, list, and footer
            // Files Header
            HStack {
                Text("Related Files") // Static header title
                    .font(.title3)
                    .fontWeight(.semibold)
                    .padding(.leading, 10) // Left padding for alignment

                Spacer() // Pushes the status text to the right

                Text(viewModel.statusText) // Dynamic text (e.g., "5 Files Found")
                    .font(.callout)
                    .fontWeight(.medium)
                    .padding(.trailing, 10) // Right padding for alignment
            }
            .padding(.vertical, 10) // Vertical padding for header
            .background(Color.primary.opacity(0.2)) // Header background color
            .help("Number of files found for the selected app.") // Tooltip for the header

            // Files List (Scrollable)
            List {
                // Iterate over the files from the ViewModel.
                // Using `$` prefix with `file` creates a Binding, allowing FileRowView to modify it.
                ForEach($viewModel.files) { $file in
                    FileRowView(file: $file) // Pass the Binding to the row view
                        .listRowSeparator(.hidden) // Hide default List row separators
                        .listRowBackground( // Apply alternating background colors to rows
                            Group {
                                if let index = viewModel.files.firstIndex(where: { $0.id == file.id }) {
                                    // Alternate between two shades of primary color for visual distinction
                                    (index % 2 == 0 ? Color.primary.opacity(0.15) : Color.primary.opacity(0.05))
                                } else {
                                    Color.clear // Fallback for rows not found (shouldn't happen with ForEach)
                                }
                            }
                        )
                }
            }
            .listStyle(.plain) // Remove default list styling (e.g., borders, extra padding)
            .scrollContentBackground(.hidden) // Ensures the background color applies to the scrollable content
            .background(Color.clear) // Transparent list background

            // MARK: - Bottom Action Bar (Replaced with new view)
            BottomActionBarView(viewModel: viewModel)
        }
        .frame(minWidth: 300) // Set a minimum width for the right column
        .layoutPriority(2) // Give this column a higher priority for horizontal space distribution
    }
}

// MARK: - Preview Provider
struct FilesListColumnView_Previews: PreviewProvider {
    static var previews: some View {
        FilesListColumnView(viewModel: MainWindowViewModel())
            .frame(width: 500, height: 600)
            .preferredColorScheme(.dark)
    }
}
