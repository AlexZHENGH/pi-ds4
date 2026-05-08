#!/bin/sh
set -eu

usage() {
    echo "usage: $0 [--force] /path/to/ds4-server-checkout" >&2
}

FORCE=0
if [ "${1:-}" = "--force" ]; then
    FORCE=1
    shift
fi

if [ "$#" -ne 1 ] || [ "${1:-}" = "-h" ] || [ "${1:-}" = "--help" ]; then
    usage
    exit 1
fi

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
PI_AGENT_DIR=${PI_CODING_AGENT_DIR:-"$HOME/.pi/agent"}
EXTENSION_DIR="$PI_AGENT_DIR/extensions"
EXTENSION_LINK="$EXTENSION_DIR/pi-ds4"
DS4_DIR="$HOME/.pi/ds4"
SUPPORT_LINK="$DS4_DIR/support"

DS4_CHECKOUT_INPUT=$1
if [ ! -d "$DS4_CHECKOUT_INPUT" ]; then
    echo "error: ds4 checkout does not exist: $DS4_CHECKOUT_INPUT" >&2
    exit 1
fi
DS4_CHECKOUT=$(CDPATH= cd -- "$DS4_CHECKOUT_INPUT" && pwd)

if [ ! -f "$ROOT/index.ts" ]; then
    echo "error: $ROOT/index.ts not found" >&2
    exit 1
fi

if [ ! -f "$ROOT/ds4-watchdog.sh" ]; then
    echo "error: $ROOT/ds4-watchdog.sh not found" >&2
    exit 1
fi

for file in download_model.sh Makefile ds4_server.c; do
    if [ ! -f "$DS4_CHECKOUT/$file" ]; then
        echo "error: $DS4_CHECKOUT does not look like a ds4 server checkout (missing $file)" >&2
        exit 1
    fi
done

mkdir -p "$EXTENSION_DIR" "$DS4_DIR"
ln -sfn "$ROOT" "$EXTENSION_LINK"

installed_support=0
if [ -L "$SUPPORT_LINK" ]; then
    current=$(CDPATH= cd -- "$SUPPORT_LINK" 2>/dev/null && pwd || true)
    if [ "$current" = "$DS4_CHECKOUT" ]; then
        installed_support=1
    else
        rm -f "$SUPPORT_LINK"
        ln -s "$DS4_CHECKOUT" "$SUPPORT_LINK"
        installed_support=1
    fi
elif [ -e "$SUPPORT_LINK" ]; then
    current=$(CDPATH= cd -- "$SUPPORT_LINK" 2>/dev/null && pwd || true)
    if [ "$current" = "$DS4_CHECKOUT" ]; then
        installed_support=1
    elif [ "$FORCE" -eq 1 ]; then
        backup="$SUPPORT_LINK.backup.$(date +%Y%m%d%H%M%S)"
        mv "$SUPPORT_LINK" "$backup"
        ln -s "$DS4_CHECKOUT" "$SUPPORT_LINK"
        installed_support=1
        echo "Moved existing ds4 support checkout aside:"
        echo "  $backup"
    else
        echo "error: $SUPPORT_LINK already exists and is not this checkout" >&2
        echo "       rerun with --force to move it aside and install a symlink" >&2
        exit 1
    fi
else
    ln -s "$DS4_CHECKOUT" "$SUPPORT_LINK"
    installed_support=1
fi

if [ "$installed_support" -ne 1 ]; then
    echo "error: failed to install ds4 support checkout symlink" >&2
    exit 1
fi

echo "Installed pi extension package symlink:"
echo "  $EXTENSION_LINK -> $ROOT"
echo
echo "Installed ds4 runtime checkout symlink:"
echo "  $SUPPORT_LINK -> $DS4_CHECKOUT"
echo
echo "Reload pi with /reload or start pi normally; the extension is auto-discovered."
