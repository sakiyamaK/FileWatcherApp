import Foundation
import CoreServices
import Combine

class FileWatcher: ObservableObject {
    private var stream: FSEventStreamRef?
    private var configStore: ConfigStore
    private var logStore: LogStore
    private var cancellables = Set<AnyCancellable>()
    
    // Serial queue for event processing
    private let queue = DispatchQueue(label: "com.filewatcher.fsevents")
    
    init(configStore: ConfigStore, logStore: LogStore) {
        self.configStore = configStore
        self.logStore = logStore
        
        // Subscribe to config changes to restart watcher
        configStore.$resolvedWatchedPath
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                print("Config path changed, restarting watcher...")
                self?.start()
            }
            .store(in: &cancellables)
            
        configStore.$currentConfig
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
               print("Config object changed, restarting watcher...")
               self?.start()
            }
            .store(in: &cancellables)
            
        start()
    }
    
    deinit {
        stop()
    }
    
    func start() {
        stop()
        
        guard let config = configStore.currentConfig else {
            print("FileWatcher start failed: No current config")
            return
        }
        let path = configStore.resolvedWatchedPath
        if path.isEmpty || path == "/" {
             // Fallback or safety check? user might want to watch root, but uncommon.
             // If config hasn't loaded path logic yet.
        }
        
        let fileManager = FileManager.default
        
        // Ensure path exists
        guard fileManager.fileExists(atPath: path) else {
            print("FileWatcher start failed: Path does not exist: \(path)")
            return
        }
        
        print("FileWatcher starting for path: \(path)")
        
        // FSEventStream Context configuration
        var context = FSEventStreamContext(
            version: 0,
            info: UnsafeMutableRawPointer(Unmanaged.passUnretained(self).toOpaque()),
            retain: nil,
            release: nil,
            copyDescription: nil
        )
        
        let pathsToWatch = [path] as CFArray
        // Use a small fixed latency for FSEvents responsiveness (e.g. 0.1s)
        // We handle the "Cooldown" (debounce) manually using config.debounce_delay
        let latency = 0.1 
        
        // Request FileEvents so we know exactly which file changed
        let flags = UInt32(kFSEventStreamCreateFlagUseCFTypes | kFSEventStreamCreateFlagFileEvents)
        
        guard let stream = FSEventStreamCreate(
            kCFAllocatorDefault,
            fsEventCallback,
            &context,
            pathsToWatch,
            FSEventStreamEventId(kFSEventStreamEventIdSinceNow),
            latency,
            flags
        ) else {
            print("Failed to create FSEventStream")
            return
        }
        
        self.stream = stream
        FSEventStreamSetDispatchQueue(stream, queue)
        FSEventStreamStart(stream)
        
        print("Started watching \(path) using FSEvents with latency \(latency)s")
    }
    
    func stop() {
        if let stream = stream {
            FSEventStreamStop(stream)
            FSEventStreamInvalidate(stream)
            FSEventStreamRelease(stream)
            self.stream = nil
        }
    }
    
    // Track last execution time for debouncing specific files
    private var lastExecutionTimes: [String: Date] = [:]
    // Track currently executing files to prevent re-entry during execution
    private var currentlyExecutingFiles: Set<String> = []
    
    // Internal method called by the C-function callback
    fileprivate func handleEvents(paths: [String], flags: [FSEventStreamEventFlags]) {
        guard let config = configStore.currentConfig else { return }
        let rootPath = configStore.resolvedWatchedPath
        
        // Deduplicate paths in this batch and standardize keys
        var uniquePathsInv = [String: String]() // StandardizedLower -> Original
        
        for path in paths {
            let standard = URL(fileURLWithPath: path).standardized.path.lowercased()
            if uniquePathsInv[standard] == nil {
                uniquePathsInv[standard] = path
            }
        }
        
        for (standardPathKey, originalPath) in uniquePathsInv {
            // Check flags if needed (e.g. ItemIsFile, ItemIsModified)
            // For now, simpler approach: check if path is valid and matches config
            
            let url = URL(fileURLWithPath: originalPath)
            // Ensure the file actually exists (it might have been deleted)
            guard FileManager.default.fileExists(atPath: originalPath) else { continue }
            
            let relativePath = originalPath.replacingOccurrences(of: rootPath, with: "")
            
            // Ignore dirs check
            let shouldIgnore = config.config.ignore_dirs.contains { ignoreDir in
                return relativePath.contains(ignoreDir)
            }
            if shouldIgnore { continue }
            
            // Ignore hidden files (dotfiles) which are often temporary files created by editors
            if url.lastPathComponent.hasPrefix(".") {
                continue
            }
            
            // 1. Execution Guard: If already running, skip completely
            if currentlyExecutingFiles.contains(standardPathKey) {
                print("Skipping execution for \(url.lastPathComponent) (Guard: Already Executing)")
                continue
            }
            
            // 2. Debounce check: Check time window
            let now = Date()
            if let lastExec = lastExecutionTimes[standardPathKey] {
                let delta = now.timeIntervalSince(lastExec)
                if delta < config.config.debounce_delay {
                    print("Skipping execution for \(url.lastPathComponent) (Debounced: \(String(format: "%.2f", delta))s < \(config.config.debounce_delay)s)")
                    continue
                }
            }
            
            // Check watchers
            var executed = false
            for watcher in config.watchers {
                for pattern in watcher.patterns {
                    // Match pattern (suffix check)
                    if url.lastPathComponent.hasSuffix(pattern) {
                         // Double check existence before deciding to run
                         if !FileManager.default.fileExists(atPath: originalPath) { continue }
                         
                         // Mark as executed immediately to prevent race in serial queue for next item
                         executed = true
                        
                         // Update time immediately (Lock) using standard key
                         lastExecutionTimes[standardPathKey] = now
                         currentlyExecutingFiles.insert(standardPathKey)
                         print("Locked file for execution: \(url.lastPathComponent)")
                         
                         let capturedKey = standardPathKey

                        // Execute Async to not block the FSEvents queue
                        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                            self?.execute(watcher: watcher, file: url) {
                                // Completion (Back on Serial Queue to be safe with vars)
                                self?.queue.async {
                                    // Update timestamp AGAIN to slide window
                                    // This ignores the event caused by the script itself modifying the file
                                    self?.lastExecutionTimes[capturedKey] = Date()
                                    self?.currentlyExecutingFiles.remove(capturedKey)
                                    print("Released lock for \(url.lastPathComponent), debounce window reset.")
                                }
                            }
                        }
                    }
                }
            }
            // Logic moved inside loop
        }
    }
    
    // Add completion handler
    private func execute(watcher: WatcherConfig, file: URL, completion: @escaping () -> Void) {
        print("Executing \(watcher.name) for \(file.lastPathComponent)")
        let (output, success) = CommandRunner.run(command: watcher.command, file: file.path)
        
        let log = ExecutionLog(
            command: watcher.command,
            file: file.lastPathComponent,
            output: output,
            isSuccess: success
        )
        // LogStore is MainActor usually, or needs main thread
        DispatchQueue.main.async { [weak self] in
            self?.logStore.addLog(log)
        }
        
        completion()
    }
}

// Global/Static callback function for C-API
private func fsEventCallback(
    streamRef: ConstFSEventStreamRef,
    clientCallBackInfo: UnsafeMutableRawPointer?,
    numEvents: Int,
    eventPaths: UnsafeMutableRawPointer,
    eventFlags: UnsafePointer<FSEventStreamEventFlags>,
    eventIds: UnsafePointer<FSEventStreamEventId>
) {
    guard let clientCallBackInfo = clientCallBackInfo else { return }
    let watcher = Unmanaged<FileWatcher>.fromOpaque(clientCallBackInfo).takeUnretainedValue()
    
    // With kFSEventStreamCreateFlagUseCFTypes, eventPaths is a CFArray (NSArray) of NSStrings
    let paths = unsafeBitCast(eventPaths, to: NSArray.self) as! [String]
    
    // Convert flags to array
    // Flags are passed as UnsafePointer to array of Int32/UInt32?
    // The signature says UnsafePointer<FSEventStreamEventFlags>.
    // We can iterate via pointer arithmetic or just trust paths count.
    
    // We only need paths mostly.
    var flags = [FSEventStreamEventFlags]()
    for i in 0..<numEvents {
        flags.append(eventFlags[i])
    }
    
    watcher.handleEvents(paths: paths, flags: flags)
}
