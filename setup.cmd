@echo off
chcp 65001 >nul

REM 判断是否具备管理员权限：非管理员下 fltmc 会返回非 0
fltmc >nul 2>nul
set "ADMIN=%errorlevel%"

REM 判断是否已开启开发者模式：开启后普通用户也能创建软链接
set "DEVMODE=0"
reg query "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\AppModelUnlock" /v AllowDevelopmentWithoutDevLicense 2>nul | findstr /i "0x1" >nul
if "%errorlevel%"=="0" set "DEVMODE=1"

REM 既非管理员也未开启开发者模式时，请求 UAC 提权后重新运行本脚本
REM 在入口处提权可保证整个流程在同一窗口内完成，避免双击后窗口闪烁关闭
if not "%ADMIN%"=="0" if not "%DEVMODE%"=="1" (
    powershell -NoProfile -Command "Start-Process -FilePath '%~f0' -Verb RunAs"
    if not "%errorlevel%"=="0" (
        echo 无法获取管理员权限。请右键本脚本选择“以管理员身份运行”，
        echo 或前往 Windows 设置 - 隐私和安全性 - 开发者选项，开启开发者模式。
        pause
        exit /b
    )
    exit /b
)

REM 已具备权限：优先使用 PowerShell 7，未安装则回退到系统自带 PowerShell 5.x
where pwsh >nul 2>nul
if "%errorlevel%"=="0" (
    pwsh -ExecutionPolicy Bypass -File "%~dp0setup.ps1"
) else (
    powershell -ExecutionPolicy Bypass -File "%~dp0setup.ps1"
)

REM 仅在 PowerShell 自身报错（如无法启动）时暂停，便于排查
if not "%errorlevel%"=="0" (
    echo 脚本执行出错（退出码 %errorlevel%），请查看上方输出。
    pause
)
exit /b
