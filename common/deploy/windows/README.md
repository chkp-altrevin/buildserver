## Buildserver Installers for Windows
=================================
I don't know exactly why I created so many options but there you go :)
**Using downloader.bat**

Usage:
-------
Run from cmd window:

    downloader.bat --install    # Default fresh install, if existing will backup, wipe, install (dont use if you need to upgrade use next one)
    downloader.bat --refresh    # Updates your existing install safely, will backup, install over, preserves all vagrant virtualbox pieces
    downloader.bat --cleanup    # Removes your project
    downloader.bat --help       # this menu

**Using install.bat / install.ps1**

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

---

### Vagrant
Vagrant Downloads: https://developer.hashicorp.com/vagrant/downloads

### How to use multiple hypervisors
Hypervisors often do not allow you to bring up virtual machines if you have more than one hypervisor in use.

Below are a couple of examples to allow you to use Vagrant and VirtualBox if another hypervisor is present.

### Linux, VirtualBox, and KVM
If you see error messages because another hypervisor, like KVM, is in use etc.

Reference: https://developer.hashicorp.com/vagrant/docs/installation
