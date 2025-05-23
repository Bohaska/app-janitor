// App Janitor/Models/FoundFile.swift
import Foundation

/// Represents a file found that is related to the selected application.
struct FoundFile: Identifiable, Hashable {
    let id = UUID() // Unique ID for SwiftUI's List to track changes efficiently
    let url: URL       // The full URL/path of the file
    var isSelected: Bool = true // User can deselect files they don't want to remove

    // Convenience computed properties for display in UI
    var fileName: String {
        url.lastPathComponent
    }

    var parentDirectoryPath: String {
        url.deletingLastPathComponent().path
    }

    // MARK: - Hashable Conformance
    // Manually implement Hashable to ensure uniqueness based on 'url' only.
    static func == (lhs: FoundFile, rhs: FoundFile) -> Bool {
        return lhs.url == rhs.url
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(url)
    }
}
