#!/usr/bin/env bash
# LibreChat 配置脚本
# 提供 LibreChat 的安装和配置功能

set -euo pipefail

# 导入通用函数库
source /root/customize_airootfs_common.sh

log "开始 LibreChat 配置..."

# 检查 root 权限
check_root

# # 创建构建用户
# create_builder_user "builder"

# # 安装 LibreChat
# install_librechat() {
#     log "通过 AUR 安装 LibreChat..."
    
#     # 切换到 builder 用户安装 AUR 包
#     sudo -iu builder bash -xeuo pipefail <<'EOF'
# # 安装 yay（如果尚未安装）
# if ! command -v yay &>/dev/null; then
#     cd /tmp
#     git clone https://aur.archlinux.org/yay.git
#     cd yay
#     makepkg -si --noconfirm
# fi

# # 安装 LibreChat
# yay -S --noconfirm librechat-bin
# EOF
    
#     success "LibreChat 安装完成"
# }

# 配置 LibreChat
setup_librechat() {
    log "配置 LibreChat..."
    
    # 创建 systemd 服务文件
    cat > /etc/systemd/system/librechat.service <<'EOF'
[Unit]
Description=LibreChat AI Chat Interface
After=network.target

[Service]
Type=simple
User=builder
WorkingDirectory=/usr/share/librechat
ExecStart=/usr/bin/librechat
Restart=on-failure
Environment=NODE_ENV=production PORT=3080

[Install]
WantedBy=multi-user.target
EOF
    
    success "LibreChat 配置完成"
}

# 执行主要步骤
# install_librechat
setup_librechat

# 启用服务
enable_service "librechat" "true"

show_completion_info "LibreChat" "3080"