//  AboutView.swift

import SwiftUI

struct AboutView: View {
    // Get the app version from the main bundle's info dictionary
    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "N/A"
    }

    var body: some View {
        VStack(spacing: 20) { // Overall vertical stack for content
            Spacer() // Push content towards the center/top

            Image(systemName: "folder.fill.badge.questionmark") // Placeholder icon
                .resizable()
                .scaledToFit()
                .frame(width: 100, height: 100)
                .foregroundColor(.accentColor)
                .padding(.bottom, 10)

            Text("App Janitor")
                .font(.largeTitle)
                .fontWeight(.bold)

            Text("Version \(appVersion)")
                .font(.headline)
                .foregroundColor(.secondary)

            // Social Icons / Links (from original Electron app)
            HStack(spacing: 15) {
                // Link to App Repo
                Link(destination: Constants.AppRepoURL) {
                    Image(systemName: "safari.fill") // Using a system icon as a placeholder for GitHub/Mastodon
                        .resizable()
                        .scaledToFit()
                        .frame(width: 24, height: 24)
                        .padding(8) // Padding inside the button area
                        .background(Color.gray.opacity(0.8))
                        .cornerRadius(100) // Makes it circular
                        .foregroundColor(.white)
                }
                .buttonStyle(.plain) // Remove default button styling
                .help("Open App Repository") // Tooltip

                // Link to App Mastodon
                Link(destination: Constants.AppMastodonURL) {
                    Image(systemName: "message.fill") // Another system icon placeholder
                        .resizable()
                        .scaledToFit()
                        .frame(width: 24, height: 24)
                        .padding(8)
                        .background(Color.gray.opacity(0.8))
                        .cornerRadius(100)
                        .foregroundColor(.white)
                }
                .buttonStyle(.plain)
                .help("Open App Mastodon Page")
            }

            Divider() // Horizontal rule

            Text("Maintained by Davunt")
                .font(.callout)
                .foregroundColor(.secondary)

            // Maintainer Mastodon Link
            Link(destination: Constants.MaintainerMastodonURL) {
                Image(systemName: "person.circle.fill") // System icon placeholder
                    .resizable()
                    .scaledToFit()
                    .frame(width: 24, height: 24)
                    .padding(8)
                    .background(Color.gray.opacity(0.8))
                    .cornerRadius(100)
                    .foregroundColor(.white)
            }
            .buttonStyle(.plain)
            .help("Open Maintainer's Mastodon Page")

            Spacer() // Push content towards the center/bottom
        }
        .padding(20) // Overall padding for the view content
        .frame(minWidth: 400, minHeight: 400) // Suggest a default size for the About window
        .preferredColorScheme(.dark) // Match the app's dark theme
    }
}

// MARK: - Preview Provider
struct AboutView_Previews: PreviewProvider {
    static var previews: some View {
        AboutView()
            .previewLayout(.sizeThatFits)
    }
}
