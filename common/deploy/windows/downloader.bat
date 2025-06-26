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
if "%~1"=="" goto :missing_flag
if "%~1"=="--help" goto :help
if "%~1"=="--cleanup" goto :cleanup
if "%~1"=="--refresh" goto :do_refresh
if "%~1"=="--install" goto :install

goto :unknown_flag

:missing_flag
echo [ERROR] No flag provided. Use --install to run the installer.
goto :help

:unknown_flag
echo [ERROR] Unknown flag: %~1
goto :help

:install
:: Prompt user for extraction path
set /p DEST_DIR=Enter extract destination path (default is %USERPROFILE%): 
if "%DEST_DIR%"=="" set DEST_DIR=%USERPROFILE%

:: Ensure backup directory exists
if not exist "%BACKUP_DIR%" (
    mkdir "%BACKUP_DIR%"
)
:do_refresh
:: Prompt user for destination path
set /p DEST_DIR=Enter extract destination path (default is %USERPROFILE%): 
if "%DEST_DIR%"=="" set DEST_DIR=%USERPROFILE%

:: Ensure target exists
if not exist "%DEST_DIR%\%FINAL_FOLDER%" (
    echo [ERROR] Cannot refresh: %DEST_DIR%\%FINAL_FOLDER% does not exist.
    exit /b 1
)

:: Download latest ZIP
echo [INFO] Downloading latest buildserver ZIP for refresh...
powershell -Command "Invoke-WebRequest -Uri '%ZIP_URL%' -OutFile '%ZIP_FILE%' -UseBasicParsing"

:: Extract to TEMP folder
set TEMP_EXTRACT=%TEMP%\refresh_buildserver
if exist "%TEMP_EXTRACT%" rd /s /q "%TEMP_EXTRACT%"
powershell -Command "Expand-Archive -Path '%ZIP_FILE%' -DestinationPath '%TEMP_EXTRACT%' -Force"

:: Copy updated files (excluding .vagrant and customizations)
echo [INFO] Copying updated files...
xcopy "%TEMP_EXTRACT%\%EXTRACT_FOLDER%\*" "%DEST_DIR%\%FINAL_FOLDER%\" /E /H /Y /C /Q >nul

:: Cleanup temp extract
rd /s /q "%TEMP_EXTRACT%"

:: Completion
echo [INFO] Refresh complete. Updated files in: %DEST_DIR%\%FINAL_FOLDER%
echo [INFO] Refresh complete. >> "%LOG_FILE%"
exit /b

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
echo [INFO] Extracting ZIP to: %DEST_DIR% >> "%LOG_FILE%"
powershell -Command "Expand-Archive -Path '%ZIP_FILE%' -DestinationPath '%DEST_DIR%' -Force"

:: Rename extracted folder
if exist "%DEST_DIR%\%EXTRACT_FOLDER%" (
    ren "%DEST_DIR%\%EXTRACT_FOLDER%" "%FINAL_FOLDER%"
)

:: Completion message
echo Installation complete. Project folder: %DEST_DIR%\%FINAL_FOLDER%
echo NEW INSTALL: CD %FINAL_FOLDER% run: vagrant up *install can take up to 10 min
echo UPGRADE: CD %FINAL_FOLDER% run: vagrant up --provision
echo Once complete run: vagrant ssh
echo [INFO] Installation complete at %DEST_DIR%\%FINAL_FOLDER% >> "%LOG_FILE%"
exit /b


:help
echo --------------------------------------------------
echo               BuildServer Installer
echo --------------------------------------------------
echo First Time Install:
echo.
echo    downloader.bat --install *Warning: DO NOT use for upgrading instead use --refresh
echo.
echo Upgrade Existing Install:
echo.
echo    downloader.bat --refresh *Info: Pulls down the latest buildserver and does a copy .vagrant intact
echo.
echo Usage Flags:
echo    --install    Run initial full installation process
echo    --refresh    Re-run the script and re-install
echo    --cleanup    Remove buildserver, backups, and zip
echo    --help       Show this help message
echo.
echo Examples:
echo    downloader.bat --install
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
:: set "BUILD_DIR=C:\Users\YourName\buildserver"
:: Example path - replace with actual build dir if not already set

:: if exist "%DOT_VAGRANT%" (
::     echo [INFO] Destroy Buildserver... >> "%LOG_FILE%"
::     vagrant destroy -f
:: ) else (
::     echo [INFO] No usable buildserver found at %BUILD_DIR%. Manually remove by UI or CD to %USERPROFILE%\"VirtualBox VMs" and delete the folder. >> "%LOG_FILE%"
:: )

:: Check if .vagrant directory exists
if exist "%DOT_VAGRANT%" (
    echo [INFO] Existing Vagrant VM detected at %DOT_VAGRANT% >> "%LOG_FILE%"
    echo.
    echo ⚠ Do you want to destroy the existing VM? (Y/N)
    choice /c YN /n /m "Confirm (Y/N): "
    if errorlevel 2 (
        echo [INFO] User declined destruction. >> "%LOG_FILE%"
        echo Aborting...Use --refresh to update the project without starting from scratch
        echo User aborted provisioning - chose not to destroy existing Vagrant VM >> "%LOG_FILE%"
        exit /b 1
    ) else (
        echo [INFO] Destroying existing Vagrant VM... >> "%LOG_FILE%"
        echo Destroying VM at %DOT_VAGRANT%

        where vagrant >nul 2>&1
        if errorlevel 1 (
            echo [ERROR] Vagrant not found. Please install Vagrant or destroy manually. >> "%LOG_FILE%"
            echo Failed: Vagrant not found in PATH 
            exit /b 1
        ) else (
            vagrant destroy -f
            if errorlevel 1 (
                echo [ERROR] Vagrant destroy failed. Manual cleanup may be needed. >> "%LOG_FILE%"
                echo Vagrant destroy command failed
                exit /b 1
            ) else (
                echo [INFO] VM destroyed successfully. >> "%LOG_FILE%"
                echo Vagrant destroy succeeded"
            )
        )
    )
) else (
    echo [INFO] No usable buildserver found at %BUILD_DIR%. >> "%LOG_FILE%"
    echo Manually remove via VirtualBox UI or delete folder at: %USERPROFILE%\VirtualBox VMs
    echo No Vagrant VM found. Skipping destroy."
)

echo Cleanup complete.
echo [INFO] Cleanup complete. >> "%LOG_FILE%"
exit /b
