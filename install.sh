#!/usr/bin/env bash
set -e

# Use sudo if available (not present in some Docker containers)
if command -v sudo &>/dev/null; then
    SUDO="sudo"
else
    SUDO=""
fi

# ── Locale setup (apt-based systems only) ────────────────────────────────────
if command -v apt &>/dev/null; then
    echo "Setting up locale..."
    $SUDO apt update
    $SUDO apt install -y locales
    $SUDO locale-gen en_US.UTF-8
    $SUDO update-locale LANG=en_US.UTF-8 LC_ALL=en_US.UTF-8
fi

export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8

# Persist locale exports in ~/.bashrc
grep -qxF 'export LANG=en_US.UTF-8' ~/.bashrc || echo 'export LANG=en_US.UTF-8' >> ~/.bashrc
grep -qxF 'export LC_ALL=en_US.UTF-8' ~/.bashrc || echo 'export LC_ALL=en_US.UTF-8' >> ~/.bashrc

# ── Build essentials (apt-based systems only, required for tmux compilation) ──
if command -v apt &>/dev/null; then
    echo "Installing build essentials and tmux build dependencies..."
    $SUDO apt install -y build-essential libevent-dev libncurses-dev autoconf automake pkg-config bison git curl
fi

# ── Clone configs ─────────────────────────────────────────────────────────────
echo "Cloning tmux configs"
if [ -d ~/.config/tmux ]; then
    echo "~/.config/tmux already exists, pulling latest..."
    git -C ~/.config/tmux pull
else
    git clone https://github.com/sarve-shreyas/tmux-conf.git ~/.config/tmux
fi

echo "Cloning nvim configs"
if [ -d ~/.config/nvim ]; then
    echo "~/.config/nvim already exists, pulling latest..."
    git -C ~/.config/nvim pull
else
    git clone https://github.com/sarve-shreyas/shvim.git ~/.config/nvim
fi

# Detect OS and architecture
OS="$(uname -s)"
ARCH="$(uname -m)"

# ── Neovim v0.11.5 ────────────────────────────────────────────────────────────
echo "Installing nvim v0.11.5..."
NVIM_VERSION="v0.11.5"

if [ "$OS" = "Linux" ]; then
    if [ "$ARCH" = "x86_64" ]; then
        NVIM_ASSET="nvim-linux-x86_64.tar.gz"
    elif [ "$ARCH" = "aarch64" ] || [ "$ARCH" = "arm64" ]; then
        NVIM_ASSET="nvim-linux-arm64.tar.gz"
    else
        echo "Unsupported Linux architecture: $ARCH" && exit 1
    fi
elif [ "$OS" = "Darwin" ]; then
    if [ "$ARCH" = "x86_64" ]; then
        NVIM_ASSET="nvim-macos-x86_64.tar.gz"
    elif [ "$ARCH" = "arm64" ]; then
        NVIM_ASSET="nvim-macos-arm64.tar.gz"
    else
        echo "Unsupported macOS architecture: $ARCH" && exit 1
    fi
else
    echo "Unsupported OS: $OS" && exit 1
fi

curl -L -o "$NVIM_ASSET" \
    "https://github.com/neovim/neovim/releases/download/${NVIM_VERSION}/${NVIM_ASSET}"

[ "$OS" = "Darwin" ] && xattr -c "./${NVIM_ASSET}"

$SUDO mkdir -p /opt/nvim
$SUDO tar -xzf "$NVIM_ASSET" --strip-components=1 -C /opt/nvim
$SUDO ln -sf /opt/nvim/bin/nvim /usr/local/bin/nvim
rm -f "$NVIM_ASSET"
echo "Neovim v0.11.5 installed."

# ── Packer (Neovim plugin manager) ────────────────────────────────────────────
echo "Installing Packer plugin manager for Neovim..."
PACKER_DIR="${HOME}/.local/share/nvim/site/pack/packer/start/packer.nvim"
if [ ! -d "$PACKER_DIR" ]; then
    git clone --depth 1 https://github.com/wbthomason/packer.nvim "$PACKER_DIR"
    echo "Packer installed."
else
    echo "Packer already installed, skipping."
fi

# ── Install Neovim plugins via PackerSync ─────────────────────────────────────
echo "Installing Neovim plugins via PackerSetup..."
nvim --headless -c 'autocmd User PackerComplete quitall' -c 'PackerSetup' 2>&1
echo "Neovim plugins installed."

# ── tmux (via apt) ────────────────────────────────────────────────────────────
echo "Installing tmux..."
if command -v apt &>/dev/null; then
    $SUDO apt update
    $SUDO apt install -y tmux
    echo "tmux installed."
else
    echo "apt not found, skipping tmux installation."
fi

# ── TPM (tmux plugin manager) ─────────────────────────────────────────────────
echo "Installing TPM (tmux plugin manager)..."
TPM_DIR="${HOME}/.tmux/plugins/tpm"
if [ ! -d "$TPM_DIR" ]; then
    git clone https://github.com/tmux-plugins/tpm "$TPM_DIR"
    echo "TPM installed."
else
    echo "TPM already installed, skipping."
fi

# ── Install tmux plugins via TPM ─────────────────────────────────────────────
echo "Installing tmux plugins via TPM..."
if [ -f "${HOME}/.tmux/plugins/tpm/bin/install_plugins" ]; then
    TMUX_PLUGIN_MANAGER_PATH="${HOME}/.tmux/plugins" \
        "${HOME}/.tmux/plugins/tpm/bin/install_plugins"
    echo "tmux plugins installed."
else
    echo "TPM not found, skipping tmux plugin installation."
fi

echo "Installation complete!"

