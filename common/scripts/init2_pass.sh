# gpg2 --list-secret-keys
# need to check for existing and output to reset or override
gpg2 --quick-gen-key --batch --passphrase 'changeme!' $USER@$HOSTNAME
pass init $USER@$HOSTNAME
