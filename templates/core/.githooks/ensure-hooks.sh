#!/bin/sh
# Automatically configure git hooks if not already set up

set -e

REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || echo ".")"
CURRENT_HOOKS_PATH="$(git config --get core.hooksPath 2>/dev/null || echo "")"
EXPECTED_HOOKS_PATH=".githooks"

if [ "$CURRENT_HOOKS_PATH" = "$EXPECTED_HOOKS_PATH" ]; then
    exit 0
fi

echo "Configuring git hooks..."
cd "$REPO_ROOT"
git config core.hooksPath .githooks

echo "Git hooks configured successfully."
