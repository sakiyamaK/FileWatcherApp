import Foundation

struct AppConfig: Codable {
    var config: GlobalConfig
    var watchers: [WatcherConfig]
}

struct GlobalConfig: Codable {
    var debounce_delay: Double
    var ignore_dirs: [String]
    var shell: String?
    var path: String? // User mentioned path might be specified
}

struct WatcherConfig: Codable {
    var name: String
    var patterns: [String]
    var command: String
}

