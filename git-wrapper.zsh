# codegraph-auto-init: auto-run `codegraph init` when a new repo is created
# (git init / git clone). Managed by https://github.com/yuyutar1/codegraph-auto-init
git() {
  command git "$@" || return $?
  command -v codegraph >/dev/null 2>&1 || return 0
  local sub="" arg
  for arg in "$@"; do
    [[ "$arg" == -* ]] && continue
    sub="$arg"
    break
  done
  if [[ "$sub" == "init" || "$sub" == "clone" ]]; then
    local last="${@[-1]}" d
    for d in "$last" "$(basename "$last" .git)" "."; do
      if [[ -d "$d/.git" && ! -d "$d/.codegraph" ]]; then
        echo "codegraph: indexing ${d:A} in background" >&2
        (cd "$d" && codegraph init >/dev/null 2>&1 &)
        break
      fi
    done
  fi
}
