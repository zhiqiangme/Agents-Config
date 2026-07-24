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
agents-config/
├── setup.ps1      # PowerShell 设置脚本
├── README.md      # 中文说明
├── README_EN.md   # 英文说明
└── LICENSE        # MIT 许可证
```

注意：本仓库**不**包含 `AGENTS.md`。配置文件应放在规范源位置 `%USERPROFILE%\.agents\AGENTS.md`（即 `C:\Users\<你的用户名>\.agents\AGENTS.md`）。

## 同步目标

运行脚本后，会自动创建软链接到以下位置：

### AGENTS 配置文件

| 工具 | 目标路径 |
|------|----------|
| Codex | `%USERPROFILE%\.codex\AGENTS.md` |
| OpenCode | `%USERPROFILE%\.config\opencode\AGENTS.md` |
| Gemini | `%USERPROFILE%\.gemini\config\AGENTS.md` |
| Claude | `%USERPROFILE%\.claude\CLAUDE.md` |

所有软链接均指向规范源 `%USERPROFILE%\.agents\AGENTS.md`。

### Skills 目录

当 `%USERPROFILE%\.agents\skills` 存在时，脚本会将其中每个一级子文件夹分别软链接到以下位置。各工具的 `skills` 目录本身保持为普通目录：

| 工具 | 目标路径 |
|------|----------|
| WorkBuddy | `%USERPROFILE%\.workbuddy\skills` |
| Trae-CN | `%USERPROFILE%\.trae-cn\skills` |
| Claude | `%USERPROFILE%\.claude\skills` |
| Codex | `%USERPROFILE%\.codex\skills` |
| QoderWork | `%USERPROFILE%\.qoderworkcn\skills` |

同步时会自动删除各目标 `skills` 目录下目标已不存在的一级软链接。源目录不存在时自动跳过 Skills 同步，不影响主流程。

## 使用方法

1. 在 `%USERPROFILE%\.agents\AGENTS.md` 创建配置文件（如果已存在可跳过）
2. 如果某个工具的目录（如 `\.codex`）中已有 `AGENTS.md` 或 `CLAUDE.md`，脚本会自动识别并复用
3. 运行 `setup.ps1`（脚本会自动请求管理员权限，UAC 弹窗点「是」即可；也可用 `pwsh -ExecutionPolicy Bypass -File setup.ps1`）

## 智能收集逻辑

脚本会扫描以下位置作为候选配置文件：

- 规范源：`%USERPROFILE%\.agents\AGENTS.md`
- 四个工具目录下的 `AGENTS.md` 或 `CLAUDE.md`（`CLAUDE.md` 会被复制时自动重命名为 `AGENTS.md`）

然后按以下规则处理：

| 情况 | 处理方式 |
|------|----------|
| 没有候选文件 | 提示用户在任一位置创建后重试 |
| 只有一个非空候选 | **移动**到规范源 |
| 多个候选且内容一致 | 选择最近修改的，**复制**到规范源 |
| 多个候选且内容不一致 | 列出所有候选让用户选择，选中的**复制**到规范源 |

之后清理四个工具目录中原有的 `AGENTS.md` / `CLAUDE.md`，再创建指向规范源的软链接。

## 注意事项

- 规范源路径为 `%USERPROFILE%\.agents\AGENTS.md`，全大写
- 脚本优先使用 PowerShell 7（`pwsh`），未安装时自动回退到系统自带的 Windows PowerShell 5.x
- 无需手动以管理员身份运行，脚本会通过 UAC 自动提权（提权后仍保持使用相同版本的解释器）
- 支持 Windows 10/11
- 脚本会检测工具是否已安装（通过配置目录是否存在判断），未装的工具自动跳过
- 如需新增工具，编辑 `setup.ps1` 中的 `$targets` 数组即可

## 许可证

MIT License
