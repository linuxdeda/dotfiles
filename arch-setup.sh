#!/bin/bash

# Provera privilegija
if [ "$EUID" -ne 0 ]; then
  echo "❌ Pokreni kao root (sudo ./arch-setup.sh)"
  exit 1
fi

# Definisanje korisnika
REAL_USER="lxd"
USER_HOME="/home/$REAL_USER"

echo "🚀 Započinjem postavljanje sistema (BEZ FIREJAIL-A)..."

# ----------------------------------------------------------------
# 1. OSNOVNI ALATI I SISTEM
# ----------------------------------------------------------------
echo "📦 Instalacija osnovnih paketa..."
# Uklonjen firejail iz liste ispod
pacman -Syu --noconfirm base-devel xdg-desktop-portal-gnome doas fish git neovim fastfetch figlet ghostty \
flatpak util-linux pcsc-tools pcsclite btrfs-progs ntfs-3g dosfstools gwenview \
vlc libreoffice-fresh gimp kdenlive usbguard python-pip btop \
btrfs-assistant gparted fuzzel swaybg firefox ttf-jetbrains-mono-nerd \
xwayland-satellite firewalld tlp tlp-rdw

# Podešavanje doas
echo "permit persist :wheel" > /etc/doas.conf
chmod 0400 /etc/doas.conf
# Kreiranje simlinka za sudo
ln -sf /usr/bin/doas /usr/bin/sudo

# ----------------------------------------------------------------
# 2. AUR HELPER (YAY)
# ----------------------------------------------------------------
echo "🟨 Instaliram yay..."
sudo -u "$REAL_USER" bash <<EOF
cd /tmp
rm -rf yay
git clone https://aur.archlinux.org/yay.git
cd yay
makepkg -si --noconfirm
EOF

echo "🟦 Instaliram Niri i Noctalia..."
sudo -u "$REAL_USER" yay -S --noconfirm niri noctalia-shell

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
# 4. OPTIMIZACIJA BATERIJE (TLP)
# ----------------------------------------------------------------
echo "🔋 Podešavanje TLP..."
cat <<EOF > /etc/tlp.conf
TLP_ENABLE=1
CPU_BOOST_ON_AC=1
CPU_BOOST_ON_BAT=0
CPU_SCALING_MAX_FREQ_ON_AC=3200000
CPU_SCALING_MAX_FREQ_ON_BAT=2200000
CPU_ENERGY_PERF_POLICY_ON_AC=balance_performance
CPU_ENERGY_PERF_POLICY_ON_BAT=balance_power
PLATFORM_PROFILE_ON_AC=balanced
PLATFORM_PROFILE_ON_BAT=low-power
START_CHARGE_THRESH_BAT0=75
STOP_CHARGE_THRESH_BAT0=80
EOF
systemctl enable --now tlp

# ----------------------------------------------------------------
# 5. BEZBEDNOST (Firewall, USBGuard, DNS)
# ----------------------------------------------------------------
echo "🛡️ Bezbednosne postavke..."

# USBGuard
usbguard generate-policy > /etc/usbguard/rules.conf
systemctl enable --now usbguard
# UKLONJENA firecfg komanda

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
echo "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAdMcT6vefOaOG8rqZPvZhndojpq1zXc5c61zTzOKnim moj_nixos_pristup" > "$USER_HOME/.ssh/authorized_keys"
chown -R "$REAL_USER":"$REAL_USER" "$USER_HOME/.ssh"
chmod 700 "$USER_HOME/.ssh"
chmod 600 "$USER_HOME/.ssh/authorized_keys"

mkdir -p "$USER_HOME/.config/fish"
cat <<EOF > "$USER_HOME/.config/fish/config.fish
if status is-interactive
    alias sys-up='doas pacman -Syu'
    alias sys-clean='doas pacman -Rns (pacman -Qtdq); and doas pacman -Sc'
    alias usb-list='doas usbguard list-devices'
    alias battery='doas tlp-stat -b'
    alias fetch='fastfetch'
    
    alias gs='git status'
    alias gp='git push'
    alias gl='git pull'

    alias snap-list='doas snapper list'
    alias snap-del='doas snapper delete'
end
EOF
chown -R "$REAL_USER":"$REAL_USER" "$USER_HOME/.config"

echo "-------------------------------------------------------"
echo "✅ INSTALACIJA ZAVRŠENA (Firejail uspešno izbačen)!"
echo "🚀 Rebootuj sistem."
