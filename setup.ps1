# 设置 AI 代理配置软链接
# 将 AGENTS.md 同步到 Codex、OpenCode、Gemini、Claude

# 引入 Visual Basic 文件系统 API，用于将旧文件送入回收站而非直接删除
Add-Type -AssemblyName Microsoft.VisualBasic

# 检查是否以管理员身份运行，非管理员则自动触发 UAC 提权后退出当前进程
$isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)

if (-not $isAdmin) {
    Write-Host "当前未以管理员身份运行，正在请求提升权限..." -ForegroundColor Yellow
    # 获取当前 PowerShell 解释器路径，确保提权后仍使用相同版本（PS7 或 PS5）
    $psExe = (Get-Process -Id $PID).Path
    if (-not $psExe) { $psExe = "powershell.exe" }
    $arg = "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`" $args"
    try {
        Start-Process -FilePath $psExe -ArgumentList $arg -Verb RunAs -WorkingDirectory $PSScriptRoot
    } catch {
        Write-Host "无法自动获取管理员权限，请右键此脚本选择「以管理员身份运行」" -ForegroundColor Red
        Write-Host "按任意键退出..." -ForegroundColor Gray
        $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        exit 1
    }
    exit 0
}

# 同步目标：Tool=工具名称，ConfigDir=用于判断工具是否已安装的目录，TargetFile=软链接目标路径
$targets = @(
    @{ Tool = "Codex";    ConfigDir = "$env:USERPROFILE\.codex";            TargetFile = "$env:USERPROFILE\.codex\AGENTS.md" },
    @{ Tool = "OpenCode"; ConfigDir = "$env:USERPROFILE\.config\opencode"; TargetFile = "$env:USERPROFILE\.config\opencode\AGENTS.md" },
    @{ Tool = "Gemini";   ConfigDir = "$env:USERPROFILE\.gemini\config";   TargetFile = "$env:USERPROFILE\.gemini\config\AGENTS.md" },
    @{ Tool = "Claude";   ConfigDir = "$env:USERPROFILE\.claude";           TargetFile = "$env:USERPROFILE\.claude\CLAUDE.md" }
)

# 规范源：唯一真实的配置文件
$canonicalSource = Join-Path $env:USERPROFILE ".agents\AGENTS.md"

Write-Host "正在扫描候选配置文件..." -ForegroundColor Cyan

# 收集所有非空候选：规范源 + 各工具目录的 AGENTS.md / CLAUDE.md
$candidates = New-Object System.Collections.Generic.List[string]

if (Test-Path $canonicalSource) {
    $csContent = $null
    try { $csContent = [System.IO.File]::ReadAllText($canonicalSource) } catch { }
    if ($csContent -and $csContent.Length -gt 0) {
        $candidates.Add($canonicalSource)
    }
}

foreach ($t in $targets) {
    $dir = Split-Path $t.TargetFile -Parent
    foreach ($name in @('AGENTS.md', 'CLAUDE.md')) {
        $p = Join-Path $dir $name
        if ((Test-Path $p) -and (-not $candidates.Contains($p))) {
            $pContent = $null
            try { $pContent = [System.IO.File]::ReadAllText($p) } catch { }
            if ($pContent -and $pContent.Length -gt 0) {
                $candidates.Add($p)
            }
        }
    }
}

if ($candidates.Count -eq 0) {
    Write-Host "未找到任何 AGENTS.md 或 CLAUDE.md 文件" -ForegroundColor Red
    Write-Host "请在以下任一位置创建配置文件后重试：" -ForegroundColor Yellow
    Write-Host "  - 规范源: " $canonicalSource
    Write-Host "  - 四个工具配置目录之一 (.codex / .config\opencode / .gemini\config / .claude)" -ForegroundColor Yellow
    Write-Host "按任意键退出..." -ForegroundColor Gray
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    exit 1
}

# 决定使用哪个候选作为规范源
$selected = $null
if ($candidates.Count -eq 1) {
    $selected = $candidates[0]
} else {
    $firstHash = (Get-FileHash $candidates[0] -Algorithm SHA256).Hash
    $allSame = $true
    for ($i = 1; $i -lt $candidates.Count; $i++) {
        if ((Get-FileHash $candidates[$i] -Algorithm SHA256).Hash -ne $firstHash) {
            $allSame = $false
            break
        }
    }

    if ($allSame) {
        # $candidates 是字符串列表，需经 Get-Item 获取 LastWriteTime 属性后再排序
        $selected = $candidates | Get-Item | Sort-Object LastWriteTime -Descending | Select-Object -First 1 -ExpandProperty FullName
        Write-Host "检测到 " $candidates.Count " 个内容相同的配置文件，已选择最近修改的：" $selected -ForegroundColor Cyan
    } else {
        Write-Host "检测到多个不同的配置文件，请选择使用哪一个：" -ForegroundColor Yellow
        for ($i = 0; $i -lt $candidates.Count; $i++) {
            $info = Get-Item $candidates[$i]
            Write-Host "  [" ($i+1) "] " $candidates[$i] "  (大小: " $info.Length " 字节, 修改时间: " ($info.LastWriteTime.ToString('yyyy-MM-dd HH:mm:ss')) ")"
        }
        Write-Host "请输入编号 (1-" $candidates.Count "): " -ForegroundColor Yellow -NoNewline
        $choice = Read-Host
        $idx = 0
        if (-not [int]::TryParse($choice, [ref]$idx)) {
            Write-Host "无效选择" -ForegroundColor Red
            Write-Host "按任意键退出..." -ForegroundColor Gray
            $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
            exit 1
        }
        $idx--
        if ($idx -lt 0 -or $idx -ge $candidates.Count) {
            Write-Host "无效选择" -ForegroundColor Red
            Write-Host "按任意键退出..." -ForegroundColor Gray
            $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
            exit 1
        }
        $selected = $candidates[$idx]
    }
}

# 将选中的文件移动（唯一）或复制（多个）到规范源
if ($selected -ne $canonicalSource) {
    $canonicalDir = Split-Path $canonicalSource -Parent
    if (-not (Test-Path $canonicalDir)) {
        Write-Host "创建目录: " $canonicalDir -ForegroundColor Yellow
        New-Item -ItemType Directory -Path $canonicalDir -Force | Out-Null
    }

    if ($candidates.Count -eq 1) {
        Move-Item $selected $canonicalSource -Force
        Write-Host "已移动: " $selected " -> " $canonicalSource -ForegroundColor Green
    } else {
        Copy-Item $selected $canonicalSource -Force
        Write-Host "已复制: " $selected " -> " $canonicalSource -ForegroundColor Green
    }
}

# 删除工具目录中原有的 AGENTS.md / CLAUDE.md，为创建新软链接做准备
# 使用回收站而非永久删除，避免误操作丢失用户配置
foreach ($t in $targets) {
    $dir = Split-Path $t.TargetFile -Parent
    foreach ($name in @('AGENTS.md', 'CLAUDE.md')) {
        $p = Join-Path $dir $name
        if (Test-Path $p) {
            $it = Get-Item $p
            if ($it.LinkType -eq 'SymbolicLink') {
                Write-Host "移除现有软链接: " $p -ForegroundColor Yellow
                # 软链接直接删除即可，不会影响规范源
                Remove-Item $p -Force
            } else {
                Write-Host "移入回收站: " $p -ForegroundColor Yellow
                # 普通文件送入回收站，保留恢复可能性
                [Microsoft.VisualBasic.FileIO.FileSystem]::DeleteFile($p, 'OnlyErrorDialogs', 'SendToRecycleBin')
            }
        }
    }
}

# 为每个已安装的工具创建软链接
$created = 0
$skipped = 0
foreach ($t in $targets) {
    if (-not (Test-Path $t.ConfigDir)) {
        Write-Host "[跳过] " $t.Tool ": 未检测到配置目录 " $t.ConfigDir -ForegroundColor DarkGray
        $skipped++
        continue
    }

    $target = $t.TargetFile
    $targetDir = Split-Path $target -Parent
    if (-not (Test-Path $targetDir)) {
        Write-Host "创建目录: " $targetDir -ForegroundColor Yellow
        New-Item -ItemType Directory -Path $targetDir -Force | Out-Null
    }

    try {
        New-Item -ItemType SymbolicLink -Path $target -Target $canonicalSource | Out-Null
        Write-Host "[完成] 已创建软链接 [" $t.Tool "]: " $target -ForegroundColor Green
        $created++
    } catch {
        Write-Error ("创建软链接失败: " + $target)
        Write-Error "请确保以管理员身份运行此脚本"
        Write-Host "按任意键退出..." -ForegroundColor Gray
        $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        exit 1
    }
}

# Skills 目录同步：将规范源 .agents\skills 软链接到各工具的 skills 目录
$skillsSource = Join-Path $env:USERPROFILE ".agents\skills"

if (-not (Test-Path $skillsSource)) {
    Write-Host "未检测到 Skills 源目录: " $skillsSource "，跳过 Skills 同步。" -ForegroundColor DarkGray
} else {
    Write-Host ""
    Write-Host "正在同步 Skills 目录..." -ForegroundColor Cyan

    # 各工具的 skills 目标目录
    $skillTargets = @(
        @{ Tool = "WorkBuddy"; TargetDir = "$env:USERPROFILE\.workbuddy\skills" },
        @{ Tool = "Trae-CN";   TargetDir = "$env:USERPROFILE\.trae-cn\skills" },
        @{ Tool = "Claude";    TargetDir = "$env:USERPROFILE\.claude\skills" }
    )

    foreach ($s in $skillTargets) {
        # 确保父目录存在
        $parentDir = Split-Path $s.TargetDir -Parent
        if (-not (Test-Path $parentDir)) {
            Write-Host "创建目录: " $parentDir -ForegroundColor Yellow
            New-Item -ItemType Directory -Path $parentDir -Force | Out-Null
        }

        # 目标已存在时清理：软链接直接删除，普通目录送入回收站
        if (Test-Path $s.TargetDir) {
            $it = Get-Item $s.TargetDir -Force
            if ($it.LinkType -eq 'SymbolicLink') {
                Write-Host "移除现有软链接: " $s.TargetDir -ForegroundColor Yellow
                Remove-Item $s.TargetDir -Force
            } else {
                Write-Host "移入回收站: " $s.TargetDir -ForegroundColor Yellow
                [Microsoft.VisualBasic.FileIO.FileSystem]::DeleteDirectory($s.TargetDir, 'OnlyErrorDialogs', 'SendToRecycleBin')
            }
        }

        # 创建目录软链接
        try {
            New-Item -ItemType SymbolicLink -Path $s.TargetDir -Target $skillsSource | Out-Null
            Write-Host "[完成] 已创建软链接 [" $s.Tool "]: " $s.TargetDir -ForegroundColor Green
        } catch {
            Write-Error ("创建软链接失败: " + $s.TargetDir)
            Write-Error "请确保以管理员身份运行此脚本"
            Write-Host "按任意键退出..." -ForegroundColor Gray
            $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
            exit 1
        }
    }
}

Write-Host ""
Write-Host "完成！新建 " $created " 个软链接，跳过 " $skipped " 个未安装的工具。" -ForegroundColor Cyan
Write-Host "规范源: " $canonicalSource -ForegroundColor Cyan
Write-Host "按任意键退出..." -ForegroundColor Gray
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")