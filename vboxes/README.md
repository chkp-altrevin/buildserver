## How do I run the examples?
Copy any of the examples back to your C:\ path and customize the `Vagrantfile` if needed. Example below.

```
CD into:
C:\ubuntu-base
```
```
Review or customize:
C:\ubuntu-base\Vagrantfile
```

When ready to bring up make sure you are in your terminal and in the root path leading to your `Vagrantfile` before proceeding.
```
Example:
C:\ubuntu-base\vagrant up
```

### General Workflow
```
vagrant up # will bring up the Vagrant box
vagrant ssh # SSH login
vagrant destroy # removes the box completely
vagrant destroy -f # same as above but forces
```
These commands , SSH into it.
If you want to force remove .

## Vagrant Env Vars
`https://developer.hashicorp.com/vagrant/docs/other/environmental-variables`

## Public Template Download 
```
vagrant box add precise32 http://files.vagrantup.com/precise32.box
```

## Summary of examples
Single box with some custom configuration.
Single box with VirtualBox provider.
## Discover more
https://portal.cloud.hashicorp.com/vagrant/discover
