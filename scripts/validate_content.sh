#!/bin/zsh
# Validate every sector and level in Content/: solutions must pass their checks and
# starters must not. Optional argument: only check levels whose id or folder contains it.
#   scripts/validate_content.sh
#   scripts/validate_content.sh launch-pad.storing-cargo
set -euo pipefail
cd "$(dirname "$0")/.."
exec /usr/local/bin/Rscript --no-init-file scripts/validate_content.R "$(pwd)" "$@"
