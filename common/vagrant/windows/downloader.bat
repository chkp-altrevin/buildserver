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

:: Command-line flags
if "%~1"=="--cleanup" goto :cleanup
if "%~1"=="--refresh" (
    call "%~f0"
    exit /b
)

:: Prompt user for extraction path
set /p DEST_DIR=Enter extract destination path (default is %USERPROFILE%): 
if "%DEST_DIR%"=="" set DEST_DIR=%USERPROFILE%

echo Extraction path: %DEST_DIR% >> "%LOG_FILE%"

:: Ensure destination exists
if not exist "%DEST_DIR%" (
    echo [%DATE% %TIME%] ERROR: Destination path does not exist. >> "%LOG_FILE%"
    echo ERROR: Destination path does not exist.
    exit /b 1
)

:: Download zip
echo [%DATE% %TIME%] Downloading zip file... >> "%LOG_FILE%"
powershell -Command "Invoke-WebRequest -Uri '%ZIP_URL%' -OutFile '%ZIP_FILE%' -ErrorAction Stop"
if errorlevel 1 (
    echo [%DATE% %TIME%] ERROR: Failed to download ZIP file. >> "%LOG_FILE%"
    exit /b 1
)

:: Backup existing folder
if exist "%DEST_DIR%\%FINAL_FOLDER%" (
    echo [%DATE% %TIME%] Existing buildserver found, backing up... >> "%LOG_FILE%"
    if not exist "%BACKUP_DIR%" mkdir "%BACKUP_DIR%"
    powershell -Command "Compress-Archive -Path '%DEST_DIR%\%FINAL_FOLDER%' -DestinationPath '%BACKUP_DIR%\buildserver_backup_%DATE:/=-%_%TIME::=-%.zip'"
)

:: Extract
echo [%DATE% %TIME%] Extracting archive... >> "%LOG_FILE%"
tar -xf "%ZIP_FILE%" -C "%DEST_DIR%" || (
    echo [%DATE% %TIME%] ERROR: Failed to extract ZIP. >> "%LOG_FILE%"
    exit /b 1
)

:: Copy extracted contents into existing or new buildserver folder
echo [%DATE% %TIME%] Merging extracted folder contents... >> "%LOG_FILE%"
if not exist "%DEST_DIR%\%FINAL_FOLDER%" (
    move "%DEST_DIR%\%EXTRACT_FOLDER%" "%DEST_DIR%\%FINAL_FOLDER%" >nul 2>&1
) else (
    powershell -Command "Copy-Item -Path '%DEST_DIR%\%EXTRACT_FOLDER%\*' -Destination '%DEST_DIR%\%FINAL_FOLDER%' -Recurse -Force"
    rmdir /s /q "%DEST_DIR%\%EXTRACT_FOLDER%"
)

:: Change directory
cd /d "%DEST_DIR%\%FINAL_FOLDER%"
cd "%DEST_DIR%\%FINAL_FOLDER%"
echo [%DATE% %TIME%] Changed directory to %DEST_DIR%\%FINAL_FOLDER% >> "%LOG_FILE%"

echo DONE. Folder ready at: %DEST_DIR%\%FINAL_FOLDER%
exit /b 0

:: ----------------------------------------
:cleanup
echo [%DATE% %TIME%] Running cleanup... >> "%LOG_FILE%"
del /q "%ZIP_FILE%" 2>nul
rmdir /s /q "%USERPROFILE%\%FINAL_FOLDER%" 2>nul
rmdir /s /q "%USERPROFILE%\%EXTRACT_FOLDER%" 2>nul
echo [%DATE% %TIME%] Cleanup complete. >> "%LOG_FILE%"
echo All generated files removed.
exit /b
