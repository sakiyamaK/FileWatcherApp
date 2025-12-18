import Foundation

struct ExecutionLog: Identifiable {
    let id = UUID()
    let timestamp = Date()
    let command: String
    let file: String
    let output: String
    let isSuccess: Bool
}

import Observation

@MainActor
@Observable
class LogStore {
    var logs: [ExecutionLog] = []
    var isPaused: Bool = false
    
    func addLog(_ log: ExecutionLog) {
        // If paused, do not add new logs to the view.
        // We drop them to keep the view static as requested by "hard to check logs"
        guard !isPaused else { return }
        
        self.logs.insert(log, at: 0)
        if self.logs.count > 100 {
            self.logs.removeLast()
        }
    }
    
    func clearLogs() {
        logs.removeAll()
    }
}
