### 1. SSH AGENT PODEŠAVANJE (Fish način)
# Pokreće agenta ako već ne radi i učitava ključeve
if not pgrep -u $USER ssh-agent > /dev/null
    ssh-agent -c > $XDG_RUNTIME_DIR/ssh-agent.fish
end
if test -f $XDG_RUNTIME_DIR/ssh-agent.fish
    source $XDG_RUNTIME_DIR/ssh-agent.fish > /dev/null
end

### 2. FUNKCIJE
function banner
    set COLS (tput cols)
    printf '\e[H\e[2J' # Čisti ekran
    if type -q figlet
        figlet -f standard -w $COLS 'linuxdeda.com'
    else
        echo "linuxdeda.com"
    end
    echo
end

### 3. INTERAKTIVNI DEO (Samo kada otvoriš terminal)
if status is-interactive
    # Izgled pri startu
    banner
    if type -q fastfetch
        fastfetch
    end
    echo

    # ALIASI (Prečice)
    alias sys-up='doas dnf upgrade -y'
    alias sys-clean='doas dnf autoremove && doas dnf clean all'
    alias usb-list='doas usbguard list-devices'
    alias usb-allow='doas usbguard allow-device'
    alias battery='doas tlp-stat -p'
    alias fetch='fastfetch'
    
    # Git prečice (dodao sam ti par korisnih)
    alias gs='git status'
    alias gp='git push'
    alias gl='git pull'

    # BINDINGS
    # CTRL+L sada čisti ekran, ispisuje banner i fastfetch ponovo
    bind \cl 'banner; fastfetch; commandline -f repaint'
end
