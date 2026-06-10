#!/bin/sh
# codegraph-auto-init uninstaller
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/yuyutar1/codegraph-auto-init/main/uninstall.sh | sh
#   curl -fsSL .../uninstall.sh | sh -s -- --purge   # also delete .codegraph/ in configured scan dirs
#
# What it does:
#   1. Removes the `.codegraph/` entry from the global git ignore file
#   2. Removes the source lines from ~/.zshrc, ~/.bashrc and ~/.bash_profile,
#      the fish conf.d file, the wrapper snippets, the CLI, and the configuration
#   3. (--purge only) deletes .codegraph/ directories in git repos under the configured
#      scan directories (or DEV_DIR if set)
set -eu

info() { printf '\033[1;32m==>\033[0m %s\n' "$1"; }
warn() { printf '\033[1;33mwarn:\033[0m %s\n' "$1" >&2; }

strip_lines() {
  # strip_lines <file> <fixed-string> — remove matching lines.
  # `cat >` instead of `mv` so a symlinked file keeps pointing at its target.
  tmp=$(mktemp)
  grep -vF "$2" "$1" >"$tmp" || true
  cat "$tmp" >"$1"
  rm -f "$tmp"
}

main() {
  CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/codegraph-auto-init"
  DIRS_FILE="$CONFIG_DIR/dirs"
  CLI="$HOME/.local/bin/codegraph-auto-init"
  FISH_CONF="${XDG_CONFIG_HOME:-$HOME/.config}/fish/conf.d/codegraph-auto-init.fish"
  MARKER='# codegraph-auto-init'

  PURGE=0
  for arg in "$@"; do
    case "$arg" in
      --purge) PURGE=1 ;;
      *) echo "unknown option: $arg (supported: --purge)" >&2; exit 1 ;;
    esac
  done

  # resolve purge targets BEFORE deleting the configuration
  if [ -n "${DEV_DIR:-}" ]; then
    PURGE_DIRS="$DEV_DIR"
  elif [ -f "$DIRS_FILE" ]; then
    PURGE_DIRS=$(grep -v '^[[:space:]]*$' "$DIRS_FILE" | grep -v '^#' || true)
  else
    PURGE_DIRS="$HOME/dev"
  fi

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
    cat "$tmp" >"$EXCLUDES_FILE"
    rm -f "$tmp"
    info "global git ignore: removed .codegraph/ from $EXCLUDES_FILE"
  else
    info "global git ignore: no .codegraph/ entry found"
  fi

  # --- 2. shell git wrappers, CLI, configuration -------------------------------
  for rc in "${ZDOTDIR:-$HOME}/.zshrc" "$HOME/.bashrc" "$HOME/.bash_profile"; do
    if [ -f "$rc" ] && grep -qF "$MARKER" "$rc"; then
      strip_lines "$rc" "$MARKER"
      info "$(basename "$rc"): removed source line"
    else
      info "$(basename "$rc"): no source line found"
    fi
  done
  if [ -f "$FISH_CONF" ]; then
    rm -f "$FISH_CONF"
    info "fish: removed $FISH_CONF"
  fi
  if [ -f "$CLI" ]; then
    rm -f "$CLI"
    info "cli: removed $CLI"
  fi
  if [ -d "$CONFIG_DIR" ]; then
    rm -rf "$CONFIG_DIR"
    info "config: removed $CONFIG_DIR"
  fi

  # --- 3. optional purge of indexes ------------------------------------------
  if [ "$PURGE" -eq 1 ]; then
    printf '%s\n' "$PURGE_DIRS" | while IFS= read -r dir; do
      [ -n "$dir" ] || continue
      if [ ! -d "$dir" ]; then
        warn "not a directory, skipping: $dir"
        continue
      fi
      info "purging .codegraph/ in git repos under $dir"
      find "$dir" -name node_modules -prune -o -type d -name .git -print 2>/dev/null |
        while IFS= read -r gitdir; do
          repo=$(dirname "$gitdir")
          [ -d "$repo/.codegraph" ] || continue
          rm -rf "$repo/.codegraph"
          info "removed: $repo/.codegraph"
        done
    done
  else
    info "indexes (.codegraph/ directories) were kept. re-run with --purge to delete them."
  fi

  info "done. open a new terminal to drop the git wrapper from running shells."
}

main "$@"
