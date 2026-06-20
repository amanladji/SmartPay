@echo off
title SmartPay Backend
echo ========================================
echo   SmartPay - Starting Backend Server
echo ========================================
echo.
cd /d C:\Users\amanl\Downloads\rag-project\smartPay\backend
echo Starting Spring Boot on port 8765...
echo.
start /B /MIN java -jar target\smartpay-backend-1.0.0.jar
echo Backend started! (PID shown in task manager)
echo.
echo Waiting for backend to initialize...
timeout /t 20 /nobreak >nul
echo Backend is ready!
echo.
echo Frontend URL: http://localhost:5173
echo Backend URL:  http://localhost:8765
echo.
echo Close this window to stop the backend.
pause
