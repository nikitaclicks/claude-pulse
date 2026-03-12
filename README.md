# claude-pulse

Track how many Claude Code sessions you have active and broadcast that to your GitHub bio.

```
🤖 × 3 Claude agents active
```

## How it works

A Claude Code hook fires on every user message and every AI response. Each session writes a heartbeat timestamp to `/tmp/claude-activity/<pid>`. A companion CLI reads that state and pushes it to your GitHub bio.

**Active** = had activity in the last 30 minutes (configurable).

## Requirements

- [Claude Code](https://claude.ai/code)
- [GitHub CLI](https://cli.github.com/) (`gh`) authenticated with `user` scope

## Setup

```bash
./setup.sh
```

Then authorize `gh` with the `user` scope (required to update your bio):

```bash
unset GITHUB_TOKEN && gh auth refresh -h github.com -s user
```

Open a new Claude Code session for the hooks to take effect.

## Manual setup

1. **Install the hook script:**
   ```bash
   ln -sf "$PWD/hooks/track-sessions.sh" ~/.claude/track-sessions.sh
   chmod +x hooks/track-sessions.sh
   ```

2. **Register the hooks** in `~/.claude/settings.json`:
   ```json
   {
     "hooks": {
       "UserPromptSubmit": [
         { "hooks": [{ "type": "command", "command": "~/.claude/track-sessions.sh" }] }
       ],
       "Stop": [
         { "hooks": [{ "type": "command", "command": "~/.claude/track-sessions.sh" }] }
       ]
     }
   }
   ```

3. **Install the CLI:**
   ```bash
   mkdir -p ~/.local/bin
   ln -sf "$PWD/bin/claude-pulse" ~/.local/bin/claude-pulse
   chmod +x bin/claude-pulse
   ```
   Make sure `~/.local/bin` is in your `PATH`:
   ```bash
   echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.zshrc && source ~/.zshrc
   ```

## Usage

```bash
claude-pulse              # run immediately + loop every 10 min (default)
claude-pulse -d           # start as background daemon
claude-pulse --stop       # stop daemon + clear GitHub bio
claude-pulse --status     # show daemon status + last log lines
claude-pulse --loop 60    # run immediately + loop every 60s
claude-pulse --no-loop    # run once and exit
claude-pulse --dry-run    # show session count without updating GitHub
claude-pulse --help       # show all options
```

## Daemon logs

```bash
tail -f ~/.local/share/claude-pulse.log
```

## Inspect raw state

```bash
cat /tmp/claude-active-sessions.txt   # last recorded count + timestamp
ls /tmp/claude-activity/              # one file per session, last activity unix timestamp
```

## Customization

Copy `config.default` to `~/.config/claude-pulse/config` and edit:

```bash
# How long a session stays "active" after its last message (seconds)
CLAUDE_PULSE_WINDOW=1800   # 30 minutes

# How often claude-pulse pushes to GitHub bio (seconds)
CLAUDE_PULSE_INTERVAL=600  # 10 minutes

# GitHub bio format — $COUNT is replaced with the active session count
CLAUDE_PULSE_BIO="🤖 × \$COUNT Claude agents active"
```

## License

MIT
