# claude-pulse

Broadcast your active Claude Code session count to your GitHub bio via hooks + a tiny shell CLI.

```
🤖 × 3 Claude agents active
```

A Claude Code hook fires on every message sent and every AI response. Each session writes a heartbeat timestamp to disk. `claude-pulse` reads that state and pushes the count to your GitHub bio every 10 minutes.

## Quickstart

```bash
./setup.sh
claude-pulse -d
```

That's it. Your GitHub bio will update automatically as long as the daemon is running.

> **Note:** `setup.sh` requires `jq` for automatic hook registration. If you don't have it: `brew install jq`.

## Requirements

- [Claude Code](https://claude.ai/code)
- [GitHub CLI](https://cli.github.com/) (`gh`) — must be authenticated with the `user` scope:
  ```bash
  unset GITHUB_TOKEN && gh auth refresh -h github.com -s user
  ```
  The `unset` is needed if you have a `GITHUB_TOKEN` env var set (common in dev environments) — it overrides `gh` auth and typically lacks the `user` scope.

## Usage

```bash
claude-pulse              # run immediately + loop every 10 min
claude-pulse -d           # start as background daemon
claude-pulse --stop       # stop daemon + clear GitHub bio
claude-pulse --status     # show daemon status + last log lines
claude-pulse --dry-run    # show current session count without updating GitHub
claude-pulse --no-loop    # run once and exit
claude-pulse --loop 60    # run immediately + loop every 60s
claude-pulse --help       # show all options
```

Daemon logs: `~/.local/share/claude-pulse.log`

## How it works

1. `hooks/track-sessions.sh` is registered as a Claude Code hook for `UserPromptSubmit` and `Stop` events
2. Each hook invocation writes a unix timestamp to `/tmp/claude-activity/<claude-pid>`
3. `claude-pulse` counts files updated within the activity window (default: 30 min) and calls `gh api PATCH /user` to update your bio

```bash
cat /tmp/claude-active-sessions.txt   # last recorded count + timestamp
ls /tmp/claude-activity/              # one file per active session
```

## Configuration

Copy `config.default` to `~/.config/claude-pulse/config`:

```bash
CLAUDE_PULSE_WINDOW=1800    # how long a session stays "active" (seconds)
CLAUDE_PULSE_INTERVAL=600   # how often to push to GitHub bio (seconds)
CLAUDE_PULSE_BIO="🤖 × \$COUNT Claude agents active"  # bio format
```

## Manual setup

If you prefer not to use `setup.sh`:

1. Symlink the hook:
   ```bash
   ln -sf "$PWD/hooks/track-sessions.sh" ~/.claude/track-sessions.sh
   chmod +x hooks/track-sessions.sh
   ```

2. Register it in `~/.claude/settings.json` (use the **absolute path** — Claude
   Code 2.1.117+ invokes hook commands directly without a shell, so `~` is not
   expanded and `~/.claude/...` hooks silently fail to fire):
   ```json
   {
     "hooks": {
       "UserPromptSubmit": [
         { "hooks": [{ "type": "command", "command": "/absolute/path/to/.claude/track-sessions.sh" }] }
       ],
       "Stop": [
         { "hooks": [{ "type": "command", "command": "/absolute/path/to/.claude/track-sessions.sh" }] }
       ]
     }
   }
   ```

3. Symlink the CLI and add it to your PATH:
   ```bash
   ln -sf "$PWD/bin/claude-pulse" ~/.local/bin/claude-pulse
   chmod +x bin/claude-pulse
   echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.zshrc && source ~/.zshrc
   ```

## License

MIT
