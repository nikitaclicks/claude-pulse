#!/bin/bash
# Claude Code hook — tracks active sessions by heartbeat.
# Fires on UserPromptSubmit and Stop events.
# Activity window is configurable via CLAUDE_PULSE_WINDOW (default: 30 min).

# Load config
CLAUDE_PULSE_WINDOW=1800
[ -f "$HOME/.config/claude-pulse/config" ] && source "$HOME/.config/claude-pulse/config"

SESSION_DIR="/tmp/claude-activity"
mkdir -p "$SESSION_DIR"

# Update this session's timestamp (PPID = the claude process)
echo "$(date +%s)" > "$SESSION_DIR/$PPID"

# Count sessions active within the configured window
CUTOFF=$(($(date +%s) - CLAUDE_PULSE_WINDOW))
COUNT=0
for f in "$SESSION_DIR"/*; do
    [ -f "$f" ] || continue
    TS=$(cat "$f" 2>/dev/null)
    [ -n "$TS" ] && [ "$TS" -gt "$CUTOFF" ] && COUNT=$((COUNT + 1))
done

echo "$(date '+%Y-%m-%d %H:%M:%S') — $COUNT active Claude session(s)" > /tmp/claude-active-sessions.txt
