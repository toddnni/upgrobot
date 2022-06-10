#!/bin/sh

set -e
set -u

find * -type f | while read f
do
	echo "Line to replace the file" > "$f"
done
