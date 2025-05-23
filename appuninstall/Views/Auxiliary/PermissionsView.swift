//  PermissionsView.swift

import SwiftUI

struct PermissionsView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 15) { // Align content to leading edge
            Text("Permissions")
                .font(.largeTitle)
                .fontWeight(.bold)
                .frame(maxWidth: .infinity, alignment: .center) // Center the title
                .padding(.bottom, 10)

            Text("App Janitor requires some permissions in order to find and move files to trash.")
                .font(.body)

            Text("To allow App Janitor to work properly please do the following:")
                .font(.body)

            VStack(alignment: .leading, spacing: 10) { // For the ordered list
                Text("1. Go to **'System Settings'** (or **'System Preferences'** on older macOS versions)")

                Text("2. Go to **'Privacy & Security'**")

                Text("3. Go to the **'Privacy'** section.")

                Text("4. Enable the following permissions:")
                    .padding(.top, 5) // Small top padding for sub-list

                VStack(alignment: .leading, spacing: 8) { // For the sub-list (a, b)
                    Text("a. Enable **'Full Disk Access'** for App Janitor.")
                        .font(.callout)
                        .padding(.leading, 20) // Indent for 'a'
                    Text("   This allows App Janitor to scan and delete files across your system.")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                        .padding(.leading, 20)

                    Text("b. Alternatively, enable specific folders you want App Janitor to search in **'Files and Folders'**.")
                        .font(.callout)
                        .padding(.leading, 20) // Indent for 'b'
                    Text("   This is less broad than Full Disk Access but requires you to manually add common locations like your 'Library' folder.")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                        .padding(.leading, 20)
                }
            }
            .padding(.leading, 10) // Indent the main ordered list

            Spacer() // Push content to the top
        }
        .padding(30) // Overall padding for the view content
        .frame(minWidth: 450, minHeight: 400) // Suggest a default size for the Permissions window
        .preferredColorScheme(.dark) // Match the app's dark theme
    }
}

// MARK: - Preview Provider
struct PermissionsView_Previews: PreviewProvider {
    static var previews: some View {
        PermissionsView()
            .previewLayout(.sizeThatFits)
    }
}
