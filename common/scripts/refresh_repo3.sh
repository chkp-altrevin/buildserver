# Grap the latest
curl -fsSL https://raw.githubusercontent.com/chkp-altrevin/buildserver/main/install-script.sh -o install-script.sh && chmod +x install-script.sh && sudo ./install-script.sh --repo-download

# start the provisioning
./provision.sh
