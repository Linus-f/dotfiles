# Linus's Dotfiles (Chezmoi + Mise + CachyOS)

This repository manages my system configuration, dotfiles, and software packages using [chezmoi](https://www.chezmoi.io/) and [mise](https://mise.jdx.dev/).

## 🚀 Quick Start (Restore on New Machine)

1.  **Install Git & Chezmoi:**
    ```bash
    sudo pacman -S git chezmoi
    ```

2.  **Initialize & Apply:**
    ```bash
    # Replace <username> with your GitHub username
    chezmoi init --apply <username>
    ```

    *During this process:*
    *   **Tailscale** will install and prompt for authentication (browser opens automatically).
    *   **Bitwarden (rbw)** will prompt for your Vaultwarden credentials and Master Password.
    *   **Packages** will be installed automatically via `paru`/`pacman`.

## 🔐 Secrets Management (Critical)

This setup uses **Vaultwarden** (via `rbw`) to securely provision SSH keys. **You must set this up manually once.**

### SSH Key Setup
The SSH key is **not** stored in this repo. It is fetched from Vaultwarden at runtime.

1.  **Generate/View Key:**
    If you don't have the key yet, generate it:
    ```bash
    ssh-keygen -t ed25519 -C "your-email@example.com"
    ```
    View the private key:
    ```bash
    cat ~/.ssh/id_ed25519
    ```

2.  **Upload to Vaultwarden:**
    *   Log in to your Vaultwarden instance.
    *   Create a new **Secure Note**.
    *   **Name:** `SSH_KEY` (Case sensitive).
    *   **Content:** Paste the **entire** private key (including `-----BEGIN...` and `-----END...`).

3.  **Result:**
    Chezmoi will automatically retrieve this note and write it to `~/.ssh/id_ed25519` with correct permissions.

## 📦 Package Tracking

I use a custom automated system to track **only manually installed user packages**, keeping the system base clean.

*   **User Packages:** Listed in `packages.txt`. These are reinstalled on new machines.
*   **System/Base Packages:** Ignored via `sys_packages.txt` (local only, not synced).

**How it works:**
A Fish shell hook (`~/.config/fish/conf.d/chezmoi_pkg_tracking.fish`) runs after every `pacman`/`paru` command.
*   If you install `vlc`: It adds `vlc` to `packages.txt`.
*   If you install a kernel update: It ignores it (because it matches `sys_packages.txt`).

## 🛠️ Automated Setup (`run_once_bootstrap.sh`)

The bootstrap script runs automatically on the first `chezmoi apply`. It handles:

1.  **Network:** Installs/Enables Tailscale & connects.
2.  **Secrets:** Configures `rbw` (Vaultwarden) & syncs.
3.  **Shell:** Sets `fish` as the default shell.
4.  **UI:** Enforces System-wide Dark Mode (`prefer-dark` & `cachyos-nord` theme) for GTK4/Libadwaita apps.
5.  **Services:** Enables Bluetooth & SSD TRIM.
