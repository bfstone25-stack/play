#!/usr/bin/env bash
# Package the free web build of Flutter: After Hours.
#
# The one rule this script exists to enforce: the uncensored plates are not in
# the free package. Not hidden, not renamed, not behind a flag — absent. That is
# the Room 704 / Confession Room pattern (play/room-704/game/scripts/09_dist.rpy),
# and it is why forging a localStorage entry reveals nothing on a free build.
#
#   tools/build_free.sh [outdir] [track]
#     outdir  default: dist/free
#     track   itch_web (default) | ads_web
#
# The track matters and cannot be left to gate.js's own guess. Its dist() falls
# back to "itch_web" for every host that is not *.pages.dev — and the adult forks
# deploy to *.flat404.workers.dev, so an ad-track build that is not stamped shows
# a $8.99 BUY paywall where it should show a sponsor clip, and the whole free
# track is silently unreachable. Stamping is what ops/pages_build.sh does for the
# mainstream titles; this is the same stamp for a package built here.
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ROOT="$(cd "$HERE/../.." && pwd)"
OUT="${1:-$HERE/dist/free}"
TRACK="${2:-itch_web}"
case "$TRACK" in itch_web|ads_web) ;; *) echo "unknown track: $TRACK" >&2; exit 1 ;; esac

# Every FATAL below — the track stamp, the mainstream-Adsterra check, directLink, the
# service-worker stamp, cg/full, the plate sweep, board.js — used to run AFTER this
# directory had already been deleted, so a refusal destroyed the last good package it was
# refusing to replace. Staged beside it and swapped in at the end instead.
source "$ROOT/ops/build_guard.sh"
OUT_FINAL="$OUT"
OUT=$(stage_for "$OUT_FINAL")
# -L resolves the portraits/audio symlinks into the package.
rsync -aL --exclude 'cg/full' --exclude 'dist' "$HERE/frontend/" "$OUT/"

# Stamp the distribution track.
if [ "$TRACK" = "ads_web" ]; then
  cp "$ROOT/ops/flutter_after_hours_ads_config.js" "$OUT/ads_config.js"
  python3 - "$OUT/index.html" <<'PY'
import sys, pathlib, re
p = pathlib.Path(sys.argv[1]); t = p.read_text(encoding="utf-8")
stamp = '<script>window.DIST="ads_web";</script><script src="ads_config.js"></script>\n'
if 'window.DIST="ads_web"' not in t:
    t = re.sub(r"<head>", "<head>\n" + stamp, t, count=1, flags=re.I) if re.search(r"<head>", t, re.I) \
        else re.sub(r"(<meta charset=\"utf-8\">)", r"\1" + stamp, t, count=1, flags=re.I)
p.write_text(t, encoding="utf-8")
PY
  grep -q 'window.DIST="ads_web"' "$OUT/index.html" && [ -s "$OUT/ads_config.js" ] || {
    echo "FATAL: ads track requested but the build is not stamped for it" >&2; exit 1
  }
  # Match the KEY in an atOptions call, not the bare string: the correct adult
  # config names the mainstream one in a comment explaining why it is not used,
  # and a looser grep failed the build on that comment.
  grep -q 'atOptions.*c84fa3be5d6dea26c374b1d7d467e5dc' "$OUT/ads_config.js" && {
    echo "FATAL: the MAINSTREAM Adsterra unit is in an 18+ package" >&2; exit 1
  }
  # The ban that cost us an F95 account was a direct-link ad. Banner only, here.
  # Match an actual `directLink:` property in GATE_CONFIG — gate.js only opens a
  # sponsor page when cfg().directLink is set — not the word, which appears in the
  # comment saying why this build has none.
  grep -qE 'directLink[[:space:]]*:' "$OUT/index.html" && {
    echo "FATAL: directLink present in an adult build (ops memory: f95-ban-direct-link-ads)" >&2; exit 1
  }
  echo "track: ads_web (adult Adsterra unit, banner only, no directLink)"
else
  echo "track: itch_web"
fi

# Drop the music for editions this build does not ship.
#
# The audio symlink resolves the parent's whole five-edition BGM library into the
# package: 167 MiB of tracks that nothing in this build can ever reach, on a
# package going to a Cloudflare Workers asset upload. So the unshipped ones go.
#
# This USED TO BE a hardcoded `for pre in zh ja es pt pt-BR`, under a comment saying
# "keep this in step with editions.js: a language added there must be removed here".
# On 2026-09-21 zh was added to editions.js and this list was not updated, and the
# result was a package offering a Chinese edition with every Chinese track deleted
# out of it -- silently, because the verification below skipped exactly the prefixes
# this loop deletes, so it had nothing to say. Degrading to silence is
# indistinguishable from "the music has not started yet".
#
# So the list is no longer written twice. editions.js is the single source of truth
# and this reads SHIPPED out of it.
SHIPPED_EDITIONS=$(python3 - "$HERE/frontend/editions.js" <<'PY'
import re, sys, pathlib
src = pathlib.Path(sys.argv[1]).read_text(encoding="utf-8")
m = re.search(r"const\s+SHIPPED\s*=\s*\[([^\]]*)\]", src)
if not m:
    sys.exit("FATAL: could not read SHIPPED out of editions.js")
ids = re.findall(r"['\"]([A-Za-z-]+)['\"]", m.group(1))
if not ids:
    sys.exit("FATAL: SHIPPED in editions.js is empty")
# audio files are named by the CONTENT pack prefix, which is "pt" for pt-BR.
print(" ".join(dict.fromkeys({"pt-BR": "pt"}.get(i, i) for i in ids)))
PY
)
[ -n "$SHIPPED_EDITIONS" ] || { echo "FATAL: no shipped editions resolved" >&2; exit 1; }
echo "editions shipped: $SHIPPED_EDITIONS"
TRIMMED=""
for pre in zh ja es pt; do
  case " $SHIPPED_EDITIONS " in
    *" $pre "*) continue ;;
  esac
  TRIMMED="$TRIMMED $pre"
  find "$OUT/audio" -type f \( -name "$pre-*" -o -name "$pre.ogg" -o -name "$pre.mp3" \) -delete
  [ "$pre" = "pt" ] && find "$OUT/audio" -type f -name "pt-BR-*" -delete
done

# ...and prove the edition that IS shipped still has every file it names. A trim
# that quietly removes a track the game asks for degrades to silence, which is
# indistinguishable from "the music has not started yet".
# shellcheck disable=SC2086
python3 - "$HERE/frontend/audio.js" "$OUT" $TRIMMED <<'PY'
import re, sys, pathlib
src, out = pathlib.Path(sys.argv[1]).read_text(encoding="utf-8"), pathlib.Path(sys.argv[2])
# The prefixes to skip are the ones this build actually TRIMMED, passed in. They used
# to be hardcoded as zh/ja/es/pt, which meant that the moment zh became a shipped
# edition this check went blind to precisely the files that had just been deleted by
# mistake -- a verification that could only ever agree with the bug.
trimmed = tuple("audio/bgm/" + p for p in sys.argv[3:])
missing = []
for m in re.findall(r"audio/[A-Za-z0-9_./${}-]+\.(?:mp3|ogg|opus)", src):
    if "${" in m:           # template paths are resolved per edition at runtime
        continue
    if not (trimmed and m.startswith(trimmed)) and not (out / m).is_file():
        missing.append(m)
if missing:
    print("FATAL: the shipped edition references files the trim removed:", file=sys.stderr)
    for m in missing:
        print("  " + m, file=sys.stderr)
    sys.exit(1)
print("audio: every non-trimmed path audio.js names is present")
PY

# Stamp the service-worker cache name. The parent's sw.js carried a constant from
# 2026-08-17 that nothing ever bumped, and `activate` only evicts caches whose key
# differs from the current one — so a returning player kept the shipped JS forever
# and no fix to cg.js could ever reach them. Silent by construction: the game still
# worked, it was just the old game.
STAMP="$(date -u +%Y%m%d%H%M%S)"
sed -i "s/__BUILD_STAMP__/$STAMP/g" "$OUT/sw.js"
if grep -q '__BUILD_STAMP__' "$OUT/sw.js"; then
  echo "FATAL: service-worker cache stamp not substituted" >&2; exit 1
fi
grep -q "flutter-ah-$STAMP" "$OUT/sw.js" || {
  echo "FATAL: service-worker cache name is not this build's" >&2; exit 1
}

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

# The cross-promotion board has to BE in the package, not merely called by the game:
# play/confession-room wired board_offer_break() and shipped no board.js, so the board has
# never appeared in it. rsync brings it across from frontend/; this proves it did.
grep -q 'src="board.js"' "$OUT/index.html" && [ -s "$OUT/board.js" ] || {
  echo "FATAL: board.js missing from the free package (or index.html does not load it)" >&2
  exit 1
}

publish_stage "$OUT_FINAL" "$OUT"
OUT="$OUT_FINAL"

echo "free build -> $OUT"
du -sh "$OUT"
echo "plates shipped: $(ls "$OUT"/cg/*_locked.webp 2>/dev/null | wc -l) covered, 0 uncensored"
