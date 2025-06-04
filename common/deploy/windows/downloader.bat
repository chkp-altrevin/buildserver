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

:: ====== FLAGS ======
if "%~1"=="--help" goto :help
if "%~1"=="--cleanup" goto :cleanup
if "%~1"=="--refresh" (
    call "%~f0"
    exit /b
)


:: Prompt user for extraction path
set /p DEST_DIR=Enter extract destination path (default is %USERPROFILE%): 
if "%DEST_DIR%"=="" set DEST_DIR=%USERPROFILE%
echo [INFO] Extract path set to: %DEST_DIR% >> "%LOG_FILE%"

:: Download ZIP
echo [INFO] Downloading latest buildserver ZIP...
powershell -Command "Invoke-WebRequest -Uri '%ZIP_URL%' -OutFile '%ZIP_FILE%'"
if errorlevel 1 (
    echo [ERROR] Failed to download ZIP file. >> "%LOG_FILE%"
    exit /b 1
)

:: Ensure backup directory exists
mkdir "%BACKUP_DIR%" >nul 2>&1

:: Backup existing folder if it exists
if exist "%DEST_DIR%\%FINAL_FOLDER%" (
    :: Generate a safe timestamp using delayed expansion
    for /f "tokens=1-4 delims=/:-. " %%a in ("%DATE% %TIME%") do (
        set TS_DATE=%%d%%b%%c
        set TS_TIME=%%e%%f%%g
        set TIMESTAMP=!TS_DATE!_!TS_TIME!
        set BACKUP_NAME=buildserver_backup_!TIMESTAMP!
        set BACKUP_PATH=%BACKUP_DIR%\!BACKUP_NAME!.zip

        echo [INFO] Backing up existing %FINAL_FOLDER% to !BACKUP_PATH!
        powershell -Command "Compress-Archive -Path '%DEST_DIR%\%FINAL_FOLDER%\*' -DestinationPath '!BACKUP_PATH!' -Force"
    )
)

:: Extract without deleting target folder
echo [INFO] Extracting ZIP to: %DEST_DIR%
tar -xf "%ZIP_FILE%" -C "%DEST_DIR%"

:: Move extracted contents into FINAL_FOLDER
if exist "%DEST_DIR%\%EXTRACT_FOLDER%" (
    echo [INFO] Merging contents into %FINAL_FOLDER%...
    xcopy /E /Y /H "%DEST_DIR%\%EXTRACT_FOLDER%\*" "%DEST_DIR%\%FINAL_FOLDER%\" >nul
    rd /s /q "%DEST_DIR%\%EXTRACT_FOLDER%"
)

:: Change to project directory
cd /d "%DEST_DIR%\%FINAL_FOLDER%"
echo [INFO] Moved into project directory: %CD% >> "%LOG_FILE%"

echo ✅ Installation complete. Project folder: %CD%
exit /b 0

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
echo - Launch a new CMD window in the extracted folder.
echo.
exit /b

:cleanup
echo [INFO] Running cleanup...
del /q "%ZIP_FILE%" >nul 2>&1
rd /s /q "%DEST_DIR%\%FINAL_FOLDER%" >nul 2>&1
echo ✅ Cleanup complete.
exit /b 0
