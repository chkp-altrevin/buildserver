
<#
.SYNOPSIS
    BuildServer Installer for Windows
.DESCRIPTION
    Use --install, --refresh, --cleanup, or --help to manage installation.
#>

param (
    [Parameter(Mandatory = $false)]
    [switch]$Install,

    [Parameter(Mandatory = $false)]
    [switch]$Refresh,

    [Parameter(Mandatory = $false)]
    [switch]$Cleanup,

    [Parameter(Mandatory = $false)]
    [switch]$Help
)

$ErrorActionPreference = "Stop"
$BuildserverVersion = "1.0.0"
$LogPath = "$HOME\install_buildserver.log"
$RepoUrl = "https://github.com/chkp-altrevin/buildserver/archive/refs/heads/main.zip"
$TempZip = "$env:TEMP\buildserver-main.zip"
$ExtractPath = "$env:TEMP\buildserver-main"
$TargetDir = "$HOME\buildserver"
$DesktopShortcut = "$HOME\Desktop\BuildServer.lnk"

function Log {
    param([string]$msg)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $entry = "[$timestamp] $msg"
    Write-Host $entry
    Add-Content -Path $LogPath -Value $entry
}

function Show-Help {
    Write-Host ""
    Write-Host "Buildserver Installer v$BuildserverVersion"
    Write-Host "==========================================="
    Write-Host "Usage:"
    Write-Host "  install.ps1 --install     # Fresh install if not up-to-date"
    Write-Host "  install.ps1 --refresh     # Force re-install with backup"
    Write-Host "  install.ps1 --cleanup     # Uninstall buildserver and logs"
    Write-Host "  install.ps1 --help        # Show this help menu"
    Write-Host ""
    exit 0
}

function Validate-Zip {
    param([string]$Path)
    $header = [System.IO.File]::ReadAllBytes($Path)[0..1] -join ''
    if ($header -ne '8075') {
        throw "Invalid ZIP file: missing PK signature."
    }
}

function Backup-Existing {
    if (Test-Path $TargetDir) {
        $BackupDir = "$HOME\buildserver_backup_$(Get-Date -Format 'yyyyMMdd_HHmmss')"
        Log "Backing up existing buildserver to $BackupDir"
        Copy-Item -Path $TargetDir -Destination $BackupDir -Recurse
        Remove-Item -Path $TargetDir -Recurse -Force
    }
}

function Extract-Repo {
    Log "Extracting repo..."
    Expand-Archive -Path $TempZip -DestinationPath $env:TEMP -Force
    Rename-Item -Path "$ExtractPath" -NewName "buildserver"
    Move-Item "$env:TEMP\buildserver" $TargetDir
}

function Fix-Permissions {
    Get-ChildItem -Path "$TargetDir" -Recurse -Filter *.sh | ForEach-Object {
        $_.Attributes = 'Normal'
    }
}

function Create-Shortcut {
    $WScriptShell = New-Object -ComObject WScript.Shell
    $shortcut = $WScriptShell.CreateShortcut($DesktopShortcut)
    $shortcut.TargetPath = "C:\Program Files\Git\bin\bash.exe"
    $shortcut.Arguments = "`"$TargetDir\install-script.sh`""
    $shortcut.WorkingDirectory = $TargetDir
    $shortcut.Save()
    Log "Shortcut created on Desktop."
}

function Check-Version {
    $versionFile = "$TargetDir\VERSION"
    if (Test-Path $versionFile) {
        $existingVersion = Get-Content $versionFile -ErrorAction SilentlyContinue
        Log "Existing version: $existingVersion"
        if ($existingVersion -eq $BuildserverVersion) {
            Log "Buildserver is already up to date (v$BuildserverVersion)"
            return $false
        }
    }
    return $true
}

function Write-Version {
    Set-Content -Path "$TargetDir\VERSION" -Value $BuildserverVersion
}

function Download-And-Install {
    if (-not (Check-Version)) {
        return
    }

    Log "Downloading from $RepoUrl..."
    Invoke-WebRequest -Uri $RepoUrl -OutFile $TempZip -UseBasicParsing
    Validate-Zip -Path $TempZip
    Backup-Existing
    Extract-Repo
    Fix-Permissions
    Write-Version
    Create-Shortcut
    Log "Buildserver installation complete at: $TargetDir"
}

function Cleanup-Buildserver {
    Log "Starting cleanup..."
    if (Test-Path $TargetDir) {
        Remove-Item $TargetDir -Recurse -Force
        Log "Removed: $TargetDir"
    }
    if (Test-Path $LogPath) {
        Remove-Item $LogPath -Force
        Log "Removed: $LogPath"
    }
    Log "Cleanup complete."
}

# ---------------- MAIN ----------------

try {
    if ($Help) {
        Show-Help
    } elseif ($Install -or $Refresh) {
        if (Test-Path $LogPath) { Remove-Item $LogPath -Force }
        Log "=========== Buildserver Installer Started ==========="
        Download-And-Install
    } elseif ($Cleanup) {
        Cleanup-Buildserver
    } else {
        Show-Help
    }
} catch {
    Log "ERROR: $_"
    exit 1
} finally {
    if (Test-Path $TempZip) { Remove-Item $TempZip -Force }
    if (Test-Path $ExtractPath) { Remove-Item $ExtractPath -Recurse -Force }
}
