# ╔═══════════════════════════════════════════════════════════════╗
# ║                    Fish Shell Configuration                    ║
# ║                    for Caelestia Rice                          ║
# ╚═══════════════════════════════════════════════════════════════╝

# ── Disable Greeting ──────────────────────────────────────────────
set -g fish_greeting

# ── Environment Variables ─────────────────────────────────────────
set -gx EDITOR nano
set -gx VISUAL nano
set -gx BROWSER firefox
set -gx TERMINAL foot

# XDG Base Directories
set -gx XDG_CONFIG_HOME $HOME/.config
set -gx XDG_CACHE_HOME $HOME/.cache
set -gx XDG_DATA_HOME $HOME/.local/share
set -gx XDG_STATE_HOME $HOME/.local/state

# Path additions
fish_add_path $HOME/.local/bin
fish_add_path $HOME/.cargo/bin
fish_add_path $HOME/go/bin
fish_add_path $HOME/.npm-global/bin

# ── Aliases ───────────────────────────────────────────────────────

# File listing (eza)
alias ls='eza --icons --group-directories-first'
alias ll='eza -la --icons --group-directories-first --git'
alias la='eza -a --icons --group-directories-first'
alias lt='eza --tree --icons --group-directories-first --level=3'
alias l='eza -l --icons --group-directories-first'

# Modern replacements
alias cat='bat --style=auto'
alias grep='rg'
alias find='fd'
alias du='dust'
alias df='duf'
alias top='btop'

# Navigation
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias .....='cd ../../../..'
alias cd..='cd ..'

# Safety nets
alias rm='trash-put'
alias cp='cp -iv'
alias mv='mv -iv'
alias mkdir='mkdir -pv'

# Shortcuts
alias cls='clear'
alias h='history'
alias j='jobs -l'
alias path='echo -e ${PATH//:/\\n}'
alias now='date +"%T"'
alias nowdate='date +"%d-%m-%Y"'

# Git aliases
alias g='git'
alias gs='git status'
alias ga='git add'
alias gaa='git add --all'
alias gc='git commit -m'
alias gca='git commit -am'
alias gp='git push'
alias gpl='git pull'
alias gl='git log --oneline --graph --decorate -10'
alias gla='git log --oneline --graph --decorate --all'
alias gd='git diff'
alias gds='git diff --staged'
alias gb='git branch'
alias gco='git checkout'
alias gcb='git checkout -b'
alias gm='git merge'
alias gst='git stash'
alias gstp='git stash pop'
alias greset='git reset --hard HEAD'

# NixOS specific
alias nrs='sudo nixos-rebuild switch --flake /etc/nixos#caelestia'
alias nrt='sudo nixos-rebuild test --flake /etc/nixos#caelestia'
alias nrb='sudo nixos-rebuild boot --flake /etc/nixos#caelestia'
alias nfu='nix flake update'
alias ncg='sudo nix-collect-garbage -d'
alias nse='nix search nixpkgs'
alias nsh='nix-shell -p'
alias ndev='nix develop'

# Home Manager
alias hms='home-manager switch --flake /etc/nixos#$USER'
alias hme='$EDITOR /etc/nixos/home.nix'

# Caelestia
alias cae-shell='qs -c caelestia'
alias cae-reload='caelestia shell reload'
alias cae-wall='caelestia wallpaper'
alias cae-scheme='caelestia scheme'

# System
alias sysinfo='fastfetch'
alias myip='curl -s ifconfig.me'
alias ports='ss -tulanp'
alias meminfo='free -h'
alias cpuinfo='lscpu'

# ── Functions ─────────────────────────────────────────────────────

# Create directory and cd into it
function mkcd
    mkdir -p $argv[1] && cd $argv[1]
end

# Extract various archives
function extract
    if test -f $argv[1]
        switch $argv[1]
            case '*.tar.bz2'
                tar xjf $argv[1]
            case '*.tar.gz'
                tar xzf $argv[1]
            case '*.tar.xz'
                tar xJf $argv[1]
            case '*.bz2'
                bunzip2 $argv[1]
            case '*.rar'
                unrar x $argv[1]
            case '*.gz'
                gunzip $argv[1]
            case '*.tar'
                tar xf $argv[1]
            case '*.tbz2'
                tar xjf $argv[1]
            case '*.tgz'
                tar xzf $argv[1]
            case '*.zip'
                unzip $argv[1]
            case '*.Z'
                uncompress $argv[1]
            case '*.7z'
                7z x $argv[1]
            case '*'
                echo "'$argv[1]' cannot be extracted via extract()"
        end
    else
        echo "'$argv[1]' is not a valid file"
    end
end

# Quickly backup a file
function backup
    cp $argv[1] $argv[1].bak.(date +%Y%m%d_%H%M%S)
end

# Find and kill process
function fkill
    set -l pid (ps aux | fzf | awk '{print $2}')
    if test -n "$pid"
        kill -9 $pid
        echo "Killed process $pid"
    end
end

# Fuzzy cd into directory
function fcd
    set -l dir (fd --type d | fzf)
    if test -n "$dir"
        cd $dir
    end
end

# Edit config files with fzf
function conf
    set -l config (fd --type f . ~/.config | fzf)
    if test -n "$config"
        $EDITOR $config
    end
end

# ── Prompt (Starship) ─────────────────────────────────────────────
if command -v starship > /dev/null
    starship init fish | source
end

# ── Vi Mode ───────────────────────────────────────────────────────
# Uncomment to enable vi mode
# fish_vi_key_bindings

# ── FZF Configuration ─────────────────────────────────────────────
set -gx FZF_DEFAULT_OPTS "--height 50% --layout=reverse --border --info=inline --marker='*' --pointer='▶' --color='bg+:#363a4f,bg:#24273a,spinner:#f4dbd6,hl:#ed8796,fg:#cad3f5,header:#ed8796,info:#c6a0f6,pointer:#f4dbd6,marker:#f4dbd6,fg+:#cad3f5,prompt:#c6a0f6,hl+:#ed8796'"
set -gx FZF_DEFAULT_COMMAND 'fd --type f --hidden --follow --exclude .git'
set -gx FZF_CTRL_T_COMMAND "$FZF_DEFAULT_COMMAND"
set -gx FZF_ALT_C_COMMAND 'fd --type d --hidden --follow --exclude .git'

# ── Direnv ────────────────────────────────────────────────────────
if command -v direnv > /dev/null
    direnv hook fish | source
end

# ── Zoxide (better cd) ────────────────────────────────────────────
if command -v zoxide > /dev/null
    zoxide init fish | source
end

# ── Welcome Message ───────────────────────────────────────────────
# Uncomment to show fastfetch on terminal start
# if status is-interactive
#     fastfetch
# end

