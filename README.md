## 🛠️ BuildServer: Rapid DevOps Lab Provisioning
**Automated, repeatable, and customizable environments for DevOps workflows.**

---

## 🚀 Overview

**BuildServer** is a comprehensive solution for quickly setting up development and testing environments using Vagrant and VirtualBox or your own Linux infrastructure. Whether you're starting from scratch or looking to automate repetitive setup tasks, BuildServer provides a streamlined approach to provisioning.

---

## 📦 Deploy Use Cases

### 🖥️ Use Case 1: Vagrant & VirtualBox Deployment

![Vagrant_and VirtualBox](https://github.com/user-attachments/assets/652ef956-9d63-48bf-a902-3cfe4f9c8790)

Ideal for users without a pre-existing server setup. This method allows for rapid deployment on Windows. *More to come with macOS + Homebrew.

**Start Here - Install Option**: [Jump to Use Case 1](https://github.com/chkp-altrevin/buildserver/blob/main/README.md#%EF%B8%8F-use-case-1-vagrant--virtualbox-deployment-1)

---

### 🧰 Use Case 2: Bring Your Own Linux

![Linux Installs on hypervisors or cloud compute running Linux](https://github.com/user-attachments/assets/13a454ec-e6be-40ed-9c6e-c2229ea9313a)

For those with existing Linux servers or virtual machines, WSL, macOS, utilize the provisioning scripts directly.

**Start Here - Install Option**: [Jump to Use Case 2](https://github.com/chkp-altrevin/buildserver/blob/main/README.md#-use-case-2-bring-your-own-linux-1)

---

## 🧰 What's Included in `provision.sh`

Upon execution, `provision.sh` automates the installation and configuration of:

* **Essential Packages**: `unzip`, `build-essential`, `fakeroot`, `curl`
* **APT Repository Additions**:

  * `kubectl`
  * `helm`
  * `docker`
  * `terraform`
  * `aws-cli`
  * `azure-cli`
  * `google-cloud-sdk`
* **User Environment Setup**:

  * Aliases (`cls`, `renv`, etc.)
  * `.bashrc` enhancements
  * NVM installation
  * Kubeconfig directories for `k3d`
  * Host file updates
  * Sample `.env` file
  * Project path mappings for Vagrant deployments
* **Included Installers**:

  * Docker (with Compose and user group configurations)
  * Kubernetes tools
  * Development tools: NVM, Hugo, Python (with `venv`)
  * `k3d` for lightweight Kubernetes clusters
  * Sample Git repositories for customization

**Example Provisioning Log**:

```
[2025-03-12 04:12:35] [SUCCESS] APT Dependencies installed.
[2025-03-12 04:12:35] [SUCCESS] Custom MOTD configured.
[2025-03-12 04:12:35] [SUCCESS] .bashrc updated.
...
[2025-03-12 04:13:07] [SUCCESS] Initial SBOM generated.
```

### 🌐 Environment Variables

A sample `.env` file is provided at `/home/vagrant/.env` to assist with environment configuration.

### 📁 Folder Structure

```
- common/menu         # System menu scripts
- common/profile      # Alias, bashrc, system scripts
- common/resources    # Additional resource files and examples
- common/scripts      # Simple scripts used by the demos
- common/deploy       # Various deployment files
- Vagrantfile         # Main deployment file
- install-script.sh   # Online installer, calls provision.sh
- provision.sh        # Primary provisioning script
- reboot.sh           # Only for Vagrant/VirtualBox deployments
```

### 🖥️ DNS and Hostname Configuration

During provisioning, the Vagrant host is configured to use `buildserver.local`. Plan on using long-term, modify as needed:

```bash
sudo hostnamectl set-hostname buildserver.local
```

**Host Entries**:

```bash
sudo -- sh -c "echo '192.168.56.10  rancher.buildserver.local' >> /etc/hosts"
sudo -- sh -c "echo '192.168.56.10  nginxproxymgr.buildserver.local' >> /etc/hosts"
sudo -- sh -c "echo '192.168.56.10  api.buildserver.local' >> /etc/hosts"
sudo -- sh -c "echo '192.168.56.10  buildserver.buildserver.local' >> /etc/hosts"
```

---

### 🖥️ CLI Menu

A cli menu (quick-setup) is created during provisioning. Sample capabilities below:
Use or modify and make your own.

```bash
quick-setup
```
### 📁 Menu Dependancy Structure
```
- menu/         # System menu scripts
- profile/      # Alias, bashrc, system scripts
- scripts/      # Simple scripts used by the demos
```
#### Menu Sample below:
```  
                                        QUICK-SETUP
===================================================
SETUP ENV VARS=====================================
1. EDIT 2. BACKUP 3. IMPORT 4. RESET  |   x. renv
===================================================
PACKAGE UPDATES-OS RELATED=========================
```

## 📦 Package Installations

An SBOM is generated post-provisioning and located in the root path. Installed packages include:

* `apt-transport-https`
* `base-files`
* `bash`
* `build-essential`
* `ca-certificates`
* `cloud-init`
* `containerd.io`
* `curl`
* `docker-ce`
* `docker-compose-plugin`
* `git`
* `kubectl`
* `nodejs`
* `npm`
* `openssh-server`
* `python3`
* `terraform`
* ...and more.

---

## 🐞 Known Issues

* **Vagrant Compatibility**: Vagrant v2.4.3 is compatible with VirtualBox versions 4.0.x through 7.1.x. Ensure installations are performed in order: VirtualBox first, then Vagrant. Refer to the [official support guide](https://developer.hashicorp.com/vagrant/docs/providers/virtualbox) for more details.

---

## 🛠️ Getting Started

### 🖥️ Use Case 1: Vagrant & VirtualBox Deployment

**Prerequisites**:

1. **Internet Connection**: Required for downloading packages during provisioning.
2. **Install Vagrant**: [Download Vagrant](https://developer.hashicorp.com/vagrant/install?product_intent=vagrant)
3. **Install VirtualBox**: [Download VirtualBox](https://www.virtualbox.org/wiki/Downloads)
4. **Download Latest Release**:
   - Download using a guided install (good idea to review before running, if satisfied right click on the link, save as `downloader.bat`.[downloader.bat](https://raw.githubusercontent.com/chkp-altrevin/buildserver/main/common/deploy/windows/downloader.bat). 
   - Run `downloader.bat` follow the prompts. extracts buildserver.  `cd buildserver`, `vagrant up`, `vagrant ssh`.
   - **or** [buildserver-main.zip](https://github.com/chkp-altrevin/buildserver/archive/refs/heads/main.zip). Download the zip to your folder of choice. Extract the contents `buildserver-main`, rename to `buildserver` `cd buildserver` `vagrant up` `vagrant ssh`

**or** use the below powershell snippet which will download the zip to your `Download` folder. It will need to be extracted, renamed to "buildserver" `cd buildserver` `vagrant up` `vagrant ssh`.
```powershell
powershell Invoke-WebRequest -Uri "https://github.com/chkp-altrevin/buildserver/archive/refs/heads/main.zip" -OutFile "$env:USERPROFILE\Downloads\buildserver-main.zip
```

**Start Vagrant/VirtualBox Provisioning**
   ```bash
   vagrant up # this is always ran in the root of the project folder where Vagrantfile is located
   ```
**Updating the Buildserver repo**
2 options:

**Access the VM**:
   - **Example:** C:\buildserver\vagrant ssh

   ```bash
   vagrant ssh
   ```
Upon SSH login, you'll be greeted with a custom MOTD and available commands (quick-setup) to assist with further setups or installs.


**Quick-Menu**
`quick-setup`

### ⚙️ Customizations

#### 🖥️ Terminal Configuration

Applicable for Vagrant & VirtualBox deployments, configure your preferred terminal (e.g., MobaXterm) with the following:

* **Username**: `vagrant`
* **Private Key**: Located in your Windows host folder for VirtualBox (e.g., `C:\Users\YourName\Documents\Virtual Machines\buildserver\`)
* **Host IP**: `192.168.56.10`
* **Port**: `2222`

---

### 🧰 Use Case 2: Bring Your Own Linux
Install using option (1) script or (2) download and extract manually.

1. **Installer Script** for Linux, WSL, GitBash, etc.
Downloads repo, extract and backup if exists and installs dependencies (all-in-one):

```bash
curl -fsSL https://raw.githubusercontent.com/chkp-altrevin/buildserver/main/install-script.sh -o install-script.sh -f && chmod +x install-script.sh && sudo ./install-script.sh --install
```

**Script Usage**

Install:
```bash
./install-script.sh --install
```
Download Only:
```bash
./install-script.sh --repo-download
```
Displays Help Menu:
```bash
./install-script.sh --help
```

---

After provisioning is complete logut/login. You will be greeted with a custom MOTD and available commands to assist with further setup.

## Manual Install
2. **Download Zip, Extract, chmod** for Linux, WSL, GitBash, etc.

   a. **Download Latest Release**: [buildserver-main.zip](https://github.com/chkp-altrevin/buildserver/archive/refs/heads/main.zip)
   
   b. **Extract**: Use your extraction app to extract buildserver-main.zip rename to folder **buildserver** Example Path: **$HOME/buildserver**
   
   c. **Set Permissions and Install**:
   
    ```bash
   chmod +x ./provision.sh
   sudo ./provision.sh
   ```
   **Usage Menu**: 
   ```bash
   sudo ./provision.sh --help
   ```
---

## 🛠️ Clone and Make it Yours!

1. **Clone Repository**:

   ```bash
   git clone https://github.com/chkp-altrevin/buildserver.git
   cd buildserver
   ```
2. **Configure Environment Variables**:

   * Edit `provision.sh` and modify the top 4 environment variables as needed.
3. **Set Execute Permissions**:

   ```bash
   chmod +x provision.sh
   ```
4. **Run Provisioning Script**:

   ```bash
   ./provision.sh
   ```

---

## 🤝 Contributing

Contributions are welcome! To contribute:

1. Fork the repository.
2. Create a new branch:

   ```bash
   git checkout -b feature/YourFeature
   ```
3. Commit your changes:

   ```bash
   git commit -m 'Add YourFeature'
   ```
4. Push to the branch:

   ```bash
   git push origin feature/YourFeature
   ```
5. Open a pull request.

Please ensure your code adheres to the existing style and includes relevant tests.

---

### 🚀 GitHub Release Workflow:

* **File**: `.github/workflows/release.yml`
* Automatically zips and uploads `buildserver-release.zip` when you push a tag like `v1.0.0`

---

## 📄 License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.

---

## 📞 Support

For issues or feature requests, please open an [issue](https://github.com/chkp-altrevin/buildserver/issues) on GitHub.

---

