#!/bin/bash

# ArchLinux 内存系统盘一键制作脚本
# 基于 petercao 的博客内容编写
# 需要以 root 权限运行

set -e

# 配置变量
PROFILE_DIR="/etc"

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

info() {
    echo -e "${GREEN}[信息]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[警告]${NC} $1"
}

error() {
    echo -e "${RED}[错误]${NC} $1"
    exit 1
}

# 检查 root 权限
check_root() {
    if [[ $EUID -ne 0 ]]; then
        error "此脚本必须以 root 权限运行，请使用 sudo 或切换到 root 用户"
    fi
}

# 安装必要的软件包
install_dependencies() {
    info "检查并安装 archiso 包..."
    if ! pacman -Qi archiso > /dev/null 2>&1; then
        pacman -S --noconfirm archiso || error "安装 archiso 失败"
    else
        info "archiso 已安装"
    fi
}



# 配置 pacman.conf
configure_pacman() {
    info "配置 pacman.conf..."
    
    # 添加 archlinuxcn 源
    cat >> "$PROFILE_DIR/pacman.conf" << EOF

[archlinuxcn]
SigLevel = Optional TrustAll
Server = https://mirrors.tuna.tsinghua.edu.cn/archlinuxcn/\$arch
EOF

    # 启用 multilib
    sed -i '/^#\[multilib\]/,/^#Include/s/^#//' "$PROFILE_DIR/pacman.conf"
    info "已启用 multilib 并添加 archlinuxcn 源"
}


# 主函数
main() {
    info "=== ArchLinux 内存系统盘制作脚本 ==="
    check_root
    echo 'Server = https://mirrors.tuna.tsinghua.edu.cn/archlinux/$repo/os/$arch' > /etc/pacman.d/mirrorlist
    pacman -Syyu  --noconfirm
    pacman -S make vim grub openssh --noconfirm
    pacman-key --init
    pacman-key --populate archlinux
    configure_pacman
    install_dependencies
    info "脚本执行完成!"
}

# 执行主函数
main "$@"