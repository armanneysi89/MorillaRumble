#!/usr/bin/env bash
# Verpackt die Exporte aus builds/<plattform>/ nach builds/release/ und erzeugt SHA256SUMS.txt.
# Aufruf: tools/package_release.sh [version]

set -euo pipefail

ROOT="${ROOT:-$(cd "$(dirname "$0")/.." && pwd)}"
V="${1:-1.0}"
B="$ROOT/builds"
R="$B/release"

mkdir -p "$R"
find "$R" -maxdepth 1 -type f \( -name 'MorillaRumble-*' -o -name SHA256SUMS.txt \) -delete

pack() {
    local dir="$1" name="$2"
    shift 2
    (cd "$B/$dir" && zip -q -9 "$R/MorillaRumble-$V-$name.zip" $@)
}

pack linux linux-x86_64 MorillaRumble.x86_64
pack linux-arm64 linux-arm64 MorillaRumble.arm64
pack windows windows-x86_64 MorillaRumble.exe
pack windows-arm64 windows-arm64 MorillaRumble.exe
pack web web index.*
cp "$B/macos/MorillaRumble.zip" "$R/MorillaRumble-$V-macos.zip"
cp "$B/android/MorillaRumble.apk" "$R/MorillaRumble-$V-android-debug.apk"

(cd "$R" && sha256sum MorillaRumble-* > SHA256SUMS.txt)
ls -la "$R"
