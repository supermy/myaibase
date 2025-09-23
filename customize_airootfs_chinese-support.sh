#!/bin/bash
# Arch Linux TTY 中文支持脚本（无桌面环境）
# 需以 root 运行
# 优化版：解决 systemd 总线连接问题，添加错误处理和备用方案

set -e  # 遇到任何错误立即退出脚本[4,5](@ref)
set -u  # 遇到未定义的变量时退出脚本

# 走 http 代理
git config --global http.proxy http://127.0.0.1:7890
git config --global https.proxy http://127.0.0.1:7890

# 如果代理用自签证书，先关闭校验（仅临时）
git config --global http.sslVerify false


echo "正在配置 TTY 中文支持..."
echo "========================================"

# 0. 检查 root 权限
if [[ $EUID -ne 0 ]]; then
   echo "错误：此脚本必须以 root 权限运行" >&2
   exit 1
fi

# 1. 设置中文 locale
echo "1. 配置中文 locale..."
if ! grep -q "^zh_CN.UTF-8 UTF-8" /etc/locale.gen; then
    sed -i 's/^#zh_CN.UTF-8 UTF-8/zh_CN.UTF-8 UTF-8/' /etc/locale.gen
fi
locale-gen
echo 'LANG=zh_CN.UTF-8' > /etc/locale.conf
export LANG=zh_CN.UTF-8

# 2. 安装中文字体
echo "2. 安装中文字体..."
#pacman -S --noconfirm wqy-zenhei  # 使用 pacman 直接安装[6,8](@ref)

##****fbterm终端中文环境支撑，安装包太大，联网之后手动安装；
# 3. 创建 builder 用户用于 AUR 包构建
echo "3. 创建构建用户..."
if ! id -u builder &>/dev/null; then
    useradd -m -G wheel -s /bin/bash builder
    echo "builder 用户已创建"
else
    echo "builder 用户已存在，继续使用"
fi

sudo bash -c 'cat >/etc/sudoers.d/builder-nopasswd <<<"builder ALL=(ALL) NOPASSWD: ALL" \
&& chmod 440 /etc/sudoers.d/builder-nopasswd \
&& visudo -c -f /etc/sudoers.d/builder-nopasswd'

# pacman -S --needed --noconfirm sudo base-devel
mkdir -p /var/cache/pacman/pkg/
chown -R builder:builder /var/cache/pacman/pkg/
chmod -R 755 /var/cache/pacman/pkg/

# yay 手动安装
# # 空间不够 实体盘手动安装 fbterm 
# sudo -u builder yay -S --noconfirm fbterm 


# 6. 配置 fbterm 支持中文显示
echo "6. 配置 fbterm..."
cat > /etc/fbtermrc << EOF
font-names=WenQuanYi Zen Hei
font-size=16
input-method=fcitx
EOF

# 7. 添加用户到 video 组（fbterm 需要）
echo "7. 设置用户权限..."
if [[ -n "${SUDO_USER:-}" ]]; then
    TARGET_USER="$SUDO_USER"
else
    TARGET_USER=$(whoami)
fi
usermod -a -G video "$TARGET_USER"


# # 9. 完成提示
# echo "========================================"
# echo "安装完成！"
# echo "请注销后重新登录或重启系统使配置生效。"
# echo ""
# echo "使用方式："
# echo "1. 在 TTY 中直接运行 'fbterm' 启动中文终端"
# echo ""
# echo "注意事项："
# echo "- 如果遇到权限问题，请确认用户已加入 video 组"
# echo "- 如需输入法支持，可能需要额外配置 fcitx"
# echo "- 如果显示仍不正常，请尝试调整 /etc/fbtermrc 中的字体设置"