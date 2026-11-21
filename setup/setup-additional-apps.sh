#!/usr/bin/env bash
# Extra apps for Fedora: Obsidian, OnlyOffice (AppImage) and Zotero (official tarball).
# Run as normal user after setup-user.sh; sudo is used internally for /opt.
set -euo pipefail

if [[ $EUID -eq 0 ]]; then
  echo "Run as normal user (sudo is used internally)." >&2; exit 1
fi
if [[ $(uname -m) != x86_64 ]]; then
  echo "Only x86_64 is supported by this script." >&2; exit 1
fi
command -v curl >/dev/null || { echo "curl is required." >&2; exit 1; }
if [[ ! -e /usr/lib64/libfuse.so.2 ]]; then
  echo "AppImages need FUSE 2: sudo dnf install fuse-libs" >&2; exit 1
fi

sudo -v
# keep the sudo timestamp fresh while the big downloads run
( while kill -0 "$$" 2>/dev/null; do sudo -n true 2>/dev/null; sleep 60; done ) &
SUDO_KEEPALIVE=$!
APPS="$HOME/.local/share/applications"
mkdir -p "$APPS"
TMP=$(mktemp -d)
trap 'kill "$SUDO_KEEPALIVE" 2>/dev/null; rm -rf "$TMP"' EXIT

gh_latest_tag() {
  local tag
  tag=$(curl -fsSL "https://api.github.com/repos/$1/releases/latest" \
    | sed -n 's/.*"tag_name": *"\([^"]*\)".*/\1/p')
  [[ -n $tag ]] || { echo "Could not read latest release of $1" >&2; exit 1; }
  printf '%s\n' "$tag"
}

download() { curl -fL --retry 3 --progress-bar -o "$2" "$1"; }

install_appimage() {
  local label=$1 dir=$2 asset=$3 target=$4 url=$5 version=$6 icon_src=$7 icon_name=$8
  if [[ -x $dir/$target && -f $dir/.version && $(<"$dir/.version") == "$version" ]]; then
    echo "==> $label $version already installed"
    return
  fi
  echo "==> $label $version"
  download "$url" "$TMP/$asset"
  chmod +x "$TMP/$asset"
  sudo mkdir -p "$dir"
  sudo install -m755 "$TMP/$asset" "$dir/$target"
  rm -rf "$TMP/squashfs-root"
  ( cd "$TMP" && "./$asset" --appimage-extract "$icon_src" >/dev/null 2>&1 )
  sudo install -m644 "$TMP/squashfs-root/$icon_src" "$dir/$icon_name"
  printf '%s\n' "$version" | sudo tee "$dir/.version" >/dev/null
}

echo "==> Obsidian"
OBS_TAG=$(gh_latest_tag obsidianmd/obsidian-releases)
OBS_VER=${OBS_TAG#v}
install_appimage Obsidian /opt/Obsidian "Obsidian-$OBS_VER.AppImage" Obsidian.AppImage \
  "https://github.com/obsidianmd/obsidian-releases/releases/download/$OBS_TAG/Obsidian-$OBS_VER.AppImage" \
  "$OBS_VER" usr/share/icons/hicolor/512x512/apps/obsidian.png obsidian.png
sudo rm -f /opt/Obsidian/Obsidian-*.AppImage # leftovers from older runs

echo "==> OnlyOffice"
OO_TAG=$(gh_latest_tag ONLYOFFICE/DesktopEditors)
install_appimage OnlyOffice /opt/OnlyOffice DesktopEditors-x86_64.AppImage DesktopEditors-x86_64.AppImage \
  "https://github.com/ONLYOFFICE/DesktopEditors/releases/download/$OO_TAG/DesktopEditors-x86_64.AppImage" \
  "$OO_TAG" usr/share/icons/hicolor/256x256/apps/onlyoffice-desktopeditors.png onlyoffice.png
sudo rm -f /opt/OnlyOffice/OnlyOffice.AppImage # old asset name from the manual install

echo "==> Desktop entries"
cat > "$APPS/Obsidian.desktop" <<EOF
[Desktop Entry]
Type=Application
Name=Obsidian
Comment=Obsidian note-taking app
Exec=/opt/Obsidian/Obsidian.AppImage %U
Icon=/opt/Obsidian/obsidian.png
Terminal=false
Categories=Office;
MimeType=x-scheme-handler/obsidian;
EOF

cat > "$APPS/OnlyOffice.desktop" <<EOF
[Desktop Entry]
Type=Application
Name=OnlyOffice
GenericName=OnlyOffice
Comment=Edit office documents
Exec=/opt/OnlyOffice/DesktopEditors-x86_64.AppImage %U
Icon=/opt/OnlyOffice/onlyoffice.png
Terminal=false
Categories=Office;
EOF

echo "==> Zotero"
download "https://www.zotero.org/download/client/dl?channel=release&platform=linux-x86_64" \
  "$TMP/zotero.tar.xz"
mkdir -p "$TMP/zotero"
tar -xf "$TMP/zotero.tar.xz" -C "$TMP/zotero"
ZOT_SRC=$(find "$TMP/zotero" -maxdepth 2 -type f -name zotero-bin -printf '%h\n' -quit)
[[ -n $ZOT_SRC ]] || { echo "zotero-bin not found in tarball." >&2; exit 1; }
ZOT_INI=$(find "$ZOT_SRC" -maxdepth 3 -name application.ini -print -quit)
[[ -n $ZOT_INI ]] || { echo "application.ini not found in tarball." >&2; exit 1; }
ZOT_VER=$(sed -n 's/^Version=//p' "$ZOT_INI")
ZOT_INI_INST=$(find /opt/Zotero -maxdepth 3 -name application.ini -print -quit 2>/dev/null || true)
if [[ -n $ZOT_INI_INST ]] \
  && [[ $(sed -n 's/^Version=//p' "$ZOT_INI_INST") == "$ZOT_VER" ]]; then
  echo "    $ZOT_VER already installed"
else
  if pgrep -f '/opt/Zotero/(zotero|zotero-bin)' >/dev/null; then
    echo "Zotero is running. Close it and re-run." >&2; exit 1
  fi
  sudo rm -rf /opt/Zotero
  sudo mv "$ZOT_SRC" /opt/Zotero
  # user-owned so Zotero's built-in updater can write to it
  sudo chown -R "$USER:$USER" /opt/Zotero
  ( cd /opt/Zotero && ./set_launcher_icon )
  echo "    installed $ZOT_VER"
fi

ln -sfn /opt/Zotero/zotero.desktop "$APPS/zotero.desktop"

desktop-file-validate "$APPS/Obsidian.desktop" "$APPS/OnlyOffice.desktop"
update-desktop-database "$APPS" >/dev/null 2>&1 || true
if command -v kbuildsycoca6 >/dev/null; then kbuildsycoca6 >/dev/null 2>&1 || true; fi

for f in /opt/Obsidian/Obsidian.AppImage /opt/OnlyOffice/DesktopEditors-x86_64.AppImage /opt/Zotero/zotero-bin; do
  [[ -x $f ]] || { echo "Missing $f" >&2; exit 1; }
done

echo
echo "Done: Obsidian $OBS_VER, OnlyOffice ${OO_TAG#v}, Zotero $ZOT_VER"
