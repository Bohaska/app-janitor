// App Janitor/AppJanitorApp.swift
import SwiftUI
import AppKit // Needed for NSWorkspace.shared.open(_:)

@main
struct AppJanitorApp: App {
    // @AppStorage automatically reads/writes to UserDefaults.
    // 'hasLaunchedBefore' will be false by default if never set.
    @AppStorage("hasLaunchedBefore") var hasLaunchedBefore: Bool = false

    // State to control the presentation of the first-run message sheet
    @State private var showFirstRunMessage: Bool = false

    var body: some Scene {
        WindowGroup {
            MainWindowView() // Our main window content view
                .frame(minWidth: 750, minHeight: 450) // Set a default initial window size
                // MARK: - First Run Message Sheet
                .sheet(isPresented: $showFirstRunMessage) {
                    FirstRunPermissionMessageView()
                }
                .onAppear { // When MainWindowView appears
                    if !hasLaunchedBefore {
                        showFirstRunMessage = true // Show the message
                        hasLaunchedBefore = true // Set the flag so it doesn't show again
                    }
                }
        }
        .commands { // Customize the application's menu bar
            CommandGroup(replacing: .appInfo) {
                Button("About App Janitor") {
                    NSApp.sendAction(Selector(("showAboutPanel:")), to: nil, from: nil)
                }
            }

            CommandGroup(replacing: .help) {
                Button("Check For Updates") {
                    NSWorkspace.shared.open(Constants.ReleasesURL)
                }

                Button("Report Issue") {
                    NSWorkspace.shared.open(Constants.IssuesURL)
                }

                Divider()

                Button("Permissions") {
                    NSApp.sendAction(Selector(("showPermissionsWindow:")), to: nil, from: nil)
                }
            }
        }

        WindowGroup("About App Janitor") {
            AboutView()
        }
        .commands {
            CommandGroup(replacing: .appInfo) { }
        }

        WindowGroup("Permissions") {
            PermissionsView()
        }
        .commands {
            CommandGroup(replacing: .help) { }
        }
    }
}

// MARK: - Extension to Handle Custom Menu Actions
extension NSApplication {
    @objc func showAboutPanel(_ sender: Any?) { } // Handled implicitly by WindowGroup title matching

    @objc func showPermissionsWindow(_ sender: Any?) { } // Handled implicitly by WindowGroup title matching
}
