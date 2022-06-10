#!/bin/sh
# Assumes that empty gitea is running beside in localhost:3000
# Provide the tested script name as paramater
set -e
set -u

ADMIN_USER=admin2
ADMIN_PASS=abcdefg
BOT_USER=botuser
BOT_USER_PASS=123456

assert_line() {
	egrep -q "^$@" || ( echo "ERROR did not find string '$@' from the output!" && false )
}

cd "$(dirname $0)"
TESTS_DIR="$(realpath $PWD)"
MAIN="$1"

echo "## The first quick CLI tests ##################################################"
echo "## Test: help message"
"$MAIN" -r https://git.example.org/repo.git -h

echo "## Test: parameters, missing parameter"
out=$("$MAIN" -r https://git.example.org/repo.git -p b -b main -e a@example.org -t Example -U test -P gitea 2>&1 || true)
echo "$out"
echo "$out" | head -1 | assert_line "Error: Some mandatory parameters missing!"

echo "## Initialize gitea for GIT repo ##############################################"
echo "## Init: gitea users for testing"
echo "Waiting for gitea"
not_reachable=y
for i in $(seq 1 60)
do
	if curl -s http://localhost:3000/ >/dev/null
	then
		not_reachable=
		continue
	fi
	sleep 1
done
if [ -n "$not_reachable" ]
then
	echo "Error: Gitea not reachable"
	exit 1
fi
curl -s http://localhost:3000/user/sign_up -F user_name="$ADMIN_USER" -F email="$ADMIN_USER"@example.org -F password="$ADMIN_PASS" -F retype="$ADMIN_PASS"
curl -s http://localhost:3000/user/sign_up -F user_name="$BOT_USER" -F email="$BOT_USER"@example.org -F password="$BOT_USER_PASS" -F retype="$BOT_USER_PASS"

echo "## Init: repository for testing"
# Admin repo will be public and the other user had only read access to the repository
curl -s -u "$ADMIN_USER":"$ADMIN_PASS" http://localhost:3000/api/v1/user/repos -H 'Content-type:application/json' -d '{"name": "test"}'
tempdir=$(mktemp -d)
cp -a example/* "$tempdir"
(cd "$tempdir" && git init && git checkout -b main && git add . && git config user.email "$ADMIN_USER@example.com" && git config user.name "$ADMIN_USER" && git commit -m "initial commit" && git push -u http://"$ADMIN_USER":"$ADMIN_PASS"@localhost:3000/"$ADMIN_USER"/test.git main)

echo "## Test error cases with test scripts #########################################"
echo "## Test: wrong script path , results script not found"
out=$("$MAIN" -r http://localhost:3000/"$ADMIN_USER"/test.git -u "$BOT_USER" -p "$BOT_USER_PASS" -b main -e "$BOT_USER"@example.org -t "Example title" -U notfound -P gitea 2>&1 || true)
echo "$out"
echo "$out" | tail -1 | assert_line "Error: Could not find script"

echo "## Test: env vars input, results script not found (re-uses the same git clone)"
out=$(UPGROBOT_GIT_URL=http://localhost:3000/"$ADMIN_USER"/test.git UPGROBOT_GIT_USER="$BOT_USER" UPGROBOT_GIT_PASS="$BOT_USER_PASS" UPGROBOT_GIT_BRANCH=main UPGROBOT_GIT_EMAIL="$BOT_USER"@example.org UPGROBOT_LEADING_TITLE="Example title" UPGROBOT_UPDATE_SCRIPT=notfound UPGROBOT_PR_SCRIPT=gitea "$MAIN" 2>&1 || true)
echo "$out"
echo "$out" | tail -1 | assert_line "Error: Could not find script"

echo "## Init: Switch to random clone dir"
export UPGROBOT_CLONE_DIR=

echo "## Test: test update script and null pr script, should work"
out=$("$MAIN" -r http://localhost:3000/"$ADMIN_USER"/test.git -u "$BOT_USER" -p "$BOT_USER_PASS" -b main -e "$BOT_USER"@example.org -t "Example title" -U "$TESTS_DIR"/mockscripts/update-test.sh -P "$TESTS_DIR"/mockscripts/empty-pr.sh 2>&1 || true)
echo "$out"
echo "$out" | tail -1 | assert_line "Mock PR finished"
echo "$out" | assert_line "Changes detected"

echo "## Test: test missing change script output"
out=$("$MAIN" -r http://localhost:3000/"$ADMIN_USER"/test.git -u "$BOT_USER" -p "$BOT_USER_PASS" -b main -e "$BOT_USER"@example.org -t "Example title" -U "$TESTS_DIR"/mockscripts/update-missing-output.sh -P "$TESTS_DIR"/mockscripts/empty-pr.sh 2>&1 || true)
echo "$out"
echo "$out" | tail -1 | assert_line "Error: Title or commit input from change script is missing"

echo "## Test: test missing commit input"
out=$("$MAIN" -r http://localhost:3000/"$ADMIN_USER"/test.git -u "$BOT_USER" -p "$BOT_USER_PASS" -b main -e "$BOT_USER"@example.org -t "Example title" -U "$TESTS_DIR"/mockscripts/update-partial-output.sh -P "$TESTS_DIR"/mockscripts/empty-pr.sh 2>&1 || true)
echo "$out"
echo "$out" | tail -1 | assert_line "Error: Title or commit input from change script is missing"

echo "## Test: test malformed change script output, missing first empty line"
out=$("$MAIN" -r http://localhost:3000/"$ADMIN_USER"/test.git -u "$BOT_USER" -p "$BOT_USER_PASS" -b main -e "$BOT_USER"@example.org -t "Example title" -U "$TESTS_DIR"/mockscripts/update-malformed-output.sh -P "$TESTS_DIR"/mockscripts/empty-pr.sh 2>&1 || true)
echo "$out"
echo "$out" | tail -1 | assert_line "Error: Reading change output. Expecting an empty line"

echo "## Test: test change script output without instructions"
out=$("$MAIN" -r http://localhost:3000/"$ADMIN_USER"/test.git -u "$BOT_USER" -p "$BOT_USER_PASS" -b main -e "$BOT_USER"@example.org -t "Example title" -U "$TESTS_DIR"/mockscripts/update-short-output.sh -P "$TESTS_DIR"/mockscripts/empty-pr.sh 2>&1 || true)
echo "$out"
echo "$out" | tail -1 | assert_line "Mock PR finished"

echo "## Test: test evaluation logic if no changes happened"
out=$("$MAIN" -r http://localhost:3000/"$ADMIN_USER"/test.git -u "$BOT_USER" -p "$BOT_USER_PASS" -b main -e "$BOT_USER"@example.org -t "Example title" -U "$TESTS_DIR"/mockscripts/update-no-changes.sh -P "$TESTS_DIR"/mockscripts/empty-pr.sh 2>&1 || true)
echo "$out"
echo "$out" | tail -1 | assert_line "No changes"

# TODO
# -test changes and no changes

echo "## PR gitea test ##############################################################"

echo "## Test: create PR, should succeed"
out=$("$MAIN" -r http://localhost:3000/"$ADMIN_USER"/test.git -u "$BOT_USER" -p "$BOT_USER_PASS" -b main -e "$BOT_USER"@example.org -t "Example title" -U "$TESTS_DIR"/mockscripts/update-test.sh -P pr/gitea.sh 2>&1 || true)
echo "$out"
echo "$out" | tail -1 | assert_line "PR Created successfully"

echo "## Test: try to create another PR, will not do anything"
out=$("$MAIN" -r http://localhost:3000/"$ADMIN_USER"/test.git -u "$BOT_USER" -p "$BOT_USER_PASS" -b main -e "$BOT_USER"@example.org -t "Example title" -U "$TESTS_DIR"/mockscripts/update-test.sh -P pr/gitea.sh 2>&1 || true)
echo "$out"
echo "$out" | tail -1 | assert_line "PR with the same title already exists"

echo "## Test: replace the PR"
out=$("$MAIN" -r http://localhost:3000/"$ADMIN_USER"/test.git -u "$BOT_USER" -p "$BOT_USER_PASS" -b main -e "$BOT_USER"@example.org -t "Example title" -U "$TESTS_DIR"/mockscripts/update-test2.sh -P pr/gitea.sh 2>&1 || true)
echo "$out"
echo "$out" | tail -1 | assert_line "PR Created successfully"
echo "$out" | tail -3 | assert_line "Now, commenting to the old PR"

echo "## TESTS SUCCESS ##############################################################"
