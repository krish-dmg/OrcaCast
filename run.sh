#!/usr/bin/env bash
set -e

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
cd "$DIR"

# Clean any orphaned processes
pkill -9 -f "OrcaCast" 2>/dev/null || true
pkill -9 -f "ZenCast" 2>/dev/null || true
defaults -currentHost write com.apple.controlcenter AirplayReceiverEnabled -bool false 2>/dev/null || true
killall ControlCenter 2>/dev/null || true
sleep 0.5

# Clear quarantine flags if cloned or downloaded from GitHub
xattr -cr "$DIR/OrcaCast.app" 2>/dev/null || true

# Ensure recordings directory exists
mkdir -p "$HOME/game recordings"

# Seed default configuration to Application Support if not present
APP_SUPPORT="$HOME/Library/Application Support/OrcaCast"
mkdir -p "$APP_SUPPORT"
if [ ! -f "$APP_SUPPORT/userdefaults.conf" ]; then
  sed "s|\"~/game recordings\"|\"$HOME/game recordings\"|g" "$DIR/config/userdefaults.conf" > "$APP_SUPPORT/userdefaults.conf" 2>/dev/null || cp "$DIR/config/userdefaults.conf" "$APP_SUPPORT/userdefaults.conf"
fi

echo "=== Launching OrcaCast ==="
open -a "$DIR/OrcaCast.app"

# Monitor and immediately position the window on the primary screen when created
(
  for i in {1..60}; do
    sleep 0.5
    STATUS=$(osascript << 'APPLESCRIPT' 2>/dev/null || echo "WAIT"
tell application "System Events"
    if exists (application process "OrcaCast") then
        tell application process "OrcaCast"
            if exists (window "OrcaCast") then
                set pos to position of window "OrcaCast"
                set px to item 1 of pos
                if px > 1440 or px < 0 then
                    set position of window "OrcaCast" to {140, 100}
                    set frontmost to true
                    return "MOVED"
                else
                    set frontmost to true
                    return "IN_PLACE"
                end if
            else if (count of windows) > 0 then
                set pos to position of window 1
                set px to item 1 of pos
                if px > 1440 or px < 0 then
                    set position of window 1 to {140, 100}
                    set frontmost to true
                    return "MOVED"
                else
                    set frontmost to true
                    return "IN_PLACE"
                end if
            end if
        end tell
    end if
    return "WAIT"
end tell
APPLESCRIPT
    )
    if [ "$STATUS" = "IN_PLACE" ] || [ "$STATUS" = "MOVED" ]; then
      break
    fi
  done
) >/dev/null 2>&1 &
