#!/usr/bin/env bash
set -euo pipefail

status="$(git status --short --untracked-files=no)"
if [ -n "${status}" ]; then
  echo "Tracked files changed during CI:" >&2
  echo "${status}" >&2
  exit 1
fi
