// App Janitor/Utils/PathLocations.swift
import Foundation

struct AppPaths { // Wrapped pathLocations in a struct
    static let homeDirectory = FileManager.default.homeDirectoryForCurrentUser.path

    static let pathLocations: [String] = [
      "/Applications",
      "/private/var/db/receipts",
      "/Library/LaunchDaemons",
      homeDirectory,
      "\(homeDirectory)/Downloads",
      "\(homeDirectory)/Library",
      "\(homeDirectory)/Library/Application Support",
      "\(homeDirectory)/Library/Application Scripts",
      "\(homeDirectory)/Library/Application Support/CrashReporter",
      "\(homeDirectory)/Library/Containers",
      "\(homeDirectory)/Library/Caches",
      "\(homeDirectory)/Library/HTTPStorages",
      "\(homeDirectory)/Library/Group Containers",
      "\(homeDirectory)/Library/Internet Plug-Ins",
      "\(homeDirectory)/Library/LaunchAgents",
      "\(homeDirectory)/Library/Logs",
      "/Library/Logs/DiagnosticReports",
      "\(homeDirectory)/Library/Preferences",
      "\(homeDirectory)/Library/Preferences/ByHost",
      "\(homeDirectory)/Library/Saved Application State",
      "\(homeDirectory)/Library/WebKit",
      "\(homeDirectory)/Library/Caches/com.apple.helpd/Generated",
      "/Library/Audio/Plug-Ins/HAL",
    ]
}
