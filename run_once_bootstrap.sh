#!/bin/bash

# This script runs only when it hasn't been run before (tracked by chezmoi state)

echo "Running one-time bootstrap setup..."

# 1. Set Fish as default shell
current_shell=$(basename "$SHELL")
if [ "$current_shell" != "fish" ]; then
    if command -v fish &> /dev/null; then
        echo "Changing default shell to fish..."
        chsh -s "$(which fish)"
    else
        echo "Fish not found, skipping shell change."
    fi
fi

# 2. Set System-wide Dark Mode (for GTK4/Libadwaita)
if command -v gsettings &> /dev/null; then
    echo "Setting system-wide dark mode..."
    gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'
    gsettings set org.gnome.desktop.interface gtk-theme 'cachyos-nord'
fi

# 3. Enable standard services (idempotent, safe to run multiple times)
# Check if systemd is active
if pidof systemd &> /dev/null; then
    echo "Enabling common services..."
    sudo systemctl enable --now bluetooth.service 2>/dev/null || true
    # fstrim is good for SSDs
    sudo systemctl enable --now fstrim.timer 2>/dev/null || true
fi

# 4. Install Mise tools
if command -v mise &> /dev/null; then
    echo "Installing global mise tools..."
    mise install -y
fi

echo "Bootstrap complete!"
