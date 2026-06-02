#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Generate macOS icon assets from one image.

Usage:
  bash generate_macos_logo.sh -i <input_image> [-o <output_dir>] [-n <app_name>] [--png-only] [--no-optimize]

Options:
  -i, --input       Source image path (required)
  -o, --output      Output directory (default: ./dist)
  -n, --name        App/icon base name (default: AppIcon)
      --png-only    Generate PNG sets only; skip .icns packaging
      --no-optimize Disable PNG optimization step after generation
  -h, --help        Show help
EOF
}

require_command() {
  local cmd="$1"
  if ! command -v "$cmd" >/dev/null 2>&1; then
    echo "Error: required command not found: $cmd" >&2
    exit 1
  fi
}

INPUT_IMAGE=""
OUTPUT_DIR="./dist"
APP_NAME="AppIcon"
PNG_ONLY="false"
OPTIMIZE="true"

while [[ $# -gt 0 ]]; do
  case "$1" in
    -i|--input)
      INPUT_IMAGE="${2:-}"
      shift 2
      ;;
    -o|--output)
      OUTPUT_DIR="${2:-}"
      shift 2
      ;;
    -n|--name)
      APP_NAME="${2:-}"
      shift 2
      ;;
    --png-only)
      PNG_ONLY="true"
      shift
      ;;
    --no-optimize)
      OPTIMIZE="false"
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Error: unknown argument: $1" >&2
      usage
      exit 1
      ;;
  esac
done

if [[ -z "$INPUT_IMAGE" ]]; then
  echo "Error: input image is required." >&2
  usage
  exit 1
fi

if [[ ! -f "$INPUT_IMAGE" ]]; then
  echo "Error: input image not found: $INPUT_IMAGE" >&2
  exit 1
fi

require_command sips
if [[ "$PNG_ONLY" != "true" ]]; then
  require_command iconutil
fi

mkdir -p "$OUTPUT_DIR"

ICONSET_DIR="$OUTPUT_DIR/$APP_NAME.iconset"
ICNS_FILE="$OUTPUT_DIR/$APP_NAME.icns"
SQUARE_DIR="$OUTPUT_DIR/$APP_NAME-square"
STORE_DIR="$OUTPUT_DIR/$APP_NAME-store"

rm -rf "$ICONSET_DIR"
rm -rf "$SQUARE_DIR"
rm -rf "$STORE_DIR"
mkdir -p "$ICONSET_DIR"
mkdir -p "$SQUARE_DIR"
mkdir -p "$STORE_DIR"

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

NORMALIZED_IMAGE="$TMP_DIR/normalized.png"

# Convert to PNG first so downstream resizing is consistent.
sips -s format png "$INPUT_IMAGE" --out "$NORMALIZED_IMAGE" >/dev/null

WIDTH="$(sips -g pixelWidth "$NORMALIZED_IMAGE" | awk '/pixelWidth:/ {print $2}')"
HEIGHT="$(sips -g pixelHeight "$NORMALIZED_IMAGE" | awk '/pixelHeight:/ {print $2}')"

if [[ "$WIDTH" != "$HEIGHT" ]]; then
  if [[ "$WIDTH" -gt "$HEIGHT" ]]; then
    SQUARE="$WIDTH"
  else
    SQUARE="$HEIGHT"
  fi
  # Preserve the full logo by padding the shorter side to a square canvas.
  sips --padToHeightWidth "$SQUARE" "$SQUARE" "$NORMALIZED_IMAGE" --out "$NORMALIZED_IMAGE" >/dev/null
fi

write_icon() {
  local size="$1"
  local filename="$2"
  sips -z "$size" "$size" "$NORMALIZED_IMAGE" --out "$ICONSET_DIR/$filename" >/dev/null
}

write_square() {
  local size="$1"
  sips -z "$size" "$size" "$NORMALIZED_IMAGE" --out "$SQUARE_DIR/square-${size}.png" >/dev/null
}

write_store() {
  local size="$1"
  sips -z "$size" "$size" "$NORMALIZED_IMAGE" --out "$STORE_DIR/store-${size}.png" >/dev/null
}

optimize_png_file() {
  local file="$1"
  if command -v pngquant >/dev/null 2>&1; then
    pngquant --force --output "$file" --speed 1 --quality 65-90 -- "$file" >/dev/null 2>&1 || true
    return 0
  fi
  if command -v zopflipng >/dev/null 2>&1; then
    zopflipng -y "$file" "$file" >/dev/null 2>&1 || true
    return 0
  fi
  if command -v optipng >/dev/null 2>&1; then
    optipng -quiet -o2 "$file" >/dev/null 2>&1 || true
    return 0
  fi
  return 1
}

# Standard macOS iconset files.
write_icon 16   "icon_16x16.png"
write_icon 32   "icon_16x16@2x.png"
write_icon 32   "icon_32x32.png"
write_icon 64   "icon_32x32@2x.png"
write_icon 128  "icon_128x128.png"
write_icon 256  "icon_128x128@2x.png"
write_icon 256  "icon_256x256.png"
write_icon 512  "icon_256x256@2x.png"
write_icon 512  "icon_512x512.png"
write_icon 1024 "icon_512x512@2x.png"

# Additional square series (generic distribution assets).
write_square 16
write_square 32
write_square 64
write_square 128
write_square 256
write_square 512
write_square 1024

# Store series (App Store and high-res marketing).
write_store 1024
write_store 2048

if [[ "$OPTIMIZE" == "true" ]]; then
  OPTIMIZER_FOUND="false"
  for target_dir in "$ICONSET_DIR" "$SQUARE_DIR" "$STORE_DIR"; do
    for png_file in "$target_dir"/*.png; do
      if optimize_png_file "$png_file"; then
        OPTIMIZER_FOUND="true"
      fi
    done
  done
  if [[ "$OPTIMIZER_FOUND" == "true" ]]; then
    echo "Done: optimized PNG files in iconset/square/store."
  else
    echo "Info: PNG optimization skipped (no optimizer found: pngquant/zopflipng/optipng)." >&2
    echo "Info: install one with Homebrew, e.g. brew install pngquant" >&2
  fi
fi

if [[ "$PNG_ONLY" == "true" ]]; then
  echo "Done: generated macOS iconset PNGs at: $ICONSET_DIR"
  echo "Done: generated square PNGs at: $SQUARE_DIR"
  echo "Done: generated store PNGs at: $STORE_DIR"
  exit 0
fi

iconutil -c icns "$ICONSET_DIR" -o "$ICNS_FILE"
echo "Done: generated macOS iconset at: $ICONSET_DIR"
echo "Done: generated macOS icns at: $ICNS_FILE"
echo "Done: generated square PNGs at: $SQUARE_DIR"
echo "Done: generated store PNGs at: $STORE_DIR"
