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
├── setup.cmd      # Windows batch wrapper script
├── README.md      # Chinese documentation
├── README_EN.md   # English documentation
└── LICENSE        # MIT License
```

## Sync Targets

Running the script will automatically create symbolic links to:

| Tool | Target Path |
|------|-------------|
| Codex | `%USERPROFILE%\.codex\AGENTS.md` |
| OpenCode | `%USERPROFILE%\.config\opencode\AGENTS.md` |
| Gemini | `%USERPROFILE%\.gemini\config\AGENTS.md` |
| Claude | `%USERPROFILE%\.claude\CLAUDE.md` |

## Usage

1. Place `AGENTS.md` in this directory
2. Run `setup.cmd` (the script will automatically request administrator privileges via UAC; click "Yes" on the prompt)
3. The script creates symbolic links so all tools share the same configuration

## Notes

- No need to run as administrator manually; the script auto-elevates via UAC
- Supports Windows 10/11
- To add a new tool, edit the `$targets` array in `setup.ps1`

## License

MIT License
