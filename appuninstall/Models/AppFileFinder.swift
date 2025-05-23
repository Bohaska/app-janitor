// App Janitor/Models/AppFileFinder.swift
import Foundation
import AppKit // For NSWorkspace and NSImage, which are needed for getting app icons and bundle IDs.
import SwiftUI // For Image type (used in AppInfo)

// MARK: - Helper for Regex Compilation
/// Helper function to compile a regex string into an `NSRegularExpression` object.
/// This is a private utility specific to AppFileFinder.
private func compileRegex(_ pattern: String) -> NSRegularExpression? {
    do {
        return try NSRegularExpression(pattern: pattern, options: .caseInsensitive)
    } catch {
        // In a real app, you might want to log this more robustly.
        print("Error compiling regex \(pattern): \(error.localizedDescription)")
        return nil
    }
}

// MARK: - Pre-compiled Regex Patterns (from FilePatterns.swift in Utils)
// These are private to this file for efficiency.
// `FilePatterns.swift` should be in your Utils folder and included in the target.
// Ensure these constants are visible from here.
// They are defined globally in FilePatterns.swift, which by default makes them internal and accessible.
private let uuidRegex = compileRegex(uuidRegexString)
private let dateRegex = compileRegex(dateRegexString)
private let diagRegex = compileRegex(diagRegexString)
private let mmpVersionRegex = compileRegex(mmpVersionRegexString)
private let mmVersionRegex = compileRegex(mmVersionRegexString)
private let duplicateFileNumberRegex = compileRegex(duplicateFileNumberRegexString)

/// Manages the core logic for finding associated files for a given macOS application.
actor AppFileFinder { // Using an actor for thread-safe mutable state (computerName)
    private var computerName: String = "" // Internal state for computer name

    init() {
        // Initialize computer name asynchronously
        Task {
            await loadComputerName()
        }
    }

    /// Loads the computer's name using `scutil` command.
    private func loadComputerName() async {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/sbin/scutil")
        process.arguments = ["--get", "ComputerName"]

        let pipe = Pipe()
        process.standardOutput = pipe

        do {
            try process.run() // Start the process
            let data = pipe.fileHandleForReading.readDataToEndOfFile() // Read output
            if let output = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) {
                self.computerName = output
                print("Computer Name Loaded: \(self.computerName)")
            }
            process.waitUntilExit() // Wait for the process to complete
        } catch {
            print("Error getting computer name: \(error.localizedDescription)")
            self.computerName = "" // Fallback in case of error
        }
    }

    // MARK: - String Normalization & Cleaning

    /// Converts string to lowercase and removes spaces.
    /// - Parameters:
    ///   - str: The input string.
    ///   - spacer: The string to replace spaces with. Default is empty string.
    /// - Returns: Normalized string.
    func normalizeString(_ str: String, spacer: String = "") -> String {
        return str.lowercased().replacingOccurrences(of: " ", with: spacer)
    }

    /// Replaces spaces and space-like characters with a '*' wildcard.
    /// - Parameter str: The input string.
    /// - Returns: Transformed string with '*' wildcards.
    func replaceSpaceCharacters(_ str: String) -> String {
        return str.lowercased()
            .replacingOccurrences(of: " ", with: "*")
            .replacingOccurrences(of: "-", with: "*")
            .replacingOccurrences(of: "_", with: "*")
            .replacingOccurrences(of: ".", with: "*")
    }

    /// Removes common substrings (UUIDs, dates, versions, etc.) from file names based on predefined regexes and string lists.
    /// - Parameter file: The file name string to clean.
    /// - Returns: The cleaned file name string.
    func removeCommonFileSubstrings(_ file: String) async -> String { // Made async to await computerName
        var transformedString = file.lowercased()
        var nsString = transformedString as NSString // Use NSString for NSRange and regex operations

        // Apply regex replacements
        // FIXED: Recalculate fullRange in each iteration.
        [uuidRegex, dateRegex, diagRegex, mmpVersionRegex, mmVersionRegex, duplicateFileNumberRegex].forEach { regex in
            if let regex = regex {
                let currentFullRange = NSRange(location: 0, length: nsString.length) // Recalculate here!
                transformedString = regex.stringByReplacingMatches(in: nsString as String, options: [], range: currentFullRange, withTemplate: "")
                nsString = transformedString as NSString // Update nsString for subsequent operations
            }
        }

        // Remove common extensions and substrings directly
        // These are simple string replacements as in the original JS, not regex
        // `commonExtensions` and `commonSubStrings` are from Utils/FilePatterns.swift
        for pattern in commonExtensions + commonSubStrings {
            transformedString = transformedString.replacingOccurrences(of: pattern.lowercased(), with: "")
        }

        // Remove computer name if available (read from actor's isolated state)
        let currentComputerName = await self.computerName // Access isolated state using await
        if !currentComputerName.isEmpty {
            let normCompName = normalizeString(currentComputerName, spacer: "-")
                .replacingOccurrences(of: "’", with: "") // Handle specific apostrophe
                .replacingOccurrences(of: "(", with: "")
                .replacingOccurrences(of: ")", with: "")
            transformedString = transformedString.replacingOccurrences(of: normCompName.lowercased(), with: "")
        }

        // Replace remaining space-like characters for consistency
        transformedString = replaceSpaceCharacters(transformedString)

        return transformedString
    }

    // MARK: - App Pattern Generation

    /// Returns an array of app name variations using the app name and bundleId.
    /// - Parameters:
    ///   - appName: The name of the application.
    ///   - bundleId: The bundle identifier of the application.
    /// - Returns: An array of normalized app name patterns.
    func getAppNameVariations(appName: String, bundleId: String) -> [String] {
        var patternArray: [String] = []

        // 1. App name with space-like chars replaced by '*'
        patternArray.append(replaceSpaceCharacters(appName))

        // 2. If app name contains a '.', add first component (e.g. test.com -> test)
        let appNameComponents = normalizeString(appName).split(separator: ".").map(String.init)
        if let firstComponent = appNameComponents.first, !firstComponent.isEmpty {
            patternArray.append(firstComponent)
        }

        // 3. If bundleId contains more than 2 components (e.g. com.test.app)
        // add first two components (e.g. com.test)
        let bundleIdComponents = normalizeString(bundleId).split(separator: ".").map(String.init)
        if bundleIdComponents.count > 2 {
            let firstTwoComponents = bundleIdComponents.prefix(bundleIdComponents.count - 1).joined(separator: ".")
            patternArray.append(replaceSpaceCharacters(firstTwoComponents))
        }

        // Ensure unique values using a Set
        return Array(Set(patternArray))
    }

    // MARK: - File Content Checking

    /// Checks if a file name contains app-related patterns using the bundle ID and app name variations.
    /// - Parameters:
    ///   - appNameVariations: An array of app name patterns to check against.
    ///   - bundleId: The bundle identifier of the application.
    ///   - fileNameToCheck: The file name string to analyze.
    /// - Returns: `true` if the file name is determined to be related to the app, `false` otherwise.
    func doesFileContainAppPattern(appNameVariations: [String], bundleId: String, fileNameToCheck: String) async -> Bool { // Made async to await removeCommonFileSubstrings
        let strippedFileName = await removeCommonFileSubstrings(fileNameToCheck) // Clean the filename first (now async)
        let normalizedBundleId = replaceSpaceCharacters(bundleId)

        // 1. Check if file contains bundleID
        if strippedFileName.contains(normalizedBundleId) {
            return true
        }

        // 2. Check if file contains variations of app name with a score threshold
        // `scoreThreshold` is defined in Utils/Config.swift
        for appNameFilePattern in appNameVariations {
            let patternLowercased = appNameFilePattern.lowercased()
            if strippedFileName.contains(patternLowercased) {
                var score = 0
                // Simple score calculation based on original JS: count length of pattern if found
                if let _ = strippedFileName.range(of: patternLowercased) {
                    score += patternLowercased.count
                }

                // Check ratio: pattern length / stripped file name length > scoreThreshold
                // `scoreThreshold` is from Utils/Config.swift
                if strippedFileName.count > 0 && Double(score) / Double(strippedFileName.count) > scoreThreshold {
                    return true
                }
            }
        }

        return false
    }

    // MARK: - Main File Finding Logic

    /// Scans predefined system locations for files related to the specified application.
    /// This is an asynchronous function that may take time due to file system access.
    /// - Parameters:
    ///   - appURL: The URL of the `.app` bundle.
    ///   - appName: The human-readable name of the application.
    ///   - bundleId: The bundle identifier of the application.
    /// - Returns: An array of `FoundFile` objects representing detected related files.
    /// - Throws: An error if essential bundle information cannot be retrieved.
    func findAppFilesToRemove(appURL: URL, appName: String, bundleId: String) async throws -> [FoundFile] {
        await loadComputerName() // Ensure computer name is loaded

        let fileManager = FileManager.default
        var filesToRemove = Set<FoundFile>()

        let bundleIdComponents = bundleId.split(separator: ".").map(String.init)
        let appOrg = bundleIdComponents.count > 1 ? bundleIdComponents[1] : ""

        // Prepare paths to search, converting String paths to URL.
        // `AppPaths.pathLocations` is now used to access the array from Utils/PathLocations.swift
        var searchURLs: [URL] = []
        for pathString in AppPaths.pathLocations { // FIXED: Use AppPaths.pathLocations
            let baseUrl = URL(fileURLWithPath: pathString)
            searchURLs.append(baseUrl)
            if !appOrg.isEmpty {
                // Add company-specific subdirectories within common locations
                searchURLs.append(baseUrl.appendingPathComponent(appOrg))
            }
        }

        let appNameVariations = getAppNameVariations(appName: appName, bundleId: bundleId)

        // Add the main app bundle itself to the list of files to remove by default
        filesToRemove.insert(FoundFile(url: appURL))

        for directoryURL in searchURLs {
            do {
                var isDirectory: ObjCBool = false
                guard fileManager.fileExists(atPath: directoryURL.path, isDirectory: &isDirectory), isDirectory.boolValue else {
                    // print("Directory does not exist or is not a directory: \(directoryURL.path)")
                    continue // Skip if path doesn't exist or isn't a directory
                }

                // Use enumerator to iterate contents, which is more efficient for large directories
                let resourceKeys: Set<URLResourceKey> = [.isRegularFileKey, .isDirectoryKey]
                guard let enumerator = fileManager.enumerator(at: directoryURL,
                                                              includingPropertiesForKeys: Array(resourceKeys),
                                                              options: [.skipsHiddenFiles, .skipsPackageDescendants /*, .skipsItemEnclosures */]) else { // FIXED: Removed .skipsItemEnclosures if deployment target is too low
                    continue // Could not create enumerator (e.g., due to permissions)
                }

                for case let itemURL as URL in enumerator {
                    // Check item type (file or directory)
                    if let resourceValues = try? itemURL.resourceValues(forKeys: resourceKeys),
                       let isRegularFile = resourceValues.isRegularFile,
                       let isDirectoryItem = resourceValues.isDirectory {

                        if isRegularFile {
                            let fileName = itemURL.lastPathComponent
                            if await doesFileContainAppPattern(appNameVariations: appNameVariations, bundleId: bundleId, fileNameToCheck: fileName) { // FIXED: Await call
                                filesToRemove.insert(FoundFile(url: itemURL))
                            }
                        } else if isDirectoryItem {
                            // If it's a directory, check its name as well
                            let dirName = itemURL.lastPathComponent
                             if await doesFileContainAppPattern(appNameVariations: appNameVariations, bundleId: bundleId, fileNameToCheck: dirName) { // FIXED: Await call
                                // If the directory name itself matches, add the directory to the list
                                filesToRemove.insert(FoundFile(url: itemURL))
                            }
                        }
                    }
                }
            } catch {
                // This catch block handles errors like permission denied for a specific directory.
                // We print the error and continue to the next directory.
                print("Error enumerating contents of \(directoryURL.path): \(error.localizedDescription)")
            }
        }

        return Array(filesToRemove)
    }

    /// Gets the application's icon for SwiftUI display.
    /// - Parameter appURL: The URL of the .app bundle.
    /// - Returns: A SwiftUI `Image` if successful, otherwise nil.
    func getAppIcon(forAppAt appURL: URL) -> Image? {
        let nsImage = NSWorkspace.shared.icon(forFile: appURL.path)
        return Image(nsImage: nsImage)
    }

    /// Gets the Bundle Identifier for a given .app bundle.
    /// - Parameter appURL: The URL of the .app bundle.
    /// - Returns: The bundle identifier string, or nil if not found.
    func getBundleIdentifier(forAppAt appURL: URL) -> String? {
        return Bundle(url: appURL)?.bundleIdentifier
    }

    /// Extracts the human-readable application name from its .app bundle URL.
    /// - Parameter appURL: The URL of the .app bundle.
    /// - Returns: The application name (e.g., "Safari" from "Safari.app").
    func appNameFromPath(_ appURL: URL) -> String {
        return appURL.deletingPathExtension().lastPathComponent
    }
}
