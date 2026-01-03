#!/usr/bin/env bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Ambil daftar config yang sesuai pola
configs=(*.toml)

# Validasi keberadaan file
if [ ${#configs[@]} -eq 0 ]; then
  echo "Tidak ditemukan file config dengan pola starship*.toml"
  exit 1
fi

echo "Pilih konfigurasi Starship:"
for i in "${!configs[@]}"; do
  printf "%d) %s\n" "$((i+1))" "${configs[$i]}"
done

read -p "Masukkan nomor pilihan: " choice

# Validasi input numerik
if ! [[ "$choice" =~ ^[0-9]+$ ]] || [ "$choice" -lt 1 ] || [ "$choice" -gt "${#configs[@]}" ]; then
  echo "Pilihan tidak valid"
  exit 1
fi

selected="${configs[$((choice-1))]}"

# Salin config terpilih
cp "$selected" ../starship.toml

echo "Konfigurasi '$selected' berhasil diaktifkan sebagai starship.toml"

