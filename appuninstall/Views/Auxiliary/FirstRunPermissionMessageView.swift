//  FirstRunPermissionMessageView.swift

import SwiftUI

struct FirstRunPermissionMessageView: View {
    @Environment(\.dismiss) var dismiss // For dismissing the sheet

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "hand.raised.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 80, height: 80)
                .foregroundColor(.yellow) // A friendly warning color

            Text("Welcome to App Janitor!")
                .font(.largeTitle)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)

            Text("To effectively clean applications, App Janitor needs to scan various folders on your system, including your 'Library' directories.")
                .font(.body)
                .multilineTextAlignment(.center)

            Text("On first launch, you might see several **system prompts asking for access to different folders.** This is **normal and expected** for the app to function properly.")
                .font(.body)
                .fontWeight(.semibold)
                .multilineTextAlignment(.center)
                .foregroundColor(.orange) // Highlight this important part

            Text("Please grant the necessary permissions when prompted. For comprehensive cleaning, granting 'Full Disk Access' in System Settings is recommended.")
                .font(.callout)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)

            Button("Got It!") {
                dismiss() // Dismiss the sheet
            }
            .buttonStyle(.borderedProminent)
            .padding(.top, 10)
        }
        .padding(30)
        .frame(minWidth: 400, idealWidth: 500, maxWidth: 600, minHeight: 300, idealHeight: 400, maxHeight: 500)
        .fixedSize(horizontal: false, vertical: true) // Allow vertical resizing if content needs it
        .preferredColorScheme(.dark)
    }
}

// MARK: - Preview Provider
struct FirstRunPermissionMessageView_Previews: PreviewProvider {
    static var previews: some View {
        FirstRunPermissionMessageView()
            .previewLayout(.sizeThatFits)
    }
}
