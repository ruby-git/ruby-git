#!/usr/bin/env bash
set -euo pipefail

# Skip if this repo does not use bin/setup.
[[ -x "./bin/setup" ]] || exit 0

# Keep setup idempotent per-worktree.
command -v git >/dev/null 2>&1 || exit 0
marker="$(git rev-parse --git-path copilot-bin-setup.done 2>/dev/null)" || exit 0
[[ -f "$marker" ]] && exit 0

./bin/setup
mkdir -p "$(dirname "$marker")"
touch "$marker"
