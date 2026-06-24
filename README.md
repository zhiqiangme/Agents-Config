<div align="right">

[![中文](https://img.shields.io/badge/中文-当前阅读-FF6B6B?style=for-the-badge)](README.md)
[![English](https://img.shields.io/badge/English-Switch-1E90FF?style=for-the-badge)](README_EN.md)

</div>

# AI 代理配置管理

统一管理 Codex、OpenCode、Gemini、Claude 的代理配置文件。

## 痛点

想必你也遇到过这样的困扰：Codex 中放一份 `AGENTS.md`，OpenCode 中又要放一份，Claude Code 还得专门放一个 `CLAUDE.md`，而它们承载的内容本应完全相同。每次规范更新都要逐个文件手动复制、反复同步，繁琐又容易遗漏。

本项目的目的正是消除这种重复：只维护一份 `AGENTS.md`，通过软链接分发到各个 AI 工具的配置目录，所有工具都自动识别同一份内容——编辑一处，全部生效。

## 原理

通过 Windows 软链接（Symbolic Link）将一份 `AGENTS.md` 同步到多个 AI 工具的配置目录，修改一处，全部生效。

## 目录结构

```
ai-agents-config/
├── AGENTS.md      # 主配置文件（原件）
├── setup.ps1      # PowerShell 设置脚本
├── setup.cmd      # Windows 批处理包装脚本
├── README.md      # 中文说明
├── README_EN.md   # 英文说明
└── LICENSE        # MIT 许可证
```

## 同步目标

运行脚本后，会自动创建软链接到以下位置：

| 工具 | 目标路径 |
|------|----------|
| Codex | `%USERPROFILE%\.codex\AGENTS.md` |
| OpenCode | `%USERPROFILE%\.config\opencode\AGENTS.md` |
| Gemini | `%USERPROFILE%\.gemini\config\AGENTS.md` |
| Claude | `%USERPROFILE%\.claude\CLAUDE.md` |

## 使用方法

1. 将 `AGENTS.md` 放在本目录
2. 运行 `setup.cmd`（脚本会自动请求管理员权限，UAC 弹窗点「是」即可）
3. 脚本会自动创建软链接，所有工具共享同一份配置

## 注意事项

- 无需手动以管理员身份运行，脚本会通过 UAC 自动提权
- 支持 Windows 10/11
- 如需新增工具，编辑 `setup.ps1` 中的 `$targets` 数组即可

## 许可证

MIT License
