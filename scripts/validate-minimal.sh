#!/bin/bash

# MyAIBase 极简验证脚本
# 快速验证构建环境和依赖

set -euo pipefail

# 简单输出函数（避免编码问题）
log() { echo "INFO: $1"; }
success() { echo "OK: $1"; }
warn() { echo "WARN: $1"; }
error() { echo "ERROR: $1"; }

# 快速检查
check_file() {
    if [ -f "$1" ]; then
        success "文件存在: $1"
        return 0
    else
        error "文件不存在: $1"
        return 1
    fi
}

check_dir() {
    if [ -d "$1" ]; then
        success "目录存在: $1"
        return 0
    else
        error "目录不存在: $1"
        return 1
    fi
}

check_cmd() {
    if command -v "$1" &>/dev/null; then
        success "命令可用: $1"
        return 0
    else
        error "命令不可用: $1"
        return 1
    fi
}

# 快速验证
quick_check() {
    log "开始快速验证..."
    local errors=0
    
    # 检查依赖
    check_cmd mkarchiso || ((errors++))
    check_cmd sudo || ((errors++))
    check_cmd mkfs.fat || ((errors++))
    
    # 检查基础文件
    check_file profiledef.sh || ((errors++))
    check_file customize_airootfs.sh || ((errors++))
    
    # 检查目录
    check_dir airootfs || ((errors++))
    check_dir efiboot || ((errors++))
    
    if [ $errors -eq 0 ]; then
        log "快速验证通过！"
        return 0
    else
        error "验证失败，发现 $errors 个问题"
        return 1
    fi
}

# 完整验证
full_check() {
    log "开始完整验证..."
    local errors=0
    
    # 检查所有依赖
    check_cmd mkarchiso || ((errors++))
    check_cmd sudo || ((errors++))
    check_cmd mkfs.fat || ((errors++))
    check_cmd mksquashfs || ((errors++))
    check_cmd grub-mkrescue || ((errors++))
    
    # 检查所有软件包列表
    check_file packages.x86_64-mini || ((errors++))
    check_file packages.x86_64-base || ((errors++))
    check_file packages.x86_64-ai || ((errors++))
    
    # 检查所有脚本
    check_file customize_airootfs.sh || ((errors++))
    check_file customize_airootfs_chinese-support.sh || ((errors++))
    check_file customize_airootfs_ollama.sh || ((errors++))
    
    # 检查目录结构
    check_dir airootfs || ((errors++))
    check_dir efiboot || ((errors++))
    check_dir grub || ((errors++))
    check_dir syslinux || ((errors++))
    
    # 检查配置
    check_file pacman.conf || ((errors++))
    check_file bootstrap_packages.x86_64 || ((errors++))
    
    if [ $errors -eq 0 ]; then
        log "完整验证通过！"
        return 0
    else
        error "验证失败，发现 $errors 个问题"
        return 1
    fi
}

# 显示帮助
show_help() {
    cat << EOF
MyAIBase 极简验证脚本

用法: $0 [选项]

选项:
    quick   快速验证（默认）
    full    完整验证
    deps    仅验证依赖
    -h      显示帮助

示例:
    $0         # 快速验证
    $0 full    # 完整验证
    $0 deps    # 仅检查依赖
EOF
}

# 主函数
main() {
    case "${1:-quick}" in
        quick) quick_check ;;
        full) full_check ;;
        deps)
            log "检查系统依赖..."
            check_cmd mkarchiso
            check_cmd sudo
            check_cmd mkfs.fat
            check_cmd mksquashfs
            check_cmd grub-mkrescue
            ;;
        -h|--help) show_help ;;
        *) error "未知选项: $1"; show_help; exit 1 ;;
    esac
}

# 如果直接执行
[ "${BASH_SOURCE[0]}" = "${0}" ] && main "$@"