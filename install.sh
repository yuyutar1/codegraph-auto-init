#!/bin/sh
# codegraph-auto-init installer
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/yuyutar1/codegraph-auto-init/main/install.sh | sh
#   curl -fsSL .../install.sh | sh -s -- --no-scan
#   DEV_DIR=~/src curl -fsSL .../install.sh | sh
#
# What it does (idempotent — safe to re-run):
#   1. Adds `.codegraph/` to the global git ignore file
#   2. Installs a zsh `git` wrapper that auto-runs `codegraph init` on git init/clone
#   3. Installs the `codegraph-auto-init` CLI into ~/.local/bin
#   4. Runs `codegraph init` in every existing git repository under the configured
#      scan directories (seeded from DEV_DIR, default: ~/dev — change any time later
#      with `codegraph-auto-init add-dir`)
set -eu

REPO_RAW="https://raw.githubusercontent.com/yuyutar1/codegraph-auto-init/main"
DEV_DIR="${DEV_DIR:-$HOME/dev}"
CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/codegraph-auto-init"
SNIPPET="$CONFIG_DIR/git-wrapper.zsh"
DIRS_FILE="$CONFIG_DIR/dirs"
BIN_DIR="$HOME/.local/bin"
CLI="$BIN_DIR/codegraph-auto-init"
ZSHRC="${ZDOTDIR:-$HOME}/.zshrc"
MARKER='# codegraph-auto-init'

SCAN=1
for arg in "$@"; do
  case "$arg" in
    --no-scan) SCAN=0 ;;
    *) echo "unknown option: $arg (supported: --no-scan)" >&2; exit 1 ;;
  esac
done

info() { printf '\033[1;32m==>\033[0m %s\n' "$1"; }
warn() { printf '\033[1;33mwarn:\033[0m %s\n' "$1" >&2; }

script_dir=$(CDPATH='' cd -- "$(dirname -- "$0")" 2>/dev/null && pwd) || script_dir=""

fetch() {
  # fetch <repo-relative-path> <destination> — prefer local checkout, fall back to raw URL
  if [ -n "$script_dir" ] && [ -f "$script_dir/$1" ]; then
    cp "$script_dir/$1" "$2"
  else
    curl -fsSL "$REPO_RAW/$1" -o "$2"
  fi
}

# --- 1. global git ignore -------------------------------------------------
EXCLUDES_FILE=$(git config --global --get core.excludesFile || true)
if [ -z "$EXCLUDES_FILE" ]; then
  EXCLUDES_FILE="${XDG_CONFIG_HOME:-$HOME/.config}/git/ignore"
fi
case "$EXCLUDES_FILE" in
  "~/"*) EXCLUDES_FILE="$HOME/${EXCLUDES_FILE#"~/"}" ;;
esac
mkdir -p "$(dirname "$EXCLUDES_FILE")"
touch "$EXCLUDES_FILE"
if grep -qxF '.codegraph/' "$EXCLUDES_FILE"; then
  info "global git ignore: .codegraph/ already present ($EXCLUDES_FILE)"
else
  printf '.codegraph/\n' >>"$EXCLUDES_FILE"
  info "global git ignore: added .codegraph/ to $EXCLUDES_FILE"
fi

# --- 2. zsh git wrapper ---------------------------------------------------
mkdir -p "$CONFIG_DIR"
fetch git-wrapper.zsh "$SNIPPET"
info "wrapper: installed to $SNIPPET"

SOURCE_LINE="[ -f \"\${XDG_CONFIG_HOME:-\$HOME/.config}/codegraph-auto-init/git-wrapper.zsh\" ] && source \"\${XDG_CONFIG_HOME:-\$HOME/.config}/codegraph-auto-init/git-wrapper.zsh\" $MARKER"
touch "$ZSHRC"
if grep -qF "$MARKER" "$ZSHRC"; then
  info "zshrc: wrapper already wired in $ZSHRC"
else
  printf '\n%s\n' "$SOURCE_LINE" >>"$ZSHRC"
  info "zshrc: added source line to $ZSHRC"
fi

# --- 3. management CLI ------------------------------------------------------
mkdir -p "$BIN_DIR"
fetch bin/codegraph-auto-init "$CLI"
chmod +x "$CLI"
info "cli: installed to $CLI"
case ":$PATH:" in
  *":$BIN_DIR:"*) ;;
  *) warn "$BIN_DIR is not in PATH — add it to use the codegraph-auto-init command" ;;
esac

# seed the scan-directory configuration (DEV_DIR is only the initial value;
# manage later with `codegraph-auto-init add-dir/remove-dir`)
if [ -f "$DIRS_FILE" ]; then
  info "scan dirs: existing configuration kept ($DIRS_FILE)"
else
  printf '%s\n' "$DEV_DIR" >"$DIRS_FILE"
  info "scan dirs: seeded with $DEV_DIR ($DIRS_FILE)"
fi

# --- 4. initial scan of existing repositories ------------------------------
if ! command -v codegraph >/dev/null 2>&1; then
  warn "codegraph CLI not found in PATH — skipping the initial scan."
  warn "install codegraph, then run: codegraph-auto-init scan"
  SCAN=0
fi

if [ "$SCAN" -eq 1 ]; then
  "$CLI" scan
fi

info "done. open a new terminal (or run: source $ZSHRC) to activate the git wrapper."
