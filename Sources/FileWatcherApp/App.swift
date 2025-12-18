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
        WindowGroup(id: "mainWindow") {
            ContentView()
                .environment(appManager.configStore)
                .environment(appManager.logStore)
                .onAppear {
                    appManager.startApp()
                }
                .onDisappear {
                    appManager.logStore.clearLogs()
                }
                .alert("Permission Required", isPresented: $appManager.showPermissionAlert) {
                    Button("Open Settings") {
                        appManager.openSettings()
                    }
                    Button("Cancel", role: .cancel) { }
                } message: {
                    Text("This app monitors file changes in your home directory.\n\nPlease grant permissions or Full Disk Access to 'FileWatcher'.\n\nIf the app is not in the list:\n1. Click the '+' button at the bottom of the list.\n2. Navigate to 'build/FileWatcher.app' and select it.")
                }
        }

        MenuBarExtra("FileWatcherApp", systemImage: "star.fill") {
            Button("Open Window") {
                openWindow(id: "mainWindow")
                NSApp.activate(ignoringOtherApps: true)
            }
            Divider()
            Button("Check Permissions") {
                appManager.checkPermissions()
            }
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
}

