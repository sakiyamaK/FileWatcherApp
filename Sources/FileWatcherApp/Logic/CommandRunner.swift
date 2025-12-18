import Foundation

class CommandRunner {
    static func run(command: String, file: String) -> (output: String, success: Bool) {
        let process = Process()
        let pipe = Pipe()
        
        let fileURL = URL(fileURLWithPath: file)
        // Simple variable replacement
        // Note: For complex shell parsing we might need more, but this covers basic usage.
        let expandedCommand = command.replacingOccurrences(of: "$FILE", with: fileURL.path)
        
        process.standardOutput = pipe
        process.standardError = pipe
        process.arguments = ["-c", expandedCommand]
        process.launchPath = "/bin/zsh" // Or /bin/bash
        
        do {
            try process.run()
            process.waitUntilExit()
            
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            let output = String(data: data, encoding: .utf8) ?? ""
            return (output, process.terminationStatus == 0)
        } catch {
            return ("Failed to launch process: \(error.localizedDescription)", false)
        }
    }
}
