import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack {
            Image(systemName: "folder.fill.badge.questionmark")
                .resizable()
                .scaledToFit()
                .frame(width: 60, height: 60)
                .foregroundColor(.gray)
            Text("App Janitor")
                .font(.largeTitle)
            Text("Phase 1: Project Setup Complete")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
