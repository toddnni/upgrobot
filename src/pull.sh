#!/bin/sh
set -e
set -u

urlwoschema="${UPGROBOT_GIT_URL#*://}"
schema="${UPGROBOT_GIT_URL%://*}"
echo "Cloning '$schema://$UPGROBOT_GIT_USER@$urlwoschema' branch '$UPGROBOT_GIT_BRANCH' to '$UPGROBOT_CLONE_DIR'"
if [ -d "$UPGROBOT_CLONE_DIR/.git" ]
then
	cd "$UPGROBOT_CLONE_DIR"
	git checkout "$UPGROBOT_GIT_BRANCH"
	git pull "$schema://$UPGROBOT_GIT_USER:$UPGROBOT_GIT_PASS@$urlwoschema" "$UPGROBOT_GIT_BRANCH"
	git reset --hard
else
	git clone "$schema://$UPGROBOT_GIT_USER:$UPGROBOT_GIT_PASS@$urlwoschema" -b "$UPGROBOT_GIT_BRANCH" "$UPGROBOT_CLONE_DIR"
fi
