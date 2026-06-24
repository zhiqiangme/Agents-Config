# 设置 AI 代理配置软链接
# 将 AGENTS.md 同步到 Codex、OpenCode、Gemini、Claude

# 检查是否以管理员身份运行，非管理员则自动触发 UAC 提权后退出当前进程
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    Write-Host "当前未以管理员身份运行，正在请求提升权限..." -ForegroundColor Yellow
    $arg = "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`" $args"
    try {
        Start-Process -FilePath "powershell.exe" -ArgumentList $arg -Verb RunAs -WorkingDirectory $PSScriptRoot
    } catch {
        Write-Host "无法自动获取管理员权限，请右键此脚本选择「以管理员身份运行」" -ForegroundColor Red
        Write-Host "按任意键退出..." -ForegroundColor Gray
        $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        exit 1
    }
    exit 0
}

$source = "$PSScriptRoot\AGENTS.md"

# 同步目标：Tool=工具名称，ConfigDir=用于判断工具是否已安装的目录，TargetFile=软链接目标路径
$targets = @(
    @{ Tool = "Codex";    ConfigDir = "$env:USERPROFILE\.codex";            TargetFile = "$env:USERPROFILE\.codex\AGENTS.md" },
    @{ Tool = "OpenCode"; ConfigDir = "$env:USERPROFILE\.config\opencode"; TargetFile = "$env:USERPROFILE\.config\opencode\AGENTS.md" },
    @{ Tool = "Gemini";   ConfigDir = "$env:USERPROFILE\.gemini\config";   TargetFile = "$env:USERPROFILE\.gemini\config\AGENTS.md" },
    @{ Tool = "Claude";   ConfigDir = "$env:USERPROFILE\.claude";           TargetFile = "$env:USERPROFILE\.claude\CLAUDE.md" }
)

Write-Host "正在设置 AI 代理配置软链接..." -ForegroundColor Cyan

# 检查源文件是否存在
if (-not (Test-Path $source)) {
    Write-Error "源文件不存在: $source"
    pause
    exit 1
}

$created = 0
$skipped = 0

foreach ($t in $targets) {
    # 通过工具配置目录是否存在判断是否已安装，未安装则跳过（避免创建空目录和无效软链接）
    if (-not (Test-Path $t.ConfigDir)) {
        Write-Host "[跳过] $($t.Tool)：未检测到配置目录 $($t.ConfigDir)" -ForegroundColor DarkGray
        $skipped++
        continue
    }

    $target = $t.TargetFile
    $targetDir = Split-Path $target -Parent

    # 确保目标文件所在目录存在
    if (-not (Test-Path $targetDir)) {
        Write-Host "创建目录: $targetDir" -ForegroundColor Yellow
        New-Item -ItemType Directory -Path $targetDir -Force | Out-Null
    }

    # 如果目标已存在，删除它
    if (Test-Path $target) {
        $item = Get-Item $target
        if ($item.LinkType -eq "SymbolicLink") {
            Write-Host "删除现有软链接: $target" -ForegroundColor Yellow
        } else {
            Write-Host "删除现有文件: $target" -ForegroundColor Yellow
        }
        Remove-Item $target -Force
    }

    # 创建软链接
    try {
        New-Item -ItemType SymbolicLink -Path $target -Target $source | Out-Null
        Write-Host "[完成] 已创建软链接 [$($t.Tool)]: $target" -ForegroundColor Green
        $created++
    } catch {
        Write-Error "创建软链接失败: $target"
        Write-Error "请确保以管理员身份运行此脚本"
        pause
        exit 1
    }
}

Write-Host ""
Write-Host "完成！新建 $created 个软链接，跳过 $skipped 个未安装的工具。" -ForegroundColor Cyan
Write-Host "源文件: $source" -ForegroundColor Cyan
Write-Host "按任意键退出..." -ForegroundColor Gray
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")