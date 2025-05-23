curl -o harbor.sh https://gist.githubusercontent.com/kacole2/95e83ac84fec950b1a70b0853d6594dc/raw/ad6d65d66134b3f40900fa30f5a884879c5ca5f9/harbor.sh
chmod 777 harbor.sh
sudo ./harbor.sh
rm ./harbor.sh
# Print completion message
echo "Harbor installed."
