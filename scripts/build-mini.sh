#!/bin/bash

# MyAIBase 最小化ISO构建脚本
# 用于构建最小化的Arch Linux ISO镜像

set -euo pipefail

# 脚本目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# 导入通用函数
source "$SCRIPT_DIR/build-common.sh"

# 默认配置
WORK_DIR="work"
OUT_DIR="out"
ISO_NAME="archlinux-mini"
FINAL_ISO_NAME="myaibase-mini-$(date +%Y%m%d).iso"

# 显示帮助信息
show_help() {
    cat << EOF
MyAIBase 最小化ISO构建脚本

用法: $0 [选项]

选项:
    -w, --work-dir <目录>      工作目录 (默认: $WORK_DIR)
    -o, --out-dir <目录>       输出目录 (默认: $OUT_DIR)
    -n, --iso-name <名称>      ISO名称 (默认: $ISO_NAME)
    -f, --final-name <名称>    最终ISO文件名 (默认: $FINAL_ISO_NAME)
    -h, --help                 显示此帮助信息

示例:
    $0                                    # 使用默认配置构建
    $0 -w /tmp/work -o /tmp/out          # 指定工作目录和输出目录
    $0 -n my-custom-mini                 # 自定义ISO名称

EOF
}

# 解析命令行参数
parse_args() {
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

# 构建最小化ISO
build_mini_iso() {
    log_info "开始构建最小化ISO镜像..."
    
    # 切换到项目根目录
    cd "$PROJECT_ROOT"
    
    # 1. 检查必要文件
    log_info "检查必要文件..."
    check_file_exists "packages.x86_64-mini" "最小化软件包列表" || return 1
    check_file_exists "customize_airootfs.sh" "自定义脚本" || return 1
    check_file_exists "profiledef.sh" "配置文件" || return 1
    
    # 2. 准备软件包列表
    log_info "准备软件包列表..."
    if ! cp "packages.x86_64-mini" "packages.x86_64"; then
        log_error "复制软件包列表失败"
        return 1
    fi
    log_success "已复制最小化软件包列表"
    
    # 3. 准备自定义脚本
    log_info "准备自定义脚本..."
    if ! cp "customize_airootfs.sh" "airootfs/root/customize_airootfs.sh"; then
        log_error "复制自定义脚本失败"
        return 1
    fi
    log_success "已复制自定义脚本"
    
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
    if ! run_mkarchiso "$WORK_DIR" "$OUT_DIR"; then
        # 构建失败，恢复配置
        restore_profiledef
        return 1
    fi
    
    # 7. 恢复原始配置
    restore_profiledef
    
    # 8. 重命名输出文件
    rename_iso_output "${ISO_NAME}-x86_64.iso" "$FINAL_ISO_NAME" "$OUT_DIR"
    
    log_success "最小化ISO构建完成！"
    log_info "输出文件: $OUT_DIR/$FINAL_ISO_NAME"
    
    return 0
}

# 主函数
main() {
    parse_args "$@"
    
    log_info "MyAIBase 最小化ISO构建脚本"
    log_info "工作目录: $WORK_DIR"
    log_info "输出目录: $OUT_DIR"
    log_info "ISO名称: $ISO_NAME"
    log_info "最终文件名: $FINAL_ISO_NAME"
    echo
    
    if build_mini_iso; then
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