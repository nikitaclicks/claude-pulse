#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SETTINGS="$HOME/.claude/settings.json"

echo "Setting up claude-pulse..."

# 1. Install hook script
ln -sf "$SCRIPT_DIR/hooks/track-sessions.sh" "$HOME/.claude/track-sessions.sh"
chmod +x "$SCRIPT_DIR/hooks/track-sessions.sh"
echo "✓ Hook symlinked at ~/.claude/track-sessions.sh"

# 2. Install CLI
mkdir -p "$HOME/.local/bin"
ln -sf "$SCRIPT_DIR/bin/claude-pulse" "$HOME/.local/bin/claude-pulse"
chmod +x "$SCRIPT_DIR/bin/claude-pulse"
echo "✓ CLI symlinked at ~/.local/bin/claude-pulse"

# 3. Install default config (skip if user already has one)
CONFIG_DIR="$HOME/.config/claude-pulse"
mkdir -p "$CONFIG_DIR"
if [ ! -f "$CONFIG_DIR/config" ]; then
    cp "$SCRIPT_DIR/config.default" "$CONFIG_DIR/config"
    echo "✓ Default config installed at ~/.config/claude-pulse/config"
else
    echo "✓ Config already exists at ~/.config/claude-pulse/config — skipping"
fi

# 4. Patch ~/.claude/settings.json
if [ ! -f "$SETTINGS" ]; then
    echo "{}" > "$SETTINGS"
fi

# Use absolute path: Claude Code 2.1.117+ calls hook commands directly
# without a shell, so `~/` is never expanded and tilde paths silently fail.
HOOK_PATH="$HOME/.claude/track-sessions.sh"

if ! command -v jq &> /dev/null; then
    echo ""
    echo "⚠️  jq not found — skipping automatic hook registration."
    echo "   Add the following to $SETTINGS manually:"
    cat <<EOF
{
  "hooks": {
    "UserPromptSubmit": [
      { "hooks": [{ "type": "command", "command": "$HOOK_PATH" }] }
    ],
    "Stop": [
      { "hooks": [{ "type": "command", "command": "$HOOK_PATH" }] }
    ]
  }
}
EOF
else
    HOOK_ENTRY=$(jq -n --arg cmd "$HOOK_PATH" '{hooks:[{type:"command",command:$cmd}]}')

    # Only add hooks if not already registered (idempotent)
    ALREADY=$(jq --arg cmd "$HOOK_PATH" '[.hooks.UserPromptSubmit // [], .hooks.Stop // []] | flatten | map(select(.hooks[]?.command == $cmd)) | length' "$SETTINGS" 2>/dev/null || echo 0)
    if [ "$ALREADY" -gt 0 ]; then
        echo "✓ Hooks already registered in $SETTINGS — skipping"
    else
        UPDATED=$(jq \
            --argjson entry "$HOOK_ENTRY" \
            '.hooks.UserPromptSubmit += [$entry] | .hooks.Stop += [$entry]' \
            "$SETTINGS")
        echo "$UPDATED" > "$SETTINGS"
        echo "✓ Hooks registered in $SETTINGS"
    fi
fi

# 5. PATH reminder
if ! echo "$PATH" | grep -q "$HOME/.local/bin"; then
    echo ""
    echo "⚠️  ~/.local/bin is not in your PATH."
    echo "   Add this to your ~/.zshrc or ~/.bashrc:"
    echo '   export PATH="$HOME/.local/bin:$PATH"'
fi

# 6. GitHub auth reminder
echo ""
echo "Almost done! Authorize GitHub CLI with the 'user' scope:"
echo "  unset GITHUB_TOKEN && gh auth refresh -h github.com -s user"
echo ""
echo "Then restart Claude Code and run: claude-pulse --dry-run"
