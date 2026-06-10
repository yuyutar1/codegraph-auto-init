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
#   3. Runs `codegraph init` in every existing git repository under DEV_DIR (default: ~/dev)
set -eu

REPO_RAW="https://raw.githubusercontent.com/yuyutar1/codegraph-auto-init/main"
DEV_DIR="${DEV_DIR:-$HOME/dev}"
SNIPPET_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/codegraph-auto-init"
SNIPPET="$SNIPPET_DIR/git-wrapper.zsh"
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
mkdir -p "$SNIPPET_DIR"
script_dir=$(CDPATH='' cd -- "$(dirname -- "$0")" 2>/dev/null && pwd) || script_dir=""
if [ -n "$script_dir" ] && [ -f "$script_dir/git-wrapper.zsh" ]; then
  cp "$script_dir/git-wrapper.zsh" "$SNIPPET"
  info "wrapper: copied from local checkout to $SNIPPET"
else
  curl -fsSL "$REPO_RAW/git-wrapper.zsh" -o "$SNIPPET"
  info "wrapper: downloaded to $SNIPPET"
fi

SOURCE_LINE="[ -f \"\${XDG_CONFIG_HOME:-\$HOME/.config}/codegraph-auto-init/git-wrapper.zsh\" ] && source \"\${XDG_CONFIG_HOME:-\$HOME/.config}/codegraph-auto-init/git-wrapper.zsh\" $MARKER"
touch "$ZSHRC"
if grep -qF "$MARKER" "$ZSHRC"; then
  info "zshrc: wrapper already wired in $ZSHRC"
else
  printf '\n%s\n' "$SOURCE_LINE" >>"$ZSHRC"
  info "zshrc: added source line to $ZSHRC"
fi

# --- 3. initial scan of existing repositories ------------------------------
if ! command -v codegraph >/dev/null 2>&1; then
  warn "codegraph CLI not found in PATH — skipping the initial scan."
  warn "install codegraph, then re-run this installer."
  SCAN=0
fi

if [ "$SCAN" -eq 1 ]; then
  if [ -d "$DEV_DIR" ]; then
    info "scanning $DEV_DIR for git repositories (set DEV_DIR=... to change)"
    find "$DEV_DIR" -name node_modules -prune -o -type d -name .git -print 2>/dev/null |
      while IFS= read -r gitdir; do
        repo=$(dirname "$gitdir")
        [ -d "$repo/.codegraph" ] && continue
        info "codegraph init: $repo"
        (cd "$repo" && codegraph init >/dev/null 2>&1) || warn "codegraph init failed: $repo"
      done
  else
    warn "DEV_DIR not found: $DEV_DIR — skipping the initial scan."
  fi
fi

info "done. open a new terminal (or run: source $ZSHRC) to activate the git wrapper."
