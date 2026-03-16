#!/bin/bash

if [ "$EUID" -ne 0 ]; then 
  echo "❌ Pokreni kao root (sudo ./arch-setup.sh)"
  exit 1
fi

echo "🚀 Arch KDE setup iz Fedore..."

# 1. OSNOVNI ALATI (pacman umesto dnf)
echo "📦 Osnovni alati..."
pacman -Syu --noconfirm doas fish git neovim fastfetch figlet alacritty flatpak util-linux pcsc-tools pcsclite

# doas.conf (isti)
echo "permit persist :wheel" > /etc/doas.conf
chmod 0400 /etc/doas.conf

systemctl enable --now pcscd.socket

# 2. TLP (isti config, ali pacman)
echo "🔋 TLP za Intel..."
pacman -S --noconfirm tlp tlp-rdw
systemctl enable tlp

cat <<EOF > /etc/tlp.conf
# Isti TLP config kao gore (kopiraj ceo blok iz originala)
TLP_ENABLE=1
CPU_BOOST_ON_AC=1
CPU_BOOST_ON_BAT=1
CPU_HWP_DYN_BOOST_ON_AC=0
CPU_HWP_DYN_BOOST_ON_BAT=0
CPU_SCALING_MAX_FREQ_ON_AC=3200000
CPU_SCALING_MAX_FREQ_ON_BAT=2200000
CPU_SCALING_MIN_FREQ_ON_AC=400000
CPU_SCALING_MIN_FREQ_ON_BAT=400000
CPU_ENERGY_PERF_POLICY_ON_AC=balance_performance
CPU_ENERGY_PERF_POLICY_ON_BAT=balance_power
PLATFORM_PROFILE_ON_AC=balanced
PLATFORM_PROFILE_ON_BAT=quiet
START_CHARGE_THRESH_BAT0=70
STOP_CHARGE_THRESH_BAT0=80
DISK_APM_LEVEL_ON_AC="254 254"
EOF
tlp start

# 3. PROGRAMI (Arch ekvivalenti)
echo "🛒 Aplikacije..."
pacman -S --noconfirm vlc libreoffice-fresh gimp thunderbird keepassxc syncthing networkmanager-openvpn kcalc kdenlive ktorrent dolphin partitionmanager firejail usbguard veracrypt python-pip

# LibreOffice Qt6 podrška: pacman -S qt6-svg qt6-declarative (ako treba)

# 4. BEZBEDNOST
echo "🛡️ Firejail & USBGuard..."
usbguard generate-policy > /etc/usbguard/rules.conf
systemctl enable --now usbguard
firecfg

# 5. DNS over TLS (systemd-resolved dostupan)
echo "🌐 DNS over TLS..."
sed -i '/\[Resolve\]/,/^\[/s|.*||' /etc/systemd/resolved.conf 2>/dev/null || true
cat <<EOF >> /etc/systemd/resolved.conf
[Resolve]
DNS=1.1.1.1 9.9.9.9
DNSOverTLS=yes
DNSSEC=yes
Domains=~.
FallbackDNS=1.1.1.1
EOF
ln -sf /run/systemd/resolve/stub-resolv.conf /etc/resolv.conf
systemctl restart systemd-resolved

# 6. Firewall (nftables/firewalld nije default; koristi nft ili firewalld)
pacman -S --noconfirm firewalld
systemctl enable --now firewalld
firewall-cmd --permanent --add-service=syncthing
firewall-cmd --permanent --add-service=ssh
firewall-cmd --permanent --add-service=openvpn
firewall-cmd --permanent --add-interface=tun+ --zone=trusted
firewall-cmd --reload

# 7. Korisnik lxd
echo "👤 Konfiguracija lxd..."
FISH_PATH=/usr/bin/fish
chsh -s "$FISH_PATH" lxd

mkdir -p /home/lxd/.ssh
echo "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAdMcT6vefOaOG8rqZPvZhndojpq1zXc5c61zTzOKnim moj_nixos_pristup" > /home/lxd/.ssh/authorized_keys
chown -R lxd:lxd /home/lxd/.ssh
chmod 700 /home/lxd/.ssh
chmod 600 /home/lxd/.ssh/authorized_keys

mkdir -p /home/lxd/.config/fish
cat <<EOF > /home/lxd/.config/fish/config.fish
if status is-interactive
   alias sys-up='doas pacman -Syu --refresh'
   alias sys-clean='doas pacman -Rns (pacman -Qtdq) && doas pacman -Sc'  # fish subshell, ali za sys-clean koristi funkciju dole
   alias usb-list='doas usbguard list-devices'
   alias usb-allow='doas usbguard allow-device'
   alias battery='doas tlp-stat -b'
   alias fetch='fastfetch'
   alias gs='git status'
   alias gp='git push'
   alias gl='git pull'
end
EOF
chown -R lxd:lxd /home/lxd/.config/fish

echo "✅ Gotovo! Reboot za TLP/fish."
