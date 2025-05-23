import Foundation

// MARK: - Regex Patterns (as Strings)
let uuidRegexString = "[a-fA-F0-9]{8}-[a-fA-F0-9]{4}-[a-fA-F0-9]{4}-[a-fA-F0-9]{4}-[a-fA-F0-9]{12}"
let dateRegexString = "[0-9]{4}-[0-9]{2}-[0-9]{2}-[0-9]{6}"
let diagRegexString = ".[a-zA-Z]+_resource.diag"
let mmpVersionRegexString = "[0-9]{1,4}\\.[0-9]{1,3}\\.[0-9]{1,3}" // Added escape for '.'
let mmVersionRegexString = "[0-9]{1,4}\\.[0-9]{1,3}" // Added escape for '.'
let duplicateFileNumberRegexString = "\\([0-9]{1,2}\\)" // Added escape for '(' and ')'

// Combine regex strings for easier use later
let combinedFileRegexStrings = [
    uuidRegexString,
    dateRegexString,
    diagRegexString,
    mmpVersionRegexString,
    mmVersionRegexString,
    duplicateFileNumberRegexString
]

// MARK: - Common Extensions and Substrings
let commonExtensions = [
  ".dmg",
  ".app",
  ".bom",
  ".plist",
  ".XPCHelper",
  ".beta",
  ".extensions",
  ".savedState",
  ".driver",
  ".wakeups_resource",
  ".diag",
  ".zip",
]

let commonSubStrings = [
  "install",
  "universal",
  "arm64",
  "x64",
  "intel",
  "macOS",
]

// Combine all patterns for easier use later
let allCommonPatterns: [String] = combinedFileRegexStrings + commonExtensions + commonSubStrings

/*
 // Example of compiling regex strings (will be done in Phase 2 usually)
 func compileRegex(_ pattern: String) -> NSRegularExpression? {
     do {
         return try NSRegularExpression(pattern: pattern, options: .caseInsensitive) // caseInsensitive is common for file paths
     } catch {
         print("Error compiling regex \(pattern): \(error)")
         return nil
     }
 }

 let uuidRegex = compileRegex(uuidRegexString)
 // ... etc.
 */