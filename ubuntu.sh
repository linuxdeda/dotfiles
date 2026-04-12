#!/usr/bin/env bash
set -Eeuo pipefail

TARGET_USER="${SUDO_USER:-lxd}"
SSH_PUBKEY='ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIAdMcT6vefOaOG8rqZPvZhndojpq1zXc5c61zTzOKnim moj_nixos_pristup'
HOSTNAME_CURRENT="$(hostname)"
LOG_FILE="/var/log/ubuntu-setup.log"

exec > >(tee -a "$LOG_FILE") 2>&1

cleanup_on_error() {
  local exit_code=$?
  echo "❌ Greška na liniji ${BASH_LINENO[0]} (exit ${exit_code}). Pogledaj log: ${LOG_FILE}"
  exit "$exit_code"
}
trap cleanup_on_error ERR

need_cmd() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "❌ Nedostaje komanda: $1"
    exit 1
  }
}

backup_file() {
  local f="$1"
  if [ -e "$f" ] && [ ! -e "${f}.bak" ]; then
    cp -a "$f" "${f}.bak"
  fi
}

write_file_if_changed() {
  local path="$1"
  local tmp
  tmp="$(mktemp)"
  cat > "$tmp"
  if [ ! -f "$path" ] || ! cmp -s "$tmp" "$path"; then
    backup_file "$path"
    install -m 0644 -o root -g root "$tmp" "$path"
  fi
  rm -f "$tmp"
}

echo "🚀 Ubuntu setup startuje..."
echo "ℹ️ Log: $LOG_FILE"

if [ "${EUID}" -ne 0 ]; then
  echo "❌ Pokreni kao root: sudo ./ubuntu-setup.sh"
  exit 1
fi

if ! grep -qi ubuntu /etc/os-release; then
  echo "❌ Ova skripta je namenjena Ubuntu sistemu."
  exit 1
fi

if ! id "${TARGET_USER}" >/dev/null 2>&1; then
  echo "❌ Korisnik '${TARGET_USER}' ne postoji."
  echo "➡️ Pokreni npr: sudo TARGET_USER=tvoje_ime ./ubuntu-setup.sh"
  exit 1
fi

need_cmd apt
need_cmd systemctl

export DEBIAN_FRONTEND=noninteractive

echo "📦 Ažuriranje paketa..."
apt update
apt install -y software-properties-common ca-certificates curl gnupg lsb-release apt-transport-https

echo "📦 Instalacija paketa..."
apt install -y \
  fish git vim fastfetch figlet alacritty flatpak fzf curl \
  pcscd intel-microcode \
  tlp tlp-rdw \
  vlc libreoffice gimp \
  syncthing openvpn network-manager-openvpn-gnome \
  python3-pip firejail usbguard ufw systemd-resolved

if apt-cache show opendoas >/dev/null 2>&1; then
  apt install -y opendoas
  PRIVCMD="doas"
  write_file_if_changed /etc/doas.conf <<EOF
permit persist ${TARGET_USER}
EOF
  chown root:root /etc/doas.conf
  chmod 0400 /etc/doas.conf
else
  PRIVCMD="sudo"
  echo "⚠️ opendoas nije dostupan; koristi se sudo."
fi

echo "🔌 Uključivanje pametnih servisa..."
systemctl enable --now pcscd
systemctl enable --now NetworkManager

echo "🔋 Podešavanje TLP..."
systemctl mask power-profiles-daemon.service >/dev/null 2>&1 || true
apt remove -y power-profiles-daemon || true
systemctl enable --now tlp

write_file_if_changed /etc/tlp.conf <<'EOF'
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

tlp start || true

echo "🔍 Provera battery threshold podrške..."
BAT_THRESH_OK=0
if grep -Rqs . /sys/class/power_supply/BAT*/charge_control_*_threshold 2>/dev/null; then
  BAT_THRESH_OK=1
  echo "✅ Kernel interfejs za charge threshold postoji."
else
  echo "⚠️ Charge threshold interfejs nije detektovan; TLP pragovi možda neće raditi na ovom kernelu/hardveru."
fi

echo "🛡️ Firejail..."
if command -v firecfg >/dev/null 2>&1; then
  firecfg || true
fi

echo "🛡️ USBGuard bootstrap..."
backup_file /etc/usbguard/rules.conf
mkdir -p /etc/usbguard

systemctl stop usbguard >/dev/null 2>&1 || true

TMP_RULES="$(mktemp)"
usbguard generate-policy > "$TMP_RULES"

if [ ! -s "$TMP_RULES" ]; then
  echo "❌ USBGuard nije uspeo da generiše inicijalnu politiku."
  rm -f "$TMP_RULES"
  exit 1
fi

install -m 0600 -o root -g root "$TMP_RULES" /etc/usbguard/rules.conf
rm -f "$TMP_RULES"

if [ -f /etc/usbguard/usbguard-daemon.conf ]; then
  backup_file /etc/usbguard/usbguard-daemon.conf
  sed -i 's|^#\?ImplicitPolicyTarget=.*|ImplicitPolicyTarget=block|' /etc/usbguard/usbguard-daemon.conf || true
  sed -i 's|^#\?PresentDevicePolicy=.*|PresentDevicePolicy=apply-policy|' /etc/usbguard/usbguard-daemon.conf || true
  sed -i 's|^#\?InsertedDevicePolicy=.*|InsertedDevicePolicy=apply-policy|' /etc/usbguard/usbguard-daemon.conf || true
fi

systemctl enable --now usbguard

echo "🌐 systemd-resolved + DNS over TLS..."
mkdir -p /etc/NetworkManager/conf.d

write_file_if_changed /etc/NetworkManager/conf.d/10-dns-systemd-resolved.conf <<'EOF'
[main]
dns=systemd-resolved
rc-manager=symlink
EOF

write_file_if_changed /etc/systemd/resolved.conf <<'EOF'
[Resolve]
DNS=1.1.1.1#cloudflare-dns.com 9.9.9.9#dns.quad9.net
FallbackDNS=1.0.0.1#cloudflare-dns.com 149.112.112.112#dns.quad9.net
DNSOverTLS=yes
DNSSEC=allow-downgrade
Domains=~.
Cache=yes
EOF

backup_file /etc/resolv.conf
rm -f /etc/resolv.conf
ln -s /run/systemd/resolve/stub-resolv.conf /etc/resolv.conf

systemctl enable --now systemd-resolved
systemctl restart systemd-resolved
systemctl restart NetworkManager

echo "🔥 UFW..."
ufw --force reset
ufw default deny incoming
ufw default allow outgoing
ufw allow OpenSSH

if ufw app info syncthing >/dev/null 2>&1; then
  ufw allow syncthing
else
  ufw allow 22000/tcp comment 'Syncthing sync TCP'
  ufw allow 22000/udp comment 'Syncthing QUIC'
  ufw allow 21027/udp comment 'Syncthing local discovery'
fi

ufw allow openvpn || true
ufw --force enable

echo "👤 Korisnički setup za ${TARGET_USER}..."
FISH_PATH="$(command -v fish)"
chsh -s "${FISH_PATH}" "${TARGET_USER}" || true

install -d -m 700 -o "${TARGET_USER}" -g "${TARGET_USER}" "/home/${TARGET_USER}/.ssh"
printf '%s\n' "${SSH_PUBKEY}" > "/home/${TARGET_USER}/.ssh/authorized_keys"
chown "${TARGET_USER}:${TARGET_USER}" "/home/${TARGET_USER}/.ssh/authorized_keys"
chmod 600 "/home/${TARGET_USER}/.ssh/authorized_keys"

install -d -m 755 -o "${TARGET_USER}" -g "${TARGET_USER}" "/home/${TARGET_USER}/.config/fish"

cat > "/home/${TARGET_USER}/.config/fish/config.fish" <<EOF
if status is-interactive
    alias sys-up="${PRIVCMD} apt update && ${PRIVCMD} apt full-upgrade -y"
    alias sys-clean="${PRIVCMD} apt autoremove -y && ${PRIVCMD} apt clean"
    alias usb-list="${PRIVCMD} usbguard list-devices"
    alias usb-allow="${PRIVCMD} usbguard allow-device"
    alias usb-block="${PRIVCMD} usbguard block-device"
    alias fetch="fastfetch"
end
EOF
chown -R "${TARGET_USER}:${TARGET_USER}" "/home/${TARGET_USER}/.config/fish"

echo "🔧 Flatpak remote..."
if command -v flatpak >/dev/null 2>&1; then
  flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo || true
fi

echo "🔎 Post-check..."
systemctl is-enabled pcscd >/dev/null && echo "✅ pcscd enabled"
systemctl is-enabled tlp >/dev/null && echo "✅ tlp enabled"
systemctl is-enabled usbguard >/dev/null && echo "✅ usbguard enabled"
systemctl is-enabled systemd-resolved >/dev/null && echo "✅ systemd-resolved enabled"
ufw status verbose || true
resolvectl status | sed -n '1,80p' || true
tlp-stat -s 2>/dev/null || true

echo
echo "✅ Setup završen."
echo "➡️ Preporuka: restart."
echo "➡️ Posle restarta proveri:"
echo "   - resolvectl status"
echo "   - tlp-stat -b"
echo "   - ${PRIVCMD} usbguard list-devices"
if [ "$BAT_THRESH_OK" -eq 0 ]; then
  echo "⚠️ Battery threshold podrška nije potvrđena; moguće je da Dell pragovi na ovom kernelu ne rade."
fi
