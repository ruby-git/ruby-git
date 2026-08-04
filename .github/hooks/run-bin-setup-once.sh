#!/usr/bin/env bash
set -euo pipefail

# This hook is shared by every agent configured for this repo (GitHub Copilot via
# .github/hooks/, Claude Code via .claude/settings.json), so do not assume the
# caller's working directory.
command -v git >/dev/null 2>&1 || exit 0
cd "$(dirname "${BASH_SOURCE[0]}")/../.." || exit 0

# Skip if this repo does not use bin/setup.
[[ -x "./bin/setup" ]] || exit 0

# Keep setup idempotent per-worktree. The marker is shared across agents so that
# cloning and opening the repo in two different tools does not run setup twice.
marker="$(git rev-parse --git-path agent-bin-setup.done 2>/dev/null)" || exit 0
[[ -f "$marker" ]] && exit 0

./bin/setup
mkdir -p "$(dirname "$marker")"
touch "$marker"
