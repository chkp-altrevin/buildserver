#docker logs ${id}  2>&1 | grep "Bootstrap Password:" > $HOME/initial-passwd
echo "$(cat "$HOME/initial-passwd")"
echo "Copy password and visit https://192.168.56.10:8443"
