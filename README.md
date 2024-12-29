# AW Attacker Applier

A configurable dynamic attacker app designed for Android World.

## Features

### Android APP

- 🎯 **Dynamic UI Overlay System**
  - Automatically detect current app state and activity
  - Draw floating windows based on predefined rules
  - Support multiple overlays with different styles and positions
  - Persistent overlay management in background
  - System-level permission handling

- 📝 **Rule Configuration**
  - Create and edit UI element detection rules
  - Import/Export rule configurations as JSON
  - Support various element locator strategies (XPath, UiAutomator)


- 🔄 **Real-time Monitoring & Communication**
  - Monitor window state and activity changes
  - Real-time UI element detection and matching
  - WebSocket integration with Appium server
  - Auto-reconnect and state synchronization
  - Background service for continuous monitoring

- 🎨 **Modern Material Design**
  - Clean and intuitive user interface
  - Material 3 design language
  - Smooth animations and transitions

### Server

- 🔍 **Appium Integration & UI Detection**
  - Real-time window state monitoring
  - Multiple element locator strategies
  - Accurate element position calculation
  - UI Automator2 support

- 🌐 **WebSocket Communication**
  - Real-time bidirectional data flow
  - Connection management with ping/pong
  - File transfer with progress tracking
  - JSON validation for rule imports

### What's going on NEXT?

- [x] Support JSON rule file import directly from Android File System.
- [ ] Support **configurable popup window rendering rules** with customizable styles and layouts
- [ ] Organize rules with customizable tags
- [ ] Quick filter and search by tags
- [ ] Support bidirectional WebSocket rule JSON file transfer with validation and error handling
- [ ] Support downloading rule configurations from PC to app with integrity checks
- [ ] Support rule format validation and version compatibility checks
- [ ] Add retry mechanisms and progress tracking for rule transfers

## Setup

### Python Environment

1. Install PDM if you haven't already; check https://pdm-project.org/en/latest/ for installation guide.

2. Initialize the project and install dependencies:
```bash
# Initialize PDM project
pdm init

# Install all dependencies (including dev dependencies)
pdm install
```

3. Configure the server:
- The server will create an `uploads` directory to store received files (this function is still under development)
- Default WebSocket server runs on port 8000
- Make sure Appium server is running on `http://localhost:4723` (this is the default port that appium will work on, **run `appium` in another terminal window first.**)

4. Start the server:

```bash
# Development mode with auto-reload
pdm run uvicorn python.server:app --reload --port 8000

# Production mode
pdm run uvicorn python.server:app --host 0.0.0.0 --port 8000
```

5. Code quality tools:
```bash
# Format code
pdm run format

# Check code quality
pdm run check

# Fix common issues
pdm run fix
```

6. Verify the server is running:
- Health check: `http://localhost:8000/health`
- WebSocket endpoint: `ws://localhost:8000/ws`

### Flutter

> Note: This part of documentation may not be provided since we will directly use the compiled APK.