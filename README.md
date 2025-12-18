# FileWatcher

A high-performance macOS file watcher that automates command execution on file changes.

## Features

- **Event-Driven**: Uses macOS FSEvents for zero-latency detection.
- **Efficient**: No polling interval. Only runs when events occur.
- **Smart Debounce**: Automatically coalesces rapid save events to execute only once.
- **Background Mode**: Runs unobtrusively in the menu bar.

## Installation

### Option A: Download Release
1. Download `FileWatcher.zip` from the [Releases](https://github.com/sakiyamaK/FileWatcherApp/releases) page.
2. Extract and move `FileWatcher.app` to your Applications folder.

### Option B: Build from Source
1.  Clone and build:
    ```bash
    ./scripts/build_app.sh
    ```
2.  Move `build/FileWatcher.app` to your Applications folder.

## Configuration

Support YAML format.

**Example `file_save_watcher.yml`**:

```yaml
config:
  debounce_delay: 1.0  # Seconds to wait before allowing re-execution
  ignore_dirs:
    - .git
    - node_modules
    - .build

watchers:
  - name: "Swift Formatter"
    patterns:
      - ".swift"
    command: "swiftlint --fix $FILE"
  
  - name: "Python Linter"
    patterns:
      - ".py"
    command: "flake8 $FILE"
```

## Setup
1. Launch `FileWatcher.app`. It will appear in your Menu Bar (eye icon).
2. Click the Menu Bar icon → **Settings**.
3. Load your `.yml` config file.
4. **Permissions**: Ensure the app has "Full Disk Access" if watching protected directories.
