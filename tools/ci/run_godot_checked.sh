#!/usr/bin/env bash
set -euo pipefail

if [ "$#" -lt 3 ]; then
  echo "usage: $0 <label> <timeout-seconds> <godot-args...>" >&2
  exit 2
fi

label="$1"
timeout_seconds="$2"
shift 2

if ! [[ "${label}" =~ ^[a-z0-9-]+$ ]]; then
  echo "invalid smoke label: ${label}" >&2
  exit 2
fi

if ! [[ "${timeout_seconds}" =~ ^[1-9][0-9]*$ ]]; then
  echo "invalid timeout: ${timeout_seconds}" >&2
  exit 2
fi

log_path="godot-${label}.log"
set +e
timeout "${timeout_seconds}s" godot "$@" 2>&1 | tee "${log_path}"
godot_status=${PIPESTATUS[0]}
set -e

if [ "${godot_status}" -ne 0 ]; then
  echo "Godot exited with ${godot_status} during ${label}." >&2
  exit "${godot_status}"
fi

if grep -E "SCRIPT ERROR|ERROR:" "${log_path}"; then
  echo "Godot reported errors during ${label}." >&2
  exit 1
fi
