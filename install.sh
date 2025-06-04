#!/usr/bin/env bash

# Spiral Installation Script
# This will make the spiral command available from anywhere

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SPIRAL_SCRIPT="$SCRIPT_DIR/spiral.sh"

# Check if spiral.sh exists
if [ ! -f "$SPIRAL_SCRIPT" ]; then
    echo "❌ spiral.sh not found in $SCRIPT_DIR"
    exit 1
fi

# Make sure spiral.sh is executable
chmod +x "$SPIRAL_SCRIPT"

# Try to find a good place to install the symlink
INSTALL_PATHS=("$HOME/.local/bin" "$HOME/bin" "/usr/local/bin")
INSTALL_DIR=""

for path in "${INSTALL_PATHS[@]}"; do
    if [ -d "$path" ] && [[ ":$PATH:" == *":$path:"* ]]; then
        # Test if we can write to this directory
        if [ -w "$path" ]; then
            INSTALL_DIR="$path"
            break
        fi
    fi
done

# If no writable directory found, try to create ~/.local/bin
if [ -z "$INSTALL_DIR" ]; then
    mkdir -p "$HOME/.local/bin"
    if [[ ":$PATH:" == *":$HOME/.local/bin:"* ]]; then
        INSTALL_DIR="$HOME/.local/bin"
    fi
fi

if [ -z "$INSTALL_DIR" ]; then
    echo "❌ Could not find a suitable directory in your PATH to install spiral."
    echo "Please add one of these directories to your PATH:"
    for path in "${INSTALL_PATHS[@]}"; do
        echo "  - $path"
    done
    echo ""
    echo "Or create a symlink manually:"
    echo "  ln -sf \"$SPIRAL_SCRIPT\" /path/to/directory/in/PATH/spiral"
    exit 1
fi

# Create the symlink
SYMLINK_PATH="$INSTALL_DIR/spiral"

if [ -L "$SYMLINK_PATH" ] || [ -f "$SYMLINK_PATH" ]; then
    echo "Removing existing spiral command at $SYMLINK_PATH"
    rm -f "$SYMLINK_PATH"
fi

echo "Installing spiral to $SYMLINK_PATH"
ln -sf "$SPIRAL_SCRIPT" "$SYMLINK_PATH"

if [ $? -eq 0 ]; then
    echo "✅ Spiral installed successfully!"
    echo ""
    echo "You can now use 'spiral' from anywhere. Try:"
    echo "  spiral --help"
    echo "  spiral use path/to/your/roadmap.yml"
    echo ""
    echo "To uninstall, simply run:"
    echo "  rm $SYMLINK_PATH"
else
    echo "❌ Failed to create symlink. You may need to run with sudo:"
    echo "  sudo $0"
fi 