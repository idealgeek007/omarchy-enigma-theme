# Syntax colours follow the active Omarchy theme (reads its colors.toml).
# Monochrome-first, accent for commands, red only for errors (Enigma theme).
status is-interactive; or return
set -l f ~/.local/state/omarchy/current/theme/colors.toml
test -r $f; or return

function __omarchy_color -a file key
    string match -rg "^$key\s*=\s*\"#?([0-9a-fA-F]{6})\"" < $file
end

set -l fg (__omarchy_color $f foreground)
set -l accent (__omarchy_color $f accent)
set -l muted (__omarchy_color $f muted)
set -l dim (__omarchy_color $f dark_foreground)
set -l red (__omarchy_color $f red)
set -l sel (__omarchy_color $f selection)
set -l yellow (__omarchy_color $f yellow)
set -l cyan (__omarchy_color $f cyan)

set -g fish_color_normal $fg
set -g fish_color_command $accent --bold
set -g fish_color_keyword $accent
set -g fish_color_param $fg
set -g fish_color_option $muted
set -g fish_color_quote $yellow
set -g fish_color_redirection $cyan
set -g fish_color_end $muted
set -g fish_color_operator $muted
set -g fish_color_escape $cyan
set -g fish_color_comment $dim --italics
set -g fish_color_autosuggestion $dim
set -g fish_color_error $red --underline
set -g fish_color_valid_path --underline
set -g fish_color_selection --background=$sel
set -g fish_color_search_match --background=$sel
set -g fish_pager_color_prefix $accent --bold
set -g fish_pager_color_completion $fg
set -g fish_pager_color_description $muted
set -g fish_pager_color_progress $dim
set -g __omarchy_accent $accent
set -g __omarchy_red $red
set -g __omarchy_dim $dim
set -g __omarchy_muted $muted
functions -e __omarchy_color
