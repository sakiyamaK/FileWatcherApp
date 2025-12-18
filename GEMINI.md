# FileWatcher.app

**FileWatcher.app** is a high-performance macOS menu bar application (macOS 14.0+) tailored for automating local development workflows. It monitors specified directories for file changes using native filesystem events and executes defined shell commands.

## Core Architecture

The application follows a clean separation of concerns:

-   **Models**: Defines configuration structures (`Config`, `WatcherConfig`) compliant with `Codable` for YAML parsing.
-   **Views**: SwiftUI-based UI (`ContentView`) for configuration management and status visualization.
-   **Logic**:
    -   **AppManager (Singleton)**: Central controller ensuring a single instance of the application logic exists.
    -   **FileWatcher**: Wraps the macOS `FSEvents` C-API for efficient, zero-polling file monitoring. Uses `DispatchQueue` and a serial queue for state management, marked as `@unchecked Sendable`.
    -   **CommandRunner**: Executes shell commands asynchronously.
    -   **Stores**: `ConfigStore` and `LogStore` manage state and persistence using the Swift Observation framework (`@Observable`).
    -   **Concurrency**: Uses `@MainActor` for UI-bound state and `Task` for bridging background events to the main thread.

## Key Technical Features

### 1. Event-Driven Monitoring (FSEvents)
Unlike traditional polling methods, this app uses `FSEventStream` to receive kernel-level notifications about file system changes. This results in near-zero CPU usage when idle and instant reaction times.

### 2. Robust Debouncing & Execution Guard
To handle the "double execution" problem common in editor save flows (where editors save to a temporary file, then move/rename), the app implements a strict locking mechanism:
-   **Execution Guard**: While a command is running for a file, subsequent events for that file are ignored.
-   **Sliding Window**: Upon command completion, the debounce timer is reset to the current time, ensuring any trailing events caused by the command itself (e.g., auto-formatting) are also ignored.
-   **Case-Insensitive Checking**: Canonicalizes file paths to prevent duplicates due to case variations.

### 3. YAML Configuration
Configuration is loaded from a user-specified YAML file, supporting multiple watchers and distinct patterns.

```yaml
config:
  debounce_delay: 1.0
  ignore_dirs: [.git, .build]

watchers:
  - name: "Swift Formatting"
    patterns: [".swift"]
    command: "swiftlint --fix $FILE"
```

## Build & Installation

The project uses Swift Package Manager (SPM).

```bash
# Build and create .app bundle
./scripts/build_app.sh
```

**Output**: 
- `build/FileWatcher.app`
- `build/FileWatcher.zip` (Signed and ready for distribution)

## Permissions

Requires **Full Disk Access** (TCC) to monitor user directories like Desktop or Documents. The app includes a built-in check and guides the user to System Settings if permissions are missing.
