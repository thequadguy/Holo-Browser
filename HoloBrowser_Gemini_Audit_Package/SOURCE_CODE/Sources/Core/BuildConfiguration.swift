import Foundation

public enum AppEnvironment: String, Codable, Sendable {
    case development = "Development"
    case beta = "Public Beta"
    case production = "Production"
}

/// Core configuration store for release build environments and feature flags.
public enum BuildConfiguration {
    public static let appVersion: String = "1.0.0-beta.1"
    public static let buildNumber: String = "100"
    public static let bundleIdentifier: String = "com.holo.browser"
    
    #if DEBUG
    public static let currentEnvironment: AppEnvironment = .development
    #else
    public static let currentEnvironment: AppEnvironment = .production
    #endif
    
    public static var isBeta: Bool {
        return currentEnvironment == .beta
    }
}
