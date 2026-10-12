@echo off
chcp 65001 >nul
title Smart QR Attendance System

echo ========================================================
echo    Smart QR Attendance System
echo ========================================================
echo.
echo Starting local server and opening your browser...
echo.

powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0server.ps1"

if %ERRORLEVEL% NEQ 0 (
    echo Opening index.html directly in browser...
    start "" "%~dp0index.html"
)

pause
