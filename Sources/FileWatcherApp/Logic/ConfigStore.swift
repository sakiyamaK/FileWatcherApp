import Foundation
import Yams

import Observation
import Combine

@MainActor
@Observable
class ConfigStore {
    var configFilePath: String = ""
    var currentConfig: AppConfig? {
        didSet {
            configChangedSubject.send()
        }
    }
    var resolvedWatchedPath: String = "/" {
        didSet {
            configChangedSubject.send()
        }
    }
    var errorMessage: String?
    
    // Manual publisher for FileWatcher or other logic that needs explicit signals
    // Since @Observable doesn't provide $properties
    let configChangedSubject = PassthroughSubject<Void, Never>()
    
    init() {
        // Since loadConfig is sync here for initial load on main actor
        loadConfig()
    }
    
    func loadConfig() {
        // 1. Try to load from saved path in UserDefaults
        if let savedPath = UserDefaults.standard.string(forKey: "ConfigFilePath") {
            let url = URL(fileURLWithPath: savedPath)
            if FileManager.default.fileExists(atPath: savedPath) {
                print("Found saved config path: \(savedPath)")
                loadConfig(from: url, isInitialLoad: true)
                return
            }
        }

        // 2. Fallback to bundled resource
        guard let url = Bundle.module.url(forResource: "file_save_watcher", withExtension: "yml") else {
            errorMessage = "Bundled config file not found."
            return
        }
        print("Loading bundled default config")
        loadConfig(from: url, isInitialLoad: true)
    }
    
    func loadConfig(from url: URL, isInitialLoad: Bool = false) {
        // Handle security scope if needed (for user selected files outside sandbox, though we use full disk access mostly)
        let isSecurityScoped = url.startAccessingSecurityScopedResource()
        defer {
            if isSecurityScoped {
                url.stopAccessingSecurityScopedResource()
            }
        }
        
        do {
            let data = try String(contentsOf: url)
            let decoder = YAMLDecoder()
            let config = try decoder.decode(AppConfig.self, from: data)
            
            // On @MainActor, we can update directly
            self.currentConfig = config
            self.configFilePath = url.path
            
            // Logic: 1. Config explicit path 2. Config file directory 3. Home fallback
            if let specifiedPath = config.config.path, !specifiedPath.isEmpty {
                self.resolvedWatchedPath = specifiedPath
            } else {
                // Watch directory containing the config file
                self.resolvedWatchedPath = url.deletingLastPathComponent().path
            }
            
            self.errorMessage = nil
            print("Loaded config from \(url.path). Watching: \(self.resolvedWatchedPath)")
            
            // Save to UserDefaults
            UserDefaults.standard.set(url.path, forKey: "ConfigFilePath")
        } catch {
            // On @MainActor, we can update directly
            self.currentConfig = nil
            self.errorMessage = "Failed to load config: \(error.localizedDescription)"
            print("Error loading config: \(error)")
        }
    }
}

