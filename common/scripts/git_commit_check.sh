REPO="chkp-altrevin/buildserver"
LATEST_COMMIT=$(curl -s "https://api.github.com/repos/$REPO/commits?per_page=1")

SHA=$(echo "$LATEST_COMMIT" | jq -r '.[0].sha')
DATE=$(echo "$LATEST_COMMIT" | jq -r '.[0].commit.committer.date')
MESSAGE=$(echo "$LATEST_COMMIT" | jq -r '.[0].commit.message')

echo "🔖 Latest Commit for $REPO"
echo "SHA: $SHA"
echo "Date: $DATE"
echo "Message: $MESSAGE"
