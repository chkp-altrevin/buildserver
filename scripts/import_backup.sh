# confirm and edit
echo "save existing env, importing .backup.env.."
sleep 3
vi $HOME/.backup.env
#
cp $HOME/.backup.env $HOME/.env
