#!/usr/bin/env bash
set -euo pipefail

# Recently pushed: exclude forks and the profile repo itself
pushes=$(gh api 'users/naoya25/repos?sort=pushed&per_page=30' --jq \
  '[.[] | select(.fork == false and .name != "naoya25" and .name != ".github")][:5]
   | map("- [\(.name)](\(.html_url))\(if .language then " `" + .language + "`" else "" end)\(if .description then " — " + .description else "" end)")
   | join("\n")')

# Recent PRs — public repos only, so private/company work never leaks into the profile
prs=$(gh search prs --author naoya25 --visibility public --sort updated --limit 5 \
  --json title,url,repository \
  --jq 'map("- [\(.title)](\(.url)) — \(.repository.nameWithOwner)") | join("\n")')

replace() {
  python3 - "$1" "$2" <<'PY'
import re, sys
marker, content = sys.argv[1], sys.argv[2]
with open("README.md") as f:
    readme = f.read()
pattern = re.compile(rf"(<!-- {marker}:START -->).*?(<!-- {marker}:END -->)", re.S)
readme = pattern.sub(lambda m: f"{m.group(1)}\n{content}\n{m.group(2)}", readme)
with open("README.md", "w") as f:
    f.write(readme)
PY
}

replace RECENT_PUSHES "$pushes"
replace RECENT_PRS "$prs"
