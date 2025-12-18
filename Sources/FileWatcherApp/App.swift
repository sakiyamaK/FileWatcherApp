import SwiftUI

@main
struct FileWatcherApp: App {
    @Environment(\.openWindow) var openWindow
    // Single source of truth using Observation
    @State private var appManager = AppManager()

    init() {
        let stderr = FileHandle.standardError
        let msg = "DEBUG: App full init\n".data(using: .utf8)!
        stderr.write(msg)
    }

    var body: some Scene {
        #if os(macOS)
        WindowGroup(id: "settings") {
            ContentView()
                .environment(appManager.configStore)
                .environment(appManager.logStore)
                .onAppear {
                    appManager.startApp()
                }
                .onDisappear {
                    appManager.logStore.clearLogs()
                }
        }
        .windowResizability(.contentSize)

        MenuBarExtra("FileWatcher", image: "AppIcon") {
            Text("Scanning: \(truncatedPath(appManager.configStore.resolvedWatchedPath))")
            Divider()
            Button("Settings") {
                openWindow(id: "settings")
                NSApp.activate(ignoringOtherApps: true)
            }
            Divider()
            Button("Quit") {
                NSApplication.shared.terminate(nil)
            }
        }
        #else
        WindowGroup {
            Text("This app is macOS only.")
        }
        #endif
    }
    
    func truncatedPath(_ path: String, maxLength: Int = 30) -> String {
        if path.count <= maxLength {
            return path
        }
        let prefixLen = maxLength / 2
        let suffixLen = maxLength / 2 - 3 // -3 for "..."
        
        let prefix = path.prefix(prefixLen)
        let suffix = path.suffix(suffixLen)
        return "\(prefix)...\(suffix)"
    }
}

