#!/bin/sh
set -u

git diff --exit-code HEAD --
if [ $? -eq 0 ]
then
	echo "No changes!"
else
	echo "Changes detected!"
fi
