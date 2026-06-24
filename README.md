# AI 代理配置管理

统一管理 Codex、OpenCode、Gemini、Claude 的代理配置文件。

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
2. **以管理员身份**运行 `setup.cmd`
3. 脚本会自动创建软链接，所有工具共享同一份配置

## 注意事项

- 需要管理员权限创建软链接
- 支持 Windows 10/11
- 如需新增工具，编辑 `setup.ps1` 中的 `$targets` 数组即可

## 许可证

MIT License
