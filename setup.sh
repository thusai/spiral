

#!/usr/bin/env bash
# Homebrew-style setup script for Spiral CLI

SCRIPT_NAME="spiral"
TARGET_PATH="/usr/local/bin/$SCRIPT_NAME"
SOURCE_PATH="$(pwd)/spiral.sh"

echo "🔗 Linking $SOURCE_PATH to $TARGET_PATH..."
sudo ln -sf "$SOURCE_PATH" "$TARGET_PATH"

if [ $? -eq 0 ]; then
    echo "✅ Spiral installed at $TARGET_PATH"
else
    echo "❌ Failed to install Spiral"
    exit 1
fi