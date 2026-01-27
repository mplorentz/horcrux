#!/bin/bash
# Script to run Flutter app in Docker container for Marionette MCP testing

set -e

CONTAINER_NAME="horcrux-cursor-agent"

# Check if container is running
if ! docker ps | grep -q "$CONTAINER_NAME"; then
    echo "Error: Container $CONTAINER_NAME is not running."
    echo "Start it with: docker-compose up -d"
    exit 1
fi

echo "Starting Xvfb and Flutter app in container..."
echo "This will run the app in debug mode and expose the VM service URI."

# Clean up and setup synchronously first
echo "Cleaning up existing processes..."
docker exec "$CONTAINER_NAME" bash -c '
    echo "Cleaning up existing processes..." > /tmp/flutter_run.log
    # Kill processes more carefully - avoid killing the current bash process
    for pid in $(pgrep -f "horcrux" 2>/dev/null | grep -v "$$"); do kill -9 "$pid" 2>/dev/null || true; done
    for pid in $(pgrep -f "flutter.*run" 2>/dev/null | grep -v "$$"); do kill -9 "$pid" 2>/dev/null || true; done  
    for pid in $(pgrep -f "socat.*8182" 2>/dev/null | grep -v "$$"); do kill -9 "$pid" 2>/dev/null || true; done
    sleep 2
    rm -f /tmp/vm_service_uri_host.txt
    echo "Cleanup complete" >> /tmp/flutter_run.log
' || echo "Cleanup completed (some processes may not have existed)"

# Start Xvfb if not running (or restart if resolution changed)
echo "Starting Xvfb..."
docker exec "$CONTAINER_NAME" bash -c "
    # Check if Xvfb is running with correct resolution
    if pgrep -x Xvfb > /dev/null; then
        # Check current resolution
        CURRENT_RES=\$(xdpyinfo -display :99 2>/dev/null | grep dimensions | awk '{print \$2}' || echo '')
        if [ \"\$CURRENT_RES\" != \"600x1024\" ]; then
            echo 'Restarting Xvfb with portrait resolution (600x1024)...'
            pkill -x Xvfb
            sleep 1
        else
            echo 'Xvfb already running with correct resolution'
        fi
    fi
    
    if ! pgrep -x Xvfb > /dev/null; then
        # Use portrait orientation: 600x1024 (phone-like aspect ratio)
        Xvfb :99 -screen 0 600x1024x24 > /dev/null 2>&1 &
        sleep 2
        echo 'Xvfb started with resolution 600x1024 (portrait)'
    fi
"

# Start VNC server if not running
echo "Starting VNC server..."
docker exec "$CONTAINER_NAME" bash -c "
    # Kill any existing VNC server to ensure clean start
    pkill -x x11vnc 2>/dev/null || true
    sleep 1
    
    export DISPLAY=:99
    
    # Wait for Xvfb to be ready
    for i in {1..10}; do
        if xdpyinfo -display :99 > /dev/null 2>&1; then
            break
        fi
        sleep 0.5
    done
    
    # Set VNC password to 'horcrux' (for development)
    # Store password in /tmp/.vnc_passwd
    x11vnc -storepasswd horcrux /tmp/.vnc_passwd > /dev/null 2>&1
    
    # Start VNC server with basic, reliable flags
    x11vnc -display :99 \
        -rfbauth /tmp/.vnc_passwd \
        -listen 0.0.0.0 \
        -rfbport 5900 \
        -forever \
        -shared \
        -noxdamage \
        -noxfixes \
        -noxrecord \
        -noxrandr \
        -noxinerama \
        -cursor most \
        > /tmp/x11vnc.log 2>&1 &
    
    VNC_PID=\$!
    sleep 2
    
    # Verify VNC server is listening
    if netstat -tlnp 2>/dev/null | grep -q ':5900' || ss -tlnp 2>/dev/null | grep -q ':5900'; then
        echo 'VNC server started successfully on port 5900'
        echo 'Connect with any VNC client to: localhost:5900'
        echo 'Password: horcrux'
    else
        echo 'WARNING: VNC server may not have started properly'
        echo 'Check logs: docker exec $CONTAINER_NAME cat /tmp/x11vnc.log'
    fi
"

# Create the build and run script inside the container
echo "Creating build script in container..."
docker exec -i "$CONTAINER_NAME" bash << 'SCRIPTEOF'
cat > /tmp/run_flutter_build.sh << 'INNEREOF'
#!/bin/bash
cd /workspace
    
    echo 'Starting build process...' >> /tmp/flutter_run.log
    
    # Clean previous builds
    echo 'Cleaning previous builds...' >> /tmp/flutter_run.log
    flutter clean >> /tmp/flutter_run.log 2>&1 || echo 'Clean failed (non-fatal)' >> /tmp/flutter_run.log
    
    # Build the app
    echo 'Building Flutter app...' >> /tmp/flutter_run.log
    flutter build linux --debug >> /tmp/flutter_run.log 2>&1 || { echo 'Build failed!' >> /tmp/flutter_run.log; exit 1; }
    
    # Ensure bundle directory exists with executable
    BUNDLE_DIR="build/linux/arm64/debug/bundle"
    INTERMEDIATE_DIR="build/linux/arm64/debug/intermediates_do_not_run"
    BUILD_DIR="build/linux/arm64/debug"
    
    # Run cmake install to create bundle with correct prefix
    echo 'Running cmake install to create bundle...' >> /tmp/flutter_run.log
    if [ -d "$BUILD_DIR" ]; then
        cd "$BUILD_DIR" || { echo 'ERROR: Failed to cd to BUILD_DIR' >> /tmp/flutter_run.log; exit 1; }
        # Force install prefix to bundle directory using absolute path
        ABS_BUNDLE=$(pwd)/bundle
        echo "Using bundle directory: $ABS_BUNDLE" >> /tmp/flutter_run.log
        
        # Run cmake configure
        if ! cmake -DCMAKE_INSTALL_PREFIX="$ABS_BUNDLE" . >> /tmp/flutter_run.log 2>&1; then
            echo 'WARNING: cmake configure failed, continuing with manual bundle creation...' >> /tmp/flutter_run.log
        else
            echo 'cmake configure succeeded' >> /tmp/flutter_run.log
        fi
        
        # Run cmake install
        if ! cmake --install . --component Runtime >> /tmp/flutter_run.log 2>&1; then
            echo 'WARNING: cmake install failed, will try manual bundle creation...' >> /tmp/flutter_run.log
        else
            echo 'cmake install completed' >> /tmp/flutter_run.log
        fi
        
        cd /workspace || { echo 'ERROR: Failed to cd back to workspace' >> /tmp/flutter_run.log; exit 1; }
        
        # Verify bundle was created
        if [ ! -f "$BUNDLE_DIR/horcrux" ]; then
            echo 'cmake install did not create bundle, creating manually...' >> /tmp/flutter_run.log
            mkdir -p "$BUNDLE_DIR/lib" "$BUNDLE_DIR/data"
            
            if [ -f "$INTERMEDIATE_DIR/horcrux" ]; then
                cp "$INTERMEDIATE_DIR/horcrux" "$BUNDLE_DIR/"
                chmod +x "$BUNDLE_DIR/horcrux"
                
                # Copy libraries
                [ -d "$INTERMEDIATE_DIR/lib" ] && cp -r "$INTERMEDIATE_DIR/lib/"* "$BUNDLE_DIR/lib/" 2>>/tmp/flutter_run.log || true
                [ -f "$BUILD_DIR/flutter/libflutter_linux_gtk.so" ] && cp "$BUILD_DIR/flutter/libflutter_linux_gtk.so" "$BUNDLE_DIR/lib/" 2>>/tmp/flutter_run.log || true
                [ -d "$BUILD_DIR/flutter_assets" ] && cp -r "$BUILD_DIR/flutter_assets" "$BUNDLE_DIR/data/" 2>>/tmp/flutter_run.log || true
                [ -f "$BUILD_DIR/flutter/icudtl.dat" ] && cp "$BUILD_DIR/flutter/icudtl.dat" "$BUNDLE_DIR/data/" 2>>/tmp/flutter_run.log || true
                
                echo 'Bundle created manually' >> /tmp/flutter_run.log
            else
                echo 'ERROR: Intermediate executable not found, cannot create bundle manually' >> /tmp/flutter_run.log
            fi
        else
            echo 'Bundle verified: executable exists' >> /tmp/flutter_run.log
        fi
    else
        echo 'ERROR: BUILD_DIR does not exist' >> /tmp/flutter_run.log
        exit 1
    fi
    
    # Verify bundle executable exists
    echo 'Verifying bundle executable...' >> /tmp/flutter_run.log
    if [ ! -f "$BUNDLE_DIR/horcrux" ] || [ ! -x "$BUNDLE_DIR/horcrux" ]; then
        echo 'ERROR: Bundle executable not found or not executable' >> /tmp/flutter_run.log
        echo "BUNDLE_DIR: $BUNDLE_DIR" >> /tmp/flutter_run.log
        ls -la "$BUNDLE_DIR/" >> /tmp/flutter_run.log 2>&1 || true
        exit 1
    fi
    echo 'Bundle executable verified successfully' >> /tmp/flutter_run.log
    
    # Create a wrapper script in /tmp that Flutter can find via PATH
    ABS_BUNDLE=$(cd "$BUNDLE_DIR" && pwd)
    cat > /tmp/horcrux_wrapper.sh << EOFWRAPPER
#!/bin/bash
cd "$ABS_BUNDLE"
export LD_LIBRARY_PATH="$ABS_BUNDLE/lib:\$LD_LIBRARY_PATH"
exec "$ABS_BUNDLE/horcrux" "\$@"
EOFWRAPPER
    chmod +x /tmp/horcrux_wrapper.sh
    chmod +x /tmp/horcrux_wrapper.sh
    
    # Create symlink in /tmp (which is typically in PATH)
    ln -sf "$ABS_BUNDLE/horcrux" /tmp/horcrux 2>/dev/null || true
    
    # Ensure we're in workspace root
    cd /workspace
    
    # Set environment
    export DISPLAY=:99
    export PATH="/tmp:$ABS_BUNDLE:/opt/flutter/bin:$PATH"
    export LD_LIBRARY_PATH="$ABS_BUNDLE/lib:$LD_LIBRARY_PATH"
    
    echo "Bundle ready at: $ABS_BUNDLE" >> /tmp/flutter_run.log
    echo "Environment variables set:" >> /tmp/flutter_run.log
    echo "  DISPLAY=$DISPLAY" >> /tmp/flutter_run.log
    echo "  PATH=$PATH" >> /tmp/flutter_run.log
    echo "  LD_LIBRARY_PATH=$LD_LIBRARY_PATH" >> /tmp/flutter_run.log
    echo "Running Flutter app..." >> /tmp/flutter_run.log
    
    # Try flutter run - it should find the bundle now
    # Use --host-vmservice-port to specify a fixed port for VM service
    # This makes it easier to configure Docker port forwarding
    # Disable DDS to avoid connection issues, or try with --dds-port
    flutter run -d linux --debug --host-vmservice-port=8181 --no-dds >> /tmp/flutter_run.log 2>&1 &
    FLUTTER_PID=$!
    echo "Flutter run started with PID: $FLUTTER_PID" >> /tmp/flutter_run.log
    
    # Wait for Flutter to start and extract the VM service port and path
    # Give Flutter time to start (at least 10 seconds)
    sleep 10
    
    # Retry up to 20 times (100 seconds total) to find VM service
    VM_SERVICE_LINE=""
    for i in {1..20}; do
        sleep 5
        # Get the most recent VM service line
        VM_SERVICE_LINE=$(grep -i 'A Dart VM Service' /tmp/flutter_run.log 2>/dev/null | tail -1)
        if [ -n "$VM_SERVICE_LINE" ]; then
            echo "Found VM service line: $VM_SERVICE_LINE" >> /tmp/flutter_run.log
            break
        fi
        echo "Waiting for VM service... (attempt $i/20)" >> /tmp/flutter_run.log
    done
    
    if [ -n "$VM_SERVICE_LINE" ]; then
        # Extract port: http://127.0.0.1:PORT/PATH
        # Pattern: http://127.0.0.1:PORT/PATH
        # Use sed to extract just the port number after the colon
        VM_PORT=$(echo "$VM_SERVICE_LINE" | sed -n 's|.*http://127\.0\.0\.1:\([0-9]\+\).*|\1|p')
        # Extract path: /PATH (everything after the port)
        VM_PATH=$(echo "$VM_SERVICE_LINE" | sed -n 's|.*http://127\.0\.0\.1:[0-9]\+\(/[^ ]*\).*|\1|p')
        
        if [ -n "$VM_PORT" ] && [ -n "$VM_PATH" ]; then
            echo "VM service detected on port $VM_PORT, path $VM_PATH" >> /tmp/flutter_run.log
            
            # Kill any existing socat proxy
            pkill -f 'socat TCP-LISTEN:8182' 2>/dev/null || true
            sleep 1
            
            # Use socat to proxy from 0.0.0.0:8182 (accessible from host) to 127.0.0.1:VM_PORT (Flutter's service)
            # This allows connections from outside the container via Docker port forwarding
            # We use port 8182 to avoid conflicts with Flutter's dynamic port
            socat TCP-LISTEN:8182,bind=0.0.0.0,reuseaddr,fork TCP:127.0.0.1:$VM_PORT >> /tmp/socat_proxy.log 2>&1 &
            SOCAT_PID=$!
            echo "Started socat proxy on 0.0.0.0:8182 forwarding to 127.0.0.1:$VM_PORT (PID: $SOCAT_PID)" >> /tmp/flutter_run.log
            
            # Build the proxied URI: ws://localhost:8182/PATH/ws
            # Remove trailing slash from path if present, then add /ws
            VM_PATH_CLEAN=$(echo "$VM_PATH" | sed 's|/$||')
            VM_URI="ws://localhost:8182${VM_PATH_CLEAN}/ws"
            echo "$VM_URI" > /tmp/vm_service_uri_host.txt
            echo "VM service accessible via proxy at $VM_URI" >> /tmp/flutter_run.log
        else
            echo "WARNING: Could not extract VM service port or path from: $VM_SERVICE_LINE" >> /tmp/flutter_run.log
            echo "  Extracted port: $VM_PORT" >> /tmp/flutter_run.log
            echo "  Extracted path: $VM_PATH" >> /tmp/flutter_run.log
        fi
    else
        echo "WARNING: Could not find VM service line in logs after 100 seconds" >> /tmp/flutter_run.log
        echo "Last 20 lines of log:" >> /tmp/flutter_run.log
        tail -20 /tmp/flutter_run.log >> /tmp/flutter_run.log 2>&1 || true
    fi
    
    echo "Script completed at: $(date)" >> /tmp/flutter_run.log
INNEREOF
chmod +x /tmp/run_flutter_build.sh
SCRIPTEOF

# Now run the script in background
echo "Starting Flutter build and run in background..."
docker exec -d "$CONTAINER_NAME" bash /tmp/run_flutter_build.sh

echo ""
echo "Flutter app is starting in the background."
echo ""
echo "Waiting a few seconds for Flutter to initialize..."
sleep 5

echo ""
echo "To get the VM service URI (for connecting from host), run:"
echo "  ./scripts/get-vm-uri.sh"
echo ""
echo "This script will wait up to 60 seconds for the VM service URI to appear."
echo ""
echo "To view Flutter logs in real-time:"
echo "  docker exec $CONTAINER_NAME tail -f /tmp/flutter_run.log"
echo ""
echo "To check if Flutter is running:"
echo "  docker exec $CONTAINER_NAME ps aux | grep flutter"
echo ""
echo "To stop the app:"
echo "  docker exec $CONTAINER_NAME pkill -f 'flutter run'"
