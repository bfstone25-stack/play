#!/usr/bin/env bash
# Package the free web build of Flutter: After Hours.
#
# The one rule this script exists to enforce: the uncensored plates are not in
# the free package. Not hidden, not renamed, not behind a flag — absent. That is
# the Room 704 / Confession Room pattern (play/room-704/game/scripts/09_dist.rpy),
# and it is why forging a localStorage entry reveals nothing on a free build.
#
#   tools/build_free.sh [outdir]      default: dist/free
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUT="${1:-$HERE/dist/free}"

rm -rf "$OUT"
mkdir -p "$OUT"
# -L resolves the portraits/audio symlinks into the package.
rsync -aL --exclude 'cg/full' --exclude 'dist' "$HERE/frontend/" "$OUT/"

if [ -d "$OUT/cg/full" ]; then
  echo "FATAL: uncensored plates made it into the free package" >&2
  exit 1
fi
if ls "$OUT"/cg/*.webp >/dev/null 2>&1; then
  for f in "$OUT"/cg/*.webp; do
    case "$f" in *_locked.webp|*_thumb.webp) ;; *)
      echo "FATAL: unexpected plate in the free package: $f" >&2; exit 1 ;;
    esac
  done
fi

echo "free build -> $OUT"
du -sh "$OUT"
echo "plates shipped: $(ls "$OUT"/cg/*_locked.webp 2>/dev/null | wc -l) covered, 0 uncensored"
