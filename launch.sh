#!/bin/bash

# Nama screen session
SESSION_NAME="storage"

# Jalankan script install langsung di dalam screen
screen -S "$SESSION_NAME" -dm bash -c "$(curl -s https://raw.githubusercontent.com/didinska21/Storage-Node-V3/main/autoinstall_storagenode.sh)"

echo "✅ Script sedang dijalankan di dalam screen '$SESSION_NAME'"
echo "🔧 Gunakan perintah berikut untuk masuk ke dalam screen:"
echo ""
echo "    screen -r $SESSION_NAME"
echo ""
echo "📌 Jika ingin detach dari screen, tekan: Ctrl + A lalu D"
