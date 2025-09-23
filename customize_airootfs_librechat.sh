#!/bin/bash
# Arch Linux Builder User AUR Installation Script
# 用途：创建专用用户安全安装 AUR 包 (例如 LibreChat)
# 注意：建议在完整的 Arch Linux 系统下运行，并确保已连接互联网

set -euo pipefail # 启用错误检查和未定义变量检查

# 3. 创建 builder 用户用于 AUR 包构建
echo "3. 创建构建用户..."
if ! id -u builder &>/dev/null; then
    useradd -m -G wheel -s /bin/bash builder
    echo "builder 用户已创建"
else
    echo "builder 用户已存在，继续使用"
fi


# 4. 使用 builder 用户通过 yay 安装 LibreChat
echo "使用 builder 用户通过 yay 安装 LibreChat..."
# 注意：这里使用 sudo -u 以 builder 用户身份运行 yay
sudo -u builder yay -S --noconfirm librechat


echo "✅ LibreChat 安装完成！"