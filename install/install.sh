#!/usr/bin/env bash
# NARAYA Agents - macOS / Linux installer
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/<owner>/naraya-agents/main/install/install.sh | bash
#
# Or with platform env:
#   NARAYA_PLATFORM=claude-code curl -fsSL <url> | bash
#
# Supported platforms: claude-code, opencode, droid, all

set -euo pipefail

REPO_URL="${NARAYA_REPO_URL:-https://github.com/sirkeldigital/naraya-agents}"
BRANCH="${NARAYA_BRANCH:-main}"
PLATFORM="${NARAYA_PLATFORM:-}"

# Colors
if [ -t 1 ]; then
  C_INFO='\033[36m'; C_OK='\033[32m'; C_WARN='\033[33m'; C_ERR='\033[31m'; C_OFF='\033[0m'; C_MAG='\033[35m'
else
  C_INFO=''; C_OK=''; C_WARN=''; C_ERR=''; C_OFF=''; C_MAG=''
fi

info() { printf "${C_INFO}[NARAYA]${C_OFF} %s\n" "$*"; }
ok()   { printf "${C_OK}[OK]    ${C_OFF} %s\n" "$*"; }
warn() { printf "${C_WARN}[WARN]  ${C_OFF} %s\n" "$*"; }
err()  { printf "${C_ERR}[ERROR] ${C_OFF} %s\n" "$*" 1>&2; }

# Platform selection
if [ -z "$PLATFORM" ]; then
  printf "\n${C_MAG}NARAYA Agents Installer${C_OFF}\n"
  printf "${C_MAG}========================${C_OFF}\n\n"
  echo "Detected installed AI CLIs:"
  command -v claude   >/dev/null 2>&1 && echo "  - Claude Code"
  command -v opencode >/dev/null 2>&1 && echo "  - OpenCode"
  command -v droid    >/dev/null 2>&1 && echo "  - Factory Droid"
  echo
  echo "Which platform to install for?"
  echo "  [1] Claude Code   -> ~/.claude/agents/"
  echo "  [2] OpenCode      -> ~/.config/opencode/agents/"
  echo "  [3] Factory Droid -> ~/.factory/droids/"
  echo "  [4] All"
  echo
  printf "Choice (1-4): "
  read -r choice </dev/tty
  case "$choice" in
    1) PLATFORM="claude-code" ;;
    2) PLATFORM="opencode" ;;
    3) PLATFORM="droid" ;;
    4) PLATFORM="all" ;;
    *) err "Invalid choice"; exit 1 ;;
  esac
fi

# Targets
HOME_DIR="${HOME:-$(eval echo ~$USER)}"
declare -A TARGETS
TARGETS["claude-code"]="$HOME_DIR/.claude/agents"
TARGETS["opencode"]="$HOME_DIR/.config/opencode/agents"
TARGETS["droid"]="$HOME_DIR/.factory/droids"

if [ "$PLATFORM" = "all" ]; then
  PLATFORMS=("claude-code" "opencode" "droid")
else
  PLATFORMS=("$PLATFORM")
fi

for p in "${PLATFORMS[@]}"; do
  if [ -z "${TARGETS[$p]:-}" ]; then
    err "Unknown platform: $p (valid: claude-code, opencode, droid, all)"
    exit 1
  fi
done

# Download
TMP_DIR=$(mktemp -d -t naraya-agents-XXXXXX)
trap 'rm -rf "$TMP_DIR"' EXIT
ZIP_URL="$REPO_URL/archive/refs/heads/$BRANCH.tar.gz"
info "Downloading from $ZIP_URL"
if ! curl -fsSL "$ZIP_URL" -o "$TMP_DIR/repo.tar.gz"; then
  err "Failed to download. Check the repo URL and branch."
  exit 1
fi

info "Extracting..."
tar -xzf "$TMP_DIR/repo.tar.gz" -C "$TMP_DIR"
EXTRACTED=$(find "$TMP_DIR" -maxdepth 1 -type d -name "naraya-agents-*" | head -n1)
if [ -z "$EXTRACTED" ]; then
  err "Could not find extracted repo root"
  exit 1
fi

# Source dirs
declare -A SOURCE_DIRS
SOURCE_DIRS["claude-code"]="$EXTRACTED/platforms/claude-code/agents"
SOURCE_DIRS["opencode"]="$EXTRACTED/platforms/opencode/agents"
SOURCE_DIRS["droid"]="$EXTRACTED/platforms/droid/droids"

# Install
for p in "${PLATFORMS[@]}"; do
  src="${SOURCE_DIRS[$p]}"
  dst="${TARGETS[$p]}"

  if [ ! -d "$src" ]; then
    warn "Source not found for $p ($src) - skipping"
    continue
  fi

  mkdir -p "$dst"
  info "Installing $p -> $dst"

  count=0
  skipped=0
  for f in "$src"/*.md; do
    [ -e "$f" ] || continue
    name=$(basename "$f")
    target="$dst/$name"
    if [ -f "$target" ]; then
      if cmp -s "$f" "$target"; then
        skipped=$((skipped+1))
        continue
      fi
      cp "$target" "$target.bak"
    fi
    cp "$f" "$target"
    count=$((count+1))
  done
  ok "$p : $count files installed, $skipped unchanged"
done

echo
ok "Installation complete."
echo
echo "Next steps:"
for p in "${PLATFORMS[@]}"; do
  case "$p" in
    "claude-code") echo "  Claude Code: restart, then run '/agents' to verify naraya-worker appears" ;;
    "opencode")    echo "  OpenCode:    restart, then '@naraya-worker' or check 'agent' list" ;;
    "droid")       echo "  Droid:       restart, then '/droids' to verify" ;;
  esac
done
echo
