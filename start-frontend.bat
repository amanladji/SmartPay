@echo off
title SmartPay Frontend
echo ========================================
echo   SmartPay - Starting Frontend Server
echo ========================================
echo.
cd /d C:\Users\amanl\Downloads\rag-project\smartPay\frontend
echo Starting Vite dev server on port 5173...
echo.
start /B /MIN cmd /c npx vite --host
echo Frontend started!
echo Open http://localhost:5173 in your browser
echo.
pause
