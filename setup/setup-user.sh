#!/usr/bin/env bash
# Fedora post-install (user). Run after setup-root.sh. NOT as root.
set -euo pipefail

if [[ $EUID -eq 0 ]]; then
  echo "Run as normal user." >&2; exit 1
fi

echo "==> .ssh check"
has_key=0
for f in "$HOME"/.ssh/*; do
  case "${f##*/}" in
    *.pub|config|known_hosts*) continue ;;
  esac
  if [ -f "$f" ]; then has_key=1; fi
done
if [[ ! -d "$HOME/.ssh" || ! -f "$HOME/.ssh/config" || $has_key != 1 ]]; then
  echo "Didn't you forget to paste backed up .ssh folder?" >&2
  exit 1
fi

echo "==> ssh permissions + agent"
chmod 700 "$HOME/.ssh"
chmod 600 "$HOME/.ssh"/* 2>/dev/null || true
chmod 644 "$HOME/.ssh"/*.pub 2>/dev/null || true
grep -q '^AddKeysToAgent yes' "$HOME/.ssh/config" \
  || printf 'AddKeysToAgent yes\n' >> "$HOME/.ssh/config"
systemctl --user enable --now ssh-agent.service

echo "==> load keys + github verify"
for f in "$HOME"/.ssh/*; do
  case "${f##*/}" in
    *.pub|config|known_hosts*) continue ;;
  esac
  [ -f "$f" ] && ssh-add -q "$f" 2>/dev/null || true
done
if ssh -o BatchMode=yes -o StrictHostKeyChecking=accept-new -T git@github.com 2>&1 \
  | grep -q 'successfully authenticated'; then
  echo "github OK"
else
  echo "github FAILED - add $HOME/.ssh/id_ed25519.pub at github.com/settings/keys"
fi

echo "==> git identity"
git config --global user.name "anjarhariadi"
git config --global user.email "anjarmath@gmail.com"

echo "==> Dev directory tree"
mkdir -p "$HOME/Dev/SDK" "$HOME/Dev/Script" \
  "$HOME/Dev/Projects/Personal" "$HOME/Dev/Projects/Community" \
  "$HOME/Dev/Projects/Work" "$HOME/Dev/Projects/Learn"

echo "==> Go SDK (latest, to Dev/SDK/go)"
GO_VERSION=$(curl -fsSL "https://go.dev/VERSION?m=text" | head -1)
GOARCH=$(uname -m)
case "$GOARCH" in
  x86_64)  GOARCH=amd64 ;;
  aarch64) GOARCH=arm64 ;;
esac
curl -fsSL "https://go.dev/dl/${GO_VERSION}.linux-${GOARCH}.tar.gz" \
  | tar -C "$HOME/Dev/SDK" -xzf -

echo "==> fnm (node version manager)"
curl -fsSL https://fnm.vercel.app/install | bash

echo "==> starship prompt"
curl -fsSL https://starship.rs/install.sh | sh -s -- -y

echo "==> oh-my-zsh"
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended

RC="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"
echo "==> zsh plugins"
git clone https://github.com/zsh-users/zsh-autosuggestions.git "$RC/plugins/zsh-autosuggestions"
git clone https://github.com/zdharma-continuum/fast-syntax-highlighting.git "$RC/plugins/fast-syntax-highlighting"

echo "==> zsh as login shell"
chsh -s "$(command -v zsh)"

echo "==> opencode"
curl -fsSL https://opencode.ai/install | bash

echo "User setup done. Log out and back in."