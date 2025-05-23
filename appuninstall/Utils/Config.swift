import Foundation

// MARK: - Configuration Values
let scoreThreshold: Double = 0.4
// Note: Mojave Darwin version check might be handled differently or is less critical
// in a native app, but keep the value if needed for logic.
// Darwin version strings are less common for OS version checks in native Swift.
// Use ProcessInfo.processInfo.operatingSystemVersion if a version check is necessary.
let mojaveDarwinMinVersion = "18.0.0"
