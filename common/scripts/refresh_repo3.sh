# Grab the latest
curl -fsSL https://raw.githubusercontent.com/chkp-altrevin/buildserver/main/install-script.sh -o install-script.sh && chmod +x install-script.sh && sudo ./install-script.sh --repo-download
# cd to our project folder
cd $PROJECT_PATH
# run provision to upgrade
./provision.sh
