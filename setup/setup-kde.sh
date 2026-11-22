#!/usr/bin/env bash
# KDE extras: Krohnkite (built from source), nokara plasmoid, and config restore. Run as normal user.
# Use --config-only to skip plugin installation and only merge the templates.
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
KDE_DIR="$REPO_DIR/setup/kde"
CONFIG_ONLY=0
[[ ${1:-} == "--config-only" ]] && CONFIG_ONLY=1

if [[ $EUID -eq 0 ]]; then
  echo "Run as normal user." >&2; exit 1
fi

for c in kwriteconfig6 kreadconfig6; do
  command -v "$c" >/dev/null || { echo "$c is required." >&2; exit 1; }
done

ensure_regular() {
  local file=$1 tmp
  [[ -L $file ]] || return 0
  tmp=$(mktemp "${file}.XXXXXX")
  cp -pL "$file" "$tmp"
  mv -f "$tmp" "$file"
}

unescape() {
  REPLY=${1//\\\\/\\}
  REPLY=${REPLY//\\t/$'\t'}
  if [[ $REPLY == @EMPTY@ ]]; then REPLY=''; fi
}

write_spec() {
  local file=$1 spec=$2 group key value
  local -a parts args
  while IFS=$'\t' read -r group key value; do
    [[ -n $group ]] || continue
    unescape "$value"
    value=$REPLY
    parts=()
    IFS='>' read -ra parts <<< "$group"
    args=(--file "$file")
    for part in "${parts[@]}"; do args+=(--group "$part"); done
    args+=(--key "$key" "$value")
    kwriteconfig6 "${args[@]}"
  done < "$spec"
}

apply_panel() {
  local target="$HOME/.config/plasma-org.kde.plasma.desktop-appletsrc"
  ensure_regular "$target"
  if [[ ! -s $target ]]; then
    cp "$KDE_DIR/panel-layout.conf" "$target"
    chmod 600 "$target"
    echo "installed panel/widget layout"
  fi
}

apply_shortcuts() {
  local target="$HOME/.config/kglobalshortcutsrc"
  ensure_regular "$target"
  write_spec "$target" "$KDE_DIR/shortcuts.conf"
  echo "applied global shortcuts"
}

screen_uuid() {
  local uuid
  uuid=$(kscreen-doctor -o 2>/dev/null | sed -E 's/\x1B\[[0-9;]*[mK]//g' | awk '/^Output:/ {print $4; exit}')
  if [[ -z $uuid ]]; then
    uuid=$(grep -oE '^\[Tiling\]\[[^]]+\]\[[^]]+\]' "$HOME/.config/kwinrc" 2>/dev/null \
      | head -1 | sed -E 's/.*\]\[([^]]+)\]$/\1/' || true)
  fi
  printf '%s\n' "$uuid"
}

apply_tiling() {
  local target="$HOME/.config/kwinrc" spec="$KDE_DIR/kwin-tiling.conf"
  local count i uuid screen group key value part
  local -A desktop=()
  count=$(kreadconfig6 --file kwinrc --group Desktops --key Number 2>/dev/null || true)
  [[ $count =~ ^[0-9]+$ ]] || count=0
  for ((i = 1; i <= count; i++)); do
    uuid=$(kreadconfig6 --file kwinrc --group Desktops --key "Id_$i" 2>/dev/null || true)
    [[ -n $uuid ]] && desktop[$i]=$uuid
  done
  screen=$(screen_uuid)
  [[ -n $screen ]] || { echo "could not determine screen UUID, skipped tiling" >&2; return 0; }
  while IFS=$'\t' read -r group key value; do
    [[ -n $group ]] || continue
    for i in "${!desktop[@]}"; do group=${group//@DESKTOP$i@/${desktop[$i]}}; done
    group=${group//@SCREEN@/$screen}
    [[ $group == *@* ]] && continue
    unescape "$value"
    value=$REPLY
    local -a parts args
    IFS='>' read -ra parts <<< "$group"
    args=(--file "$target")
    for part in "${parts[@]}"; do args+=(--group "$part"); done
    args+=(--key "$key" "$value")
    kwriteconfig6 "${args[@]}"
  done < "$spec"
  echo "applied Krohnkite tiling layouts"
}

apply_kwin() {
  local target="$HOME/.config/kwinrc"
  ensure_regular "$target"
  write_spec "$target" "$KDE_DIR/kwin.conf"
  apply_tiling
}

apply_launcher() {
  local target="$HOME/.config/kactivitymanagerd-statsrc"
  local spec="$KDE_DIR/launcher.conf" fav_group group key value part
  local -a parts args
  ensure_regular "$target"
  fav_group=$(grep -oE '^\[Favorites-org\.kde\.plasma\.kickoff\.favorites\.instance-[^]]*-global\]' "$target" 2>/dev/null \
    | head -1 | tr -d '[]' || true)
  [[ -n $fav_group ]] || fav_group='Favorites-org.kde.plasma.kickoff.favorites.instance-3-global'
  while IFS=$'\t' read -r group key value; do
    [[ -n $group ]] || continue
    group=${group//@FAVORITES_GROUP@/$fav_group}
    unescape "$value"
    value=$REPLY
    parts=()
    IFS='>' read -ra parts <<< "$group"
    args=(--file "$target")
    for part in "${parts[@]}"; do args+=(--group "$part"); done
    args+=(--key "$key" "$value")
    kwriteconfig6 "${args[@]}"
  done < "$spec"
  echo "applied launcher favorites"
}

apply_theme() {
  local target="$HOME/.config/kdeglobals"
  ensure_regular "$target"
  write_spec "$target" "$KDE_DIR/theme.conf"
  echo "applied theme and fonts"
}

apply_config() {
  local f
  for f in kactivitymanagerdrc plasmashellrc kscreenlockerrc; do
    ensure_regular "$HOME/.config/$f"
  done
  apply_panel
  apply_shortcuts
  apply_kwin
  apply_launcher
  apply_theme
  echo "KDE config applied. Log out and back in for shortcuts and KWin to reload."
}

if [[ $CONFIG_ONLY -eq 0 ]]; then
  for c in git make 7z kpackagetool6; do
    command -v "$c" >/dev/null || { echo "$c is required." >&2; exit 1; }
  done
  if ! command -v npm >/dev/null; then
    export PATH="$HOME/.local/share/fnm:$PATH"
    eval "$(fnm env --shell bash)"
    fnm install --lts && fnm use --lts
  fi

  KROHNKITE_VER=0.9.9.2
  KROHNKITE_META="$HOME/.local/share/kwin/scripts/krohnkite/metadata.json"
  installed=$(sed -n 's/.*"Version": "\([^"]*\)".*/\1/p' "$KROHNKITE_META" 2>/dev/null || true)
  if [[ $installed != "$KROHNKITE_VER" ]]; then
    echo "==> Krohnkite $KROHNKITE_VER (build from source)"
    tmp=$(mktemp -d); trap 'rm -rf "$tmp"' EXIT
    git clone -q --depth 1 --branch "$KROHNKITE_VER" \
      https://github.com/anametologin/krohnkite "$tmp/krohnkite"
    ( cd "$tmp/krohnkite" && make install >/dev/null )
    rm -rf "$tmp"; trap - EXIT
  else
    echo "==> Krohnkite $KROHNKITE_VER already installed"
  fi
  kwriteconfig6 --file kwinrc --group Plugins --key krohnkiteEnabled true

  NOKARA_REV=bf0d003b856bfdb8b43d6767488e794bfbb03c2d
  NOKARA_DIR="$HOME/.local/share/plasma/plasmoids/com.n3thshan.nokara"
  if [[ -d $NOKARA_DIR ]]; then
    echo "==> nokara already installed"
  else
    echo "==> nokara ($NOKARA_REV)"
    mkdir -p "$(dirname "$NOKARA_DIR")"
    git clone -q https://github.com/n3thshan/nokara "$NOKARA_DIR"
    git -C "$NOKARA_DIR" checkout -q "$NOKARA_REV"
  fi
fi

echo "==> KDE config (panel, shortcuts, kwin, launcher, theme)"
apply_config

echo "Done. Re-login to load the KWin script, shortcuts and widget layout."
