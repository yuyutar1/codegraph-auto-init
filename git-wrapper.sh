# codegraph-auto-init: auto-run `codegraph init` when a new repo is created
# (git init / git clone). Sourced by zsh and bash (bash 3.2+ compatible).
# Managed by https://github.com/yuyutar1/codegraph-auto-init
git() {
  command git "$@" || return $?
  command -v codegraph >/dev/null 2>&1 || return 0
  local sub="" last="" arg d
  for arg in "$@"; do
    case "$arg" in
      -*) continue ;;
    esac
    sub="$arg"
    break
  done
  case "$sub" in
    init|clone) ;;
    *) return 0 ;;
  esac
  for arg in "$@"; do last="$arg"; done
  # For clone, never fall back to "." — with trailing options (git clone url
  # --depth 1) the last arg is not the target, and "." would wrongly index the
  # parent repo. Doing nothing is the documented fail-safe.
  if [ "$sub" = "clone" ]; then
    set -- "$last" "$(basename "$last" .git)"
  else
    set -- "$last" "."
  fi
  for d in "$@"; do
    if [ -d "$d/.git" ] && [ ! -d "$d/.codegraph" ]; then
      echo "codegraph: indexing $d in background" >&2
      (codegraph init "$d" >/dev/null 2>&1 &)
      break
    fi
  done
  return 0
}
