### 1. SSH AGENT PODEŠAVANJE
if not pgrep -u $USER ssh-agent >/dev/null
    ssh-agent -c > $XDG_RUNTIME_DIR/ssh-agent.fish
end

if test -f $XDG_RUNTIME_DIR/ssh-agent.fish
    source $XDG_RUNTIME_DIR/ssh-agent.fish >/dev/null
end


### 2. FUNKCIJE
function banner
    set -l cols (tput cols)
    printf '\e[H\e[2J'
    if type -q figlet
        figlet -f standard -w $cols 'linuxdeda.com'
    else
        echo 'linuxdeda.com'
    end
    echo
end


### 3. ALIASI
alias sys-up='doas pacman -Syu --refresh'
alias usb-list='doas usbguard list-devices'
alias usb-allow='doas usbguard allow-device'
alias battery='doas tlp-stat -b'
alias fetch='fastfetch'
alias gs='git status'
alias gp='git push'
alias gl='git pull'


### 4. FUNKCIJE UMESTO RIZIČNIH ALIASA
function sys-clean
    set -l orphans (pacman -Qtdq 2>/dev/null)
    if test -n "$orphans"
        doas pacman -Rns $orphans
    end
    doas pacman -Sc
end


### 5. INTERAKTIVNI DEO
if status is-interactive
    banner

    if type -q fastfetch
        fastfetch
    end

    echo

    # CTRL+L: očisti ekran i prikaži samo banner
    bind \cl 'banner; commandline -f repaint'
end
