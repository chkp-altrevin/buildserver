#docker logs ${id}  2>&1 | grep "Bootstrap Password:" > $HOME/initial-passwd
echo "$(cat "$HOME/initial-passwd")"
echo "================================================================================"
echo "Vagrant & VirtualBox users copy password, visit https://192.168.56.10:8443"
echo "================================================================================"
echo "All others copy password and ip address associated to the host"
ip -4 addr show scope global | grep inet | awk '{print $2}' | cut -d/ -f1 | paste -sd' ' -
echo "================================================================================"
echo "Use like: https://ip-address:8443"
echo "================================================================================"
