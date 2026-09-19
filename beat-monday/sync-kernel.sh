#!/bin/sh
# The kernel is single-source at play/catharsis/kernel. A shipped build (itch zip,
# portal upload, per-slug static host) cannot reach outside its own folder, so the
# files it needs are vendored here by copy — never edited in place. rpg-smoke.cjs
# fails if a vendored copy drifts from the kernel.
set -e
cd "$(dirname "$0")"
mkdir -p frontend/kernel
for f in pool.js rant.js economy.js gacha.js commerce.js i18n.js save.js; do
  cp "../catharsis/kernel/$f" "frontend/kernel/$f"
done
echo "kernel vendored into frontend/kernel"
