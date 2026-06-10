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
    # For clone, never fall back to "." — with trailing options (git clone url
    # --depth 1) the last arg is not the target, and "." would wrongly index
    # the parent repo. Doing nothing is the documented fail-safe.
    set -l candidates
    if test "$sub" = clone
        set candidates $last (basename $last .git)
    else
        set candidates $last '.'
    end
    for d in $candidates
        if test -d "$d/.git"; and not test -d "$d/.codegraph"
            echo "codegraph: indexing $d in background" >&2
            codegraph init "$d" >/dev/null 2>&1 &
            disown
            break
        end
    end
    return 0
end
