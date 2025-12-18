import Foundation
import Combine
import SwiftUI

class AppManager: ObservableObject {
    let configStore: ConfigStore
    let logStore: LogStore
    
    // Private watcher instance to ensure it's managed only here
    private var watcher: FileWatcher?
    
    @Published var showPermissionAlert = false
    
    init() {
        // Initialize Stores
        let config = ConfigStore()
        let logs = LogStore()
        
        self.configStore = config
        self.logStore = logs
        
        print("Default: AppManager initialized")
    }
    
    func startApp() {
        print("Default: AppManager starting app logic...")
        
        // check permissions
        checkPermissions()
        
        // Start watcher if not already
        if watcher == nil {
            print("Default: Initializing FileWatcher singleton...")
            watcher = FileWatcher(configStore: configStore, logStore: logStore)
        } else {
            print("Default: FileWatcher already exists. Skipping init.")
        }
    }
    
    func checkPermissions() {
        if !PermissionManager.shared.hasAccess(to: configStore.resolvedWatchedPath) {
            DispatchQueue.main.async {
                self.showPermissionAlert = true
            }
        }
    }
    
    func openSettings() {
        PermissionManager.shared.openFullDiskAccessSettings()
    }
}
