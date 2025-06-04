@echo off
setlocal EnableDelayedExpansion

:: ====== LOGGING ======
set LOG_FILE=%USERPROFILE%\buildserver_install.log
echo [%DATE% %TIME%] Script started >> "%LOG_FILE%"

:: ====== VARIABLES ======
set ZIP_URL=https://github.com/chkp-altrevin/buildserver/archive/refs/heads/main.zip
set ZIP_FILE=%TEMP%\buildserver-main.zip
set EXTRACT_FOLDER=buildserver-main
set FINAL_FOLDER=buildserver
set BACKUP_DIR=%USERPROFILE%\buildserver_backups

:: ====== FLAGS ======
if "%~1"=="--help" goto :help
if "%~1"=="--cleanup" goto :cleanup
if "%~1"=="--refresh" (
    call "%~f0"
    exit /b
)

:: ====== DESTINATION PROMPT ======
set /p DEST_DIR=Enter extract destination path (default is %USERPROFILE%): 
if "%DEST_DIR%"=="" set DEST_DIR=%USERPROFILE%
if not exist "%DEST_DIR%" (
    echo [%DATE% %TIME%] ERROR: Destination path does not exist. >> "%LOG_FILE%"
    echo ❌ Destination path does not exist.
    exit /b
)

:: ====== BACKUP EXISTING ======
if exist "%DEST_DIR%\%FINAL_FOLDER%" (
    echo [%DATE% %TIME%] Existing buildserver folder found. Creating backup... >> "%LOG_FILE%"
    if not exist "%BACKUP_DIR%" mkdir "%BACKUP_DIR%"

    :: Generate a safe timestamp
    for /f "tokens=1-4 delims=/:. " %%a in ("%TIME%") do (
        set HOUR=%%a
        set MINUTE=%%b
        set SECOND=%%c
        set MS=%%d
    )
    set "TIMESTAMP=%DATE:~10,4%-%DATE:~4,2%-%DATE:~7,2%_%HOUR%-%MINUTE%-%SECOND%"
    set "BACKUP_NAME=buildserver_backup_%TIMESTAMP%.zip"

    powershell -Command "Compress-Archive -Path '%DEST_DIR%\%FINAL_FOLDER%\*' -DestinationPath '%BACKUP_DIR%\%BACKUP_NAME%' -Force"
)

:: ====== DOWNLOAD ======
echo [%DATE% %TIME%] Downloading ZIP archive... >> "%LOG_FILE%"
powershell -Command "Invoke-WebRequest -Uri '%ZIP_URL%' -OutFile '%ZIP_FILE%' -UseBasicParsing"

:: ====== VERIFY DOWNLOAD ======
if not exist "%ZIP_FILE%" (
    echo [%DATE% %TIME%] ERROR: ZIP download failed. >> "%LOG_FILE%"
    echo ❌ Download failed. Exiting.
    exit /b
)

:: ====== CLEAN EXTRACTED FOLDER IF NEEDED ======
if exist "%DEST_DIR%\%EXTRACT_FOLDER%" rmdir /s /q "%DEST_DIR%\%EXTRACT_FOLDER%"

:: ====== EXTRACT ======
echo [%DATE% %TIME%] Extracting archive to %DEST_DIR%... >> "%LOG_FILE%"
tar -xf "%ZIP_FILE%" -C "%DEST_DIR%"

:: ====== REPLACE FINAL FOLDER ======
if exist "%DEST_DIR%\%FINAL_FOLDER%" rmdir /s /q "%DEST_DIR%\%FINAL_FOLDER%"
rename "%DEST_DIR%\%EXTRACT_FOLDER%" "%FINAL_FOLDER%"

:: ====== CLEANUP ZIP ======
del "%ZIP_FILE%" >nul 2>&1

:: ====== DONE - ECHO FINAL PATH ======
echo.
echo ✅ Buildserver downloaded and ready.
echo 📁 Project path: "%DEST_DIR%\%FINAL_FOLDER%"
echo CD into: "%DEST_DIR%\%FINAL_FOLDER%"
echo.
exit /b

:: ====== HELP FLAG ======
:help
echo.
echo ===========================
echo   Buildserver Downloader
echo ===========================
echo.
echo --help       Show this help message.
echo --cleanup    Remove downloaded files and extracted folders.
echo --refresh    Restart the script (fresh execution).
echo.
echo If run with no flags, the script will:
echo - Prompt for a destination path.
echo - Download and extract the buildserver ZIP archive.
echo - Backup existing 'buildserver' folder if it exists.
echo - Display the full path where the project was extracted.
echo.
exit /b

:: ====== CLEANUP MODE ======
:cleanup
echo [%DATE% %TIME%] Running cleanup... >> "%LOG_FILE%"

:: Default to %USERPROFILE% since no prompt is used in cleanup mode
set "DEST_DIR=%USERPROFILE%"

:: Delete extracted folder
if exist "%DEST_DIR%\%FINAL_FOLDER%" (
    rmdir /s /q "%DEST_DIR%\%FINAL_FOLDER%"
    echo [%DATE% %TIME%] Removed folder: %DEST_DIR%\%FINAL_FOLDER% >> "%LOG_FILE%"
)

:: Delete backup folder
if exist "%BACKUP_DIR%" (
    rmdir /s /q "%BACKUP_DIR%"
    echo [%DATE% %TIME%] Removed backup dir: %BACKUP_DIR% >> "%LOG_FILE%"
)

:: Delete downloaded zip
if exist "%ZIP_FILE%" (
    del "%ZIP_FILE%" >nul
    echo [%DATE% %TIME%] Removed ZIP file: %ZIP_FILE% >> "%LOG_FILE%"
)

echo ✅ Cleanup complete.
exit /b
