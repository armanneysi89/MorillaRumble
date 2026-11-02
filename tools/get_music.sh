#!/usr/bin/env bash
# Lädt die Hintergrundmusik (CC0, OpenGameArt) und legt sie als OGG unter assets/audio/music/ ab.
# Aufruf: tools/get_music.sh

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUT="$ROOT/assets/audio/music"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

mkdir -p "$OUT"

# name | Quelle | Lizenz
fetch() {
    local name="$1" url="$2"
    echo "-> $name"
    curl -sL -A "Mozilla/5.0" "$url" -o "$TMP/$name.src"
    ffmpeg -y -loglevel error -i "$TMP/$name.src" -c:a libvorbis -q:a 5 -af "loudnorm=I=-18:TP=-1.5:LRA=11" "$OUT/$name.ogg"
}

# "Japanese Lofi HipHop Track" von pickentcode, CC0
fetch dojo "https://opengameart.org/sites/default/files/gods_notebook_-_main_theme.mp3"
# "Funky Hip Hop Lofi Jam" von Centurion_7, CC0
fetch menu "https://opengameart.org/sites/default/files/CVP701Jam_0.ogg"

ls -la "$OUT"
