#!/bin/sh

set -e
set -u

find * -type f | while read f
do
	echo "This replaces the lines again" > "$f"
done

echo "Test change #2

All files replaced again. This should replace the old PR.

This is not actually usable change. Ignore.
"
