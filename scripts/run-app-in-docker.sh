#!/bin/bash
# Script to build, start, and run the Linux version of Horcrux in Docker container with live log streaming
# Press Ctrl+C to stop the app and container

set -e

CONTAINER_NAME="horcrux-cursor-agent"
COMPOSE_FILE=".cursor/docker-compose.yml"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Cleanup function to run on exit
cleanup() {
    echo ""
    echo -e "${YELLOW}Cleaning up...${NC}"
    
    # Stop Flutter app if container is running
    if docker ps | grep -q "$CONTAINER_NAME"; then
        echo "Stopping Flutter app..."
        docker exec "$CONTAINER_NAME" bash -c "
            pkill -f 'flutter run' 2>/dev/null || true
            pkill -f 'horcrux' 2>/dev/null || true
            pkill -f 'socat.*8182' 2>/dev/null || true
        " 2>/dev/null || true
    fi
    
    # Stop and remove container
    echo "Stopping container..."
    cd "$PROJECT_ROOT"
    docker-compose -f "$COMPOSE_FILE" down 2>/dev/null || true
    
    echo -e "${GREEN}Cleanup complete.${NC}"
    exit 0
}

# Set up trap to catch Ctrl+C and cleanup
trap cleanup INT TERM

# Change to project root
cd "$PROJECT_ROOT"

echo -e "${BLUE}════════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}  Horcrux Docker Development Environment${NC}"
echo -e "${BLUE}════════════════════════════════════════════════════════════${NC}"
echo ""

# Step 1: Build the Docker image
echo -e "${GREEN}[1/5] Building Docker image...${NC}"
docker-compose -f "$COMPOSE_FILE" build
echo ""

# Step 2: Start the container
echo -e "${GREEN}[2/5] Starting container...${NC}"
docker-compose -f "$COMPOSE_FILE" up -d

# Wait for container to be ready
echo "Waiting for container to be ready..."
sleep 2

# Verify container is running
if ! docker ps | grep -q "$CONTAINER_NAME"; then
    echo -e "${RED}Error: Container failed to start${NC}"
    exit 1
fi

echo -e "${GREEN}Container is running${NC}"
echo ""

# Step 3: Install dependencies if needed
echo -e "${GREEN}[3/5] Checking Flutter dependencies...${NC}"
docker exec "$CONTAINER_NAME" bash -c "
    cd /workspace
    if [ ! -d 'build' ] || [ ! -f 'pubspec.lock' ]; then
        echo 'Installing Flutter dependencies...'
        flutter pub get
    else
        echo 'Dependencies already installed'
    fi
" || {
    echo -e "${YELLOW}Warning: Dependency check failed, continuing anyway...${NC}"
}
echo ""

# Step 4: Start Xvfb, VNC, and Flutter app
echo -e "${GREEN}[4/5] Starting Xvfb, VNC server, and Flutter app...${NC}"

# Start Xvfb if not running
docker exec "$CONTAINER_NAME" bash -c "
    if ! pgrep -x Xvfb > /dev/null; then
        Xvfb :99 -screen 0 600x1024x24 > /dev/null 2>&1 &
        sleep 2
        echo 'Xvfb started with resolution 600x1024 (portrait)'
    else
        CURRENT_RES=\$(xdpyinfo -display :99 2>/dev/null | grep dimensions | awk '{print \$2}' || echo '')
        if [ \"\$CURRENT_RES\" != \"600x1024\" ]; then
            pkill -x Xvfb
            sleep 1
            Xvfb :99 -screen 0 600x1024x24 > /dev/null 2>&1 &
            sleep 2
        fi
    fi
"

# Start VNC server
docker exec "$CONTAINER_NAME" bash -c "
    pkill -x x11vnc 2>/dev/null || true
    sleep 1
    export DISPLAY=:99
    for i in {1..10}; do
        if xdpyinfo -display :99 > /dev/null 2>&1; then
            break
        fi
        sleep 0.5
    done
    x11vnc -storepasswd horcrux /tmp/.vnc_passwd > /dev/null 2>&1
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
    sleep 2
    echo 'VNC server started on port 5900 (password: horcrux)'
"

# Create and run the Flutter build/run script
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
        ABS_BUNDLE=$(pwd)/bundle
        echo "Using bundle directory: $ABS_BUNDLE" >> /tmp/flutter_run.log
        
        if ! cmake -DCMAKE_INSTALL_PREFIX="$ABS_BUNDLE" . >> /tmp/flutter_run.log 2>&1; then
            echo 'WARNING: cmake configure failed, continuing with manual bundle creation...' >> /tmp/flutter_run.log
        fi
        
        if ! cmake --install . --component Runtime >> /tmp/flutter_run.log 2>&1; then
            echo 'WARNING: cmake install failed, will try manual bundle creation...' >> /tmp/flutter_run.log
        fi
        
        cd /workspace || { echo 'ERROR: Failed to cd back to workspace' >> /tmp/flutter_run.log; exit 1; }
        
        if [ ! -f "$BUNDLE_DIR/horcrux" ]; then
            echo 'cmake install did not create bundle, creating manually...' >> /tmp/flutter_run.log
            mkdir -p "$BUNDLE_DIR/lib" "$BUNDLE_DIR/data"
            
            if [ -f "$INTERMEDIATE_DIR/horcrux" ]; then
                cp "$INTERMEDIATE_DIR/horcrux" "$BUNDLE_DIR/"
                chmod +x "$BUNDLE_DIR/horcrux"
                [ -d "$INTERMEDIATE_DIR/lib" ] && cp -r "$INTERMEDIATE_DIR/lib/"* "$BUNDLE_DIR/lib/" 2>>/tmp/flutter_run.log || true
                [ -f "$BUILD_DIR/flutter/libflutter_linux_gtk.so" ] && cp "$BUILD_DIR/flutter/libflutter_linux_gtk.so" "$BUNDLE_DIR/lib/" 2>>/tmp/flutter_run.log || true
                [ -d "$BUILD_DIR/flutter_assets" ] && cp -r "$BUILD_DIR/flutter_assets" "$BUNDLE_DIR/data/" 2>>/tmp/flutter_run.log || true
                [ -f "$BUILD_DIR/flutter/icudtl.dat" ] && cp "$BUILD_DIR/flutter/icudtl.dat" "$BUNDLE_DIR/data/" 2>>/tmp/flutter_run.log || true
                echo 'Bundle created manually' >> /tmp/flutter_run.log
            fi
        fi
    fi
    
    # Verify bundle executable exists
    if [ ! -f "$BUNDLE_DIR/horcrux" ] || [ ! -x "$BUNDLE_DIR/horcrux" ]; then
        echo 'ERROR: Bundle executable not found or not executable' >> /tmp/flutter_run.log
        exit 1
    fi
    
    ABS_BUNDLE=$(cd "$BUNDLE_DIR" && pwd)
    cd /workspace
    export DISPLAY=:99
    export PATH="/tmp:$ABS_BUNDLE:/opt/flutter/bin:$PATH"
    export LD_LIBRARY_PATH="$ABS_BUNDLE/lib:$LD_LIBRARY_PATH"
    
    echo "Running Flutter app with hot reload support..." >> /tmp/flutter_run.log
    # Use flutter run with file watching enabled (default) for hot reload
    # The app will automatically hot reload when files in lib/ change
    flutter run -d linux --debug --host-vmservice-port=8181 --no-dds >> /tmp/flutter_run.log 2>&1 &
    FLUTTER_PID=$!
    echo "Flutter run started with PID: $FLUTTER_PID (hot reload enabled)" >> /tmp/flutter_run.log
    echo "$FLUTTER_PID" > /tmp/flutter_pid.txt
    
    # Wait for VM service
    sleep 10
    VM_SERVICE_LINE=""
    for i in {1..20}; do
        sleep 5
        VM_SERVICE_LINE=$(grep -i 'A Dart VM Service' /tmp/flutter_run.log 2>/dev/null | tail -1)
        if [ -n "$VM_SERVICE_LINE" ]; then
            break
        fi
    done
    
    if [ -n "$VM_SERVICE_LINE" ]; then
        VM_PORT=$(echo "$VM_SERVICE_LINE" | sed -n 's|.*http://127\.0\.0\.1:\([0-9]\+\).*|\1|p')
        VM_PATH=$(echo "$VM_SERVICE_LINE" | sed -n 's|.*http://127\.0\.0\.1:[0-9]\+\(/[^ ]*\).*|\1|p')
        
        if [ -n "$VM_PORT" ] && [ -n "$VM_PATH" ]; then
            pkill -f 'socat TCP-LISTEN:8182' 2>/dev/null || true
            sleep 1
            socat TCP-LISTEN:8182,bind=0.0.0.0,reuseaddr,fork TCP:127.0.0.1:$VM_PORT >> /tmp/socat_proxy.log 2>&1 &
            VM_PATH_CLEAN=$(echo "$VM_PATH" | sed 's|/$||')
            VM_URI="ws://localhost:8182${VM_PATH_CLEAN}/ws"
            echo "$VM_URI" > /tmp/vm_service_uri_host.txt
            echo "VM service accessible at $VM_URI" >> /tmp/flutter_run.log
        fi
    fi
    
    echo "Script completed at: $(date)" >> /tmp/flutter_run.log
INNEREOF
chmod +x /tmp/run_flutter_build.sh
SCRIPTEOF

# Run the build script in background
docker exec -d "$CONTAINER_NAME" bash /tmp/run_flutter_build.sh

echo ""
echo -e "${GREEN}[5/5] Streaming logs (Press Ctrl+C to stop)...${NC}"
echo ""
echo -e "${BLUE}VNC Server:${NC} localhost:5900 (password: horcrux)"
echo -e "${BLUE}VM Service:${NC} Check logs for URI"
echo -e "${BLUE}Hot Reload:${NC} Manual trigger: ./scripts/hot-reload-docker.sh"
echo ""

# Step 5: Stream logs
docker exec "$CONTAINER_NAME" tail -f /tmp/flutter_run.log
