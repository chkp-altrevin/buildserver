## SCRIPTS
Many if not all scripts in this folder are very simple, with no logic for retries, dups, permissions, etc. Alredy noted, this needs much uniformity and discussion. For a list of core scripts, they are referenced in the menu folder under the quick-setup script.

### File Structure
`ls -l /home/user/buildserver/scripts`
Example:
``` 
cluster_switch.sh
delete_k3d_cluster.sh
deploy_harbor.sh
deploy_k3d_cluster.sh
deploy_portainer.sh
deploy_rancher2.sh
etc.
```

### Getting Started

These are scripts used in the menu driven cli. You can use these outside of the menu as well in your own workflows or create your own! 

**Menu Link Structure**

```
1. Menu reads from buildserver/menu/lab-setup.sh
2. Scripts referenced int he menu read from this folder, /buildserver/scripts
```
