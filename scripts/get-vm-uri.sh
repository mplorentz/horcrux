#!/bin/bash
# Script to get the Marionette VM Service URI from the running Flutter app
# Returns the URI formatted for connecting from the host machine

CONTAINER_NAME="horcrux-cursor-agent"

# Try to get the host-formatted URI first
HOST_URI=$(docker exec "$CONTAINER_NAME" cat /tmp/vm_service_uri_host.txt 2>/dev/null)

if [ -n "$HOST_URI" ]; then
    echo "$HOST_URI"
    exit 0
fi

# Extract from logs - wait longer and try multiple patterns
echo "Waiting for Marionette VM Service URI..." >&2
docker exec -i "$CONTAINER_NAME" bash << 'EXTRACTEOF'
    # Wait up to 60 seconds for VM service URI to appear
    for i in {1..60}; do
        # Check if log file exists and has content
        if [ ! -f /tmp/flutter_run.log ]; then
            sleep 1
            continue
        fi
        
        # Try multiple patterns to find VM service URI
        # Pattern 1: ws://127.0.0.1:PORT/PATH/ws
        VM_URI=$(grep -oE 'ws://127\.0\.0\.1:[0-9]+/[^ ]*/ws' /tmp/flutter_run.log 2>/dev/null | tail -1)
        
        # Pattern 2: ws://127.0.0.1:PORT/PATH (without /ws suffix)
        if [ -z "$VM_URI" ]; then
            VM_URI=$(grep -oE 'ws://127\.0\.0\.1:[0-9]+/[^ ]*' /tmp/flutter_run.log 2>/dev/null | tail -1)
        fi
        
        # Pattern 3: Any ws:// URI
        if [ -z "$VM_URI" ]; then
            VM_URI=$(grep -oE 'ws://[0-9.]+:[0-9]+/[^ ]*' /tmp/flutter_run.log 2>/dev/null | tail -1)
        fi
        
        # Pattern 4: Look for VM service port in DevTools URL
        if [ -z "$VM_URI" ]; then
            # Flutter sometimes outputs: "The Flutter DevTools debugger and profiler on Linux is available at: http://127.0.0.1:9100?uri=ws://127.0.0.1:XXXXX/XXXXX=/ws"
            DEVTOOLS_LINE=$(grep -i 'devtools' /tmp/flutter_run.log 2>/dev/null | grep -i 'uri=' | tail -1)
            if [ -n "$DEVTOOLS_LINE" ]; then
                VM_URI=$(echo "$DEVTOOLS_LINE" | grep -oE 'uri=ws://[^ ]*' | cut -d= -f2)
            fi
        fi
        
        # Pattern 5: Look for "VM Service" or "Observatory" in output
        if [ -z "$VM_URI" ]; then
            VM_SERVICE_LINE=$(grep -iE '(VM Service|Observatory|vm-service|Dart VM service)' /tmp/flutter_run.log 2>/dev/null | tail -1)
            if [ -n "$VM_SERVICE_LINE" ]; then
                VM_URI=$(echo "$VM_SERVICE_LINE" | grep -oE 'ws://[^ ]*' | tail -1)
            fi
        fi
        
        # Pattern 6: Look for "listening on" pattern (common in Dart VM output)
        if [ -z "$VM_URI" ]; then
            LISTENING_LINE=$(grep -iE 'listening on.*ws://' /tmp/flutter_run.log 2>/dev/null | tail -1)
            if [ -n "$LISTENING_LINE" ]; then
                VM_URI=$(echo "$LISTENING_LINE" | grep -oE 'ws://[^ ]*' | tail -1)
            fi
        fi
        
        # Pattern 7: Look for "A Dart VM Service" HTTP URL and convert to WebSocket
        if [ -z "$VM_URI" ]; then
            VM_SERVICE_LINE=$(grep -i 'A Dart VM Service' /tmp/flutter_run.log 2>/dev/null | tail -1)
            if [ -n "$VM_SERVICE_LINE" ]; then
                HTTP_URI=$(echo "$VM_SERVICE_LINE" | grep -oE 'http://127\.0\.0\.1:[0-9]+/[^ ]*' | tail -1)
                if [ -n "$HTTP_URI" ]; then
                    # Convert http:// to ws:// and ensure /ws suffix
                    VM_URI=$(echo "$HTTP_URI" | sed 's|http://|ws://|' | sed 's|/$||' | sed 's|$|/ws|')
                fi
            fi
        fi
        
        # Pattern 8: Check if URI file was created by run-app-in-docker.sh
        if [ -z "$VM_URI" ]; then
            if [ -f /tmp/vm_service_uri_host.txt ]; then
                VM_URI=$(cat /tmp/vm_service_uri_host.txt 2>/dev/null)
            fi
        fi
        
        if [ -n "$VM_URI" ]; then
            # Extract port from URI
            PORT=$(echo "$VM_URI" | grep -oE ':[0-9]+' | head -1 | cut -d: -f2)
            
            # Save for future use
            echo "$VM_URI" > /tmp/vm_service_uri.txt
            [ -n "$PORT" ] && echo "$PORT" > /tmp/vm_service_port.txt
            
            # Format for host access (use localhost since we're port-forwarding)
            if [ -n "$PORT" ]; then
                HOST_URI="ws://localhost:$PORT/ws"
                echo "$HOST_URI" > /tmp/vm_service_uri_host.txt
                echo "$HOST_URI"
            else
                echo "$VM_URI" > /tmp/vm_service_uri_host.txt
                echo "$VM_URI"
            fi
            exit 0
        fi
        
        # Show progress every 5 seconds
        if [ $((i % 5)) -eq 0 ]; then
            echo "Still waiting... (attempt $i/60)" >&2
        fi
        
        sleep 1
    done
    
    # If we get here, show the last few lines of the log for debugging
    echo 'Error: Could not find Marionette VM Service URI in logs after 60 seconds' >&2
    echo 'Last 20 lines of Flutter log:' >&2
    tail -20 /tmp/flutter_run.log >&2
    exit 1
EXTRACTEOF
