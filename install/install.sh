#!/usr/bin/env bash
# NARAYA Agents - macOS / Linux installer
# Installs NARAYA agents + skills to Claude Code, OpenCode, and/or Factory Droid.
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/sirkeldigital/naraya-agents/main/install/install.sh | bash
#
# Non-interactive:
#   NARAYA_PLATFORM=claude-code curl -fsSL <url> | bash       # platform: claude-code|opencode|droid|all
#   NARAYA_COMPONENTS=agents,skills curl -fsSL <url> | bash   # what to install (default: all)
#   NARAYA_BRANCH=main                                        # repo branch (default: main)

set -euo pipefail

REPO_URL="${NARAYA_REPO_URL:-https://github.com/sirkeldigital/naraya-agents}"
BRANCH="${NARAYA_BRANCH:-main}"
PLATFORM="${NARAYA_PLATFORM:-}"
COMPONENTS="${NARAYA_COMPONENTS:-all}"

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

# === Interactive platform selection ===
if [ -z "$PLATFORM" ]; then
  printf "\n${C_MAG}NARAYA Agents Installer${C_OFF}\n"
  printf "${C_MAG}========================${C_OFF}\n\n"
  echo "Detected installed AI CLIs:"
  command -v claude   >/dev/null 2>&1 && echo "  - Claude Code"
  command -v opencode >/dev/null 2>&1 && echo "  - OpenCode"
  command -v droid    >/dev/null 2>&1 && echo "  - Factory Droid"
  echo
  echo "Which platform to install for?"
  echo "  [1] Claude Code   -> ~/.claude/"
  echo "  [2] OpenCode      -> ~/.config/opencode/"
  echo "  [3] Factory Droid -> ~/.factory/"
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

# === Components ===
case ",$COMPONENTS," in
  *,agents,*|*,skills,*|*,all,*) ;;
  *) err "Invalid NARAYA_COMPONENTS: $COMPONENTS (use agents, skills, or all)"; exit 1 ;;
esac
INSTALL_AGENTS=0; INSTALL_SKILLS=0
case ",$COMPONENTS," in
  *,all,*|*,agents,*) INSTALL_AGENTS=1 ;;
esac
case ",$COMPONENTS," in
  *,all,*|*,skills,*) INSTALL_SKILLS=1 ;;
esac

# === Targets ===
HOME_DIR="${HOME:-$(eval echo ~$USER)}"

agent_target() {
  case "$1" in
    "claude-code") echo "$HOME_DIR/.claude/agents" ;;
    "opencode")    echo "$HOME_DIR/.config/opencode/agents" ;;
    "droid")       echo "$HOME_DIR/.factory/droids" ;;
  esac
}

skill_target() {
  case "$1" in
    "claude-code") echo "$HOME_DIR/.claude/skills" ;;
    "opencode")    echo "$HOME_DIR/.config/opencode/skills" ;;
    "droid")       echo "$HOME_DIR/.factory/skills" ;;
  esac
}

agent_source() {
  case "$1" in
    "claude-code") echo "$EXTRACTED/platforms/claude-code/agents" ;;
    "opencode")    echo "$EXTRACTED/platforms/opencode/agents" ;;
    "droid")       echo "$EXTRACTED/platforms/droid/droids" ;;
  esac
}

if [ "$PLATFORM" = "all" ]; then
  PLATFORMS=("claude-code" "opencode" "droid")
else
  PLATFORMS=("$PLATFORM")
fi

for p in "${PLATFORMS[@]}"; do
  case "$p" in
    "claude-code"|"opencode"|"droid") ;;
    *) err "Unknown platform: $p (valid: claude-code, opencode, droid, all)"; exit 1 ;;
  esac
done

# === Download ===
TMP_DIR=$(mktemp -d -t naraya-agents-XXXXXX)
trap 'rm -rf "$TMP_DIR"' EXIT
TARBALL_URL="$REPO_URL/archive/refs/heads/$BRANCH.tar.gz"
info "Downloading from $TARBALL_URL"
if ! curl -fsSL "$TARBALL_URL" -o "$TMP_DIR/repo.tar.gz"; then
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

SKILLS_SOURCE="$EXTRACTED/skills"

# === Install helper functions ===

# Install flat .md files (agents)
install_flat_files() {
  local src="$1" dst="$2" label="$3"
  if [ ! -d "$src" ]; then
    warn "Source not found ($src) - skipping $label"
    return
  fi
  mkdir -p "$dst"
  local installed=0 unchanged=0 updated=0
  for f in "$src"/*.md; do
    [ -e "$f" ] || continue
    local name target
    name=$(basename "$f")
    target="$dst/$name"
    if [ -f "$target" ]; then
      if cmp -s "$f" "$target"; then
        unchanged=$((unchanged+1))
        continue
      fi
      cp "$target" "$target.bak"
      updated=$((updated+1))
    else
      installed=$((installed+1))
    fi
    cp "$f" "$target"
  done
  printf "${C_OK}[OK]    ${C_OFF} %-13s : %d new, %d updated, %d unchanged\n" "$label" "$installed" "$updated" "$unchanged"
}

# Install skill folders (recursive)
install_skill_folders() {
  local src_root="$1" dst_root="$2" label="$3"
  if [ ! -d "$src_root" ]; then
    warn "Skills source not found ($src_root) - skipping $label"
    return
  fi
  mkdir -p "$dst_root"
  local installed=0 unchanged=0 updated=0
  for skill_dir in "$src_root"/*/; do
    [ -e "$skill_dir" ] || continue
    local skill_name dst_skill
    skill_name=$(basename "$skill_dir")
    dst_skill="$dst_root/$skill_name"

    # Compute manifest for both sides
    local src_manifest dst_manifest
    src_manifest=$(cd "$skill_dir" && find . -type f -exec sha256sum {} \; 2>/dev/null | sort | awk '{print $1}' | tr '\n' '|' || echo "")

    if [ -d "$dst_skill" ]; then
      dst_manifest=$(cd "$dst_skill" && find . -type f -exec sha256sum {} \; 2>/dev/null | sort | awk '{print $1}' | tr '\n' '|' || echo "")
      if [ "$src_manifest" = "$dst_manifest" ]; then
        unchanged=$((unchanged+1))
        continue
      fi
      # Backup SKILL.md if present
      [ -f "$dst_skill/SKILL.md" ] && cp "$dst_skill/SKILL.md" "$dst_skill/SKILL.md.bak"
      rm -rf "$dst_skill"
      updated=$((updated+1))
    else
      installed=$((installed+1))
    fi
    cp -R "$skill_dir" "$dst_skill"
  done
  printf "${C_OK}[OK]    ${C_OFF} %-13s : %d new, %d updated, %d unchanged\n" "$label" "$installed" "$updated" "$unchanged"
}

# Fallback if sha256sum doesn't exist (macOS has shasum)
if ! command -v sha256sum >/dev/null 2>&1; then
  if command -v shasum >/dev/null 2>&1; then
    sha256sum() { shasum -a 256 "$@"; }
  fi
fi

# === Install ===
echo
info "Installing components: $COMPONENTS"
echo

for p in "${PLATFORMS[@]}"; do
  printf "${C_MAG}=== %s ===${C_OFF}\n" "$p"
  if [ "$INSTALL_AGENTS" = "1" ]; then
    install_flat_files "$(agent_source "$p")" "$(agent_target "$p")" "$p agents"
  fi
  if [ "$INSTALL_SKILLS" = "1" ]; then
    install_skill_folders "$SKILLS_SOURCE" "$(skill_target "$p")" "$p skills"
  fi
  echo
done

ok "Installation complete."
echo
echo "Next steps:"
for p in "${PLATFORMS[@]}"; do
  case "$p" in
    "claude-code")
      echo "  Claude Code:"
      echo "    1. Restart Claude Code"
      echo "    2. Run /agents - verify naraya-worker is listed"
      echo "    3. Try /handoff to test the manual handoff skill"
      ;;
    "opencode")
      echo "  OpenCode:"
      echo "    1. Restart OpenCode"
      echo "    2. @naraya-worker to invoke, or check the agent list"
      ;;
    "droid")
      echo "  Factory Droid:"
      echo "    1. Restart Droid"
      echo "    2. Run /droids - verify NARAYA droids appear"
      ;;
  esac
done
echo
