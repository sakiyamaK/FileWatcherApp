import Foundation
import AppKit

class PermissionManager {
    static let shared = PermissionManager()
    
    /// Checks if we have read access to the specified path.
    /// This is used to verify if we can watch the target directory.
    func hasAccess(to path: String) -> Bool {
        let fileManager = FileManager.default
        var isDir: ObjCBool = false
        
        guard fileManager.fileExists(atPath: path, isDirectory: &isDir) else {
            // If the path doesn't exist, we technically "have access" in the sense that permissions aren't blocking us (it's verified elsewhere)
            // But for the sake of the alert, let's return true (don't alert) if it's just missing. 
            // The FileWatcher will complain about missing path separately.
            return true
        }
        
        do {
            // Try to list the directory contents. This usually proves read access.
            if isDir.boolValue {
                _ = try fileManager.contentsOfDirectory(atPath: path)
            } else {
                // If it's a file, try to read attributes
                _ = try fileManager.attributesOfItem(atPath: path)
            }
            return true
        } catch {
            print("Access check failed for \(path): \(error)")
            return false
        }
    }
    
    func openFullDiskAccessSettings() {
        // macOS 13+ (Ventura) and older backward compatibility
        // Try the standard URL scheme.
        // Note: x-apple.systempreferences (dots) not x-apple-system-preferences (hyphens)
        let urlString = "x-apple.systempreferences:com.apple.preference.security?Privacy_AllFiles"
        
        if let url = URL(string: urlString) {
            NSWorkspace.shared.open(url)
        }
    }
}
