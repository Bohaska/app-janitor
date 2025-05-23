import Foundation

// MARK: - App URLs & Constants Container
struct Constants { // Wrap everything inside a struct

    // MARK: - App URLs
    static let AppRepoURLString = "https://github.com/davunt/app-eraser"
    static let IssuesURLString = "https://github.com/davunt/app-eraser/issues"
    static let ReleasesURLString = "https://github.com/davunt/app-eraser/releases"
    static let AppMastodonURLString = "https://mastodon.online/@davunt"
    static let MaintainerMastodonURLString = "https://mastodon.online/@davunt"

    // Convert to URL objects immediately
    static let AppRepoURL = URL(string: AppRepoURLString)!
    static let IssuesURL = URL(string: IssuesURLString)!
    static let ReleasesURL = URL(string: ReleasesURLString)!
    static let AppMastodonURL = URL(string: AppMastodonURLString)!
    static let MaintainerMastodonURL = URL(string: MaintainerMastodonURLString)!

    // Add other constants from Config.swift here if you want a single constants file
    // Or keep them separate but also within a struct or enum if needed elsewhere.
    // For now, we'll just fix the URLs.
}

// If you also put Config, FilePatterns, etc. into structs/enums,
// you would access them similarly (e.g., Config.scoreThreshold)
