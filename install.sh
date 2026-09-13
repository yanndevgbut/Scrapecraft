#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET_DIR=""
PROJECT_MODE=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --project)
      PROJECT_MODE=true
      shift
      ;;
    --dir)
      TARGET_DIR="$2"
      shift 2
      ;;
    -h|--help)
      echo "ScrapeCraft Universal Installer"
      echo ""
      echo "Usage:"
      echo "  ./install.sh             Install globally for all agents (~/.claude, ~/.config/opencode, ~/.agents)"
      echo "  ./install.sh --project   Install into current project (.claude, .opencode, .agents)"
      echo "  ./install.sh --dir PATH  Install into a specific directory"
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      exit 1
      ;;
  esac
done

copy_skill() {
  local dest="$1"
  echo "==> Installing ScrapeCraft to: $dest"
  mkdir -p "$dest"
  cp -r "$SCRIPT_DIR/SKILL.md" "$dest/"
  cp -r "$SCRIPT_DIR/references" "$dest/"
  cp -r "$SCRIPT_DIR/scripts" "$dest/"
  if [ -d "$SCRIPT_DIR/assets" ]; then
    cp -r "$SCRIPT_DIR/assets" "$dest/"
  fi
  chmod +x "$dest/scripts/"*.sh 2>/dev/null || true
  echo "    Done."
}

if [ -n "$TARGET_DIR" ]; then
  copy_skill "$TARGET_DIR"
  echo ""
  echo "Installation complete!"
  exit 0
fi

if [ "$PROJECT_MODE" = true ]; then
  echo "Installing ScrapeCraft into current project..."
  copy_skill ".claude/skills/scrapecraft"
  copy_skill ".opencode/skills/scrapecraft"
  copy_skill ".agents/skills/scrapecraft"
  echo ""
  echo "Project installation complete."
  exit 0
fi

echo "Installing ScrapeCraft globally..."
copy_skill "$HOME/.claude/skills/scrapecraft"
copy_skill "$HOME/.config/opencode/skills/scrapecraft"
copy_skill "$HOME/.agents/skills/scrapecraft"

echo ""
echo "ScrapeCraft successfully installed globally."
echo "Claude Code, OpenCode, and standard agent runtimes will now auto-discover ScrapeCraft."
