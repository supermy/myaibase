#!/usr/bin/env bash
# 中文支持配置脚本
# 提供中文 locale、字体和输入法支持

set -euo pipefail

# 导入通用函数库
source /root/customize_airootfs_common.sh

log "开始中文支持配置..."

# 检查 root 权限
check_root

# 设置中文 locale
setup_locale "zh_CN.UTF-8"

# 安装中文字体 在 packages.x86_64-base 中
# log "安装中文字体..."
# pacman -S --needed --noconfirm adobe-source-han-sans-cn-fonts adobe-source-han-serif-cn-fonts
# success "中文字体安装完成"

# 创建 builder 用户
create_builder_user "builder"

# 配置中文字体
setup_chinese_fonts "wqy-microhei"

# 配置 TTY 中文支持
cat > /etc/profile.d/chinese.sh << 'EOF'
export LANG=zh_CN.UTF-8
export LANGUAGE=zh_CN:zh
export LC_ALL=zh_CN.UTF-8
EOF

# 配置 fbterm 支持中文显示
cat > /etc/fbterm.conf << 'EOF'
font-size=16
font-names=wqy-microhei
# input-method=fcitx
EOF

# 安装 fbterm 使用本地库 fcitx需要桌面环境
# log "安装输入法相关软件..."
# pacman -S --needed --noconfirm fbterm fcitx fcitx-configtool fcitx-gtk2 fcitx-gtk3 fcitx-qt4 fcitx-qt5
# success "输入法软件安装完成"

# # 配置 fcitx 环境变量
# cat > /etc/profile.d/fcitx.sh << 'EOF'
# export GTK_IM_MODULE=fcitx
# export QT_IM_MODULE=fcitx
# export XMODIFIERS="@im=fcitx"
# EOF

# 设置 builder 用户的 locale 和输入法
if id "builder" &>/dev/null; then
    cp /etc/profile.d/chinese.sh /home/builder/.profile
    # cp /etc/profile.d/fcitx.sh /home/builder/.profile
    chown builder:builder /home/builder/.profile
fi

success "中文支持配置完成"