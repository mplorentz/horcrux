#!/bin/bash
# Launch two Horcrux instances (owner + steward) in Docker for end-to-end testing.
#
# Usage:
#   ./scripts/run-two-instances.sh           # Build + start + launch both apps
#   ./scripts/run-two-instances.sh --attach   # Also stream owner logs (Ctrl+C to stop)
#
# After launch, check logs for VM service URIs:
#   docker exec horcrux-owner grep 'ws://' /tmp/flutter_run.log
#   docker exec horcrux-steward grep 'ws://' /tmp/flutter_run.log
#
# Cleanup:
#   docker compose -f .cursor/docker-compose.two-instance.yml down -v

set -e

COMPOSE_FILE=".cursor/docker-compose.two-instance.yml"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
ATTACH="${1:-}"

RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

cleanup() {
    echo ""
    echo -e "${YELLOW}Stopping containers...${NC}"
    cd "$PROJECT_ROOT"
    docker compose -f "$COMPOSE_FILE" down 2>/dev/null || true
    echo -e "${GREEN}Done.${NC}"
    exit 0
}
trap cleanup INT TERM

cd "$PROJECT_ROOT"

echo -e "${BLUE}════════════════════════════════════════════════════════════${NC}"
echo -e "${BLUE}  Horcrux Two-Instance Test Environment${NC}"
echo -e "${BLUE}════════════════════════════════════════════════════════════${NC}"

# Build and start
echo -e "${GREEN}[1/3] Building and starting containers...${NC}"
docker compose -f "$COMPOSE_FILE" up -d --build
sleep 2

# Fix ownership (container runs as root, host user may differ)
for container in horcrux-owner horcrux-steward; do
    docker exec "$container" chown -R 1001:1001 /workspace/ 2>/dev/null || true
done

# Install deps
echo -e "${GREEN}[2/3] Installing Flutter dependencies...${NC}"
for container in horcrux-owner horcrux-steward; do
    docker exec "$container" bash -c "cd /workspace && flutter pub get" > /dev/null 2>&1 &
done
wait
echo "Dependencies installed in both containers"

# Launch apps
echo -e "${GREEN}[3/3] Launching Flutter apps...${NC}"

docker exec -d horcrux-owner bash -c "\
    source /workspace/scripts/setup-x11.sh && \
    cd /workspace && \
    flutter run -d linux --debug --host-vmservice-port=8181 --no-dds \
    &> /tmp/flutter_run.log"

docker exec -d horcrux-steward bash -c "\
    source /workspace/scripts/setup-x11.sh && \
    cd /workspace && \
    flutter run -d linux --debug --host-vmservice-port=9181 --no-dds \
    &> /tmp/flutter_run.log"

echo ""
echo -e "${BLUE}Waiting for apps to start (this takes ~2-3 minutes)...${NC}"
echo ""

# Wait for VM service URIs
for i in $(seq 1 36); do
    OWNER_URI=$(docker exec horcrux-owner grep -o 'ws://[^\ ]*' /tmp/flutter_run.log 2>/dev/null | head -1 || true)
    STEWARD_URI=$(docker exec horcrux-steward grep -o 'ws://[^\ ]*' /tmp/flutter_run.log 2>/dev/null | head -1 || true)
    if [ -n "$OWNER_URI" ] && [ -n "$STEWARD_URI" ]; then
        echo -e "${GREEN}Both apps are running!${NC}"
        echo ""
        echo -e "${BLUE}Owner VM service:${NC}    $OWNER_URI"
        echo -e "${BLUE}Steward VM service:${NC}  $STEWARD_URI"
        echo ""
        echo "Connect Marionette MCP to these URIs to interact with each app."
        echo "Use 'docker exec horcrux-owner tail -f /tmp/flutter_run.log' for owner logs."
        echo "Use 'docker exec horcrux-steward tail -f /tmp/flutter_run.log' for steward logs."
        break
    fi
    sleep 5
done

if [ "$ATTACH" = "--attach" ]; then
    echo ""
    echo -e "${YELLOW}Streaming owner logs (Ctrl+C to stop both containers)...${NC}"
    docker exec horcrux-owner tail -f /tmp/flutter_run.log
fi
