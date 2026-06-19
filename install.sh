#!/usr/bin/env bash
set -e

# ─────────────────────────────────────────────────────────────────
# m30sync — installer
# https://github.com/janhellion/m30sync
# ─────────────────────────────────────────────────────────────────

BIN_DIR="${HOME}/.local/bin"
REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
M30_MOUNT="${M30_MOUNT:-/run/media/janhellion/MECHEN M30}"

# ── colours ──────────────────────────────────────────────────────
BOLD='\033[1m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

info()  { echo -e "  ${GREEN}✓${NC} $1"; }
warn()  { echo -e "  ${YELLOW}⚠${NC} $1"; }
err()   { echo -e "  ${RED}✗${NC} $1"; }
header(){ echo -e "\n${BOLD}$1${NC}"; echo "  ─────────────────────────────"; }

# ── checks ───────────────────────────────────────────────────────

header "Checking dependencies"

PYTHON_OK=false
for py in python3 python; do
    if command -v "$py" &>/dev/null; then
        VER=$("$py" --version 2>&1 | grep -oP '\d+\.\d+')
        MAJOR="${VER%%.*}"
        if [ "$MAJOR" -ge 3 ]; then
            info "Python $VER ($py)"
            PYTHON_OK=true
            PYTHON="$py"
            break
        fi
    fi
done

if ! $PYTHON_OK; then
    err "Python 3 not found. Install it first."
    exit 1
fi

# mutagen check
MUTAGEN_OK=false
if "$PYTHON" -c "import mutagen" 2>/dev/null; then
    MUTAGEN_VER=$("$PYTHON" -c "import mutagen; print(mutagen.version_string)" 2>/dev/null)
    info "mutagen ${MUTAGEN_VER:-installed}"
    MUTAGEN_OK=true
else
    warn "mutagen not found — will be installed"
fi

# ffmpeg check
if command -v ffmpeg &>/dev/null; then
    FFMPEG_VER=$(ffmpeg -version 2>&1 | head -1 | grep -oP 'n?\d+\.\d+\.?\d*' | head -1)
    info "ffmpeg ${FFMPEG_VER:-installed}  (gapless merge)"
else
    warn "ffmpeg not found — gapless merge disabled"
    warn "  Install: sudo pacman -S ffmpeg  (or your distro's equivalent)"
fi

# ── install mutagen if missing ───────────────────────────────────

if ! $MUTAGEN_OK; then
    header "Installing mutagen"
    echo -n "  Install mutagen via pip? [Y/n] "
    read -r resp
    if [[ "$resp" =~ ^[Yy]?$|^$ ]]; then
        "$PYTHON" -m pip install mutagen --user 2>&1 | sed 's/^/  /'
        if "$PYTHON" -c "import mutagen" 2>/dev/null; then
            info "mutagen installed"
        else
            err "mutagen installation failed"
            err "  Try: $PYTHON -m pip install mutagen --user"
            exit 1
        fi
    else
        warn "Skipping mutagen install — tool won't work without it"
    fi
fi

# ── install scripts ──────────────────────────────────────────────

header "Installing scripts"

mkdir -p "$BIN_DIR"

for script in m30sync m30_tag_fix.py; do
    src="${REPO_DIR}/${script}"
    dst="${BIN_DIR}/${script}"
    if [ ! -f "$src" ]; then
        err "$script not found in $REPO_DIR"
        continue
    fi
    cp "$src" "$dst"
    chmod +x "$dst"
    info "$script → $dst"
done

# ── configure M30_MOUNT ──────────────────────────────────────────

if [ ! -d "$M30_MOUNT" ]; then
    header "M30 mount point"
    warn "Default mount: ${M30_MOUNT} not found"
    echo "  If your M30 mounts elsewhere, set:"
    echo "    export M30_MOUNT=/your/mount/point"
    echo "  Or edit the M30_MOUNT variable in ${BIN_DIR}/m30sync"
fi

# ── PATH check ───────────────────────────────────────────────────

header "PATH check"

if [[ ":$PATH:" != *":${BIN_DIR}:"* ]]; then
    warn "${BIN_DIR} is not in your PATH"
    echo -n "  Add it to ~/.bashrc? [Y/n] "
    read -r resp
    if [[ "$resp" =~ ^[Yy]?$|^$ ]]; then
        {
            echo ""
            echo "# m30sync"
            echo "export PATH=\"\${PATH}:${BIN_DIR}\""
        } >> "${HOME}/.bashrc"
        info "Added ${BIN_DIR} to PATH in ~/.bashrc"
        echo "  Run: source ~/.bashrc"
    fi
else
    info "${BIN_DIR} is in PATH"
fi

# ── done ─────────────────────────────────────────────────────────

header "Installation complete"

echo "  m30sync          — copy + tag strip + gapless merge"
echo "  m30_tag_fix.py   — strip tags in-place"
echo ""
echo "  ${BOLD}Usage:${NC}  m30sync /path/to/music/"
echo ""
echo "  Files installed in: ${BIN_DIR}/"
echo "  Repo:              https://github.com/janhellion/m30sync"

# Suggest running on M30 if mounted
if [ -d "$M30_MOUNT" ]; then
    echo ""
    echo "  M30 is mounted at ${M30_MOUNT}"
    echo -n "  Run m30sync on the M30's current files now? [y/N] "
    read -r resp
    if [[ "$resp" =~ ^[Yy]$ ]]; then
        echo ""
        m30sync "$M30_MOUNT"
    fi
fi
