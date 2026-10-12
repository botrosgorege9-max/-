@echo off
chcp 65001 >nul
title نظام تسجيل الحضور والانصراف بالـ QR

echo ========================================================
echo    نظام تسجيل الحضور والانصراف الذكي بالـ QR
echo ========================================================
echo.
echo جاري بدء تشغيل النظام وفتح المتصفح...
echo.

powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0server.ps1"

if %ERRORLEVEL% NEQ 0 (
    echo تعذر تشغيل الخادم المحلي، سيتم فتح النظام مباشرة في المتصفح...
    start "" "%~dp0index.html"
)

pause
