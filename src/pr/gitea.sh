#!/bin/sh
set -e
set -u

# This first part will check nearly all the input variables
echo "About to do the following:"
echo "Commiting the change with message '$commit_message' (Author $UPGROBOT_GIT_USER ($UPGROBOT_GIT_EMAIL))"
schema="${UPGROBOT_GIT_URL%://*}"
gitea_base_url="${UPGROBOT_GIT_URL#*://}"
gitea_base_url="${gitea_base_url%%/*}"
repo_name="$(basename $UPGROBOT_GIT_URL .git)" 
organization="${UPGROBOT_GIT_URL%/*}"
organization="${organization##*/}"
pr_branch="$UPGROBOT_PR_BRANCH_PREFIX$(echo "$pr_title" | sha256sum | head -c 7)"
echo "Creating PR in for $gitea_base_url (source $organization repo $repo_name branch '$UPGROBOT_GIT_BRANCH') from branch '$pr_branch' with title '$pr_title' and message '$pr_message'"

echo "But first, lets check if the PR with the title already exists"
prs=$(curl -s -u "$UPGROBOT_GIT_USER:$UPGROBOT_GIT_PASS" "$schema://$gitea_base_url"/api/v1/repos/"$organization"/"$repo_name"/pulls)
if ! printf '%s\n' "$prs" | python3 -c 'import json, sys; d=json.load(sys.stdin); sys.exit(len([ x for x in d if x["title"] == sys.argv[1] and x["state"] == "open"]))' "$pr_title"
then
	echo "PR with the same title already exists. We are done."
	exit 0
fi

old_pr=$(printf '%s\n' "$prs" | python3 -c 'import json, sys; d=json.load(sys.stdin); print(([""] + [ x["id"] for x in d if x["title"].startswith(sys.argv[1] + ":") and x["state"] == "open" ])[-1])' "$UPGROBOT_LEADING_TITLE")
if [ -n "$old_pr" ]
then
	echo "PR with the same leading title $UPGROBOT_LEADING_TITLE already exists. Closing it first"
	curl -s -u "$UPGROBOT_GIT_USER:$UPGROBOT_GIT_PASS" "$schema://$gitea_base_url"/api/v1/repos/"$organization"/"$repo_name"/pulls/"$old_pr" -X PATCH -H 'Content-type:application/json' -d '{"state": "closed"}'
fi

echo "Now, commiting"
git checkout -b "$pr_branch"
git config user.name "$UPGROBOT_GIT_USER"
git config user.email "$UPGROBOT_GIT_EMAIL"
git add .
git commit -m "$commit_message"

echo "Now, forking"
curl -s -u "$UPGROBOT_GIT_USER:$UPGROBOT_GIT_PASS" "$schema://$gitea_base_url"/api/v1/repos/"$organization"/"$repo_name"/forks -H 'Content-type:application/json' -d "{\"name\":\"$repo_name\"}"

echo "Now, pushing"
git push "$schema://$UPGROBOT_GIT_USER:$UPGROBOT_GIT_PASS@$gitea_base_url"/"$UPGROBOT_GIT_USER"/"$repo_name".git "$pr_branch"

echo "Now, creating PR"
new_json=$(curl -s -u "$UPGROBOT_GIT_USER:$UPGROBOT_GIT_PASS" "$schema://$gitea_base_url"/api/v1/repos/"$organization"/"$repo_name"/pulls -H 'Content-type:application/json' -d "{
	\"head\":\"$UPGROBOT_GIT_USER:$pr_branch\",
	\"base\":\"$UPGROBOT_GIT_BRANCH\",
	\"title\":\"$pr_title\",
	\"body\":\"$pr_message\"
}")
echo "$new_json"
new_pr=$(printf '%s\n' "$new_json" | python3 -c 'import json, sys; print(json.load(sys.stdin)["id"])')

if [ -n "$old_pr" ]
then
	echo "Now, commenting to the old PR"
	curl -s -u "$UPGROBOT_GIT_USER:$UPGROBOT_GIT_PASS" "$schema://$gitea_base_url"/api/v1/repos/"$organization"/"$repo_name"/issues/"$old_pr"/comments -H 'Content-type:application/json' -d "{\"body\": \"This pull request was deprecated by new changes. A new pull request was created #$new_pr\"}"
fi

echo "PR Created successfully"
