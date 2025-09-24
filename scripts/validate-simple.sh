#!/bin/bash

# MyAIBase 简化验证脚本
# 快速验证构建环境和依赖

set -euo pipefail

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# 日志函数
log() { echo -e "${BLUE}ℹ️  $1${NC}"; }
success() { echo -e "${GREEN}✅ $1${NC}"; }
warn() { echo -e "${YELLOW}⚠️  $1${NC}"; }
error() { echo -e "${RED}❌ $1${NC}"; }

# 检查结果
declare -a ERRORS=()
declare -a WARNS=()

# 快速检查
check() {
    local type=$1 file=$2 desc=$3 required=$4
    
    if [ "$type" = "file" ] && [ ! -f "$file" ]; then
        if [ "$required" = true ]; then
            ERRORS+=("$desc 缺失: $file")
        else
            WARNS+=("$desc 不存在: $file")
        fi
        return 1
    elif [ "$type" = "dir" ] && [ ! -d "$file" ]; then
        if [ "$required" = true ]; then
            ERRORS+=("$desc 目录缺失: $file")
        else
            WARNS+=("$desc 目录不存在: $file")
        fi
        return 1
    elif [ "$type" = "cmd" ] && ! command -v "$file" &>/dev/null; then
        if [ "$required" = true ]; then
            ERRORS+=("依赖缺失: $desc")
        else
            WARNS+=("可选依赖不存在: $desc")
        fi
        return 1
    fi
    
    [ "$required" = true ] && success "$desc 正常"
    return 0
}

# 显示结果
show_results() {
    echo
    log "验证结果汇总:"
    
    # 显示警告
    if [ ${#WARNS[@]} -gt 0 ]; then
        warn "警告信息:"
        for warn in "${WARNS[@]}"; do
            echo "  ⚠️  $warn"
        done
        echo
    fi
    
    # 显示错误
    if [ ${#ERRORS[@]} -gt 0 ]; then
        error "错误信息:"
        for err in "${ERRORS[@]}"; do
            echo "  ❌ $err"
        done
        echo
        error "验证失败！请修复上述错误后再试。"
        return 1
    else
        success "所有检查通过！环境准备就绪。"
        return 0
    fi
}

# 重置结果数组
reset_results() {
    ERRORS=()
    WARNS=()
}

# 快速验证
quick_check() {
    reset_results
    log "快速验证构建环境..."
    
    # 依赖检查
    check cmd mkarchiso "archiso工具" true
    check cmd sudo "sudo权限" true
    check cmd mkfs.fat "FAT文件系统工具" true
    
    # 基础文件
    check file "profiledef.sh" "配置文件" true
    check file "packages.x86_64-mini" "最小化软件包" false
    check file "packages.x86_64-base" "基础软件包" false
    check file "packages.x86_64-ai" "AI软件包" false
    
    # 自定义脚本
    check file "customize_airootfs.sh" "基础自定义脚本" true
    check file "customize_airootfs_chinese-support.sh" "中文支持脚本" false
    check file "customize_airootfs_ollama.sh" "Ollama脚本" false
    
    # 目录结构
    check dir "airootfs" "airootfs目录" true
    check dir "efiboot" "efiboot目录" true
    
    show_results
}

# 完整验证
full_check() {
    reset_results
    log "完整验证构建环境..."
    
    # 依赖检查（完整）
    check cmd mkarchiso "archiso工具" true
    check cmd sudo "sudo权限" true
    check cmd mkfs.fat "FAT文件系统工具" true
    check cmd mksquashfs "SquashFS工具" true
    check cmd grub-mkrescue "GRUB工具" true
    check cmd xorriso "ISO创建工具" true
    
    # 所有软件包列表
    check file "packages.x86_64-mini" "最小化软件包" true
    check file "packages.x86_64-base" "基础软件包" true
    check file "packages.x86_64-ai" "AI软件包" true
    
    # 所有自定义脚本
    check file "customize_airootfs.sh" "基础自定义脚本" true
    check file "customize_airootfs_chinese-support.sh" "中文支持脚本" true
    check file "customize_airootfs_ollama.sh" "Ollama脚本" true
    check file "customize_airootfs_librechat.sh" "LibreChat脚本" true
    
    # 完整目录结构
    check dir "airootfs" "airootfs目录" true
    check dir "efiboot" "efiboot目录" true
    check dir "grub" "grub目录" true
    check dir "syslinux" "syslinux目录" true
    
    # 配置文件
    check file "pacman.conf" "Pacman配置" true
    check file "bootstrap_packages.x86_64" "引导软件包" true
    
    # 本地仓库脚本
    check file "scripts/local_repo.sh" "本地仓库脚本" false
    
    show_results
}

# 显示帮助
show_help() {
    cat << EOF
MyAIBase 简化验证脚本

用法: $0 [选项]

选项:
    quick    快速验证（默认）
    full     完整验证
    deps     仅验证依赖
    files    仅验证文件
    -h       显示帮助

示例:
    $0          # 快速验证
    $0 full     # 完整验证
    $0 deps     # 仅检查依赖
EOF
}

# 主函数
main() {
    case "${1:-quick}" in
        quick) quick_check ;;
        full) full_check ;;
        deps)
            log "验证系统依赖..."
            check cmd mkarchiso "archiso工具" true
            check cmd sudo "sudo权限" true
            check cmd mkfs.fat "FAT文件系统工具" true
            check cmd mksquashfs "SquashFS工具" true
            check cmd grub-mkrescue "GRUB工具" true
            show_results
            ;;
        files)
            log "验证文件完整性..."
            check file "profiledef.sh" "配置文件" true
            check file "packages.x86_64-mini" "最小化软件包" true
            check file "packages.x86_64-base" "基础软件包" true
            check file "customize_airootfs.sh" "基础自定义脚本" true
            check dir "airootfs" "airootfs目录" true
            check dir "efiboot" "efiboot目录" true
            show_results
            ;;
        -h|--help) show_help ;;
        *) error "未知选项: $1"; show_help; exit 1 ;;
    esac
}

# 如果直接执行
[ "${BASH_SOURCE[0]}" = "${0}" ] && main "$@"