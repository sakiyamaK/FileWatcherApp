import Foundation
import Yams

class ConfigStore: ObservableObject {
    @Published var configFilePath: String = ""
    @Published var currentConfig: AppConfig?
    @Published var resolvedWatchedPath: String = "/"
    @Published var errorMessage: String?
    
    init() {
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
            
            DispatchQueue.main.async {
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
                
                // Save to UserDefaults only if it's not the initial specific load (or we can validly save it regardless)
                // Actually we should always save if it's a valid user file. If it's bundled we might not want to save that path if it's dynamic?
                // But generally users pick a file.
                
                // For bundled file, the path might be inside the .app bundle which varies. 
                // We should probably check if it is part of the bundle resource before saving, 
                // OR just save it and if it fails next time (e.g. app moved) we logic falls back.
                
                // Let's save it.
                 UserDefaults.standard.set(url.path, forKey: "ConfigFilePath")
            }
        } catch {
            DispatchQueue.main.async {
                self.currentConfig = nil
                self.errorMessage = "Failed to load config: \(error.localizedDescription)"
                print("Error loading config: \(error)")
            }
        }
    }
}

