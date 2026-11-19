# One-line pill prompt, after Panacea's fish_prompt.
# ▍dir  branch*  ⏵jobs  ⟢   — the arrow turns red when the last command failed.
function fish_prompt
    set -l last_status $status
    set -l accent (set -q __omarchy_accent; and echo $__omarchy_accent; or echo red)
    set -l dim (set -q __omarchy_dim; and echo $__omarchy_dim; or echo 4a4a4a)
    set -l muted (set -q __omarchy_muted; and echo $__omarchy_muted; or echo 6a6a6a)
    set -l red (set -q __omarchy_red; and echo $__omarchy_red; or echo ff5555)

    set -l cwd (string replace -r '^~/?' '' -- (prompt_pwd -d 2))
    test -n "$cwd"; or set cwd home

    set_color $dim; echo -n '▍'
    set_color normal --bold; echo -n $cwd; set_color normal

    set -l branch (command git symbolic-ref --short HEAD 2>/dev/null; or command git rev-parse --short HEAD 2>/dev/null)
    if test -n "$branch"
        set_color $muted
        echo -n '  '(string sub -l 24 -- $branch)
        command git diff-index --quiet HEAD -- 2>/dev/null; or begin; set_color $accent; echo -n '*'; end
        set_color normal
    end

    set -l running (count (jobs -p))
    if test $running -gt 0
        set_color $muted; echo -n "  ⏵$running"; set_color normal
    end

    if test $last_status -ne 0
        set_color $red --bold
    else
        set_color $accent
    end
    echo -n '  ⟢ '
    set_color normal
end
