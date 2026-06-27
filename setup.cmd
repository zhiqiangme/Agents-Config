@echo off
chcp 65001 >nul
REM 优先使用 PowerShell 7（pwsh），未安装则回退到系统自带的 Windows PowerShell 5.x
where pwsh >nul 2>nul
if %errorlevel% equ 0 (
    pwsh -ExecutionPolicy Bypass -File "%~dp0setup.ps1"
) else (
    powershell -ExecutionPolicy Bypass -File "%~dp0setup.ps1"
)
if %errorlevel% neq 0 pause
