@echo off
title SmartPay - Full Stack Application
echo ========================================
echo     SMART PAY - Starting Application
echo ========================================
echo.
echo [1/2] Starting Backend (Spring Boot) on port 8765...
cd /d C:\Users\amanl\Downloads\rag-project\smartPay\backend
start /B /MIN java -jar target\smartpay-backend-1.0.0.jar

echo Waiting for backend to initialize (20 seconds)...
timeout /t 20 /nobreak >nul

echo [2/2] Starting Frontend (React + Vite) on port 5173...
cd /d C:\Users\amanl\Downloads\rag-project\smartPay\frontend
start /B /MIN cmd /c npx vite --host

timeout /t 5 /nobreak >nul

echo.
echo ========================================
echo   SmartPay is RUNNING!
echo.
echo   Frontend: http://localhost:5173
echo   Backend:  http://localhost:8765
echo.
echo   Close this window to stop.
echo ========================================
echo.
pause
