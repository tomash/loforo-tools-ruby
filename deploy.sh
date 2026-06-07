#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REMOTE="tomek@nucbox3:/home/tomek/projects/loforo-tools-ruby"

rsync -av "${SCRIPT_DIR}/" "${REMOTE}/"
