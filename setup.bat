@echo off
REM Kiểm tra xem Chocolatey đã cài chưa
where choco >nul 2>nul
if %ERRORLEVEL% equ 0 (
    echo Chocolatey đã được cài đặt sẵn.
) else (
    REM Bước 1: Cài đặt Chocolatey
    echo Cài đặt Chocolatey...
    set "choco_installer=https://community.chocolatey.org/install.ps1"
    powershell -NoProfile -ExecutionPolicy Bypass -Command "(New-Object System.Net.WebClient).DownloadFile('%choco_installer%', 'install.ps1')"
    powershell -NoProfile -ExecutionPolicy Bypass -File install.ps1
)

REM Kiểm tra xem AutoHotkey đã cài chưa
choco list --local-only autohotkey | findstr "autohotkey" >nul
if %ERRORLEVEL% equ 0 (
    echo AutoHotkey 2 đã được cài đặt sẵn.
) else (
    REM Bước 2: Cài đặt AutoHotkey 2
    echo Cài đặt AutoHotkey 2...
    choco install autohotkey.install -y
)

REM Kiểm tra xem Visual Studio Code đã cài chưa
choco list --local-only vscode | findstr "vscode" >nul
if %ERRORLEVEL% equ 0 (
    echo Visual Studio Code đã được cài đặt sẵn.
) else (
    REM Bước 3: Cài đặt Visual Studio Code
    echo Cài đặt Visual Studio Code...
    choco install vscode -y
)

REM Kiểm tra lại các phần mềm đã được cài đặt
echo Cài đặt hoàn tất! 
pause