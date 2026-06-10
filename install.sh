#!/bin/sh
# codegraph-auto-init installer
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/yuyutar1/codegraph-auto-init/main/install.sh | sh
#   curl -fsSL .../install.sh | sh -s -- --no-scan
#   curl -fsSL .../install.sh | sh -s -- --no-ignore
#   DEV_DIR=~/src curl -fsSL .../install.sh | sh
#
# Pinning a release: fetch install.sh from a tag AND set the same ref for the
# assets it downloads (defaults to main):
#   curl -fsSL https://raw.githubusercontent.com/yuyutar1/codegraph-auto-init/v1.0.0/install.sh \
#     | CODEGRAPH_AUTO_INIT_REF=v1.0.0 sh
#
# What it does (idempotent — safe to re-run):
#   1. Adds `.codegraph/` to the global git ignore file (skip with --no-ignore
#      if you want git to track .codegraph/)
#   2. Installs a `git` wrapper that auto-runs `codegraph init` on git init/clone
#      (zsh and bash via rc source line; fish via conf.d — each only when the
#      shell is present)
#   3. Installs the `codegraph-auto-init` CLI into ~/.local/bin
#   4. Runs `codegraph init` in every existing git repository under the configured
#      scan directories (seeded from DEV_DIR, default: ~/dev — change any time later
#      with `codegraph-auto-init add-dir`)
set -eu

info() { printf '\033[1;32m==>\033[0m %s\n' "$1"; }
warn() { printf '\033[1;33mwarn:\033[0m %s\n' "$1" >&2; }

fetch() {
  # fetch <repo-relative-path> <destination> — prefer the local checkout this
  # script lives in, fall back to the raw URL. When piped (`curl | sh`), $0 is
  # the shell name, so the local path is intentionally never used — otherwise
  # files in the caller's CWD could be installed.
  if [ -n "$script_dir" ] && [ -f "$script_dir/$1" ]; then
    cp "$script_dir/$1" "$2"
  else
    curl -fsSL "$REPO_RAW/$1" -o "$2"
  fi
}

wire_rc() {
  # wire_rc <rc-file> — idempotently (re)write the marker-tagged source line.
  # `cat >` instead of `mv` so a symlinked rc file keeps pointing at its target.
  touch "$1"
  if [ "$(grep -cF "$MARKER" "$1" || true)" = 1 ] && grep -qxF "$SOURCE_LINE" "$1"; then
    info "$(basename "$1"): wrapper already wired"
    return 0
  fi
  if grep -qF "$MARKER" "$1"; then
    tmp=$(mktemp)
    grep -vF "$MARKER" "$1" >"$tmp" || true
    cat "$tmp" >"$1"
    rm -f "$tmp"
    printf '%s\n' "$SOURCE_LINE" >>"$1"
    info "$(basename "$1"): updated stale wrapper line"
  else
    printf '\n%s\n' "$SOURCE_LINE" >>"$1"
    info "$(basename "$1"): added source line"
  fi
}

main() {
  REPO_RAW="https://raw.githubusercontent.com/yuyutar1/codegraph-auto-init/${CODEGRAPH_AUTO_INIT_REF:-main}"
  DEV_DIR="${DEV_DIR:-$HOME/dev}"
  CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/codegraph-auto-init"
  SNIPPET="$CONFIG_DIR/git-wrapper.sh"
  FISH_CONF="${XDG_CONFIG_HOME:-$HOME/.config}/fish/conf.d/codegraph-auto-init.fish"
  DIRS_FILE="$CONFIG_DIR/dirs"
  BIN_DIR="$HOME/.local/bin"
  CLI="$BIN_DIR/codegraph-auto-init"
  MARKER='# codegraph-auto-init'

  SCAN=1
  IGNORE=1
  for arg in "$@"; do
    case "$arg" in
      --no-scan) SCAN=0 ;;
      --no-ignore) IGNORE=0 ;;
      *) echo "unknown option: $arg (supported: --no-scan, --no-ignore)" >&2; exit 1 ;;
    esac
  done

  # trust $0 only when it is actually this script (not `sh` from a pipe)
  case "$0" in
    */install.sh|install.sh)
      script_dir=$(CDPATH='' cd -- "$(dirname -- "$0")" 2>/dev/null && pwd) || script_dir=""
      ;;
    *) script_dir="" ;;
  esac

  # --- 1. global git ignore (optional) --------------------------------------
  if [ "$IGNORE" -eq 1 ]; then
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
      # repair a missing trailing newline so we don't mangle the last pattern
      if [ -s "$EXCLUDES_FILE" ] && [ -n "$(tail -c1 "$EXCLUDES_FILE")" ]; then
        printf '\n' >>"$EXCLUDES_FILE"
      fi
      printf '.codegraph/\n' >>"$EXCLUDES_FILE"
      info "global git ignore: added .codegraph/ to $EXCLUDES_FILE"
    fi
  else
    info "global git ignore: skipped (--no-ignore) — .codegraph/ stays visible to git"
  fi

  # --- 2. shell git wrappers (zsh / bash / fish) -----------------------------
  mkdir -p "$CONFIG_DIR"
  fetch git-wrapper.sh "$SNIPPET"
  rm -f "$CONFIG_DIR/git-wrapper.zsh" # legacy name from zsh-only versions
  info "wrapper: installed to $SNIPPET"

  SOURCE_LINE="[ -f \"\${XDG_CONFIG_HOME:-\$HOME/.config}/codegraph-auto-init/git-wrapper.sh\" ] && . \"\${XDG_CONFIG_HOME:-\$HOME/.config}/codegraph-auto-init/git-wrapper.sh\" $MARKER"

  command -v zsh >/dev/null 2>&1 && wire_rc "${ZDOTDIR:-$HOME}/.zshrc"
  if command -v bash >/dev/null 2>&1; then
    wire_rc "$HOME/.bashrc"
    # macOS terminals start bash as a login shell, which reads .bash_profile and
    # not .bashrc. Wire it only when it already exists — creating it would stop
    # bash from falling back to ~/.profile.
    [ -f "$HOME/.bash_profile" ] && wire_rc "$HOME/.bash_profile"
  fi
  if command -v fish >/dev/null 2>&1 || [ -d "${XDG_CONFIG_HOME:-$HOME/.config}/fish" ]; then
    mkdir -p "$(dirname "$FISH_CONF")"
    fetch git-wrapper.fish "$FISH_CONF"
    info "fish: installed $(basename "$FISH_CONF") to fish conf.d"
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

  info "done. open a new terminal to activate the git wrapper."
}

main "$@"
