
#!/usr/bin/env bash

set -uo pipefail

ROOT="${ROOT:-$(cd "$(dirname "$0")/.." && pwd)}"
GODOT="${GODOT:-$HOME/tools/Godot_v4.7.2-stable_linux.x86_64}"
BUILD="$ROOT/builds"

mkdir -p "$BUILD"
touch "$BUILD/.gdignore"

# Der Godot-Editor setzt den Java-Pfad gern zurück; ohne ihn scheitert der Android-Export.
SETTINGS="${XDG_CONFIG_HOME:-$HOME/.config}/godot/editor_settings-4.7.tres"
if [[ -f "$SETTINGS" ]]; then
    sed -i "s|^export/android/java_sdk_path = \"\"|export/android/java_sdk_path = \"${JAVA_HOME:-/usr/lib/jvm/java-17-openjdk-amd64}\"|" "$SETTINGS"
fi

if [[ ! -x "$GODOT" ]]; then
    echo "ERROR: Godot executable not found: $GODOT"
    exit 1
fi

cd "$ROOT"

FAILED=()
SUCCESS=()

build() {
    local preset="$1"
    local output="$2"
    local mode="${3:---export-release}"

    echo ""
    echo "======================================"
    echo "Building: $preset"
    echo "Output:   $output"
    echo "======================================"

    mkdir -p "$(dirname "$output")"

    if "$GODOT" --headless --path "$ROOT" \
        "$mode" "$preset" "$output"; then

        SUCCESS+=("$preset")
        echo "SUCCESS: $preset"
    else
        FAILED+=("$preset")
        echo "FAILED: $preset"
    fi
}

# Linux
build "Linux" "$BUILD/linux/MorillaRumble.x86_64"

# Linux ARM64
build "Linux ARM64" "$BUILD/linux-arm64/MorillaRumble.arm64"

# Windows
build "Windows" "$BUILD/windows/MorillaRumble.exe"

# Windows ARM64
build "Windows ARM64" "$BUILD/windows-arm64/MorillaRumble.exe"

# macOS
build "macOS" "$BUILD/macos/MorillaRumble.zip"

# Web
build "Web" "$BUILD/web/index.html"

# Android (kein Release-Keystore konfiguriert, daher Debug-Signatur)
build "Android" "$BUILD/android/MorillaRumble.apk" --export-debug

echo ""
echo "======================================"
echo "          RELEASE SUMMARY"
echo "======================================"

echo "Successful: ${#SUCCESS[@]}"
for item in "${SUCCESS[@]}"; do
    echo "  OK: $item"
done

echo ""
echo "Failed: ${#FAILED[@]}"
for item in "${FAILED[@]}"; do
    echo "  ERROR: $item"
done

echo ""
echo "Build directory: $BUILD"

if (( ${#FAILED[@]} > 0 )); then
    exit 1
fi

echo "ALL BUILDS SUCCESSFUL"
