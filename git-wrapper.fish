# codegraph-auto-init: auto-run `codegraph init` when a new repo is created
# (git init / git clone). Auto-loaded from fish conf.d.
# Managed by https://github.com/yuyutar1/codegraph-auto-init
function git --wraps git --description 'git with codegraph auto-init'
    command git $argv
    set -l ret $status
    test $ret -eq 0; or return $ret
    type -q codegraph; or return 0
    set -l sub ''
    for arg in $argv
        string match -q -- '-*' $arg; and continue
        set sub $arg
        break
    end
    contains -- $sub init clone; or return 0
    set -l last $argv[-1]
    for d in $last (basename $last .git) '.'
        if test -d "$d/.git"; and not test -d "$d/.codegraph"
            echo "codegraph: indexing $d in background" >&2
            codegraph init "$d" >/dev/null 2>&1 &
            disown
            break
        end
    end
    return 0
end
