# claude-pulse

Broadcast your active coding agent session count to your GitHub bio via a tiny shell CLI.

```
🤖 × 3 coding agents active
```

`claude-pulse` reads local state files from supported agent CLIs to detect which sessions are actively exchanging messages, and pushes the count to your GitHub bio every 10 minutes. No hook registration required; the daemon watches the filesystem signals those tools already write.

## Quickstart

```bash
./setup.sh
claude-pulse -d
```

That's it. Your GitHub bio will update automatically as long as the daemon is running; no agent restart needed, even on first install.

> **Note:** `jq` is required for Claude Code counting because Claude's session state is JSON. `brew install jq` if missing.

## Requirements

- At least one supported local agent: [Claude Code](https://claude.ai/code), Cursor Agent, or GitHub Copilot CLI
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
claude-pulse --dry-run    # show current session counts without updating GitHub
claude-pulse --no-loop    # run once and exit
claude-pulse --loop 60    # run immediately + loop every 60s
claude-pulse --help       # show all options
```

Daemon logs: `~/.local/share/claude-pulse.log`

## How it works

Supported agents keep local state on disk:

- Claude Code:
  - `~/.claude/sessions/<pid>.json` — one file per running session, with the `pid` and `sessionId`
  - `~/.claude/projects/<cwd-slug>/<sessionId>.jsonl` — transcript, `mtime` updates on every message exchange
- Cursor Agent:
  - `~/.cursor/projects/<project-slug>/agent-transcripts/<session>/<session>.jsonl` — transcript, `mtime` updates as the agent works
- GitHub Copilot CLI:
  - `~/.copilot/session-state/<session>/events.jsonl` — event log, `mtime` updates as the agent works

`claude-pulse` keeps Claude Code's stronger live-session check by filtering to PIDs still alive, then requiring a recent transcript update. Cursor Agent and Copilot CLI are counted by recent transcript/event-log activity because their local state does not expose the same PID index. Then it calls `gh api PATCH /user` to update the bio.

No hook, no heartbeat file, no restart required; the daemon starts counting existing sessions immediately.

## Configuration

Copy `config.default` to `~/.config/claude-pulse/config`:

```bash
CLAUDE_PULSE_WINDOW=1800    # how long a session stays "active" (seconds)
CLAUDE_PULSE_INTERVAL=600   # how often to push to GitHub bio (seconds)
CLAUDE_PULSE_AGENTS="claude cursor copilot"  # providers to count
CLAUDE_PULSE_BIO="🤖 × \$COUNT coding agents active"  # bio format
```

The bio template can use `$COUNT` plus provider-specific variables: `$CLAUDE_COUNT`, `$CURSOR_COUNT`, and `$COPILOT_COUNT`. You can also override provider state directories with `CLAUDE_PULSE_CLAUDE_SESSIONS_DIR`, `CLAUDE_PULSE_CLAUDE_PROJECTS_DIR`, `CLAUDE_PULSE_CURSOR_PROJECTS_DIR`, and `CLAUDE_PULSE_COPILOT_SESSIONS_DIR`.

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
