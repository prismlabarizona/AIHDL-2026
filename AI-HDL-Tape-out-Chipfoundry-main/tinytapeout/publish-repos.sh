#!/usr/bin/env bash
# Publish every TinyTapeout project in this directory as its own public
# GitHub repo created from chipfoundry/chipdiscover-verilog-template,
# with GitHub Actions enabled — the format the ChipFoundry MPW flow needs.
#
# Requirements: gh CLI logged in (`gh auth status`), git.
# Usage:  ./publish-repos.sh <github-user-or-org> [project ...]
#         (no project args = all tt-* directories here)
set -euo pipefail

OWNER="${1:?usage: ./publish-repos.sh <github-user-or-org> [project ...]}"
shift || true
cd "$(dirname "$0")"

PROJECTS=("$@")
# Default: every project except tt-slm-gemm (per Jeff 2026-09-16: no
# custom-size tile on CI2609, leave the GEMM engine off this chip).
# Pass it explicitly to publish it anyway.
if [ ${#PROJECTS[@]} -eq 0 ]; then
  PROJECTS=()
  for d in tt-*/; do [ "${d%/}" != "tt-slm-gemm" ] && PROJECTS+=("$d"); done
fi

WORK=$(mktemp -d)
trap 'rm -rf "$WORK"' EXIT

for p in "${PROJECTS[@]}"; do
  name=${p%/}
  echo "=== $name ==="
  # 1. create the repo from the template (public)
  gh repo create "$OWNER/$name" \
      --template chipfoundry/chipdiscover-verilog-template \
      --public 2>/dev/null || echo "    (repo exists, updating)"
  # template generation is async; wait for the initial commit
  for i in $(seq 1 20); do
    gh api "repos/$OWNER/$name/commits" -q '.[0].sha' >/dev/null 2>&1 && break
    sleep 3
  done
  # 2. overlay the project contents on the template clone
  git clone -q "https://github.com/$OWNER/$name" "$WORK/$name"
  rm -f "$WORK/$name/src/project.v"          # template placeholder
  rsync -a --exclude .git --exclude tt --exclude runs \
        --exclude "harden*.log" --exclude sim_build --exclude results.xml \
        --exclude tb.vcd --exclude __pycache__ \
        --exclude src/user_config.json --exclude src/config_merged.json \
        --exclude src/user_defines.v \
        "$name/" "$WORK/$name/"
  # 3. make sure Actions are enabled, then push (push triggers the workflows)
  gh api -X PUT "repos/$OWNER/$name/actions/permissions" \
      -F enabled=true -f allowed_actions=all >/dev/null || true
  git -C "$WORK/$name" add -A
  git -C "$WORK/$name" commit -q -m "import $name (template-format project)" || echo "    (no changes)"
  git -C "$WORK/$name" push -q
  echo "    https://github.com/$OWNER/$name"
done

echo
echo "All pushed. Watch the Actions (test -> gds -> docs/fpga) on each repo:"
for p in "${PROJECTS[@]}"; do echo "  https://github.com/$OWNER/${p%/}/actions"; done
