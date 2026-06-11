#!/usr/bin/env bash
set -euo pipefail

REPO_URL="https://github.com/liuyuqing803/wiki-skill.git"
SKILLS_DIR="${AGENTS_SKILLS_DIR:-$HOME/.agents/skills}"
INSTALL_DIR="$SKILLS_DIR/wiki"

mkdir -p "$SKILLS_DIR"

if [ -d "$INSTALL_DIR/.git" ]; then
  git -C "$INSTALL_DIR" pull --ff-only
elif [ -e "$INSTALL_DIR" ]; then
  echo "Error: $INSTALL_DIR already exists and is not a git checkout." >&2
  echo "Move it away or set AGENTS_SKILLS_DIR to another skills directory, then retry." >&2
  exit 1
else
  git clone "$REPO_URL" "$INSTALL_DIR"
fi

if [ ! -f "$INSTALL_DIR/SKILL.md" ]; then
  echo "Error: installed directory does not contain SKILL.md: $INSTALL_DIR" >&2
  exit 1
fi

echo "Installed wiki skill to $INSTALL_DIR"
echo "Restart your agent or start a new session if skills are loaded at startup."
