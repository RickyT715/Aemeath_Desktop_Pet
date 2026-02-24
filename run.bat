@echo off
title Aemeath Desktop Pet
cd /d "%~dp0"
dotnet run --project src\AemeathDesktopPet
if %errorlevel% neq 0 (
    echo.
    echo Failed to start. Make sure .NET 8 SDK is installed:
    echo   https://dotnet.microsoft.com/download/dotnet/8.0
    pause
)
