#!/bin/bash
# Setup X11 virtual display, D-Bus session, and gnome-keyring inside a Docker container.
# Required by flutter_secure_storage (libsecret) and the Horcrux app at runtime.
#
# Usage: source /setup-x11.sh
#   (must be sourced, not executed, so environment variables persist in the calling shell)

set -e

# Start Xvfb if not already running
if ! pgrep -x Xvfb > /dev/null; then
    Xvfb :99 -screen 0 600x1024x24 > /dev/null 2>&1 &
    sleep 1
    echo "Xvfb started (600x1024 portrait)"
else
    echo "Xvfb already running"
fi
export DISPLAY=:99

# Start D-Bus session if not already running
if [ -z "$DBUS_SESSION_BUS_ADDRESS" ]; then
    eval "$(dbus-launch --sh-syntax)"
    export DBUS_SESSION_BUS_ADDRESS
    echo "D-Bus session started"
else
    echo "D-Bus session already active"
fi

# Unlock and start gnome-keyring for libsecret
mkdir -p ~/.cache ~/.local/share/keyrings
printf '\n' | gnome-keyring-daemon --unlock 2>/dev/null || true
gnome-keyring-daemon --start --components=secrets --daemonize 2>/dev/null || true
echo "gnome-keyring ready"

# Start notification daemon (for flutter_local_notifications)
if ! pgrep -f notification-daemon > /dev/null; then
    notification-daemon 2>/dev/null &
    sleep 0.5
    echo "notification-daemon started"
fi

echo "X11 environment ready (DISPLAY=$DISPLAY)"
