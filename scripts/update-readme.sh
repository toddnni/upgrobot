#!/bin/sh

set -e
set -u

cd "$(dirname $0)"

help_text="$(UPGROBOT_CLONE_DIR=/tmp/clonepath ../src/upgrobot.sh -h | sed -e 's|../src/upgrobot.sh|upgrobot.sh|' -e 's|/home/.*/src|/bin/path|')"

cd ..
echo "$help_text" | python -c 'import sys
help = sys.stdin.read()
with open("README.md") as f:
  content = f.read()

in_old_section=False
for line in content.splitlines():
  if line.startswith("    usage:"):
    in_old_section = True
  elif in_old_section and line == "":
    in_old_section = False
    for line in help.splitlines():
      print("    " + line)
    print("")
  else:
    if not in_old_section:
      print(line)
' > README.md2
mv README.md2 README.md
