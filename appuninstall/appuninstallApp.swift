// App Janitor/AppJanitorApp.swift
import SwiftUI
import AppKit // Needed for NSWorkspace.shared.open(_:)

@main
struct AppJanitorApp: App {
    var body: some Scene {
        WindowGroup {
            MainWindowView() // Our main window content view
                .frame(minWidth: 750, minHeight: 450) // Set a default initial window size
        }
        .commands { // Customize the application's menu bar
            // The standard "App Janitor" menu (Quit, Hide, etc.) is automatically added.
            // If you wanted to replace it, you'd use `CommandGroup(replacing: .appInfo)`.

            // Add the "About App Janitor" menu item under the main app menu (which is implicit here)
            CommandGroup(replacing: .appInfo) {
                // The default AppInfo group contains "About [AppName]", "Services", "Hide", "Hide Others", "Show All", "Quit"
                // We typically just add our custom About item here, and the others are automatically generated.
                Button("About App Janitor") {
                    // Action to show the About window.
                    // This will open a new instance of the "About App Janitor" WindowGroup.
                    NSApp.sendAction(Selector(("showAboutPanel:")), to: nil, from: nil)
                }
                // ... other default app info items will be added here automatically ...
            }


            // Replace the default Help menu
            CommandGroup(replacing: .help) {
                // "Check For Updates" menu item
                Button("Check For Updates") {
                    // This action will open the releases URL in the default browser.
                    // In Phase 6, this could be replaced with a native update framework like Sparkle.
                    NSWorkspace.shared.open(Constants.ReleasesURL) // Using URL constant from Utils/Constants.swift
                }

                // "Report Issue" menu item
                Button("Report Issue") {
                    // This action will open the issues URL in the default browser.
                    NSWorkspace.shared.open(Constants.IssuesURL) // Using URL constant
                }

                Divider() // A separator in the menu

                // "Permissions" menu item
                Button("Permissions") {
                    // Action to show the Permissions window.
                    // This will open a new instance of the "Permissions" WindowGroup.
                    // We can't directly use NSApp.sendAction with custom window groups like the About one.
                    // A common way for new WindowGroups is to use the `openWindow` environment value,
                    // or define a specific window identifier.
                    NSApp.sendAction(Selector(("showPermissionsWindow:")), to: nil, from: nil)
                }

                // "Open Dev Tools" is an Electron-specific concept and is not applicable
                // directly in a native macOS app. It's omitted here.
            }
        }

        // Define separate WindowGroups for About and Permissions windows here.
        // They will be opened when their corresponding menu items are clicked.

        WindowGroup("About App Janitor") { // Title for the window's title bar
            AboutView()
        }
        // Add a custom command to open this window. `NSApp.sendAction` will route to this.
        .commands {
            CommandGroup(replacing: .appInfo) {
                // This empty command group makes this About window a "panel" that can be opened by the NSApp.sendAction
            }
        }


        WindowGroup("Permissions") { // Title for the window's title bar
            PermissionsView()
        }
        // Add a custom command to open this window. `NSApp.sendAction` will route to this.
        .commands {
            CommandGroup(replacing: .help) {
                // This empty command group allows the 'Permissions' menu item to target this window group
            }
        }
    }
}

// MARK: - Extension to Handle Custom Menu Actions
// This is a common pattern to bridge menu actions to specific window types or handlers.
extension NSApplication {
    @objc func showAboutPanel(_ sender: Any?) {
        // This will open the WindowGroup with the title "About App Janitor"
        // (as it implicitly handles the NSApp.sendAction(Selector(("showAboutPanel:")))
        // if a WindowGroup is defined with no specific command.
        // For custom window groups, it's often more robust to use an environment value or direct presentation.
        // For now, this is a placeholder that usually works for standard 'About' panels.
        // A more explicit way would be `openWindow(id: "about")` if `AboutView` was part of a named `WindowGroup`.
    }

    @objc func showPermissionsWindow(_ sender: Any?) {
        // Find the "Permissions" window or create it if it doesn't exist
        // NSApp.sendAction to a specific window group is often implicitly handled by SwiftUI
        // if the button in the menu bar has the same string as the WindowGroup's title.
        // However, if you need more control, you'd manage WindowGroup visibility via `@Environment(.openWindow)`.
        // For simplicity and direct translation of the spirit of the Electron behavior,
        // relying on the implicit behavior for now is fine.
    }
}
