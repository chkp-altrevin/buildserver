## Docker Images

The first method that Vagrant can use to source a Docker container is via an image. This image can be from any Docker registry. An example is shown below:

```
Vagrant.configure("2") do |config|
  config.vm.provider "docker" do |d|
    d.image = "foo/bar"
  end
end
```

When `vagrant up --provider=docker` is run, this will bring up the image foo/bar.

This is useful for extra components of your application that it might depend on: databases, queues, etc. Typically, the primary application you are working on is built with a Dockerfile, or via a container with SSH.

## Dockerfiles
Vagrant can also automatically build and run images based on a local Dockerfile. This is useful for iterating on an application locally that is built into an image later. An example is shown below:

```
Vagrant.configure("2") do |config|
  config.vm.provider "docker" do |d|
    d.build_dir = "."
  end
end
```

The above configuration will look for a Dockerfile in the same directory as the Vagrantfile. When `vagrant up --provider=docker` is run, Vagrant automatically builds that Dockerfile and starts a container based on that Dockerfile.

The Dockerfile is rebuilt when vagrant reload is called.

### Synced Folders and Networking
When using Docker, Vagrant automatically converts synced folders and networking options into Docker volumes and forwarded ports. You do not have to use the Docker-specific configurations to do this. This helps keep your Vagrantfile similar to how it has always looked.

The Docker provider does not support specifying options for owner or group on folders synced with a docker container.

### Volume Consistency
Docker's volume consistency setting can be specified using the docker_consistency option when defining a synced folder. This can greatly improve performance on macOS. An example is shown using the cached and delegated settings:
```
config.vm.synced_folder "/host/dir1", "/guest/dir1", docker_consistency: "cached"
config.vm.synced_folder "/host/dir2", "/guest/dir2", docker_consistency: "delegated"
```

## Host VM
If the system cannot run Linux containers natively, Vagrant automatically spins up a "host VM" to run Docker. This allows your Docker-based Vagrant environments to remain portable, without inconsistencies depending on the platform they are running on.

Vagrant will spin up a single instance of a host VM and run multiple containers on this one VM. This means that with the Docker provider, you only have the overhead of one virtual machine, and only if it is absolutely necessary.

By default, the host VM Vagrant spins up is backed by boot2docker, because it launches quickly and uses little resources. But the host VM can be customized to point to any Vagrantfile. This allows the host VM to more closely match production by running a VM running Ubuntu, RHEL, etc. It can run any operating system supported by Vagrant.

**Synced folder note**: Vagrant will attempt to use the "best" synced folder implementation it can. For boot2docker, this is often rsync. In this case, make sure you have rsync installed on your host machine. Vagrant will give you a human-friendly error message if it is not.

An example of changing the host VM is shown below. Remember that this is optional, and Vagrant will spin up a default host VM if it is not specified:

```
Vagrant.configure("2") do |config|
  config.vm.provider "docker" do |d|
    d.vagrant_vagrantfile = "../path/to/Vagrantfile"
  end
end
```

The host VM will be spun up at the first vagrant up where the provider is Docker. To control this host VM, use the `global-status` command along with global control.

