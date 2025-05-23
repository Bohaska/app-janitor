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
private let pythonDirectoryRegex = compileRegex("^Python(\\d+(\\.\\d+)*)?$") // Regex for "Python" or "PythonX.Y" directories

/// Manages the core logic for finding associated files for a given macOS application.
actor AppFileFinder { // Using an actor for thread-safe mutable state (computerName)
    private var computerName: String = "" // Internal state for computer name
    private var otherAppBundleIdentifiers: Set<String> = [] // NEW: Store other app bundle IDs

    init() {
        // Initialize computer name asynchronously
        Task {
            await loadComputerName()
        }
    }

    // NEW: Function to load bundle IDs of other installed applications
    private func loadOtherAppBundleIdentifiers(excluding bundleIdToExclude: String) async {
        var foundBundleIds: Set<String> = []
        // Common application directories
        let appSearchPaths = [
            "/Applications",
            "/System/Applications",
            FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Applications").path
        ]

        let fileManager = FileManager.default
        let resourceKeys: Set<URLResourceKey> = [.isDirectoryKey]

        for pathString in appSearchPaths {
            let appsDirectoryURL = URL(fileURLWithPath: pathString)
            guard let enumerator = fileManager.enumerator(at: appsDirectoryURL,
                                                          includingPropertiesForKeys: Array(resourceKeys),
                                                          options: [.skipsHiddenFiles, .skipsPackageDescendants]) else {
                continue // Skip if directory cannot be enumerated
            }

            for case let itemURL as URL in enumerator {
                // Only consider top-level .app bundles
                if itemURL.pathExtension.lowercased() == "app" {
                    if let bundle = Bundle(url: itemURL), let bundleId = bundle.bundleIdentifier {
                        if bundleId.lowercased() != bundleIdToExclude.lowercased() {
                            foundBundleIds.insert(bundleId.lowercased())
                        }
                    }
                }
            }
        }
        self.otherAppBundleIdentifiers = foundBundleIds
        print("Loaded \(foundBundleIds.count) other app bundle IDs for exclusion.")
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

    // MARK: - Regex Conversion Helper
    /// Converts a glob-style pattern (using '*' as wildcard) into a regular expression pattern.
    /// Adds word boundaries for single-word patterns to prevent partial matches.
    private func globToRegex(_ globPattern: String) -> String {
        // Escape special regex characters that are not intended as wildcards
        let escapedPattern = NSRegularExpression.escapedPattern(for: globPattern)
        // Replace glob '*' with regex '.*' (match any character zero or more times)
        // Replace glob '?' with regex '.' (match any character exactly once)
        var regexPattern = escapedPattern.replacingOccurrences(of: "\\*", with: ".*")
        regexPattern = regexPattern.replacingOccurrences(of: "\\?", with: ".")

        // Heuristic: if the pattern doesn't contain '.*' (meaning it didn't have '*' originally)
        // and it's not empty, consider it a "word" pattern and add word boundaries.
        // This prevents "bar" from matching "foobar" but allows "hidden.*bar" to match "hidden-bar".
        if !regexPattern.contains(".*") && !regexPattern.isEmpty {
            regexPattern = "\\b" + regexPattern + "\\b"
        }
        return regexPattern
    }

    // MARK: - File Content Checking

    /// Checks if a file or directory path contains app-related patterns, using stricter context checks.
    /// - Parameters:
    ///   - appNameVariations: An array of app name patterns to check against (e.g., "Hidden Bar", "hidden*bar").
    ///   - bundleId: The bundle identifier of the application (e.g., "com.example.HiddenBar").
    ///   - itemURL: The full URL of the file or directory being checked.
    ///   - appURL: The URL of the main .app bundle.
    ///   - appName: The human-readable name of the application.
    /// - Returns: `true` if the file/directory is determined to be related to the app, `false` otherwise.
    func doesFileContainAppPattern(appNameVariations: [String], bundleId: String, itemURL: URL, appURL: URL, appName: String) async -> Bool {
        let fullPath = itemURL.path.lowercased()
        let lastPathComponent = itemURL.lastPathComponent.lowercased()
        let parentPath = itemURL.deletingLastPathComponent().path.lowercased()

        // 1. Direct containment within the app bundle itself (most reliable)
        // This handles files like MyApp.app/Contents/Info.plist
        if fullPath.hasPrefix(appURL.path.lowercased()) {
            return true
        }

        // Prepare strong patterns for path-level matching.
        // These are patterns that, if found anywhere in the path, strongly indicate a match.
        let normalizedBundleId = replaceSpaceCharacters(bundleId) // e.g., "com*example*hiddenbar"
        let normalizedAppName = replaceSpaceCharacters(appName)   // e.g., "hidden*bar"
        let normalizedAppBundleName = replaceSpaceCharacters(appName) + ".app" // e.g., "hidden*bar.app"

        let strongPathPatterns = [normalizedBundleId, normalizedAppName, normalizedAppBundleName]

        // 2. Check if the full path contains any of the strong patterns.
        // These are checked against the raw full path, not stripped, to preserve directory context.
        for pattern in strongPathPatterns {
            if let regex = compileRegex(globToRegex(pattern)) {
                if regex.firstMatch(in: fullPath, options: [], range: NSRange(location: 0, length: fullPath.utf16.count)) != nil {
                    return true
                }
            }
        }

        // 3. Check the last path component (filename/dirname) against app name variations.
        // This is where we apply `removeCommonFileSubstrings` to the last component.
        let strippedLastPathComponent = await removeCommonFileSubstrings(lastPathComponent)

        for appNameFilePattern in appNameVariations {
            let patternLowercased = appNameFilePattern.lowercased()
            let appNameRegexPattern = globToRegex(patternLowercased) // This adds \b for single words

            if let regex = compileRegex(appNameRegexPattern) {
                let fullStrippedRange = NSRange(location: 0, length: strippedLastPathComponent.utf16.count)
                let matchResult = regex.firstMatch(in: strippedLastPathComponent, options: [], range: fullStrippedRange)

                if let match = matchResult {
                    // A match on the last component. Now, verify context and match strictness.

                    // Define what constitutes a "generic" pattern that needs stronger context.
                    // - Short patterns (e.g., "bar", "app", "data")
                    // - Patterns that are also in commonSubStrings or commonExtensions
                    let isGenericPattern = (patternLowercased.count <= 4 && !patternLowercased.contains("*")) ||
                                           commonSubStrings.contains(patternLowercased) ||
                                           commonExtensions.contains(patternLowercased)

                    if isGenericPattern {
                        // For generic patterns, require the match to cover the entire stripped last path component
                        // AND require that the parent path contains a strong app pattern.
                        // This prevents "bar.py" (stripped to "bar*py") from matching "bar" unless it's exactly "bar".
                        // And even then, it needs parent context.
                        if match.range == fullStrippedRange { // Match must cover the entire stripped string
                            var foundStrongContextInParent = false
                            // Define strong patterns for parent path context check, including exact strings
                            let strongParentContextPatterns = [
                                normalizedBundleId,
                                normalizedAppName,
                                normalizedAppBundleName,
                                bundleId.lowercased(), // New: exact bundle ID
                                appName.lowercased()   // New: exact app name
                            ]
                            for strongPattern in strongParentContextPatterns {
                                if let strongRegex = compileRegex(globToRegex(strongPattern)) {
                                    let parentRange = NSRange(location: 0, length: parentPath.utf16.count)
                                    if strongRegex.firstMatch(in: parentPath, options: [], range: parentRange) != nil {
                                        foundStrongContextInParent = true
                                        break
                                    }
                                }
                            }
                            if foundStrongContextInParent {
                                return true
                            }
                        }
                    } else {
                        // If the pattern itself is specific (e.g., "hidden*bar", "com*hidden*bar"),
                        // a match on the last component is sufficient (even if it's a substring match).
                        return true
                    }
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
    ///   - progressHandler: A closure to report scanning progress (0.0-1.0) and the current file path.
    /// - Returns: A tuple containing an array of `FoundFile` objects and a boolean
    ///            indicating if any permission-related errors were encountered during the scan.
    /// - Throws: An error if essential bundle information cannot be retrieved (e.g., bundleId itself).
    func findAppFilesToRemove(appURL: URL, appName: String, bundleId: String, progressHandler: @escaping @Sendable @MainActor (Double, String) -> Void) async throws -> ([FoundFile], hasPermissionErrors: Bool) {
        await loadComputerName() // Ensure computer name is loaded
        await loadOtherAppBundleIdentifiers(excluding: bundleId) // NEW: Load other app bundle IDs for exclusion

        let fileManager = FileManager.default
        var allFilesToRemove = Set<FoundFile>()
        var overallPermissionError = false

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

        let totalSearchLocations = searchURLs.count
        var completedLocations = 0

        // MARK: - Concurrency Improvement: Use TaskGroup to scan directories in parallel
        await withTaskGroup(of: ([FoundFile], Bool).self) { group in
            for directoryURL in searchURLs {
                group.addTask { [self] in // Capture self strongly within the task for actor context
                    var filesFoundInDir = Set<FoundFile>()
                    var dirHasPermissionError = false

                    // Report progress for starting a new top-level directory scan
                    await progressHandler(Double(completedLocations) / Double(totalSearchLocations), "Scanning: \(directoryURL.path)")

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

                    // Labeled loop for skipping items
                    itemLoop: for case let itemURL as URL in enumerator {
                        // Report progress for each item being processed
                        await progressHandler(Double(completedLocations) / Double(totalSearchLocations), "Scanning: \(itemURL.path)")

                        do {
                            if let resourceValues = try? itemURL.resourceValues(forKeys: resourceKeys),
                               let isRegularFile = resourceValues.isRegularFile,
                               let isDirectoryItem = resourceValues.isDirectory {

                                // NEW: Skip directories belonging to other apps
                                if isDirectoryItem {
                                    let itemPathLowercased = itemURL.path.lowercased()
                                    for otherBundleId in self.otherAppBundleIdentifiers {
                                        // Check if the directory path contains another app's bundle ID as a component.
                                        // This is a heuristic, assuming bundle IDs often appear as directory names
                                        // in Application Support, Caches, etc.
                                        if itemPathLowercased.contains("/\(otherBundleId)/") || itemPathLowercased.hasSuffix("/\(otherBundleId)") {
                                            print("Skipping directory \(itemURL.path) as it appears to belong to another app (\(otherBundleId)).")
                                            enumerator.skipDescendants()
                                            continue itemLoop // Skip to the next top-level item in the enumerator
                                        }
                                    }
                                }

                                // Existing: Skip Python directories
                                if isDirectoryItem, let pythonRegex = pythonDirectoryRegex {
                                    let lastPathComponent = itemURL.lastPathComponent
                                    let range = NSRange(location: 0, length: lastPathComponent.utf16.count)
                                    if pythonRegex.firstMatch(in: lastPathComponent, options: [], range: range) != nil {
                                        print("Skipping Python directory: \(itemURL.path)")
                                        enumerator.skipDescendants()
                                        continue itemLoop // Skip to the next item
                                    }
                                }

                                if isRegularFile || isDirectoryItem {
                                    if await self.doesFileContainAppPattern(appNameVariations: appNameVariations, bundleId: bundleId, itemURL: itemURL, appURL: appURL, appName: appName) {
                                        filesFoundInDir.insert(FoundFile(url: itemURL))
                                        if isDirectoryItem {
                                            // If this directory itself matches, skip its contents to avoid redundant matches
                                            enumerator.skipDescendants()
                                        }
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
                completedLocations += 1 // Increment count for completed top-level search location
                // Final update for this location's completion
                await progressHandler(Double(completedLocations) / Double(totalSearchLocations), "Completed: \(completedLocations)/\(totalSearchLocations) locations")
            }
        }

        // Ensure progress is 100% when done
        await progressHandler(1.0, "Scan Complete.")
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
