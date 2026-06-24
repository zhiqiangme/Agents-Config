@echo off
chcp 65001 >nul
powershell -ExecutionPolicy Bypass -File "%~dp0setup.ps1"
if %errorlevel% neq 0 pause
