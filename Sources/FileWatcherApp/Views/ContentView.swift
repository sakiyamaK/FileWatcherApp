import SwiftUI

struct ContentView: View {
    @Environment(ConfigStore.self) var configStore
    @Environment(LogStore.self) var logStore
    @State private var showFileImporter = false

    var body: some View {
        validView
    }

    var validView: some View {
        TabView {
            configView
                .tabItem {
                    Label("Config", systemImage: "gear")
                }
            logsView
                .tabItem {
                    Label("Logs", systemImage: "list.bullet")
                }
        }
        .padding()
        .frame(minWidth: 500, minHeight: 400)
        .fileImporter(
            isPresented: $showFileImporter,
            allowedContentTypes: [.yaml],
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                if let url = urls.first {
                    configStore.loadConfig(from: url)
                }
            case .failure(let error):
                print("Error selecting file: \(error.localizedDescription)")
            }
        }
    }

    var configView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header / Status
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: "circle.fill")
                            .foregroundColor(.green)
                            .font(.caption2)
                        Text("Active")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Button("Select Config File") {
                            showFileImporter = true
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                    }
                    
                    HStack(spacing: 8) {
                        Image(systemName: "doc.text.fill")
                            .foregroundColor(.blue)
                        Text(configStore.configFilePath.isEmpty ? "Bundled Default" : configStore.configFilePath)
                            .font(.system(.footnote, design: .monospaced))
                            .lineLimit(1)
                            .truncationMode(.middle)
                            .padding(8)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(8)
                    }
                }
                .padding(.bottom, 8)
                
                Divider()
                
                if let config = configStore.currentConfig {
                    // Global Settings Section
                    VStack(alignment: .leading, spacing: 16) {
                        Label("Global Settings", systemImage: "slider.horizontal.3")
                            .font(.headline)
                        
                        HStack(spacing: 24) {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Watched Path")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                HStack {
                                    Image(systemName: "folder")
                                    Text(configStore.resolvedWatchedPath)
                                        .fontWeight(.medium)
                                }
                            }
                            
                            Spacer()
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Debounce")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                HStack {
                                    Image(systemName: "clock")
                                    Text("\(config.config.debounce_delay, specifier: "%.1f")s")
                                        .fontWeight(.medium)
                                }
                            }
                        }
                        .padding()
                        .background(Color.gray.opacity(0.05))
                        .cornerRadius(12)
                    }
                    
                    // Watchers Section
                    VStack(alignment: .leading, spacing: 16) {
                        Label("Watchers Rules", systemImage: "eye")
                            .font(.headline)
                        
                        ForEach(config.watchers, id: \.name) { watcher in
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Text(watcher.name)
                                        .font(.headline)
                                    Spacer()
                                }
                                
                                HStack(alignment: .top) {
                                    Image(systemName: "doc.on.doc")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .padding(.top, 2)
                                    
                                    // Tags for patterns
                                    HStack(spacing: 4) {
                                        ForEach(watcher.patterns, id: \.self) { pattern in
                                            Text(pattern)
                                                .font(.caption2)
                                                .padding(.horizontal, 6)
                                                .padding(.vertical, 2)
                                                .background(Color.blue.opacity(0.1))
                                                .foregroundColor(.blue)
                                                .cornerRadius(4)
                                        }
                                    }
                                }
                                
                                HStack(alignment: .top) {
                                    Image(systemName: "terminal")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .padding(.top, 2)
                                    
                                    Text(watcher.command)
                                        .font(.system(.caption, design: .monospaced))
                                        .foregroundColor(.secondary)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                }
                            }
                            .padding()
                            .background(Color.white.opacity(0.5)) // Slightly lighter
                            .background(RoundedRectangle(cornerRadius: 12).stroke(Color.gray.opacity(0.2), lineWidth: 1))
                        }
                    }
                    
                } else {
                    VStack {
                        Spacer()
                        Image(systemName: "exclamationmark.triangle")
                            .font(.largeTitle)
                            .foregroundColor(.orange)
                        Text(configStore.errorMessage ?? "Loading configuration...")
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                    .frame(height: 200)
                }
            }
            .padding()
        }
    }

    var logsView: some View {
        VStack(alignment: .leading) {
            HStack {
                Text("Execution Logs")
                    .font(.headline)
                Spacer()
                Button(action: {
                    logStore.isPaused.toggle()
                }) {
                    Image(systemName: logStore.isPaused ? "play.fill" : "pause.fill")
                    Text(logStore.isPaused ? "Resume" : "Pause")
                }
                .buttonStyle(.bordered)
                
                Button(action: {
                    logStore.clearLogs()
                }) {
                    Image(systemName: "trash")
                }
                .buttonStyle(.plain)
            }
            List(logStore.logs) { log in
                VStack(alignment: .leading) {
                    HStack {
                        Image(systemName: log.isSuccess ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .foregroundStyle(log.isSuccess ? .green : .red)
                        Text(log.command)
                            .fontWeight(.bold)
                        Spacer()
                        Text(log.timestamp, style: .time)
                            .font(.caption)
                    }
                    Text("File: \(log.file)")
                        .font(.caption)
                    if !log.output.isEmpty {
                        Text(log.output)
                            .font(.system(.caption, design: .monospaced))
                            .padding(4)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(4)
                    }
                }
                .padding(.vertical, 4)
            }
        }
    }

}
