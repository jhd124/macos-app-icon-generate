---
name: macos-logo-series
description: Generate macOS app icon assets from one input image, including iconset PNG sizes and optional ICNS packaging. Use when the user asks to convert a logo/image into macOS icon files, app icons, iconset, or icns.
disable-model-invocation: true
---

# macOS Logo Series Generator

## What this skill does

Turns one user-provided image into a macOS icon asset set:
- `*.iconset` directory with standard macOS PNG sizes
- `*.icns` file (default)
- optional PNG-only output

## When to use

Use this skill when the user asks to:
- generate macOS app icons from a logo or image
- create an `iconset` or `icns`
- export multi-size icon PNGs for macOS

## Required input

- A source image path (`png`, `jpg`, `jpeg`, `webp`, `tiff`, etc.)

## Command

Run:

```bash
bash .cursor/skills/macos-logo-series/scripts/generate_macos_logo.sh -i "<input_image>" -o "<output_dir>" -n "<app_name>"
```

### PNG only mode

```bash
bash .cursor/skills/macos-logo-series/scripts/generate_macos_logo.sh -i "<input_image>" -o "<output_dir>" -n "<app_name>" --png-only
```

### Disable PNG optimization

```bash
bash .cursor/skills/macos-logo-series/scripts/generate_macos_logo.sh -i "<input_image>" -o "<output_dir>" -n "<app_name>" --no-optimize
```

## Output

Default mode:
- `<output_dir>/<app_name>.iconset/`
- `<output_dir>/<app_name>.icns`

PNG-only mode:
- `<output_dir>/<app_name>.iconset/`

## Notes

- Script uses macOS built-in `sips` and `iconutil`.
- If the source image is not square, the script pads it to square before resizing.
- For best visual quality, use a high-resolution transparent PNG (recommended >= 1024x1024).
- PNG optimization runs automatically when an optimizer is available (`pngquant` preferred, fallback to `zopflipng` or `optipng`).
- Optional install: `brew install pngquant` (recommended).
