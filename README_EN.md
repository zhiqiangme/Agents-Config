<div align="right">

[![中文](https://img.shields.io/badge/中文-切换-FF6B6B?style=for-the-badge)](README.md)
[![English](https://img.shields.io/badge/English-Current-1E90FF?style=for-the-badge)](README_EN.md)

</div>

# AI Agent Configuration Manager

Unified management of agent configuration files for Codex, OpenCode, Gemini, and Claude.

## The Problem

If you've ever juggled agent configurations across AI tools, you know the pain: Codex wants an `AGENTS.md`, OpenCode wants one too, and Claude Code requires a separate `CLAUDE.md`. They should all contain the same content, but every update means manually copying the file to each location—tedious and error-prone.

This project eliminates that duplication. Maintain a single `AGENTS.md` and distribute it to every tool's config directory via symbolic links. Edit once, and every tool picks up the latest version automatically.

## How It Works

Uses Windows Symbolic Links to sync a single `AGENTS.md` across multiple AI tool configuration directories. Edit once, apply everywhere.

## Directory Structure

```
ai-agents-config/
├── AGENTS.md      # Main configuration file (source)
├── setup.ps1      # PowerShell setup script
├── README.md      # Chinese documentation
├── README_EN.md   # English documentation
└── LICENSE        # MIT License
```

## Repository Layout

```
agents-config/
├── setup.ps1      # PowerShell setup script
├── README.md      # Chinese documentation
├── README_EN.md   # English documentation
└── LICENSE        # MIT license
```

Note: this repository does **not** contain `AGENTS.md`. The configuration file should live at the canonical source location `%USERPROFILE%\.agents\AGENTS.md` (e.g. `C:\Users\<your-username>\.agents\AGENTS.md`).

## Sync Targets

After running the script, symbolic links are created at:

### AGENTS configuration file

| Tool | Target path |
|------|-------------|
| Codex | `%USERPROFILE%\.codex\AGENTS.md` |
| OpenCode | `%USERPROFILE%\.config\opencode\AGENTS.md` |
| Gemini | `%USERPROFILE%\.gemini\config\AGENTS.md` |
| Claude | `%USERPROFILE%\.claude\CLAUDE.md` |

All links point to the canonical source at `%USERPROFILE%\.agents\AGENTS.md`.

### Skills directory

When `%USERPROFILE%\.agents\skills` exists, the script creates a separate symbolic link for each first-level subfolder at the following locations. Each tool's `skills` directory remains a regular directory:

| Tool | Target path |
|------|-------------|
| WorkBuddy | `%USERPROFILE%\.workbuddy\skills` |
| Trae-CN | `%USERPROFILE%\.trae-cn\skills` |
| Claude | `%USERPROFILE%\.claude\skills` |
| Codex | `%USERPROFILE%\.codex\skills` |
| QoderWork | `%USERPROFILE%\.qoderworkcn\skills` |

If the source directory does not exist, Skills sync is skipped without affecting the main flow.

## Usage

1. Create the configuration file at `%USERPROFILE%\.agents\AGENTS.md` (skip if it already exists)
2. If any tool directory (e.g. `\.codex`) already contains an `AGENTS.md` or `CLAUDE.md`, the script picks it up automatically
3. Run `setup.ps1` (the script will request administrator privileges via UAC; click "Yes" on the prompt). You can also run it directly with `pwsh -ExecutionPolicy Bypass -File setup.ps1`.

## Smart Collection

The script scans these locations for candidate configuration files:

- Canonical source: `%USERPROFILE%\.agents\AGENTS.md`
- `AGENTS.md` or `CLAUDE.md` in each of the four tool directories (`CLAUDE.md` is automatically renamed to `AGENTS.md` when copied)

Then it applies the following logic:

| Case | Action |
|------|--------|
| No candidates found | Prompt the user to create one and re-run |
| Exactly one non-empty candidate | **Move** it to the canonical source |
| Multiple candidates with identical content | **Copy** the most recently modified one to the canonical source |
| Multiple candidates with different content | List all candidates and let the user pick; the chosen one is **copied** to the canonical source |

After that, any existing `AGENTS.md` / `CLAUDE.md` in the four tool directories is removed, and symlinks pointing to the canonical source are created.

## Notes

- The canonical source path is `%USERPROFILE%\.agents\AGENTS.md` (uppercase)
- The script prefers PowerShell 7 (`pwsh`) and falls back to the built-in Windows PowerShell 5.x if unavailable
- No need to run as administrator manually; the script auto-elevates via UAC (the same interpreter version is preserved after elevation)
- Supports Windows 10/11
- The script detects whether each tool is installed (via the presence of its config directory) and skips tools that are not installed
- To add a new tool, edit the `$targets` array in `setup.ps1`

## License

MIT License
