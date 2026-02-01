#!/bin/sh
# Automatically configure git hooks if not already set up
# This script is called by Makefile targets to ensure hooks are always active

set -e

REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || echo ".")"
CURRENT_HOOKS_PATH="$(git config --get core.hooksPath 2>/dev/null || echo "")"
EXPECTED_HOOKS_PATH=".githooks"

# Check if hooks are already configured correctly
if [ "$CURRENT_HOOKS_PATH" = "$EXPECTED_HOOKS_PATH" ]; then
    # Hooks are already set up correctly
    exit 0
fi

# Hooks are not configured - set them up
echo "Configuring git hooks to use .githooks directory..."
cd "$REPO_ROOT"
git config core.hooksPath .githooks

echo "Git hooks configured successfully."
echo "Pre-commit and pre-push hooks are now active."
echo ""
