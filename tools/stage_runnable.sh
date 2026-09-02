#!/bin/bash
# =============================================================================
# stage_runnable.sh - put a simple_widgets executable's freight beside it
# =============================================================================
#
#   usage:  tools/stage_runnable.sh <folder-holding-the-exe>
#   e.g.:   tools/stage_runnable.sh EIFGENs/sw_demo/F_code
#
# THREE THINGS TRAVEL WITH A SHAPED-TEXT APP, AND ONLY THREE:
#
#   cairo.dll                       simple_cairo links cairo.LIB, an IMPORT
#                                   library - the DLL must be found at PROCESS
#                                   START or the exe will not launch at all.
#                                   There is no runtime check to degrade
#                                   through, and the failure looks exactly like
#                                   a code crash.
#
#   assets/noto-emoji/png/128/      the Noto artwork simple_shaping resolves
#                                   emoji against. SW_SHAPING.make looks for it
#                                   beside the RUNNING EXECUTABLE, never in the
#                                   working directory: a shortcut, a service,
#                                   an Explorer double-click and a debugger all
#                                   have different working directories, and
#                                   none of them is a contract.
#
#   LICENSE-ASSETS.md               the artwork's licence. It ships WITH the
#                                   artwork; that is the condition of
#                                   redistributing it.
#
# Missing artwork is not a crash - simple_shaping degrades to a note and a box.
# Missing cairo.dll IS. Every finalize wipes F_code, so run this after each
# build.
#
# usp10, gdi32 and dwrite are Windows' own. Nothing else needs an installer.
# =============================================================================

set -e

DEST="$1"
ROOT="${SIMPLE_EIFFEL:-/d/prod}"

if [ -z "$DEST" ]; then
    echo "usage: $0 <folder-holding-the-exe>" >&2
    exit 2
fi
if [ ! -d "$DEST" ]; then
    echo "ERROR: $DEST is not a directory" >&2
    exit 2
fi

CAIRO="$ROOT/simple_cairo/cairo.dll"
SHAPING="$ROOT/simple_shaping"

if [ ! -f "$CAIRO" ]; then
    echo "ERROR: $CAIRO not found (is SIMPLE_EIFFEL set?)" >&2
    exit 1
fi

cp "$CAIRO" "$DEST/"
echo "staged: cairo.dll"

if [ -f "$SHAPING/LICENSE-ASSETS.md" ]; then
    cp "$SHAPING/LICENSE-ASSETS.md" "$DEST/"
    echo "staged: LICENSE-ASSETS.md"
else
    echo "WARNING: $SHAPING/LICENSE-ASSETS.md not found - emoji artwork must not"
    echo "         be redistributed without it" >&2
fi

SRC_ASSETS="$SHAPING/assets/noto-emoji/png/128"
if [ -d "$SRC_ASSETS" ]; then
    mkdir -p "$DEST/assets/noto-emoji/png/128"
    cp -r "$SRC_ASSETS/." "$DEST/assets/noto-emoji/png/128/"
    echo "staged: assets/noto-emoji/png/128 ($(ls "$DEST/assets/noto-emoji/png/128" | wc -l) files)"
else
    echo "WARNING: $SRC_ASSETS not found - emoji will degrade to a note and a box" >&2
fi

echo "runnable folder ready: $DEST"
