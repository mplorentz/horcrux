#!/bin/bash
# Script to trigger hot reload in the Flutter app running in Docker

CONTAINER_NAME="horcrux-cursor-agent"

# Check if container is running
if ! docker ps | grep -q "$CONTAINER_NAME"; then
    echo "Error: Container $CONTAINER_NAME is not running."
    exit 1
fi

# Send SIGUSR1 to Flutter process to trigger hot reload
echo "Triggering hot reload..."
docker exec "$CONTAINER_NAME" bash -c "
    # Try to get PID from file first, then fall back to pgrep
    FLUTTER_PID=\$(cat /tmp/flutter_pid.txt 2>/dev/null || pgrep -f 'flutter run' | head -1)
    if [ -n \"\$FLUTTER_PID\" ]; then
        if kill -USR1 \"\$FLUTTER_PID\" 2>/dev/null; then
            echo \"Hot reload triggered (PID: \$FLUTTER_PID)\"
            echo \"Check logs: docker exec $CONTAINER_NAME tail -20 /tmp/flutter_run.log\"
        else
            echo \"Failed to trigger hot reload. Process may have exited.\"
            exit 1
        fi
    else
        echo \"Error: Flutter process not found. Is the app running?\"
        echo \"Check if app is running: docker exec $CONTAINER_NAME ps aux | grep flutter\"
        exit 1
    fi
"
