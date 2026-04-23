# claude-pulse

Broadcast your active Claude Code session count to your GitHub bio via a tiny shell CLI.

```
🤖 × 3 Claude agents active
```

`claude-pulse` reads Claude Code's own per-session transcripts (`~/.claude/projects/*/<sid>.jsonl`) to detect which sessions are actively exchanging messages, and pushes the count to your GitHub bio every 10 minutes. No hook registration required — the daemon watches the filesystem signals Claude Code already writes.

## Quickstart

```bash
./setup.sh
claude-pulse -d
```

That's it. Your GitHub bio will update automatically as long as the daemon is running — no Claude Code restart needed, even on first install.

> **Note:** `jq` is required (used to parse Claude Code's session state files). `brew install jq` if missing.

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

Claude Code keeps its own state on disk:

- `~/.claude/sessions/<pid>.json` — one file per running session, with the `pid` and `sessionId`
- `~/.claude/projects/<cwd-slug>/<sessionId>.jsonl` — transcript, `mtime` updates on every message exchange

`claude-pulse` iterates the session files, filters to PIDs still alive, looks up each session's transcript, and counts the ones whose transcript was modified within the activity window (default: 30 min). Then it calls `gh api PATCH /user` to update the bio.

No hook, no heartbeat file, no restart required — the daemon starts counting existing sessions immediately.

## Configuration

Copy `config.default` to `~/.config/claude-pulse/config`:

```bash
CLAUDE_PULSE_WINDOW=1800    # how long a session stays "active" (seconds)
CLAUDE_PULSE_INTERVAL=600   # how often to push to GitHub bio (seconds)
CLAUDE_PULSE_BIO="🤖 × \$COUNT Claude agents active"  # bio format
```

## Manual setup

If you prefer not to use `setup.sh`, symlink the CLI and add it to your PATH:

```bash
ln -sf "$PWD/bin/claude-pulse" ~/.local/bin/claude-pulse
chmod +x bin/claude-pulse
echo 'export PATH="$HOME/.local/bin:$PATH"' >> ~/.zshrc && source ~/.zshrc
```

Optionally copy `config.default` to `~/.config/claude-pulse/config` and edit.

## License

MIT
