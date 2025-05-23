 gpg2 --full-generate-key
gpg --quick-gen-key --batch --passphrase 'changeme!' $USER@$HOSTNAME

# pass init $USER "Password Storage Key"
# pass generate CloudGuard/spectral 15
# pass generate CloudGuard/shiftleft 15
# pass generate CloudGuard/k8s-onboard 15
