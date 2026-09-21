#!/usr/bin/env bash
# Fedora post-install (root). Run: sudo ./setup-root.sh, then ./setup-user.sh as normal user.
set -euo pipefail

if [[ $EUID -ne 0 ]]; then
  echo "Run with sudo." >&2; exit 1
fi

echo "==> dnf.conf"
cat > /etc/dnf/dnf.conf <<'EOF'
[main]
max_parallel_downloads=10
fastestmirror=True
EOF

# echo "==> system update"
# dnf update -y

echo "==> swappiness"
printf 'vm.swappiness=10\n' > /etc/sysctl.d/99-swappiness.conf
sysctl --system >/dev/null

echo "==> disable metadata makecache timer"
systemctl disable --now dnf-makecache.timer

echo "==> RPM Fusion"
dnf install -y \
  "https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm" \
  "https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm"

echo "==> ffmpeg (swap free build for full)"
dnf swap -y ffmpeg-free ffmpeg --allowerasing

echo "==> remove KDE bloat + firefox (chrome replaces it)"
dnf remove -y \
  'libreoffice*' kmahjongg kmines kpat kolourpaint \
  akregator kmail neochat dragon elisa-player kamoso \
  kaddressbook korganizer firefox

echo "==> VS Code repo"
rpm --import https://packages.microsoft.com/keys/microsoft.asc
cat > /etc/yum.repos.d/vscode.repo <<'EOF'
[code]
name=Visual Studio Code
baseurl=https://packages.microsoft.com/yumrepos/vscode
enabled=1
autorefresh=1
type=rpm-md
gpgcheck=1
gpgkey=https://packages.microsoft.com/keys/microsoft.asc
EOF

echo "==> Google Chrome (rpm install adds the repo)"
dnf install -y https://dl.google.com/linux/direct/google-chrome-stable_current_x86_64.rpm
dnf list --installed google-chrome-stable >/dev/null || { echo "Chrome install FAILED." >&2; exit 1; }

echo "==> base packages"
dnf install -y stow zsh code

echo "Root setup done."
