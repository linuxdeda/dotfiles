#!/bin/bash

# Provera da li se skripta pokreće kao root
if [ "$EUID" -ne 0 ]; then 
  echo "❌ Molim te pokreni kao root (sudo ./fedora-setup.sh)"
  exit
fi

echo "🚀 Započinjem transformaciju Fedore u tvoj NixOS setup..."

# 1. OSNOVNI ALATI, SHELL I SERVISI
echo "📦 Instalacija osnovnih alata..."
dnf copr enable scottames/ghostty
dnf install -y doas fish  vim fastfetch figlet ghostty

# Podešavanje doas (zamena za tvoj security.doas iz Nix-a)
echo 'permit persist :wheel' | sudo tee /etc/doas.conf >/dev/null
sudo chown root:root /etc/doas.conf
sudo chmod 0400 /etc/doas.conf

# Omogućavanje pcscd (važno za KeepassXC i hardverske ključeve)
systemctl enable --now pcscd

# 2. TLP (INTEL 13. GEN KONFIGURACIJA)
echo "🔋 Podešavanje baterije i termalnih limita..."
dnf remove -y power-profiles-daemon
dnf install -y tlp tlp-rdw
systemctl enable tlp

cat <<EOF > /etc/tlp.conf
# ------------------------------------------------------------------------------
# TLP FINALNA KONFIGURACIJA - DELL i5-1334U (Optimizovano za Fedoru 43)
# ------------------------------------------------------------------------------

# Omogući TLP
TLP_ENABLE=1

# --- PROCESOR (Glavna podešavanja) ---

# Dozvoljavamo Turbo da bismo preskočili limit od 1.3 GHz
CPU_BOOST_ON_AC=1
CPU_BOOST_ON_BAT=1

# Isključujemo dinamički boost da bismo imali stabilne frekvencije
CPU_HWP_DYN_BOOST_ON_AC=0
CPU_HWP_DYN_BOOST_ON_BAT=0

# DIREKTNO OGRANIČENJE FREKVENCIJE (Fiksni limiti u kHz)
# Na punjaču: 3.2 GHz (Brzo i stabilno, bez pregrevanja)
CPU_SCALING_MAX_FREQ_ON_AC=3200000
# Na bateriji: 2.2 GHz (Dovoljno za tečan rad, velika ušteda)
CPU_SCALING_MAX_FREQ_ON_BAT=2200000

# Minimalna frekvencija (400 MHz)
CPU_SCALING_MIN_FREQ_ON_AC=400000
CPU_SCALING_MIN_FREQ_ON_BAT=400000

# ENERGY PERFORMANCE POLICY (EPP)
CPU_ENERGY_PERF_POLICY_ON_AC=balance_performance
CPU_ENERGY_PERF_POLICY_ON_BAT=balance_power

# PLATFORM PROFILE (BIOS/Firmware nivo)
PLATFORM_PROFILE_ON_AC=balanced
PLATFORM_PROFILE_ON_BAT=quiet

# --- BATERIJA (Dell specifično) ---
# Čuva zdravlje baterije (puni od 70% do 80%)
START_CHARGE_THRESH_BAT0=70
STOP_CHARGE_THRESH_BAT0=80

# --- DISKOVI I OSTALO ---
# Isključujemo preagresivno gašenje diskova na punjaču
DISK_APM_LEVEL_ON_AC="254 254"
EOF

# 3. INSTALACIJA SVIH PROGRAMA
echo "🛒 Instalacija aplikacija..."
dnf install -y vlc gimp openvpn NetworkManager-openvpn-gnome nm-connection-editor python3-pip  kdenlive firejail usbguard

# 4. BEZBEDNOST (FIREJAIL & USBGUARD)
echo "🛡️ Učvršćivanje sistema (Sandboxing & USB)..."
# USBGuard inicijalizacija (dozvoljava trenutno prikačene uređaje)
sudo usbguard generate-policy | sudo tee /etc/usbguard/rules.conf >/dev/null
sudo systemctl enable --now usbguard

# Firejail sandbox integracija
firecfg

# 5. PRIVATNOST I DNS (DNS over TLS)
echo "🌐 Podešavanje DNS over TLS (Cloudflare/Quad9)..."
systemctl enable --now systemd-resolved
cat <<EOF > /etc/systemd/resolved.conf
[Resolve]
DNS=1.1.1.1 9.9.9.9
DNSOverTLS=yes
DNSSEC=yes
Domains=~.
FallbackDNS=1.1.1.1
EOF
ln -sf /run/systemd/resolve/stub-resolv.conf /etc/resolv.conf
systemctl restart systemd-resolved

# 6. FIREWALL (OTVARANJE PORTOVA)
echo "🔥 Konfiguracija firewall-a..."
firewall-cmd --permanent --add-service=syncthing
firewall-cmd --permanent --add-service=ssh
firewall-cmd --permanent --add-service=openvpn
firewall-cmd --permanent --add-interface=tun+ --zone=trusted
firewall-cmd --reload

# 7. KORISNIK (SHELL, SSH, ALIASI)
echo "👤 Konfiguracija korisnika lxd..."

# Promena shell-a (koristimo punu putanju do fish-a)
FISH_PATH=$(which fish)
chsh -s "$FISH_PATH" lxd

# SSH Ključ
mkdir -p /home/lxd/.ssh
echo "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAdMcT6vefOaOG8rqZPvZhndojpq1zXc5c61zTzOKnim moj_nixos_pristup" > /home/lxd/.ssh/authorized_keys
chown -R lxd:lxd /home/lxd/.ssh
chmod 700 /home/lxd/.ssh
chmod 600 /home/lxd/.ssh/authorized_keys

# Fish Aliases
mkdir -p /home/lxd/.config/fish
cat <<EOF > /home/lxd/.config/fish/config.fish
if status is-interactive
    alias sys-up="doas dnf upgrade -y"
    alias sys-clean="doas dnf autoremove && doas dnf clean all"
    alias usb-list="doas usbguard list-devices"
    alias usb-allow="doas usbguard allow-device"
    alias fetch="fastfetch"
end
EOF
chown -R lxd:lxd /home/lxd/.config/fish

echo "✅ Sve je završeno! Sistem je spreman."
echo "⚠️  RESTARTUJ KOMPJUTER kako bi TLP i promene shell-a stupile na snagu."


After install Fedora:

1⃣ Faster DNF Configuration

Open:
sudo nano /etc/dnf/dnf.conf

Add these lines:
max_parallel_downloads=10
fastestmirror=True
defaultyes=True
keepcache=True

━━━━━━━━━━━━━━━

2⃣ Update The System

sudo dnf upgrade --refresh

━━━━━━━━━━━━━━━

3⃣ RPM Fusion Repositories

sudo dnf install https://download1.rpmfusion.org/free/fedora/rpmfusion-free-release-44.noarch.rpm

sudo dnf install https://download1.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-44.noarch.rpm

━━━━━━━━━━━━━━━

4⃣ Multimedia Codecs

sudo dnf swap ffmpeg-free ffmpeg --allowerasing
sudo dnf group upgrade multimedia --setopt="install_weak_deps=False" --exclude=PackageKit-gstreamer-plugin

━━━━━━━━━━━━━━━

5⃣ Enable Flathub

flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo

━━━━━━━━━━━━━━━

6⃣ AppImage Support

sudo dnf install fuse fuse-libs

━━━━━━━━━━━━━━━

7⃣ Docker Installation

sudo dnf install docker docker-compose

sudo systemctl enable --now docker

sudo usermod -aG docker $USER

━━━━━━━━━━━━━━━

Reboot once after setup for best experience 👍
