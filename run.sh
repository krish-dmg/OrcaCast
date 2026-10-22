#!/usr/bin/env bash
set -e

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
cd "$DIR"

# Clean any orphaned processes
pkill -9 -f "OrcaCast" 2>/dev/null || true
pkill -9 -f "ZenCast" 2>/dev/null || true
sleep 0.5

echo "=== Launching OrcaCast ==="
open -a "$DIR/OrcaCast.app"

# Monitor and immediately position the window on the primary screen when created
(
  for i in {1..240}; do
    sleep 0.5
    STATUS=$(osascript << 'APPLESCRIPT' 2>/dev/null || echo "WAIT"
tell application "System Events"
    if exists (application process "OrcaCast") then
        tell application process "OrcaCast"
            if (count of windows) > 0 then
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
      # Ensure it stays settled
      sleep 0.5
      osascript -e 'tell application "System Events" to tell application process "OrcaCast" to set position of window 1 to {140, 100}' 2>/dev/null || true
      break
    fi
  done
) >/dev/null 2>&1 &
