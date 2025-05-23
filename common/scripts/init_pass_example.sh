cat >password-setup <<EOF
     %echo Generating a basic OpenPGP key
     Key-Type: RSA
     Key-Length: 3072
     Subkey-Type: RSA
     Subkey-Length: 3072
     Name-Real: $USER
     Name-Comment: default password
     Name-Email: $USER@$HOSTNAME
     Expire-Date: 0
     Passphrase: changeme!
     %pubring password-setup.pub
     %secring password-manager.sec
     # Do a commit here, so that we can later print "done" :)
     %commit
     %echo done
EOF
gpg2 --batch --gen-key password-setup

gpg2 --no-default-keyring --secret-keyring ./password-setup.sec \
       --keyring ./password-setup.pub --list-secret-keys

pass init $USER@$HOSTNAME
