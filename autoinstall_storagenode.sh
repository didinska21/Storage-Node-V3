#!/bin/bash

# ================================
# AUTO INSTALLER - 0G Storage Node
# By: AstroStake + Didin
# ================================

set -e

# Warna CLI
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

banner() {
echo -e "${YELLOW}
╔═════════════════════════════════════════════════╗
║         🚀  AUTO INSTALL - 0G STORAGE NODE       ║
╚═════════════════════════════════════════════════╝
${NC}"
}

log() {
    echo -e "${GREEN}✔ $1${NC}"
}

error_exit() {
    echo -e "${RED}✖ $1${NC}"
    exit 1
}

banner

# Step 1: Install Dependencies
echo -e "${YELLOW}📦 Menginstall paket dependencies...${NC}"
sudo apt-get update && \
sudo apt-get install -y clang cmake build-essential openssl pkg-config libssl-dev jq git bc || error_exit "Gagal install dependencies"
log "Dependencies selesai diinstall."

# Step 2: Install Golang (jika belum)
if ! command -v go &>/dev/null; then
    echo -e "${YELLOW}🐹 Menginstall Golang...${NC}"
    cd $HOME
    ver="1.22.0"
    wget "https://golang.org/dl/go$ver.linux-amd64.tar.gz"
    sudo rm -rf /usr/local/go
    sudo tar -C /usr/local -xzf "go$ver.linux-amd64.tar.gz"
    rm "go$ver.linux-amd64.tar.gz"
    echo "export PATH=\$PATH:/usr/local/go/bin:\$HOME/go/bin" >> ~/.bash_profile
    source ~/.bash_profile
    go version || error_exit "Gagal install Golang"
    log "Golang berhasil diinstall."
else
    log "Golang sudah terinstall. Melewati..."
fi

# Step 3: Install Rust (jika belum)
if ! command -v cargo &>/dev/null; then
    echo -e "${YELLOW}🦀 Menginstall Rust...${NC}"
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
    . "$HOME/.cargo/env"
    log "Rust berhasil diinstall."
else
    log "Rust sudah terinstall. Melewati..."
fi

# Step 4: Clone Repo
echo -e "${YELLOW}📥 Mengunduh 0G Storage Node...${NC}"
cd $HOME
git clone -b v1.0.0 https://github.com/0glabs/0g-storage-node.git || error_exit "Gagal clone repo"
log "Repo berhasil di-clone."

# Step 5: Setup & Build
cd $HOME/0g-storage-node
git stash
git fetch --all --tags
git checkout v1.0.0
git submodule update --init
cargo build --release || error_exit "Gagal compile dengan Cargo"
log "Build selesai."

# Step 6: Download config
echo -e "${YELLOW}⚙️  Mengatur config.toml...${NC}"
rm -rf $HOME/0g-storage-node/run/config.toml
curl -o $HOME/0g-storage-node/run/config.toml https://vault.astrostake.xyz/testnet/0g-labs/config-v3.toml || error_exit "Gagal download config.toml"
log "Config berhasil diunduh."

# Step 7 & 8: Edit Private Key
echo -e "${YELLOW}🔐 Silakan masukkan Private Key untuk mining (diawali dengan 0x):${NC}"
read -p "Private Key: " MINER_KEY

if [[ $MINER_KEY != 0x* ]]; then
    error_exit "Private key harus diawali dengan 0x!"
fi

sed -i "s|^miner_key *= *\".*\"|miner_key = \"$MINER_KEY\"|" $HOME/0g-storage-node/run/config.toml || error_exit "Gagal menulis private key"
log "Private key berhasil disisipkan."

# Step 9: Create systemd service
echo -e "${YELLOW}🛠️  Membuat service systemd...${NC}"
sudo tee /etc/systemd/system/zgs.service > /dev/null <<EOF
[Unit]
Description=ZGS Node
After=network.target

[Service]
User=$USER
WorkingDirectory=$HOME/0g-storage-node/run
ExecStart=$HOME/0g-storage-node/target/release/zgs_node --config $HOME/0g-storage-node/run/config.toml
Restart=on-failure
RestartSec=10
LimitNOFILE=65535

[Install]
WantedBy=multi-user.target
EOF
log "Service zgs dibuat."

# Step 10: Start service
echo -e "${YELLOW}🚀 Menjalankan node ZGS...${NC}"
sudo systemctl daemon-reload
sudo systemctl enable zgs
sudo systemctl start zgs
log "Node berhasil dijalankan."

# Step 11: Check block & peers
echo -e "${YELLOW}📡 Mengecek blok dan peers...${NC}"
source <(curl -s https://raw.githubusercontent.com/astrostake/0G-Labs-script/refs/heads/main/storage-node/check_block.sh)
