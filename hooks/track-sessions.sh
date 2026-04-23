#!/bin/bash
# Claude Code hook — tracks active sessions by heartbeat.
# Fires on UserPromptSubmit and Stop events.
# Activity window is configurable via CLAUDE_PULSE_WINDOW (default: 30 min).

# Load config
CLAUDE_PULSE_WINDOW=1800
[ -f "$HOME/.config/claude-pulse/config" ] && source "$HOME/.config/claude-pulse/config"

SESSION_DIR="/tmp/claude-activity"
mkdir -p "$SESSION_DIR"

# Walk up the process tree to find the `claude` ancestor. Claude Code 2.1.117+
# spawns hooks through an ephemeral intermediate process, so $PPID is that
# short-lived shell rather than the long-lived claude pid we want to track.
CLAUDE_PID=""
cur=$PPID
for _ in 1 2 3 4 5 6 7 8; do
    [ -z "$cur" ] || [ "$cur" = "1" ] && break
    comm=$(ps -p "$cur" -o comm= 2>/dev/null | tr -d ' ')
    if [ "$comm" = "claude" ]; then
        CLAUDE_PID=$cur
        break
    fi
    cur=$(ps -p "$cur" -o ppid= 2>/dev/null | tr -d ' ')
done
CLAUDE_PID=${CLAUDE_PID:-$PPID}

# Update this session's timestamp, keyed on the claude pid
echo "$(date +%s)" > "$SESSION_DIR/$CLAUDE_PID"

# Count sessions active within the configured window
CUTOFF=$(($(date +%s) - CLAUDE_PULSE_WINDOW))
COUNT=0
for f in "$SESSION_DIR"/*; do
    [ -f "$f" ] || continue
    TS=$(cat "$f" 2>/dev/null)
    [ -n "$TS" ] && [ "$TS" -gt "$CUTOFF" ] && COUNT=$((COUNT + 1))
done

echo "$(date '+%Y-%m-%d %H:%M:%S') — $COUNT active Claude session(s)" > /tmp/claude-active-sessions.txt
