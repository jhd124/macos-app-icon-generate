#!/usr/bin/env bash
set -euo pipefail

SKILL_NAME="macos-logo-series"
SKILL_REL_PATH=".cursor/skills/${SKILL_NAME}"
TARGET_ROOT="${HOME}/.cursor/skills"
TARGET_DIR="${TARGET_ROOT}/${SKILL_NAME}"

REPO=""
REF="main"
FORCE="false"

usage() {
  cat <<'EOF'
Install Cursor skill: macos-logo-series

Usage:
  # Local install (run inside cloned repo)
  bash install.sh

  # Remote install (without cloning repo first)
  bash install.sh --repo <owner/repo> [--ref <branch-or-tag>] [--force]

Options:
  --repo   GitHub repo, e.g. dp/macos-app-logo-generate
  --ref    Branch or tag (default: main)
  --force  Overwrite existing skill directory
  -h       Show help
EOF
}

require_cmd() {
  local cmd="$1"
  if ! command -v "$cmd" >/dev/null 2>&1; then
    echo "Error: missing required command: ${cmd}" >&2
    exit 1
  fi
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --repo)
      REPO="${2:-}"
      shift 2
      ;;
    --ref)
      REF="${2:-}"
      shift 2
      ;;
    --force)
      FORCE="true"
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

mkdir -p "${TARGET_ROOT}"

if [[ -d "${TARGET_DIR}" && "${FORCE}" != "true" ]]; then
  echo "Error: skill already exists at ${TARGET_DIR}" >&2
  echo "Tip: rerun with --force to overwrite." >&2
  exit 1
fi

if [[ "${FORCE}" == "true" && -d "${TARGET_DIR}" ]]; then
  rm -rf "${TARGET_DIR}"
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOCAL_SKILL_PATH="${SCRIPT_DIR}/${SKILL_REL_PATH}"

install_from_local() {
  cp -R "${LOCAL_SKILL_PATH}" "${TARGET_DIR}"
  echo "Installed from local repo: ${TARGET_DIR}"
}

install_from_github() {
  require_cmd curl
  require_cmd tar

  if [[ -z "${REPO}" ]]; then
    echo "Error: --repo is required for remote install." >&2
    echo "Example: bash install.sh --repo dp/macos-app-logo-generate --ref main" >&2
    exit 1
  fi

  local tmp_dir
  tmp_dir="$(mktemp -d)"
  trap 'rm -rf "${tmp_dir}"' EXIT

  local tarball_url
  tarball_url="https://codeload.github.com/${REPO}/tar.gz/refs/heads/${REF}"

  if ! curl -fsSL "${tarball_url}" -o "${tmp_dir}/repo.tar.gz"; then
    tarball_url="https://codeload.github.com/${REPO}/tar.gz/refs/tags/${REF}"
    curl -fsSL "${tarball_url}" -o "${tmp_dir}/repo.tar.gz"
  fi

  tar -xzf "${tmp_dir}/repo.tar.gz" -C "${tmp_dir}"

  local repo_root=""
  local candidate=""
  for candidate in "${tmp_dir}"/*; do
    if [[ -d "${candidate}" && -d "${candidate}/${SKILL_REL_PATH}" ]]; then
      repo_root="${candidate}"
      break
    fi
  done

  if [[ -z "${repo_root}" || ! -f "${repo_root}/${SKILL_REL_PATH}/SKILL.md" ]]; then
    echo "Error: could not find skill files in ${REPO}@${REF}" >&2
    exit 1
  fi

  cp -R "${repo_root}/${SKILL_REL_PATH}" "${TARGET_DIR}"
  echo "Installed from GitHub (${REPO}@${REF}): ${TARGET_DIR}"
}

if [[ -d "${LOCAL_SKILL_PATH}" ]]; then
  install_from_local
else
  install_from_github
fi

echo "Done. You can now use this skill in Cursor."
