# 设置 AI 代理配置软链接
# 将 AGENTS.md 同步到 Codex、OpenCode、Gemini、Claude

$source = "$PSScriptRoot\AGENTS.md"
$targets = @(
    "$env:USERPROFILE\.codex\AGENTS.md",
    "$env:USERPROFILE\.config\opencode\AGENTS.md",
    "$env:USERPROFILE\.gemini\config\AGENTS.md",
    "$env:USERPROFILE\.claude\CLAUDE.md"
)

Write-Host "正在设置 AI 代理配置软链接..." -ForegroundColor Cyan

# 检查源文件是否存在
if (-not (Test-Path $source)) {
    Write-Error "源文件不存在: $source"
    exit 1
}

foreach ($target in $targets) {
    $targetDir = Split-Path $target -Parent
    
    # 确保目标目录存在
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
        Write-Host "✓ 已创建软链接: $target" -ForegroundColor Green
    } catch {
        Write-Error "创建软链接失败: $target"
        Write-Error "请确保以管理员身份运行此脚本"
        exit 1
    }
}

Write-Host "`n所有软链接创建成功！" -ForegroundColor Green
Write-Host "源文件: $source" -ForegroundColor Cyan