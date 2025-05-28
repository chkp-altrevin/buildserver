# -*- mode: ruby -*-
# vi: set ft=ruby :

# Vagrantfile API/syntax version. Don't touch unless you know what you're doing
VAGRANTFILE_API_VERSION = "2"

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|
  config.vm.synced_folder ".", "/home/vagrant/buildserver", disabled: false
  # config.vm.boot_timeout = "1440"
  config.vm.define "builder", primary: true  do |builder|
    # builder.vm.box = "hashicorp/bionic64"
    builder.vm.box = "ubuntu/jammy64"
    builder.vm.hostname = "buildserver"
    builder.vm.network "private_network", ip: "192.168.56.10"
    builder.vm.provision :shell, reboot: true, path: "provision.sh"
    builder.vm.provision :shell, path: "reboot.sh"
    builder.vm.provider "virtualbox" do |vb|
      vb.memory = "4096"
      vb.cpus = 1
      vb.gui = false
      vb.name = "buildserver"
    end
  end
#  config.vm.define "fwmgw", autostart: false do |fwmgw|
#    fwmgw.vm.box = "cloudguard/cg-fwm-gw"
#  end
end

