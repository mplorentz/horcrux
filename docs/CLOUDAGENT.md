# Docker Setup for Cursor Cloud Agent

This Docker setup provides a complete environment for running Cursor Cloud Agent with:
- Dart & Flutter 3.35.0
- Nostrbook MCP server
- Marionette MCP server
- Ability to run the Flutter app inside the container for testing

## Prerequisites

- Docker and Docker Compose installed
- Sufficient disk space (Flutter SDK is ~2GB)

## Quick Start

Run the Flutter app in Docker with a single command:

```bash
./scripts/run-app-in-docker.sh
```

This script automatically:
- Builds the Docker image (if needed)
- Starts the container
- Installs Flutter dependencies (if needed)
- Starts Xvfb (virtual framebuffer) for headless display
- Launches the Flutter app in debug mode on Linux desktop
- Extracts and saves the Marionette VM Service URI for Marionette MCP
- Streams logs in real-time

You can then interact with the app via Marionette MCP tools.

**Press Ctrl+C to stop the app and container.**

### Testing with Marionette MCP 

You can test changes in the app using Marionette MCP. It includes tools for taking screenshots,
tapping buttons, entering text, etc.

#### Get the Marionette VM Service URI

The Marionette MCP server connects to the Flutter VM service via a websocket connection. You can 
get the websocket URI (from outside the docker container) by running the script: 

```bash
./scripts/get-vm-uri.sh
```

The URI will typically be: `ws://localhost:8182/ws` 

#### Connect Marionette MCP

Use the Marionette VM Service URI with Marionette MCP tools:
```
mcp_horcrux_app-marionette_connect with uri: ws://localhost:8182/ws
```

### Hot Reload

After making changes to your Dart code, trigger hot reload manually:

```bash
./scripts/hot-reload-docker.sh
```

## Manual Usage

### Exec into the Container

```bash
docker exec -it horcrux-cursor-agent bash
```

### Run Flutter Commands

```bash
# Inside the container
cd /workspace
flutter doctor
flutter pub get
flutter run -d linux --debug
```

### View Flutter Logs

```bash
docker exec horcrux-cursor-agent tail -f /tmp/flutter_run.log
```

## Port Forwarding and Network Access

The Marionette VM Service port needs to be accessible from outside the container. The Docker Compose file exposes ports 8181-8185. Flutter will auto-select a port when starting - check the logs or use `./scripts/get-vm-uri.sh` to find which port it's using.

**Important**: If Flutter chooses a port outside the 8181-8185 range, you'll need to:
1. Add that port to the `ports` section in `.cursor/docker-compose.yml`
2. Restart the container: `docker-compose -f .cursor/docker-compose.yml restart`

### Local Access (Same Machine)

When running Docker locally, use `ws://localhost:8181/ws` to connect.

### Remote Access (Different Machine)

If Cursor Cloud Agent is running on a different machine:

1. **Option 1: Use Host IP** - Replace `localhost` with your Docker host's IP address:
   ```
   ws://<docker-host-ip>:8181/ws
   ```

2. **Option 2: SSH Port Forwarding** - Set up SSH tunnel:
   ```bash
   ssh -L 8181:localhost:8181 user@docker-host
   ```
   Then connect to `ws://localhost:8181/ws`

3. **Option 3: Host Networking (Linux only)** - For Linux hosts, you can use host networking mode by modifying `.cursor/docker-compose.yml`:
   ```yaml
   network_mode: host
   ```
   Then remove the `ports` section. The Marionette VM Service will be directly accessible on the host.

## MCP Server Configuration

The container includes:
- **Marionette MCP**: Installed via `dart pub global activate marionette_mcp`
  - Command: `marionette_mcp`
- **Nostrbook MCP**: Installed via `npx`
  - Command: `npx -y @nostrbook/mcp@latest`

Configure these in your Cursor MCP settings (`.cursor/mcp.json`).

## Troubleshooting

### Docker Compose Variable Warnings

If you see warnings like:
```
WARN[0000] The "TLx" variable is not set. Defaulting to a blank string.
WARN[0000] The "jYz" variable is not set. Defaulting to a blank string.
```

This happens when your `.env` file contains `$` characters that Docker Compose interprets as variable references. To fix:

1. Open your `.env` file
2. Find any values containing `$` characters (like passwords)
3. **Wrap the entire value in single quotes** to prevent Docker Compose variable expansion
   - Example: `MATCH_PASSWORD=password$TLx$jYz` becomes `MATCH_PASSWORD='password$TLx$jYz'`

**Why single quotes?** Single quotes prevent Docker Compose from doing variable substitution, while Fastlane's `dotenv` gem will correctly read the quoted value. Using `$$` escapes would cause Fastlane to see literal `$$` characters.

These warnings are harmless but can be annoying. The build will still work correctly.

### Flutter App Won't Start

1. Check if Xvfb is running:
   ```bash
   docker exec horcrux-cursor-agent pgrep -x Xvfb
   ```

2. Check Flutter logs:
   ```bash
   docker exec horcrux-cursor-agent cat /tmp/flutter_run.log
   ```

3. Verify Linux desktop is enabled:
   ```bash
   docker exec horcrux-cursor-agent flutter config
   ```

### CMake "A required package was not found" Error

If you see this error, it means a required pkg-config package is missing. To diagnose:

1. **Check which packages Flutter needs**:
   ```bash
   docker exec horcrux-cursor-agent bash -c "cd /workspace && pkg-config --list-all | grep -E '(gtk|glib|gio)'"
   ```

2. **Verify required packages are installed**:
   ```bash
   docker exec horcrux-cursor-agent bash -c "pkg-config --exists gtk+-3.0 && echo 'gtk+-3.0: OK' || echo 'gtk+-3.0: MISSING'"
   docker exec horcrux-cursor-agent bash -c "pkg-config --exists glib-2.0 && echo 'glib-2.0: OK' || echo 'glib-2.0: MISSING'"
   docker exec horcrux-cursor-agent bash -c "pkg-config --exists gio-2.0 && echo 'gio-2.0: OK' || echo 'gio-2.0: MISSING'"
   ```

3. **Rebuild the container** after updating the Dockerfile:
   ```bash
   docker-compose -f .cursor/docker-compose.yml build --no-cache
   docker-compose -f .cursor/docker-compose.yml up -d
   ```

4. **Check plugin-specific requirements**: Some Flutter plugins may require additional packages. Check the plugin's documentation or CMakeLists.txt files.

### Marionette VM Service URI Not Found

The Marionette VM Service URI appears in Flutter debug output. If it's not found:
1. Wait longer (app may still be starting)
2. Check logs for errors
3. Verify the app is actually running: `docker exec horcrux-cursor-agent ps aux | grep flutter`

### Cannot Connect to Marionette VM Service

If Marionette MCP cannot connect to the Marionette VM Service:

1. **Check if port is accessible**: 
   ```bash
   docker exec horcrux-cursor-agent netstat -tlnp | grep 8181
   ```

2. **Verify Flutter is binding correctly**: Flutter's Marionette VM Service binds to `127.0.0.1` by default, which can cause issues with Docker port forwarding. The Marionette VM Service may reject connections that don't appear to come from localhost:
   - **On Linux hosts**: Try using host networking mode by adding `network_mode: host` to `.cursor/docker-compose.yml` and removing the `ports` section
   - **On macOS/Windows**: Docker port forwarding may not work reliably due to Flutter's localhost-only binding. Consider:
     - Running Marionette MCP inside the container (if possible)
     - Using SSH port forwarding to the Docker host
     - Configuring Flutter to bind to `0.0.0.0` (requires Flutter/Dart VM configuration)

3. **Check firewall**: Ensure port 8181 is not blocked by firewall rules

4. **Current Status**: The app runs successfully in the container and exposes the Marionette VM Service on port 8181. However, connecting from the host via Marionette MCP may fail due to Flutter's `127.0.0.1` binding. The Marionette VM Service URI is available in `/tmp/flutter_run.log` inside the container.

### VNC Connection Issues

If VNC client hangs or won't connect:

1. **Verify VNC server is running**:
   ```bash
   docker exec horcrux-cursor-agent ps aux | grep x11vnc
   ```

2. **Check if port is listening**:
   ```bash
   docker exec horcrux-cursor-agent netstat -tlnp | grep 5900
   # or
   docker exec horcrux-cursor-agent ss -tlnp | grep 5900
   ```

3. **Check VNC server logs**:
   ```bash
   docker exec horcrux-cursor-agent tail -30 /tmp/x11vnc.log
   ```

4. **Restart VNC server** (see "Restart VNC Server" section above)

5. **Try a different VNC client** (macOS Screen Sharing can be unreliable):
   - **macOS**: Download [RealVNC Viewer](https://www.realvnc.com/en/connect/download/viewer/) - it's more reliable than Screen Sharing
   - **macOS alternative**: Install `vncviewer` via Homebrew: `brew install tigervnc` then use `vncviewer localhost:5900`
   - **Linux**: Use `vncviewer`, `vinagre`, or `remmina`
   - **Windows**: Use TightVNC Viewer or RealVNC Viewer
   
6. **macOS Screen Sharing specific issues**:
   - Screen Sharing may hang if the VNC server doesn't support certain features
   - Try connecting with the address format: `vnc://localhost:5900` in Finder's "Connect to Server"
   - If it still hangs, use RealVNC Viewer instead

6. **Verify Xvfb is running**:
   ```bash
   docker exec horcrux-cursor-agent pgrep -x Xvfb
   ```

### Port Already in Use

If ports 8181-8200 or 5900 are already in use, modify `.cursor/docker-compose.yml` to use different ports.

## Development Workflow

1. Make code changes in your local workspace
2. Changes are synced to `/workspace` in the container (via volume mount)
3. Trigger hot reload: `./scripts/hot-reload-docker.sh` (or use VS Code task "Docker: Hot Reload")
4. Or restart the app: `./scripts/run-app-in-docker.sh`

## Cleanup

Stop and remove containers:
```bash
docker-compose -f .cursor/docker-compose.yml down
```

Remove volumes (clears Flutter/pub cache):
```bash
docker-compose -f .cursor/docker-compose.yml down -v
```

## Notes

- The container uses Ubuntu 22.04 as the base image
- Flutter 3.35.0 is installed (matching `pubspec.yaml`)
- Xvfb provides a virtual display for headless operation
- The workspace is mounted as a volume, so code changes are reflected immediately
