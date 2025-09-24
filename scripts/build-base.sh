#!/bin/bash

# MyAIBase 基础ISO构建脚本
# 用于构建基础版本的Arch Linux ISO镜像（包含中文支持）

set -euo pipefail

# 脚本目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# 导入通用函数
source "$SCRIPT_DIR/build-common.sh"

# 默认配置
WORK_DIR="work"
OUT_DIR="out"
ISO_NAME="archlinux-baseline"
FINAL_ISO_NAME="myaibase-base-$(date +%Y%m%d).iso"

# 显示帮助信息
show_help() {
    cat << EOF
MyAIBase 基础ISO构建脚本

用法: $0 [选项]

选项:
    -w, --work-dir <目录>      工作目录 (默认: $WORK_DIR)
    -o, --out-dir <目录>       输出目录 (默认: $OUT_DIR)
    -n, --iso-name <名称>      ISO名称 (默认: $ISO_NAME)
    -f, --final-name <名称>    最终ISO文件名 (默认: $FINAL_ISO_NAME)
    -q, --quick                快速模式（静默构建）
    -h, --help                 显示此帮助信息

示例:
    $0                                    # 使用默认配置构建
    $0 -w /tmp/work -o /tmp/out          # 指定工作目录和输出目录
    $0 -n my-custom-base                 # 自定义ISO名称
    $0 -q                                 # 快速静默构建

EOF
}

# 解析命令行参数
parse_args() {
    QUICK_MODE=false
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            -w|--work-dir)
                WORK_DIR="$2"
                shift 2
                ;;
            -o|--out-dir)
                OUT_DIR="$2"
                shift 2
                ;;
            -n|--iso-name)
                ISO_NAME="$2"
                shift 2
                ;;
            -f|--final-name)
                FINAL_ISO_NAME="$2"
                shift 2
                ;;
            -q|--quick)
                QUICK_MODE=true
                shift
                ;;
            -h|--help)
                show_help
                exit 0
                ;;
            *)
                log_error "未知参数: $1"
                show_help
                exit 1
                ;;
        esac
    done
}

# 构建基础ISO
build_base_iso() {
    log_info "开始构建基础ISO镜像..."
    
    # 切换到项目根目录
    cd "$PROJECT_ROOT"
    
    # 1. 检查必要文件
    log_info "检查必要文件..."
    check_file_exists "packages.x86_64-base" "基础软件包列表" || return 1
    check_file_exists "customize_airootfs.sh" "基础自定义脚本" || return 1
    check_file_exists "customize_airootfs_chinese-support.sh" "中文支持脚本" || return 1
    check_file_exists "profiledef.sh" "配置文件" || return 1
    
    # 2. 准备软件包列表
    log_info "准备软件包列表..."
    if ! merge_packages "packages.x86_64" "packages.x86_64-base"; then
        return 1
    fi
    
    # 3. 准备自定义脚本（基础版本仅包含中文支持）
    log_info "准备自定义脚本..."
    if ! merge_customize_scripts "airootfs/root/customize_airootfs.sh" \
                                "customize_airootfs.sh" \
                                "customize_airootfs_chinese-support.sh"; then
        return 1
    fi
    
    # 复制通用函数库
    log_info "复制通用函数库..."
    cp "customize_airootfs_common.sh" "airootfs/root/customize_airootfs_common.sh"
    
    # 4. 设置ISO名称
    if ! set_iso_name "$ISO_NAME"; then
        return 1
    fi
    
    # 5. 创建必要目录
    mkdir -p "$WORK_DIR" "$OUT_DIR"
    
    # 6. 构建ISO
    local verbose_flag="true"
    if [ "$QUICK_MODE" = true ]; then
        verbose_flag="false"
    fi
    
    if ! run_mkarchiso "$WORK_DIR" "$OUT_DIR" "$verbose_flag"; then
        # 构建失败，恢复配置
        restore_profiledef
        return 1
    fi
    
    # 7. 恢复原始配置
    restore_profiledef
    
    # 8. 重命名输出文件
    rename_iso_output "${ISO_NAME}-x86_64.iso" "$FINAL_ISO_NAME" "$OUT_DIR"
    
    log_success "基础ISO构建完成！"
    log_info "输出文件: $OUT_DIR/$FINAL_ISO_NAME"
    
    return 0
}

# 主函数
main() {
    parse_args "$@"
    
    log_info "MyAIBase 基础ISO构建脚本"
    log_info "工作目录: $WORK_DIR"
    log_info "输出目录: $OUT_DIR"
    log_info "ISO名称: $ISO_NAME"
    log_info "最终文件名: $FINAL_ISO_NAME"
    if [ "$QUICK_MODE" = true ]; then
        log_info "模式: 快速构建（静默）"
    fi
    echo
    
    if build_base_iso; then
        log_success "构建成功完成！"
        exit 0
    else
        log_error "构建失败！"
        exit 1
    fi
}

# 如果直接执行此脚本
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    main "$@"
fi