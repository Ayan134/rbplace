#!/usr/bin/env bash
# Builds StickerPeel.rbxl: Rojo compiles the scripts, then Lune runs the game's own
# level/lobby builders so the place opens in Studio with everything already built.
#
#   ./scripts/build.sh          # build StickerPeel.rbxl
#   ./scripts/build.sh --test   # also run the sticker generation checks
set -euo pipefail
cd "$(dirname "$0")/.."

ROJO="${ROJO:-rojo}"
LUNE="${LUNE:-lune}"

mkdir -p build
"$ROJO" build default.project.json -o build/rojo.rbxl
"$LUNE" run tools/lune/build-place.luau build/rojo.rbxl StickerPeel.rbxl

if [[ "${1:-}" == "--test" ]]; then
	"$LUNE" run tools/lune/test-generation.luau build/rojo.rbxl all
fi
