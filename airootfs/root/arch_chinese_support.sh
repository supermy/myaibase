#!/bin/bash

# ArchLinux Terminal Chinese Support Auto-Setup Script
# 注意：建议在运行前执行 'sudo pacman -Syu' 更新系统

# 检查 root 权限
if [ "$(id -u)" -ne 0 ]; then
    echo "请使用 sudo 运行此脚本或切换到 root 用户。"
    exit 1
fi

# 1. 安装必要的包：语言环境支持和中文字体
echo "正在安装语言环境支持和中文字体..."
#pacman -S --noconfirm glibc lib32-glibc
#pacman -S --noconfirm noto-fonts-cjk wqy-microhei

# 2. 配置 locale
echo "正在配置 locale..."
# 取消 zh_CN.UTF-8 UTF-8 的注释
sed -i '/zh_CN.UTF-8 UTF-8/s/^#//g' /etc/locale.gen
sed -i '/zh_CN.GB18030 GB18030/s/^#//g' /etc/locale.gen
sed -i '/zh_CN.GBK GBK/s/^#//g' /etc/locale.gen
# 生成 locale
locale-gen

# 3. 设置系统级 locale (可选)
echo "设置系统级 locale..."
#echo "LANG=zh_CN.UTF-8" > /etc/locale.conf
echo "LANG=en_US.UTF-8" > /etc/locale.conf

# 4. 提示用户配置
echo "配置完成！"
echo "请手动执行以下操作之一以使更改生效："
echo "1. 重启系统（推荐）。"
echo "2. 或者，为当前用户生效，请在 ~/.bashrc 或 ~/.zshrc 中添加："
echo "   export LANG=zh_CN.UTF-8"
echo "   export LC_ALL=zh_CN.UTF-8"
echo "   然后运行 source ~/.bashrc 或 source ~/.zshrc"

# 5. 配置用户环境变量
echo "配置用户环境变量..."
echo -e "\n# 设置中文环境" >> "$HOME/.bashrc"
echo "export LANG=zh_CN.UTF-8" >> "$HOME/.bashrc"
echo "export LANGUAGE=en_US.UTF-8" >> "$HOME/.bashrc"

#echo -e "\n# 设置输入法环境变量" >> "$HOME/.bashrc"
#echo "export GTK_IM_MODULE=fcitx5" >> "$HOME/.bashrc"
#echo "export QT_IM_MODULE=fcitx5" >> "$HOME/.bashrc"
#echo "export XMODIFIERS=@im=fcitx5" >> "$HOME/.bashrc"

