@echo off
setlocal EnableDelayedExpansion

:: Logging
set LOG_FILE=%USERPROFILE%\buildserver_install.log
echo [%DATE% %TIME%] Script started >> "%LOG_FILE%"

:: Set variables
set ZIP_URL=https://github.com/chkp-altrevin/buildserver/archive/refs/heads/main.zip
set ZIP_FILE=%TEMP%\buildserver-main.zip
set EXTRACT_FOLDER=buildserver-main
set FINAL_FOLDER=buildserver
set BACKUP_DIR=%USERPROFILE%\buildserver_backups

:: Handle command-line flags
if "%~1"=="--help" goto :help
if "%~1"=="--cleanup" goto :cleanup
if "%~1"=="--refresh" (
    call "%~f0"
    exit /b
)

:: Prompt user for extraction path
set /p DEST_DIR=Enter extract destination path (default is %USERPROFILE%): 
if "%DEST_DIR%"=="" set DEST_DIR=%USERPROFILE%

:: Ensure backup directory exists
if not exist "%BACKUP_DIR%" (
    mkdir "%BACKUP_DIR%"
)

:: Download the ZIP
echo [INFO] Downloading latest buildserver ZIP...
powershell -Command "Invoke-WebRequest -Uri '%ZIP_URL%' -OutFile '%ZIP_FILE%' -UseBasicParsing"

:: Backup existing buildserver directory if it exists
if exist "%DEST_DIR%\%FINAL_FOLDER%" (
    set BACKUP_FILENAME=buildserver_backup_%RANDOM%.zip
    set BACKUP_FILE=%BACKUP_DIR%\%BACKUP_FILENAME%
    setlocal EnableDelayedExpansion
    echo [INFO] Backing up existing buildserver to: !BACKUP_FILE!
    echo [DEBUG] BACKUP_FILE = !BACKUP_FILE! >> "%LOG_FILE%"
    powershell -Command "Compress-Archive -Path '%DEST_DIR%\%FINAL_FOLDER%\*' -DestinationPath '!BACKUP_FILE!' -Force"
    endlocal
    rd /s /q "%DEST_DIR%\%FINAL_FOLDER%"
)

:: Extract ZIP
echo [INFO] Extracting ZIP to: %DEST_DIR%
powershell -Command "Expand-Archive -Path '%ZIP_FILE%' -DestinationPath '%DEST_DIR%' -Force"

:: Rename extracted folder
if exist "%DEST_DIR%\%EXTRACT_FOLDER%" (
    ren "%DEST_DIR%\%EXTRACT_FOLDER%" "%FINAL_FOLDER%"
)

:: Completion message
echo ╬▒ Installation complete. Project folder: %DEST_DIR%\%FINAL_FOLDER%
echo [INFO] Installation complete at %DEST_DIR%\%FINAL_FOLDER% >> "%LOG_FILE%"
exit /b

:: HELP SECTION
:help
echo --------------------------------------------------
echo               BuildServer Installer
echo --------------------------------------------------
echo Usage:
echo    downloader.bat  (Installs, Backups, Verifies)
echo    downloader.bat  [--help] [--refresh] [--cleanup]
echo.
echo Flags:
echo    --help      Show this help message
echo    --refresh   Re-fresh the project folder
echo    --cleanup   Remove buildserver, backups, and zip
echo.
echo Examples:
echo    downloader.bat
echo    downloader.bat --cleanup
echo.
echo Logs stored at: %LOG_FILE%
exit /b

:: CLEANUP SECTION
:cleanup
echo [INFO] Running cleanup...

set BUILD_DIR=%USERPROFILE%\buildserver
set BACKUP_DIR=%USERPROFILE%\buildserver_backups
set ZIP_FILE=%TEMP%\buildserver-main.zip
set DOT_VAGRANT=%USERPROFILE%\buildserver\.vagrant
set VAGRANTFILE=%USERPROFILE%\buildserver\Vagrantfile

#if exist "%DOT_VAGRANT%" (
#    echo [INFO] Destroy Buildserver...
#    vagrant destroy -f
#) else (
#    echo [INFO] No usable buildserver found at %BUILD_DIR%. Manually remove by UI or CD to %USERPROFILE%\"VirtualBox VMs" and delete the folder.
#)
:: Check if .vagrant folder exists
if exist "%DOT_VAGRANT%" (
    echo [INFO] Existing Vagrant VM detected at %DOT_VAGRANT%
    echo.
    echo ⚠️  Do you want to destroy the existing VM? (Y/N)
    choice /c YN /n /m "Confirm (Y/N): "
    if errorlevel 2 (
        echo [INFO] Skipping destruction. Continuing with setup...
        call :log_info "User chose not to destroy existing Vagrant VM"
    ) else (
        echo [INFO] Destroying existing Vagrant VM...
        call :log_info "Destroying VM at %DOT_VAGRANT%"
        where vagrant >nul 2>&1
        if %errorlevel% neq 0 (
            echo [ERROR] Vagrant not found. Please install Vagrant or destroy manually.
            call :log_info "Failed: Vagrant not found in PATH"
        ) else (
            vagrant destroy -f
            if %errorlevel% neq 0 (
                echo [ERROR] Vagrant destroy failed. Manual cleanup may be needed.
                call :log_info "Vagrant destroy command failed"
            ) else (
                echo [INFO] VM destroyed successfully.
                call :log_info "Vagrant destroy succeeded"
            )
        )
    )
) else (
    echo [INFO] No usable buildserver found at %BUILD_DIR%.
    echo 💡 Manually remove via VirtualBox UI or delete folder at: %USERPROFILE%\VirtualBox VMs
    call :log_info "No Vagrant VM found. Skipping destroy."
)

if exist "%BUILD_DIR%" (
    echo [INFO] Deleting %BUILD_DIR%...
    rd /s /q "%BUILD_DIR%"
) else (
    echo [INFO] No buildserver directory found at %BUILD_DIR%.
)

if exist "%BACKUP_DIR%" (
    echo [INFO] Deleting %BACKUP_DIR%...
    rd /s /q "%BACKUP_DIR%"
) else (
    echo [INFO] No backup directory found at %BACKUP_DIR%.
)

if exist "%ZIP_FILE%" (
    echo [INFO] Deleting ZIP archive %ZIP_FILE%...
    del /q "%ZIP_FILE%"
) else (
    echo [INFO] No ZIP archive found at %ZIP_FILE%.
)

echo ╬▒ Cleanup complete.
echo [INFO] Cleanup complete. >> "%LOG_FILE%"
exit /b
