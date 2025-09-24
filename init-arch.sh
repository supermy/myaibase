#!/bin/bash

# MyAIBase 系统初始化脚本
# 用于配置Arch Linux构建环境
# 需要以 root 权限运行

set -euo pipefail

# 配置变量
readonly PROFILE_DIR="/etc"
readonly SCRIPT_NAME="$(basename "$0")"
readonly LOG_FILE="/var/log/${SCRIPT_NAME%.sh}.log"

# 颜色输出
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m' # No Color

# 日志函数
log() {
    local level="$1" msg="$2" timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo -e "${timestamp} [$level] $msg" | tee -a "$LOG_FILE"
}

info() {
    echo -e "${GREEN}[信息]${NC} $1"
    log "INFO" "$1"
}

warn() {
    echo -e "${YELLOW}[警告]${NC} $1"
    log "WARN" "$1"
}

error() {
    echo -e "${RED}[错误]${NC} $1"
    log "ERROR" "$1"
    exit 1
}

# 检查 root 权限
check_root() {
    if [[ $EUID -ne 0 ]]; then
        error "此脚本必须以 root 权限运行，请使用 sudo $0"
    fi
}

# 检查网络连接
check_network() {
    info "检查网络连接..."
    if ! ping -c 1 mirrors.tuna.tsinghua.edu.cn &>/dev/null; then
        warn "无法连接到清华镜像源，使用默认镜像源"
        return 1
    fi
    return 0
}

# 配置镜像源
configure_mirrorlist() {
    info "配置镜像源..."
    local mirrorlist="/etc/pacman.d/mirrorlist"
    local backup_mirrorlist="${mirrorlist}.bak.$(date +%Y%m%d%H%M%S)"
    
    # 备份原始镜像源
    if [[ -f "$mirrorlist" ]]; then
        cp "$mirrorlist" "$backup_mirrorlist"
        info "已备份原始镜像源到: $backup_mirrorlist"
    fi
    
    # 配置清华镜像源
    cat > "$mirrorlist" << 'EOF'
## MyAIBase 镜像源配置
Server = https://mirrors.tuna.tsinghua.edu.cn/archlinux/$repo/os/$arch
EOF
    
    info "镜像源配置完成"
}

# 更新系统
update_system() {
    info "更新系统软件包..."
    
    # 更新镜像源数据库
    if ! pacman -Syy --noconfirm; then
        warn "镜像源更新失败，尝试使用默认镜像源"
        return 1
    fi
    
    # 升级系统
    if pacman -Su --noconfirm; then
        info "系统更新完成"
    else
        warn "系统更新失败，请手动检查"
        return 1
    fi
    
    return 0
}

# 安装基础工具
install_base_tools() {
    info "安装基础工具..."
    
    local base_tools=(
        "base-devel"
        "vim"
        "git"
        "wget"
        "curl"
        "openssh"
        "sudo"
    )
    
    for tool in "${base_tools[@]}"; do
        if ! pacman -Qi "$tool" &>/dev/null; then
            info "安装 $tool..."
            pacman -S --noconfirm "$tool" || warn "安装 $tool 失败"
        else
            info "$tool 已安装"
        fi
    done
}

# 配置 Pacman 密钥
configure_pacman_key() {
    info "配置 Pacman 密钥..."
    
    # 初始化密钥环
    if ! pacman-key --init; then
        warn "Pacman 密钥初始化失败"
        return 1
    fi
    
    # 导入 Arch Linux 主密钥
    if pacman-key --populate archlinux; then
        info "Arch Linux 主密钥导入完成"
    else
        warn "Arch Linux 主密钥导入失败"
        return 1
    fi
    
    return 0
}

# 启用 multilib 仓库
enable_multilib() {
    info "启用 multilib 仓库..."
    local pacman_conf="$PROFILE_DIR/pacman.conf"
    
    if grep -q "^\[multilib\]" "$pacman_conf" && ! grep -q "^#\[multilib\]" "$pacman_conf"; then
        info "multilib 仓库已启用"
        return 0
    fi
    
    # 启用 multilib（移除注释）
    if sed -i '/^#\[multilib\]/,/^#Include/s/^#//' "$pacman_conf"; then
        info "multilib 仓库已启用"
    else
        warn "启用 multilib 仓库失败"
        return 1
    fi
    
    return 0
}

# 添加 archlinuxcn 仓库
add_archlinuxcn_repo() {
    info "添加 archlinuxcn 仓库..."
    local pacman_conf="$PROFILE_DIR/pacman.conf"
    
    # 检查是否已存在 archlinuxcn 配置
    if grep -q "^\[archlinuxcn\]" "$pacman_conf"; then
        info "archlinuxcn 仓库已配置"
        return 0
    fi
    
    # 添加 archlinuxcn 仓库配置
    cat >> "$pacman_conf" << 'EOF'

# MyAIBase 添加的 archlinuxcn 仓库
[archlinuxcn]
SigLevel = Optional TrustAll
Server = https://mirrors.tuna.tsinghua.edu.cn/archlinuxcn/$arch
EOF
    
    info "archlinuxcn 仓库添加完成"
}

# 安装 archiso 工具
install_archiso() {
    info "检查并安装 archiso 工具..."
    
    if pacman -Qi archiso &>/dev/null; then
        info "archiso 已安装"
        return 0
    fi
    
    if pacman -S --noconfirm archiso; then
        info "archiso 安装完成"
    else
        error "archiso 安装失败，这是构建 ISO 的必要工具"
        return 1
    fi
    
    return 0
}

# 显示系统信息
show_system_info() {
    info "系统信息:"
    echo "  主机名: $(hostname)"
    echo "  内核版本: $(uname -r)"
    echo "  架构: $(uname -m)"
    echo "  当前时间: $(date)"
    echo
}

# 显示完成信息
show_completion_info() {
    echo
    info "=== MyAIBase 系统初始化完成 ==="
    echo
    info "已完成配置:"
    echo "  ✓ 镜像源配置 (清华镜像源)"
    echo "  ✓ 系统更新"
    echo "  ✓ 基础工具安装"
    echo "  ✓ Pacman 密钥配置"
    echo "  ✓ multilib 仓库启用"
    echo "  ✓ archlinuxcn 仓库添加"
    echo "  ✓ archiso 工具安装"
    echo
    info "日志文件: $LOG_FILE"
    info "现在可以使用 MyAIBase 构建系统了！"
    echo
}

# 错误处理函数
error_handler() {
    local line_no="$1" exit_code="$2"
    error "脚本在第 $line_no 行出错，退出码: $exit_code"
    error "系统初始化失败，请检查日志文件: $LOG_FILE"
    exit "$exit_code"
}

# 设置错误处理陷阱
trap 'error_handler $LINENO $?' ERR

# 显示帮助信息
show_help() {
    cat << EOF
MyAIBase 系统初始化脚本

用法: $0 [选项]

选项:
    -h, --help    显示此帮助信息
    -v, --version 显示版本信息
    -q, --quiet   静默模式（仅显示错误信息）

示例:
    sudo $0              # 完整初始化
    sudo $0 -q           # 静默模式
    $0 --help            # 显示帮助

注意: 此脚本需要 root 权限运行

EOF
}

# 解析命令行参数
parse_args() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_help
                exit 0
                ;;
            -v|--version)
                echo "MyAIBase 系统初始化脚本 v1.0"
                exit 0
                ;;
            -q|--quiet)
                # 静默模式：重定向标准输出到日志文件
                exec >"$LOG_FILE" 2>&1
                shift
                ;;
            *)
                warn "未知参数: $1"
                show_help
                exit 1
                ;;
        esac
    done
}

# 主函数
main() {
    # 解析命令行参数
    parse_args "$@"
    
    # 创建日志目录
    mkdir -p "$(dirname "$LOG_FILE")"
    
    info "=== MyAIBase 系统初始化脚本 ==="
    show_system_info
    
    # 检查权限
    check_root
    
    # 检查网络
    check_network
    
    # 执行初始化步骤
    configure_mirrorlist
    update_system
    install_base_tools
    configure_pacman_key
    enable_multilib
    add_archlinuxcn_repo
    install_archiso
    
    # 显示完成信息
    show_completion_info
}

# 如果直接执行此脚本
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi