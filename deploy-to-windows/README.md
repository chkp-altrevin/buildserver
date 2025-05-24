## Buildserver Installer for Windows
=================================

Usage:
-------
Run from PowerShell or double-click the batch file:

    install.bat --install      # Fresh install
    install.bat --refresh      # Reinstall with backup

Log file will be saved to: %USERPROFILE%\install_buildserver.log

---

### Option 1: Use Named Switches (No Dashes)

```powershell
.\install.ps1 -Refresh
```

### Option 2: Use powershell.exe with Explicit Switches
```powershell
powershell.exe -ExecutionPolicy Bypass -File .\install.ps1 -Refresh
```

### Option 3: Use the .bat Launcher
If you run install.bat inside the extracted folder:

```cmd
install.bat --refresh
```
That’s handled properly — the .bat wrapper passes arguments to powershell.exe -File