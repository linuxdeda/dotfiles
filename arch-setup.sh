#!/bin/bash

# Provera privilegija
if [ "$EUID" -ne 0 ]; then
  echo "❌ Pokreni kao root (sudo ./arch-setup.sh)"
  exit 1
fi

# Definisanje korisnika
REAL_USER="lxd"
USER_HOME="/home/$REAL_USER"

echo "🚀 Započinjem postavljanje sistema (Arch Minimal + Niri + Noctalia)..."

# ----------------------------------------------------------------
# 1. OSNOVNI ALATI, AUDIO I GRAFIKA
# ----------------------------------------------------------------
echo "📦 Instalacija osnovnih paketa..."

# Dodati: mesa i vulkan-intel (za tvoj i5-1334U), 
# pipewire (audio), bluez (bluetooth), networkmanager
pacman -Syu --noconfirm base-devel xdg-desktop-portal-gnome xdg-desktop-portal-gtk \
doas fish git neovim fastfetch figlet ghostty networkmanager \
pipewire pipewire-pulse pipewire-alsa pipewire-jack wireplumber \
bluez bluez-utils mesa vulkan-intel intel-ucode \
flatpak util-linux pcsc-tools pcsclite btrfs-progs ntfs-3g dosfstools gwenview \
vlc libreoffice-fresh gimp kdenlive usbguard python-pip btop \
btrfs-assistant gparted fuzzel swaybg firefox ttf-jetbrains-mono-nerd \
xwayland-satellite firewalld tlp tlp-rdw ttf-inter brightnessctl intel-media-driver libva-utils

# Omogućavanje mrežnog servisa i bluetooth-a
systemctl enable --now NetworkManager
systemctl enable --now bluetooth

# Podešavanje doas
echo "permit persist :wheel" > /etc/doas.conf
chmod 0400 /etc/doas.conf
ln -sf /usr/bin/doas /usr/bin/sudo

# ----------------------------------------------------------------
# 2. AUR HELPER (YAY) & DESKTOP ENVIROMENT
# ----------------------------------------------------------------
echo "🟨 Instaliram yay..."
sudo -u "$REAL_USER" bash <<EOF
cd /tmp
rm -rf yay
git clone https://aur.archlinux.org/yay.git
cd yay
makepkg -si --noconfirm
EOF

echo "🟦 Instaliram Niri i Noctalia (i zavisnosti za shell)..."
# Noctalia zahteva ags i često swww za wallpapere
sudo -u "$REAL_USER" yay -S --noconfirm niri noctalia-shell swww-git aygram-hot-reload-git

# ----------------------------------------------------------------
# 3. SNAPSHOTS (Snapper + Btrfs)
# ----------------------------------------------------------------
echo "📸 Konfiguracija Snapper-a..."
pacman -S --noconfirm snapper snap-pac grub-btrfs efibootmgr grub

ROOT_PART=$(findmnt -n -o SOURCE /)

umount /.snapshots 2>/dev/null || true
rm -rf /.snapshots 2>/dev/null || true
snapper -c root create-config /
mkdir /.snapshots
mount -o subvol=@snapshots "$ROOT_PART" /.snapshots

cat <<EOF > /etc/snapper/configs/root
TIMELINE_CREATE="yes"
TIMELINE_CLEANUP="yes"
TIMELINE_MIN_AGE="1800"
TIMELINE_LIMIT_HOURLY="10"
TIMELINE_LIMIT_DAILY="20"
TIMELINE_LIMIT_WEEKLY="7"
TIMELINE_LIMIT_MONTHLY="3"
TIMELINE_LIMIT_YEARLY="2"
NUMBER_CLEANUP="yes"
NUMBER_LIMIT="50-100"
EOF

systemctl enable --now snapper-timeline.timer snapper-cleanup.timer
grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=GRUB
grub-mkconfig -o /boot/grub/grub.cfg

# ----------------------------------------------------------------
# 4. OPTIMIZACIJA BATERIJE (TLP) - Prilagođeno tvom i5-1334U
# ----------------------------------------------------------------
echo "🔋 Podešavanje TLP..."
cat <<EOF > /etc/tlp.conf
TLP_ENABLE=1
CPU_BOOST_ON_AC=1
CPU_BOOST_ON_BAT=0
# Ograničavamo frekvenciju kako bi tvoj 13th gen ostao hladan
CPU_SCALING_MAX_FREQ_ON_AC=3200000
CPU_SCALING_MAX_FREQ_ON_BAT=2200000
CPU_ENERGY_PERF_POLICY_ON_AC=balance_performance
CPU_ENERGY_PERF_POLICY_ON_BAT=power
PLATFORM_PROFILE_ON_AC=balanced
PLATFORM_PROFILE_ON_BAT=low-power
# Čuvanje baterije na tvom laptopu
START_CHARGE_THRESH_BAT0=75
STOP_CHARGE_THRESH_BAT0=80
EOF
systemctl enable --now tlp

# ----------------------------------------------------------------
# 5. BEZBEDNOST (Firewall, USBGuard, DNS)
# ----------------------------------------------------------------
echo "🛡️ Bezbednosne postavke..."

# USBGuard - Pažljivo sa ovim, generiše polisu za trenutno ubačene uređaje
usbguard generate-policy > /etc/usbguard/rules.conf
systemctl enable --now usbguard

# DNS over TLS
cat <<EOF > /etc/systemd/resolved.conf
[Resolve]
DNS=1.1.1.1 9.9.9.9
DNSOverTLS=yes
DNSSEC=yes
Domains=~.
EOF
ln -sf /run/systemd/resolve/stub-resolv.conf /etc/resolv.conf
systemctl enable --now systemd-resolved

# Firewall
systemctl enable --now firewalld
firewall-cmd --permanent --add-service=ssh
firewall-cmd --reload

# Pametne kartice
systemctl enable --now pcscd.socket

# ----------------------------------------------------------------
# 6. KORISNIČKO OKRUŽENJE (Fish & SSH)
# ----------------------------------------------------------------
echo "👤 Konfiguracija korisnika $REAL_USER..."
chsh -s /usr/bin/fish "$REAL_USER"

mkdir -p "$USER_HOME/.ssh"
# Tvoj SSH ključ
echo "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAdMcT6vefOaOG8rqZPvZhndojpq1zXc5c61zTzOKnim lxd-secure-key" > "$USER_HOME/.ssh/authorized_keys"
chown -R "$REAL_USER":"$REAL_USER" "$USER_HOME/.ssh"
chmod 700 "$USER_HOME/.ssh"
chmod 600 "$USER_HOME/.ssh/authorized_keys"

mkdir -p "$USER_HOME/.config/fish"
cat <<'EOF' > "$USER_HOME/.config/fish/config.fish"
if status is-interactive
    set -g fish_greeting ""

    ### SSH AGENT
    if not pgrep -u (id -u) ssh-agent >/dev/null
        eval (ssh-agent -c)
    end

    ### FUNKCIJE
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

    function sys-clean
        set -l orphans (pacman -Qtdq 2>/dev/null)
        if test -n "$orphans"
            doas pacman -Rns $orphans
        end
        doas pacman -Sc
    end

    ### INTERAKTIVNI DEO
    banner

    if type -q fastfetch
        fastfetch
    end
    echo

    bind \cl 'banner; commandline -f repaint'

    ### ALIJASI
    alias sys-up='doas pacman -Syu'
    alias sys-clean='sys-clean'
    alias usb-list='doas usbguard list-devices'
    alias battery='doas tlp-stat -b'
    alias fetch='fastfetch'

    alias gs='git status'
    alias gp='git push'
    alias gl='git pull'

    alias snap-list='doas snapper list'
    alias snap-del='doas snapper delete'

    alias niri-conf='nvim ~/.config/niri/config.kdl'

    ### WAYLAND
    set -gx SDL_VIDEODRIVER wayland
    set -gx CLUTTER_BACKEND wayland
    set -gx QT_QPA_PLATFORM wayland
end
EOF
chown -R "$REAL_USER":"$REAL_USER" "$USER_HOME/.config"

echo "-------------------------------------------------------"
echo "✅ INSTALACIJA ZAVRŠENA!"
echo "💡 Preporuka: Nakon reboota, pokreni 'niri' iz terminala."
echo "🚀 Rebootuj sistem."
