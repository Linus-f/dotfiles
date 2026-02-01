#!/bin/bash

# This script runs only when it hasn't been run before (tracked by chezmoi state)

echo "Running one-time bootstrap setup..."

# --- 0. System Prep (Repos) ---

# Optimize CachyOS Mirrors
if command -v cachyos-rate-mirrors &> /dev/null; then
    echo "Optimizing CachyOS mirrors..."
    sudo cachyos-rate-mirrors
fi

# Ensure Cider Collective repository is present
if [ -f /etc/pacman.conf ] && ! grep -q "\[cidercollective\]" /etc/pacman.conf; then
    echo "Adding Cider Collective repository..."
    
    # Import and sign the GPG key
    echo "Importing Cider Collective GPG key..."
    curl -s https://repo.cider.sh/ARCH-GPG-KEY | sudo pacman-key --add -
    sudo pacman-key --lsign-key A0CD6B993438E22634450CDD2A236C3F42A61682

    cat <<EOF | sudo tee -a /etc/pacman.conf

# Cider Collective Repository
[cidercollective]
SigLevel = Required TrustedOnly
Server = https://repo.cider.sh/arch
EOF
    echo "Refreshing pacman database..."
    sudo pacman -Sy
fi

# --- 1. Network & Secrets Setup ---

# Tailscale Setup
if ! command -v tailscale &> /dev/null; then
    echo "Installing Tailscale..."
    if command -v pacman &> /dev/null; then
        sudo pacman -S --noconfirm tailscale
    fi
fi

if command -v tailscale &> /dev/null; then
    echo "Enabling Tailscale service..."
    sudo systemctl enable --now tailscaled

    # Check if logged in
    status=$(tailscale status 2>/dev/null)
    if [[ $? -ne 0 ]]; then
        echo "Authenticating Tailscale..."
        # Start authentication in background and capture output to find URL
        # We assume the user is present to authenticate in the browser
        sudo tailscale up --operator=$USER 2>&1 | while read -r line; do
            echo "$line"
            if [[ "$line" =~ https://login.tailscale.com/a/ ]]; then
                auth_url=$(echo "$line" | grep -o 'https://login.tailscale.com/a/[^ ]*')
                echo "Opening Tailscale Auth URL: $auth_url"
                xdg-open "$auth_url" 2>/dev/null || echo "Please open the URL above manually."
                break # Stop parsing once we found the URL
            fi
        done
        # Wait for the user to finish auth (simple wait or check status loop)
        echo "Waiting for Tailscale connection..."
        while ! tailscale status &>/dev/null; do
            sleep 2
        done
        echo "Tailscale connected!"
    else
        echo "Tailscale already connected."
    fi
fi

# RBW (Vaultwarden) Setup
if ! command -v rbw &> /dev/null; then
    echo "Installing rbw..."
    sudo pacman -S --noconfirm rbw
fi

if command -v rbw &> /dev/null; then
    # Configure RBW (replace with your actual values)
    VAULT_URL="https://vault.linus-fischer.de" 
    VAULT_EMAIL="accounts@linus-fischer.de"

    if ! rbw config show &>/dev/null; then
        echo "Configuring rbw..."
        rbw config set base_url "$VAULT_URL"
        rbw config set email "$VAULT_EMAIL"
        # Optional: Set lock timeout (e.g. 1 hour)
        rbw config set lock_timeout 3600
    fi

    if ! rbw unlocked &>/dev/null; then
        echo "Logging into Vaultwarden..."
        echo "Please enter your Master Password when prompted."
        rbw login
    fi
    # Always sync to ensure we have the latest secrets (like the SSH key)
    echo "Syncing Vaultwarden..."
    rbw sync
fi

# --- End Network & Secrets Setup ---

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

# 3. Configure SDDM Theme (sugar-dark)
# We check if the config matches, if not (or if file doesn't exist), we write it.
CURRENT_THEME=$(grep "Current=" /etc/sddm.conf.d/theme.conf 2>/dev/null | cut -d= -f2)
    if [ "$CURRENT_THEME" != "sugar-dark" ]; then
        echo "Configuring SDDM theme to sugar-dark..."
        sudo mkdir -p /etc/sddm.conf.d
        echo -e "[Theme]\nCurrent=sugar-dark" | sudo tee /etc/sddm.conf.d/theme.conf > /dev/null
    fi

    # Sync the theme customization (e.g. password hiding)
    if [ -f "$HOME/.config/sddm/sugar-dark/theme.conf" ]; then
        echo "Updating SDDM theme configuration..."
        sudo cp "$HOME/.config/sddm/sugar-dark/theme.conf" /usr/share/sddm/themes/sugar-dark/theme.conf
    fi
# 4. Enable standard services (idempotent, safe to run multiple times)
# Check if systemd is active
if pidof systemd &> /dev/null; then
    echo "Enabling common services..."
    sudo systemctl enable --now bluetooth.service 2>/dev/null || true
    # fstrim is good for SSDs
    sudo systemctl enable --now fstrim.timer 2>/dev/null || true
    
    # Enable sched-ext (scx) if installed
    if command -v scx_lavd &> /dev/null || pacman -Qs scx-scheds &> /dev/null; then
        echo "Enabling scx (sched-ext) scheduler..."
        sudo systemctl enable --now scx 2>/dev/null || true
    fi

    # Enable ananicy-cpp if installed
    if systemctl list-unit-files | grep -q ananicy-cpp.service; then
        echo "Enabling ananicy-cpp..."
        sudo systemctl enable --now ananicy-cpp 2>/dev/null || true
    fi
fi

# 4. Install Mise tools
if command -v mise &> /dev/null; then
    echo "Installing global mise tools..."
    mise install -y
fi

echo "Bootstrap complete!"
