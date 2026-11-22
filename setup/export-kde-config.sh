#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
KDE_DIR="$REPO_DIR/setup/kde"
HOME_DIR="$HOME"

for c in kreadconfig6 kwriteconfig6; do
  command -v "$c" >/dev/null || { echo "$c is required." >&2; exit 1; }
done

export_panel() {
  awk '
    /^\[Containments\]\[[^]]+\]\[Wallpaper\]/ { skip = 1; next }
    /^\[ScreenMapping\]/ { skip = 1; next }
    /^\[/ { skip = 0 }
    skip { next }
    /^(ItemGeometries|activityId=|lastScreen=|Image=|SlidePaths=|PreviewImage=)/ { next }
    { print }
  ' "$HOME_DIR/.config/plasma-org.kde.plasma.desktop-appletsrc" > "$KDE_DIR/panel-layout.conf"
  sed -i '${/^$/d;}' "$KDE_DIR/panel-layout.conf"
  echo "exported panel/widget layout"
}

export_shortcuts() {
  awk -F= '
    BEGIN { OFS = "\t" }
    /^\[/ { g = $0; gsub(/^\[|\]$/, "", g); next }
    {
      p = index($0, "=")
      if (!p) next
      k = substr($0, 1, p - 1)
      v = substr($0, p + 1)
      n = split(v, a, ",")
      if (n >= 2 && a[1] != a[2]) print g, k, v
    }
  ' "$HOME_DIR/.config/kglobalshortcutsrc" > "$KDE_DIR/shortcuts.conf"
  echo "exported custom global shortcuts"
}

read_key() {
  local file=$1 group=$2 key=$3 part
  local -a parts args
  parts=()
  IFS='>' read -ra parts <<< "$group"
  args=(--file "$file")
  for part in "${parts[@]}"; do args+=(--group "$part"); done
  kreadconfig6 "${args[@]}" --key "$key"
}

export_keys() {
  local file=$1 spec=$2 tmp
  tmp=$(mktemp)
  while IFS=$'\t' read -r group key value; do
    [[ -n $group ]] || continue
    current=$(read_key "$file" "$group" "$key")
    [[ -n $current ]] || current='@EMPTY@'
    printf '%s\t%s\t%s\n' "$group" "$key" "$current"
  done < "$spec" > "$tmp"
  mv "$tmp" "$spec"
}

screen_uuid() {
  local uuid
  uuid=$(kscreen-doctor -o 2>/dev/null | sed -E 's/\x1B\[[0-9;]*[mK]//g' | awk '/^Output:/ {print $4; exit}')
  if [[ -z $uuid ]]; then
    uuid=$(grep -oE '^\[Tiling\]\[[^]]+\]\[[^]]+\]' "$HOME_DIR/.config/kwinrc" 2>/dev/null \
      | head -1 | sed -E 's/.*\]\[([^]]+)\]$/\1/' || true)
  fi
  printf '%s\n' "$uuid"
}

export_tiling() {
  local spec="$KDE_DIR/kwin-tiling.conf" tmp
  local count i desktop screen padding tiles
  tmp=$(mktemp)
  count=$(kreadconfig6 --file kwinrc --group Desktops --key Number 2>/dev/null || true)
  [[ $count =~ ^[0-9]+$ ]] || count=0
  screen=$(screen_uuid)
  [[ -n $screen ]] || { echo "could not determine screen UUID" >&2; return 0; }
  for ((i = 1; i <= count; i++)); do
    desktop=$(kreadconfig6 --file kwinrc --group Desktops --key "Id_$i" 2>/dev/null || true)
    [[ -n $desktop ]] || continue
    padding=$(kreadconfig6 --file kwinrc --group Tiling --group "$desktop" --group "$screen" --key padding 2>/dev/null || true)
    tiles=$(kreadconfig6 --file kwinrc --group Tiling --group "$desktop" --group "$screen" --key tiles 2>/dev/null || true)
    printf 'Tiling>@DESKTOP%s@>@SCREEN@\tpadding\t%s\n' "$i" "$padding" >> "$tmp"
    printf 'Tiling>@DESKTOP%s@>@SCREEN@\ttiles\t%s\n' "$i" "$tiles" >> "$tmp"
  done
  [[ -s $tmp ]] && mv "$tmp" "$spec"
  echo "exported Krohnkite tiling layouts"
}

export_launcher() {
  local target="$HOME_DIR/.config/kactivitymanagerd-statsrc" spec="$KDE_DIR/launcher.conf"
  local ordering
  ordering=$(awk '/^\[Favorites-org\.kde\.plasma\.kickoff\.favorites\.instance-.*-global\]/ { found = 1; next }
    found && /^\[/ { exit }
    found && /^ordering=/ { sub(/^ordering=/, ""); print; exit }' "$target")
  [[ -n $ordering ]] || { echo "launcher favorites not found" >&2; return 0; }
  printf '@FAVORITES_GROUP@\tordering\t%s\n' "$ordering" > "$spec"
  echo "exported launcher favorites"
}

export_panel
export_shortcuts
export_keys kwinrc "$KDE_DIR/kwin.conf"
export_tiling
export_launcher
export_keys kdeglobals "$KDE_DIR/theme.conf"

echo "Templates updated in $KDE_DIR"
