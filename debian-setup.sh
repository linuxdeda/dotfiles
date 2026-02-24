#!/bin/bash

# Provera da li se skripta pokreće kao root
if [ "$EUID" -ne 0 ]; then 
  echo "❌ Molim te pokreni kao root (sudo ./debian-setup.sh)"
  exit
fi

echo "🚀 Započinjem transformaciju Debiana u tvoj setup (Intel 13th Gen)..."

# 0. OMOGUĆAVANJE REPOZITORIJUMA (Non-free je bitan za Intel Microcode)
apt update
apt install -y software-properties-common
add-apt-repository contrib non-free non-free-firmware -y
apt update

# 1. OSNOVNI ALATI, SHELL I SERVISI
echo "📦 Instalacija osnovnih alata..."
apt install -y opendoas fish git vim fastfetch figlet alacritty flatpak fzf curl pcscd intel-microcode

# Podešavanje doas (Naučili smo: direktno ime korisnika radi bolje na Debianu)
echo "permit persist lxd" > /etc/doas.conf
chown root:root /etc/doas.conf
chmod 0400 /etc/doas.conf

# Omogućavanje pcscd (važno za KeepassXC i Yubikey)
systemctl enable --now pcscd

# 2. TLP (INTEL 13. GEN KONFIGURACIJA)
echo "🔋 Podešavanje baterije i termalnih limita..."
apt remove -y power-profiles-daemon || true
apt install -y tlp tlp-rdw
systemctl enable tlp

cat <<EOF > /etc/tlp.conf
TLP_ENABLE=1
CPU_BOOST_ON_AC=1
CPU_BOOST_ON_BAT=1
CPU_HWP_DYN_BOOST_ON_AC=0
CPU_HWP_DYN_BOOST_ON_BAT=0

# Limit frekvencije (i5-1334U)
CPU_SCALING_MAX_FREQ_ON_AC=3200000
CPU_SCALING_MAX_FREQ_ON_BAT=2200000
CPU_SCALING_MIN_FREQ_ON_AC=400000
CPU_SCALING_MIN_FREQ_ON_BAT=400000

CPU_ENERGY_PERF_POLICY_ON_AC=balance_performance
CPU_ENERGY_PERF_POLICY_ON_BAT=balance_power
PLATFORM_PROFILE_ON_AC=balanced
PLATFORM_PROFILE_ON_BAT=quiet

# Dell specifično
START_CHARGE_THRESH_BAT0=70
STOP_CHARGE_THRESH_BAT0=80
DISK_APM_LEVEL_ON_AC="254 254"
EOF

# 3. INSTALACIJA SVIH PROGRAMA
echo "🛒 Instalacija aplikacija..."
apt install -y vlc libreoffice gimp \
               syncthing openvpn network-manager-openvpn-gnome \
               python3-pip  \
               firejail usbguard

# 4. BEZBEDNOST (FIREJAIL & USBGUARD)
echo "🛡️ Učvršćivanje sistema..."
# USBGuard mora prvo da se pokrene da bi alat mogao da generiše polisu
systemctl start usbguard
usbguard generate-policy > /etc/usbguard/rules.conf
systemctl enable usbguard

# Firejail integracija
firecfg

# 5. PRIVATNOST I DNS (DNS over TLS)
echo "🌐 Podešavanje DNS over TLS..."
apt install -y systemd-resolved
cat <<EOF > /etc/systemd/resolved.conf
[Resolve]
DNS=1.1.1.1 9.9.9.9
DNSOverTLS=yes
DNSSEC=yes
Domains=~.
FallbackDNS=1.1.1.1
EOF

# Linkovanje resolv.conf
rm -f /etc/resolv.conf
ln -s /run/systemd/resolve/stub-resolv.conf /etc/resolv.conf
systemctl enable --now systemd-resolved

# 6. FIREWALL (UFW)
echo "🔥 Konfiguracija firewall-a..."
apt install -y ufw
ufw default deny incoming
ufw default allow outgoing
ufw allow syncthing
ufw allow ssh
ufw allow openvpn
ufw --force enable

# 7. KORISNIK (SHELL, SSH, ALIASI)
echo "👤 Konfiguracija korisnika lxd..."

# Promena shell-a
FISH_PATH=$(which fish)
chsh -s "$FISH_PATH" lxd

# SSH Ključ
mkdir -p /home/lxd/.ssh
echo "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAdMcT6vefOaOG8rqZPvZhndojpq1zXc5c61zTzOKnim moj_nixos_pristup" > /home/lxd/.ssh/authorized_keys
chown -R lxd:lxd /home/lxd/.ssh
chmod 700 /home/lxd/.ssh
chmod 600 /home/lxd/.ssh/authorized_keys

# Fish Aliases (Prilagođeni za APT i ispravan doas)
mkdir -p /home/lxd/.config/fish
cat <<EOF > /home/lxd/.config/fish/config.fish
if status is-interactive
    alias sys-up="doas apt update && doas apt upgrade -y"
    alias sys-clean="doas apt autoremove && doas apt clean"
    alias usb-list="doas usbguard list-devices"
    alias usb-allow="doas usbguard allow-device"
    alias fetch="fastfetch"
end
EOF
chown -R lxd:lxd /home/lxd/.config/fish

echo "✅ Sve je završeno! Sistem je spreman."
echo "⚠️  VAŽNO: Pokreni 'doas nmcli connection modify \"IME_WIFI\" ipv4.ignore-auto-dns yes' nakon restarta."
echo "⚠️  RESTARTUJ KOMPJUTER."
