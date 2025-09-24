#!/usr/bin/env bash
# 基础系统配置脚本
# 提供网络、软件源和系统更新功能

set -euo pipefail

# 导入通用函数库
source /root/customize_airootfs_common.sh

log "开始基础系统配置..."

# 检查 root 权限
check_root

# 配置基础网络
setup_basic_network

# 添加软件源
add_repositories

# 更新系统
update_system

success "基础系统配置完成"
