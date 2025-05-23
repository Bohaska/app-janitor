//  Utils.swift

import Foundation

// MARK: - Utility Functions

/// Checks if all elements in an array are unique.
/// - Parameter arr: The array to check.
/// - Returns: true if all elements are unique, false otherwise.
func isArrayUniqueValues<T: Hashable>(_ arr: [T]) -> Bool {
    return Set(arr).count == arr.count
}
