#!/bin/bash
#配置网络
systemctl enable iwd

# 添加 archlinuxcn 源
cat >> "/etc/pacman.conf" << EOF

[archlinuxcn]
SigLevel = Optional TrustAll
Server = https://mirrors.tuna.tsinghua.edu.cn/archlinuxcn/\$arch
[local]
SigLevel = Optional TrustAll
Server = file:///local_repo
EOF

echo 'Server = https://mirrors.tuna.tsinghua.edu.cn/archlinux/$repo/os/$arch' > /etc/pacman.d/mirrorlist


pacman -Syy  --noconfirm 
pacman -Syu  --noconfirm 
