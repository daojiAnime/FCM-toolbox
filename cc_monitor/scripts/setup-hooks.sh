#!/bin/bash
# Setup script for git hooks
# 安装 git pre-commit hook

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GIT_ROOT="$(git rev-parse --show-toplevel)"
HOOKS_DIR="$GIT_ROOT/.git/hooks"

echo "Installing pre-commit hook..."

# 复制 pre-commit hook
cp "$SCRIPT_DIR/pre-commit" "$HOOKS_DIR/pre-commit"
chmod +x "$HOOKS_DIR/pre-commit"

echo "✅ Pre-commit hook installed successfully!"
echo ""
echo "The hook will automatically run:"
echo "  - dart format (check code formatting)"
echo "  - flutter analyze (lint check)"
echo ""
echo "To skip the hook temporarily, use: git commit --no-verify"
