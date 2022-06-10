#!/bin/sh

set -e
set -u

echo "commit_message=$commit_message"
echo "pr_title=$pr_title"
echo "pr_message=$pr_message"
echo "UPGROBOT_GIT_URL=$UPGROBOT_GIT_URL"
echo "UPGROBOT_GIT_USER=$UPGROBOT_GIT_USER"
echo "UPGROBOT_GIT_PASS=$UPGROBOT_GIT_PASS"
echo "UPGROBOT_GIT_BRANCH=$UPGROBOT_GIT_BRANCH"
echo "UPGROBOT_GIT_EMAIL=$UPGROBOT_GIT_EMAIL"
echo "UPGROBOT_LEADING_TITLE=$UPGROBOT_LEADING_TITLE"
echo "UPGROBOT_PR_BRANCH_PREFIX=$UPGROBOT_PR_BRANCH_PREFIX"

echo "Mock PR finished"
