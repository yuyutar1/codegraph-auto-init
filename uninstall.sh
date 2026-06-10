#!/bin/sh
# codegraph-auto-init uninstaller
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/yuyutar1/codegraph-auto-init/main/uninstall.sh | sh
#   curl -fsSL .../uninstall.sh | sh -s -- --purge   # also delete .codegraph/ in repos under DEV_DIR
#
# What it does:
#   1. Removes the `.codegraph/` entry from the global git ignore file
#   2. Removes the source line from ~/.zshrc and deletes the wrapper snippet
#   3. (--purge only) deletes .codegraph/ directories in git repos under DEV_DIR (default: ~/dev)
set -eu

DEV_DIR="${DEV_DIR:-$HOME/dev}"
SNIPPET_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/codegraph-auto-init"
ZSHRC="${ZDOTDIR:-$HOME}/.zshrc"
MARKER='# codegraph-auto-init'

PURGE=0
for arg in "$@"; do
  case "$arg" in
    --purge) PURGE=1 ;;
    *) echo "unknown option: $arg (supported: --purge)" >&2; exit 1 ;;
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
if [ -f "$EXCLUDES_FILE" ] && grep -qxF '.codegraph/' "$EXCLUDES_FILE"; then
  tmp=$(mktemp)
  grep -vxF '.codegraph/' "$EXCLUDES_FILE" >"$tmp" || true
  mv "$tmp" "$EXCLUDES_FILE"
  info "global git ignore: removed .codegraph/ from $EXCLUDES_FILE"
else
  info "global git ignore: no .codegraph/ entry found"
fi

# --- 2. zsh git wrapper ---------------------------------------------------
if [ -f "$ZSHRC" ] && grep -qF "$MARKER" "$ZSHRC"; then
  tmp=$(mktemp)
  grep -vF "$MARKER" "$ZSHRC" >"$tmp" || true
  mv "$tmp" "$ZSHRC"
  info "zshrc: removed source line from $ZSHRC"
else
  info "zshrc: no source line found"
fi
if [ -d "$SNIPPET_DIR" ]; then
  rm -rf "$SNIPPET_DIR"
  info "wrapper: removed $SNIPPET_DIR"
fi

# --- 3. optional purge of indexes ------------------------------------------
if [ "$PURGE" -eq 1 ]; then
  if [ -d "$DEV_DIR" ]; then
    info "purging .codegraph/ in git repos under $DEV_DIR"
    find "$DEV_DIR" -name node_modules -prune -o -type d -name .git -print 2>/dev/null |
      while IFS= read -r gitdir; do
        repo=$(dirname "$gitdir")
        [ -d "$repo/.codegraph" ] || continue
        rm -rf "$repo/.codegraph"
        info "removed: $repo/.codegraph"
      done
  else
    warn "DEV_DIR not found: $DEV_DIR — nothing to purge."
  fi
else
  info "indexes (.codegraph/ directories) were kept. re-run with --purge to delete them."
fi

info "done. open a new terminal to drop the git wrapper from running shells."
