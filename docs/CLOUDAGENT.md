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

### 1. Build the Docker Image

```bash
docker-compose build
```

### 2. Start the Container

```bash
docker-compose up -d
```

### 3. Install Dependencies (First Time Only)

On first run, you need to install Flutter dependencies:

```bash
docker exec horcrux-cursor-agent bash -c "cd /workspace && flutter pub get"
```


### 4. Run the Flutter App in Debug Mode

```bash
./scripts/run-app-in-docker.sh
```

This script will:
- Start Xvfb (virtual framebuffer) for headless display
- Launch the Flutter app in debug mode on Linux desktop
- Extract and save the VM service URI for Marionette MCP

### 5. Get the VM Service URI

```bash
./scripts/get-vm-uri.sh
```

Or manually:
```bash
docker exec horcrux-cursor-agent cat /tmp/vm_service_uri.txt
```

The URI will be: `ws://localhost:8181/ws` (or `ws://127.0.0.1:8181/ws`)

### 6. Connect Marionette MCP

Use the VM service URI with Marionette MCP tools:
```
mcp_horcrux_app-marionette_connect with uri: ws://localhost:8181/ws
```

**Note**: 
- The VM service is bound to `0.0.0.0:8181` inside the container
- Port 8181 is forwarded to your host machine
- Use `localhost:8181` when connecting from the host
- If accessing remotely, use the Docker host's IP address instead of `localhost`

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

### Stop the Flutter App

```bash
docker exec horcrux-cursor-agent pkill -f "flutter run"
```

## Port Forwarding and Network Access

The VM service port needs to be accessible from outside the container. The Docker Compose file exposes ports 8181-8185. Flutter will auto-select a port when starting - check the logs or use `./scripts/get-vm-uri.sh` to find which port it's using.

**Important**: If Flutter chooses a port outside the 8181-8185 range, you'll need to:
1. Add that port to the `ports` section in `docker-compose.yml`
2. Restart the container: `docker-compose restart`

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

3. **Option 3: Host Networking (Linux only)** - For Linux hosts, you can use host networking mode by modifying `docker-compose.yml`:
   ```yaml
   network_mode: host
   ```
   Then remove the `ports` section. The VM service will be directly accessible on the host.

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
   docker-compose build --no-cache
   docker-compose up -d
   ```

4. **Check plugin-specific requirements**: Some Flutter plugins may require additional packages. Check the plugin's documentation or CMakeLists.txt files.

### VM Service URI Not Found

The VM service URI appears in Flutter debug output. If it's not found:
1. Wait longer (app may still be starting)
2. Check logs for errors
3. Verify the app is actually running: `docker exec horcrux-cursor-agent ps aux | grep flutter`

### Cannot Connect to VM Service

If Marionette MCP cannot connect to the VM service:

1. **Check if port is accessible**: 
   ```bash
   docker exec horcrux-cursor-agent netstat -tlnp | grep 8181
   ```

2. **Verify Flutter is binding correctly**: Flutter's VM service binds to `127.0.0.1` by default, which can cause issues with Docker port forwarding. The VM service may reject connections that don't appear to come from localhost:
   - **On Linux hosts**: Try using host networking mode by adding `network_mode: host` to `docker-compose.yml` and removing the `ports` section
   - **On macOS/Windows**: Docker port forwarding may not work reliably due to Flutter's localhost-only binding. Consider:
     - Running Marionette MCP inside the container (if possible)
     - Using SSH port forwarding to the Docker host
     - Configuring Flutter to bind to `0.0.0.0` (requires Flutter/Dart VM configuration)

3. **Check firewall**: Ensure port 8181 is not blocked by firewall rules

4. **Current Status**: The app runs successfully in the container and exposes the VM service on port 8181. However, connecting from the host via Marionette MCP may fail due to Flutter's `127.0.0.1` binding. The VM service URI is available in `/tmp/flutter_run.log` inside the container.

### Port Already in Use

If ports 8181-8200 are already in use, modify `docker-compose.yml` to use different ports.

## Development Workflow

1. Make code changes in your local workspace
2. Changes are synced to `/workspace` in the container (via volume mount)
3. Hot reload should work: `docker exec horcrux-cursor-agent pkill -USR1 -f "flutter run"`
4. Or restart the app: `./scripts/run-app-in-docker.sh`

## Cleanup

Stop and remove containers:
```bash
docker-compose down
```

Remove volumes (clears Flutter/pub cache):
```bash
docker-compose down -v
```

## Notes

- The container uses Ubuntu 22.04 as the base image
- Flutter 3.35.0 is installed (matching `pubspec.yaml`)
- Xvfb provides a virtual display for headless operation
- The workspace is mounted as a volume, so code changes are reflected immediately
