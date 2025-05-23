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
    func removeCommonFileSubstrings(_ file: String) async -> String {
        var transformedString = file.lowercased()
        var nsString = transformedString as NSString

        // Apply regex replacements
        [uuidRegex, dateRegex, diagRegex, mmpVersionRegex, mmVersionRegex, duplicateFileNumberRegex].forEach { regex in
            if let regex = regex {
                let currentFullRange = NSRange(location: 0, length: nsString.length)
                transformedString = regex.stringByReplacingMatches(in: nsString as String, options: [], range: currentFullRange, withTemplate: "")
                nsString = transformedString as NSString
            }
        }

        // Remove common extensions and substrings directly
        for pattern in commonExtensions + commonSubStrings {
            transformedString = transformedString.replacingOccurrences(of: pattern.lowercased(), with: "")
        }

        // Remove computer name if available (read from actor's isolated state)
        let currentComputerName = await self.computerName
        if !currentComputerName.isEmpty {
            let normCompName = normalizeString(currentComputerName, spacer: "-")
                .replacingOccurrences(of: "’", with: "")
                .replacingOccurrences(of: "(", with: "")
                .replacingOccurrences(of: ")", with: "")
            transformedString = transformedString.replacingOccurrences(of: normCompName.lowercased(), with: "")
        }

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

        // 1. Full app name, with spaces/dots replaced by wildcards
        patternArray.append(replaceSpaceCharacters(appName)) // e.g., "microsoft*outlook"

        // 2. Full app name, normalized (lowercase, no spaces/dots)
        patternArray.append(normalizeString(appName))       // e.g., "microsoftoutlook"

        // 3. Full bundle ID, with dots replaced by wildcards
        patternArray.append(replaceSpaceCharacters(bundleId)) // e.g., "com*microsoft*outlook"

        // 4. Full bundle ID, normalized (lowercase, no dots)
        patternArray.append(normalizeString(bundleId))       // e.g., "commicrosoftoutlook"

        // 5. Last component of the bundle ID (e.g., "outlook" from "com.microsoft.Outlook")
        // This is useful for files named after the specific product, not the full bundle path.
        let bundleIdComponents = bundleId.split(separator: ".").map(String.init)
        if let lastComponent = bundleIdComponents.last, !lastComponent.isEmpty {
            patternArray.append(normalizeString(lastComponent))
            patternArray.append(replaceSpaceCharacters(lastComponent))
        }

        // 6. Last word of the app name (e.g., "outlook" from "Microsoft Outlook")
        // Similar to the above, for files named after the product.
        let appNameWords = appName.split(separator: " ").map(String.init)
        if let lastWord = appNameWords.last, !lastWord.isEmpty {
            patternArray.append(normalizeString(lastWord))
            patternArray.append(replaceSpaceCharacters(lastWord))
        }

        // Ensure uniqueness and remove any potential empty strings
        return Array(Set(patternArray.filter { !$0.isEmpty }))
    }

    // MARK: - File Content Checking

    /// Checks if a file name contains app-related patterns using the bundle ID and app name variations.
    /// - Parameters:
    ///   - appNameVariations: An array of app name patterns to check against.
    ///   - bundleId: The bundle identifier of the application.
    ///   - fileNameToCheck: The file name string to analyze.
    /// - Returns: `true` if the file name is determined to be related to the app, `false` otherwise.
    func doesFileContainAppPattern(appNameVariations: [String], bundleId: String, fileNameToCheck: String) async -> Bool {
        let strippedFileName = await removeCommonFileSubstrings(fileNameToCheck)
        let normalizedBundleId = replaceSpaceCharacters(bundleId)

        if strippedFileName.contains(normalizedBundleId) {
            return true
        }

        for appNameFilePattern in appNameVariations {
            let patternLowercased = appNameFilePattern.lowercased()
            if strippedFileName.contains(patternLowercased) {
                var score = 0
                if let _ = strippedFileName.range(of: patternLowercased) {
                    score += patternLowercased.count
                }

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
    /// - Returns: A tuple containing an array of `FoundFile` objects and a boolean
    ///            indicating if any permission-related errors were encountered during the scan.
    /// - Throws: An error if essential bundle information cannot be retrieved (e.g., bundleId itself).
    func findAppFilesToRemove(appURL: URL, appName: String, bundleId: String) async throws -> ([FoundFile], hasPermissionErrors: Bool) {
        await loadComputerName() // Ensure computer name is loaded

        let fileManager = FileManager.default
        var allFilesToRemove = Set<FoundFile>()
        var overallPermissionError: Bool = false

        let bundleIdComponents = bundleId.split(separator: ".").map(String.init)
        let appOrg = bundleIdComponents.count > 1 ? bundleIdComponents[1] : ""

        var searchURLs: [URL] = []
        for pathString in AppPaths.pathLocations {
            let baseUrl = URL(fileURLWithPath: pathString)
            searchURLs.append(baseUrl)
            if !appOrg.isEmpty {
                searchURLs.append(baseUrl.appendingPathComponent(appOrg))
            }
        }

        let appNameVariations = getAppNameVariations(appName: appName, bundleId: bundleId)
        allFilesToRemove.insert(FoundFile(url: appURL)) // Add the main app bundle itself

        // MARK: - Concurrency Improvement: Use TaskGroup to scan directories in parallel
        await withTaskGroup(of: ([FoundFile], Bool).self) { group in
            for directoryURL in searchURLs {
                group.addTask { [self] in // Capture self strongly within the task for actor context
                    var filesFoundInDir = Set<FoundFile>()
                    var dirHasPermissionError = false

                    var isDirectory: ObjCBool = false
                    guard fileManager.fileExists(atPath: directoryURL.path, isDirectory: &isDirectory), isDirectory.boolValue else {
                        return ([], false) // Directory doesn't exist or isn't a directory, no error for us
                    }

                    let resourceKeys: Set<URLResourceKey> = [.isRegularFileKey, .isDirectoryKey]
                    guard let enumerator = fileManager.enumerator(at: directoryURL,
                                                                  includingPropertiesForKeys: Array(resourceKeys),
                                                                  options: [.skipsHiddenFiles, .skipsPackageDescendants]) else {
                        print("Skipping directory \(directoryURL.path) due to permission or access issue (enumerator is nil).")
                        return ([], true) // Return true for permission error for this directory
                    }

                    for case let itemURL as URL in enumerator {
                        do {
                            if let resourceValues = try? itemURL.resourceValues(forKeys: resourceKeys),
                               let isRegularFile = resourceValues.isRegularFile,
                               let isDirectoryItem = resourceValues.isDirectory {

                                if isRegularFile {
                                    let fileName = itemURL.lastPathComponent
                                    if await self.doesFileContainAppPattern(appNameVariations: appNameVariations, bundleId: bundleId, fileNameToCheck: fileName) {
                                        filesFoundInDir.insert(FoundFile(url: itemURL))
                                    }
                                } else if isDirectoryItem {
                                    let dirName = itemURL.lastPathComponent
                                    if await self.doesFileContainAppPattern(appNameVariations: appNameVariations, bundleId: bundleId, fileNameToCheck: dirName) {
                                        filesFoundInDir.insert(FoundFile(url: itemURL))
                                    }
                                }
                            }
                        } catch {
                            // This catch handles errors for individual items within an enumerable directory.
                            print("Error accessing item \(itemURL.path) within \(directoryURL.path): \(error.localizedDescription)")
                            // We don't set dirHasPermissionError here, as the enumerator check handles the directory's overall accessibility.
                        }
                    }
                    return (Array(filesFoundInDir), dirHasPermissionError) // Return results for this directory
                }
            }

            // Aggregate results from all tasks
            for await (foundInTask, hasErrorInTask) in group {
                allFilesToRemove.formUnion(foundInTask) // Add files from this task to the overall set
                if hasErrorInTask {
                    overallPermissionError = true // If any task had a permission error, set overall flag
                }
            }
        }

        return (Array(allFilesToRemove), hasPermissionErrors: overallPermissionError)
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
