# 🛠️ BuildServer: Rapid DevOps Lab Provisioning

**Automated, repeatable, and customizable environments for DevOps workflows.**

---

## 🚀 Overview

**BuildServer** is a comprehensive solution for quickly setting up development and testing environments using Vagrant and VirtualBox or your own Linux infrastructure. Whether you're starting from scratch or looking to automate repetitive setup tasks, BuildServer provides a streamlined approach to provisioning.

---

## 📦 Deploy Use Cases

### 🖥️ Use Case 1: Vagrant & VirtualBox Deployment

![Vagrant_and VirtualBox](https://github.com/user-attachments/assets/652ef956-9d63-48bf-a902-3cfe4f9c8790)

Ideal for users without a pre-existing server setup. This method allows for rapid deployment on Windows, (Mac, Linux not tested but should work) using local machine setup.

**Start Here - Install Option**: [Jump to Use Case 1](https://github.com/chkp-altrevin/buildserver/blob/main/README.md#%EF%B8%8F-use-case-1-vagrant--virtualbox-deployment-1)

---

### 🧰 Use Case 2: Bring Your Own Linux

![Linux Installs on hypervisors or cloud compute running Linux](https://github.com/user-attachments/assets/13a454ec-e6be-40ed-9c6e-c2229ea9313a)

For those with existing Linux servers or virtual machines, utilize the provisioning scripts directly.

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

---

## 🛠️ Getting Started

### 🖥️ Use Case 1: Vagrant & VirtualBox Deployment

**Prerequisites**:

1. **Internet Connection**: Required for downloading packages during provisioning.
2. **Install Vagrant**: [Download Vagrant](https://developer.hashicorp.com/vagrant/install?product_intent=vagrant)
3. **Install VirtualBox**: [Download VirtualBox](https://www.virtualbox.org/wiki/Downloads)
4. **Clone Repository**:

**Prior to cloning for Windows Git users**
- If you use Windows non-wsl: Set the following: `git config --global core.autocrlf input`
  This will keep your commits clean with LF only, even if editing on Windows. 

- If you use **WSL/Linux environment** proceed below and clone the repo.

- No git no worries, [download as zip below](https://github.com/chkp-altrevin/buildserver/blob/main/README.md#optional-deployment--download-as-zip).

```bash
git clone https://github.com/chkp-altrevin/buildserver.git
```
```bash
cd buildserver
```
6. **Start Vagrant**:
   ```bash
   vagrant up # this is always ran in the root of the project folder where Vagrantfile is located
   ```
   Example: C:\buildserver\vagrant up
7. **Access the VM**:

   ```bash
   vagrant ssh
   ```
   Example: C:\buildserver\vagrant ssh
Upon SSH login, you'll be greeted with a custom MOTD and available commands to assist with further setup.

**🚀 Pro Tip!**
If you see errors similiar to:
```
builder: /home/vagrant/.env: line 13: $'\r': command not found
builder: /home/vagrant/.env: line 17: $'\r': command not found
builder: /home/vagrant/.env: line 21: $'\r': command not found
 ```
Above is a good indicator we are seeing crlf, did you set `git config --global core.autocrlf input` mentioned above? If you need to start over see below to reset.

---

### 🧰 Use Case 2: Bring Your Own Linux

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

## 🖥️ Troubleshooting
Forgot a step or need to level set. No worries, follow the steps below.

### Start Over | Use Case 1
Step 1. Remove the repo it it exists, cd to C:\buildserver (or wherever you extracted to) --> vagrant destroy -f --> cd C:\ --> rmdir /S buildserver 
Step 2. Setup Git: `git config --global core.autocrlf input` this will keep your commits clean with LF only, even if editing on Windows.
 - If you use an editor (e.g., VS Code, Notepad++, Sublime) configure to use LF line endings for shell scripts.
 - In VS Code: bottom-right corner → click "CRLF" → change to "LF".
 - If you can't get past issues with using Git, another option is to download as a zip see below.

### Start Over | Use Case 2
Step 1. Remove the repo, example: `rm -rf /home/vagrant/buildserver --> `cd /home/vagrant` Clone again `git clone https://github.com/chkp-altrevin/buildserver.git`
Step 2. Change into our directory: `cd /home/user/buildserver`
Step 3. Set execute permissions: `chmod +x provision.sh`
Step 4. Re-run provisioning: `sudo ./provision.sh`

---

### Optional Deployment | Download as Zip
- Visit: https://github.com/chkp-altrevin/buildserver
- Download: builder-main.zip --> extract drop the branch name from the folder --> Example: `C:\buildserver` or `$HOME/buildserver`
- Provision Use Case 1: `cd C:\buildserver` --> `vagrant up`
- Provision Use Case 2: `cd $HOME/buildserver` --> `sudo ./provision`
- Login: --> `vagrant ssh` (use case 1)

---

## ⚙️ Optional Customizations

### 🖥️ Terminal Configuration

Applicable for Vagrant & VirtualBox deployments, configure your preferred terminal (e.g., MobaXterm) with the following:

* **Username**: `vagrant`
* **Private Key**: Located in your Windows host folder for VirtualBox (e.g., `C:\Users\YourName\Documents\Virtual Machines\buildserver\`)
* **Host IP**: `192.168.56.10`
* **Port**: `2222`

### 🌐 Environment Variables

A sample `.env` file is provided at `/home/vagrant/.env` to assist with environment configuration.

### 📁 Folder Structure

```
- ignores/      # Example Docker and Git ignore files
- menu/         # System menu scripts
- deploy/       # Workloads and apps for demos
- profile/      # Alias, bashrc, system scripts
- resources/    # Additional resource files and examples
- scripts/      # Simple scripts used by the demos
- Vagrantfile   # Main deployment file
- provision.sh  # Primary provisioning script
- reboot.sh     # Secondary provisioning script
```

### 🖥️ DNS and Hostname Configuration

During provisioning, the Vagrant host is configured to use `buildserver.local`. Modify as needed:

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
- deploy/       # Workloads and apps for demos
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
* `unzip`
* ...and many more.

---

## 🐞 Known Issues

* **Vagrant Compatibility**: Vagrant v2.4.3 is compatible with VirtualBox versions 4.0.x through 7.1.x. Ensure installations are performed in order: VirtualBox first, then Vagrant. Refer to the [official support guide](https://developer.hashicorp.com/vagrant/docs/providers/virtualbox) for more details.

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

## 📄 License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.

---

## 📞 Support

For issues or feature requests, please open an [issue](https://github.com/chkp-altrevin/buildserver/issues) on GitHub.

---

