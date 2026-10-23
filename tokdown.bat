@echo off
setlocal
chcp 65001 >nul 2>&1

:: If ruby is not yet in PATH of current session, check standard Ruby locations
where ruby >nul 2>nul
if %errorlevel% neq 0 (
    if exist "C:\Ruby33-x64\bin\ruby.exe" set "PATH=C:\Ruby33-x64\bin;%PATH%"
    if exist "C:\Ruby32-x64\bin\ruby.exe" set "PATH=C:\Ruby32-x64\bin;%PATH%"
    if exist "C:\Ruby31-x64\bin\ruby.exe" set "PATH=C:\Ruby31-x64\bin;%PATH%"
)

where ruby >nul 2>nul
if %errorlevel% neq 0 (
    echo.
    echo [!] Ruby bulunamadi / Ruby is not installed.
    echo     Kurmak icin PowerShell uzerinden su komutu calistirabilirsiniz:
    echo     winget install RubyInstallerTeam.Ruby.3.3
    echo.
    pause
    exit /b 1
)

ruby "%~dp0bin\tokdown" %*
