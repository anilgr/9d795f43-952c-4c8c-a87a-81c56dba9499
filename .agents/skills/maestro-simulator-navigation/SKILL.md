---
name: maestro-simulator-navigation
description: Guidance on using Maestro MCP tools to discover mobile simulators/emulators, navigate app UI screens, inspect view hierarchies, handle iOS vs Android navigation, and manage screenshot captures (streaming to chat vs saving to disk).
---

# Maestro Simulator Navigation & Screen Capture

This skill provides workflow guidelines and best practices for automating iOS Simulators and Android Emulators using Maestro MCP tools.

## 1. Device Discovery & Initial Workflow

Always follow the standard local Maestro workflow:
`list_devices` -> `inspect_screen` -> `run`

1. **List Devices**:
   - Call `list_devices` to retrieve connected device IDs (iOS simulator UUID, Android device ID, or `chromium`).
   - Identify active/connected devices (e.g., `connected: true`).

2. **Launch Application**:
   - Pass inline YAML to the `run` MCP tool:
     ```yaml
     appId: com.apple.Preferences # (iOS Settings example)
     ---
     - launchApp
     ```

## 2. Screen Inspection & Navigation Rules

1. **Inspect View Hierarchy**:
   - Call `inspect_screen` with the `device_id` to inspect element text (`txt`), accessibility labels (`a11y`), resource IDs (`rid`), and bounding boxes (`b`).
   - Use exact strings or regular expressions from `inspect_screen` when writing selectors.

2. **iOS vs Android Back Navigation**:
   - **Android**: Supports the `- back` flow command.
   - **iOS**: Does **NOT** support `- back`. You must target and tap the top-left navigation back button element:
     ```yaml
     appId: com.apple.Preferences
     ---
     - tapOn:
         id: "BackButton"
     ```

## 3. Screenshot Capture: Streaming vs. File Storage

Depending on whether you need visual inspection in the chat or a persistent file on disk:

### Option A: Streaming to Chat UI (`take_screenshot`)
- **Tool**: `take_screenshot` (MCP)
- **Args**: `{ "device_id": "<DEVICE_ID>" }`
- **Behavior**: Renders the screenshot directly in the chat context without polluting the workspace with image files.

### Option B: Saving Physical Screenshot File to Disk (`takeScreenshot` in Flow)
- **Tool**: `run` (MCP)
- **Args**: Inline YAML flow with `takeScreenshot`
- **Behavior**: Saves a physical `.png` file directly to the workspace path specified.
- **Example**:
  ```yaml
  appId: com.apple.Preferences
  ---
  - takeScreenshot: "settings_overview.png"
  ```
  Or specifying a custom path:
  ```yaml
  appId: com.apple.Preferences
  ---
  - takeScreenshot:
      path: "./screenshots/camera_settings.png"
  ```
