# macOS Logo Series Skill

Generate a full macOS app icon set from one input image, including:

- `.iconset` PNG files (standard macOS sizes)
- `-square` PNG series (`16/32/64/128/256/512/1024`)
- `-store` PNG series (`1024/2048`)
- optional `.icns` packaging
- optional PNG optimization (`pngquant`/`zopflipng`/`optipng`)

## Repository Structure

- `.cursor/skills/macos-logo-series/SKILL.md`
- `.cursor/skills/macos-logo-series/scripts/generate_macos_logo.sh`
- `install.sh`

## Install

### Option 1: Local install (after clone)

```bash
git clone https://github.com/jhd124/macos-app-icon-generate.git
cd macos-app-icon-generate
bash install.sh
```

### Option 2: One-line GitHub install

```bash
curl -fsSL https://raw.githubusercontent.com/jhd124/macos-app-icon-generate/main/install.sh | bash -s -- --repo jhd124/macos-app-icon-generate --ref main
```

If already installed, overwrite with:

```bash
curl -fsSL https://raw.githubusercontent.com/jhd124/macos-app-icon-generate/main/install.sh | bash -s -- --repo jhd124/macos-app-icon-generate --ref main --force
```

## Use in Cursor

After installation, call the skill by name in chat:

```text
/macos-logo-series
```

The underlying generator command is:

```bash
bash .cursor/skills/macos-logo-series/scripts/generate_macos_logo.sh -i "<input_image>" -o "<output_dir>" -n "<app_name>"
```

### Common options

- PNG-only output:

```bash
bash .cursor/skills/macos-logo-series/scripts/generate_macos_logo.sh -i "<input_image>" -o "<output_dir>" -n "<app_name>" --png-only
```

- Disable optimization:

```bash
bash .cursor/skills/macos-logo-series/scripts/generate_macos_logo.sh -i "<input_image>" -o "<output_dir>" -n "<app_name>" --no-optimize
```

## Optional Dependency (recommended)

Install `pngquant` for better PNG compression:

```bash
brew install pngquant
```

## Uninstall

```bash
rm -rf ~/.cursor/skills/macos-logo-series
```

