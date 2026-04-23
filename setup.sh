#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SETTINGS="$HOME/.claude/settings.json"

echo "Setting up claude-pulse..."

# 1. Install CLI
mkdir -p "$HOME/.local/bin"
ln -sf "$SCRIPT_DIR/bin/claude-pulse" "$HOME/.local/bin/claude-pulse"
chmod +x "$SCRIPT_DIR/bin/claude-pulse"
echo "✓ CLI symlinked at ~/.local/bin/claude-pulse"

# 2. Install default config (skip if user already has one)
CONFIG_DIR="$HOME/.config/claude-pulse"
mkdir -p "$CONFIG_DIR"
if [ ! -f "$CONFIG_DIR/config" ]; then
    cp "$SCRIPT_DIR/config.default" "$CONFIG_DIR/config"
    echo "✓ Default config installed at ~/.config/claude-pulse/config"
else
    echo "✓ Config already exists at ~/.config/claude-pulse/config — skipping"
fi

# 3. Unregister legacy track-sessions.sh hook entries if upgrading — the new
# counter reads Claude Code's own per-session transcript mtime directly and
# no longer needs a hook (which also sidesteps the 2.1.117 tilde-expansion
# regression in Claude Code's hook runner).
if command -v jq &> /dev/null && [ -f "$SETTINGS" ]; then
    BEFORE=$(jq '.hooks // {}' "$SETTINGS" 2>/dev/null || echo '{}')
    UPDATED=$(jq '
      def strip_track_sessions:
        map(
          .hooks |= map(select((.command // "") | test("track-sessions\\.sh$") | not))
        )
        | map(select((.hooks // []) | length > 0));
      if .hooks then
        .hooks.UserPromptSubmit |= (if . then strip_track_sessions else . end)
        | .hooks.Stop           |= (if . then strip_track_sessions else . end)
      else . end
    ' "$SETTINGS")
    echo "$UPDATED" > "$SETTINGS"
    AFTER=$(jq '.hooks // {}' "$SETTINGS")
    if [ "$BEFORE" != "$AFTER" ]; then
        echo "✓ Removed legacy track-sessions hook from $SETTINGS (no longer needed)"
    fi
fi

# 4. PATH reminder
if ! echo "$PATH" | grep -q "$HOME/.local/bin"; then
    echo ""
    echo "⚠️  ~/.local/bin is not in your PATH."
    echo "   Add this to your ~/.zshrc or ~/.bashrc:"
    echo '   export PATH="$HOME/.local/bin:$PATH"'
fi

# 5. GitHub auth reminder
echo ""
echo "Almost done! Authorize GitHub CLI with the 'user' scope:"
echo "  unset GITHUB_TOKEN && gh auth refresh -h github.com -s user"
echo ""
echo "Then run: claude-pulse --dry-run"
