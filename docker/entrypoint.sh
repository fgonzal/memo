#!/usr/bin/env bash
set -euo pipefail

# If the working directory doesn't have a backgrounds/ folder, symlink the
# default one from the repo so pandoc can resolve titlepage-background paths.
# The symlink is removed on exit so it doesn't litter the user's directory.
SYMLINK_CREATED=0
if [[ ! -e /work/backgrounds ]]; then
  ln -s /opt/memo/backgrounds /work/backgrounds
  SYMLINK_CREATED=1
fi

trap '[[ $SYMLINK_CREATED == 1 ]] && rm -f /work/backgrounds' EXIT

/opt/memo/bin/memo "$@"
