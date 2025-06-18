clear
echo -e "\e[1;32m"
echo "#############################################"
echo "#                                           #"
echo "#          Storage node                    #"
echo "#                                           #"
echo "# guide by : t.me/didinska                 #"
echo "#                                           #"
echo "#############################################"
echo
echo -e "\e[0m"
sleep 2

echo -e "\n=== 0G Labs Storage Node Auto Installer ===\n"

# 0. Start or create screen session
if ! command -v screen &> /dev/null; then
    echo "Installing screen..."
    sudo apt-get install -y screen
fi
echo "Starting screen session 'storage'..."
screen -dmS storage

# 1. Update system
echo -e "\n>> Updating system..."
sudo apt-get update

# 2. Install dependencies
echo -e "\n>> Installing dependencies..."
sudo apt-get install -y clang cmake build-essential openssl pkg-config libssl-dev jq git bc curl

# 3. Install Golang
echo -e "\n>> Installing Golang..."
cd "$HOME"
ver="1.22.0"
wget "https://golang.org/dl/go${ver}.linux-amd64.tar.gz"
sudo rm -rf /usr/local/go
sudo tar -C /usr/local -xzf "go${ver}.linux-amd64.tar.gz"
rm "go${ver}.linux-amd64.tar.gz"
echo "export PATH=\$PATH:/usr/local/go/bin:\$HOME/go/bin" >> ~/.bash_profile
source ~/.bash_profile
go version

# 4. Install Rust
echo -e "\n>> Installing Rust..."
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
source "$HOME/.cargo/env"

# 5. Clone the repository
echo -e "\n>> Cloning 0G Storage Node repository..."
git clone -b v1.0.0 https://github.com/0glabs/0g-storage-node.git
cd "$HOME/0g-storage-node"
git stash
git fetch --all --tags
git checkout v1.0.0
git submodule update --init

# 6. Build the node
echo -e "\n>> Building the node (15-20 minutes)..."
cargo build --release

# 7. Download config file
echo -e "\n>> Downloading config file..."
rm -f "$HOME/0g-storage-node/run/config.toml"
curl -o "$HOME/0g-storage-node/run/config.toml" https://vault.astrostake.xyz/0g-labs/config-v3.toml

# 8. Input private key
read -p "Masukkan PRIVATE KEY kamu: " PRIVATE_KEY

# 9. Insert private key into config
echo -e "\n>> Inserting PRIVATE KEY into config..."
sed -i "s|miner_key = \".*\"|miner_key = \"$PRIVATE_KEY\"|" "$HOME/0g-storage-node/run/config.toml"

# 10. Create systemd service file
echo -e "\n>> Creating systemd service..."
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

# 11. Enable and start the service
echo -e "\n>> Enabling and starting the service..."
sudo systemctl daemon-reload && sudo systemctl enable zgs && sudo systemctl start zgs

# 12. Check block & peers
echo -e "\n>> Checking block & peers..."
source <(curl -s https://raw.githubusercontent.com/astrostake/0G-Labs-script/refs/heads/main/storage-node/check_block.sh)

echo -e "\n✅ Instalasi selesai! Gunakan 'screen -r storage' untuk masuk ke session."
