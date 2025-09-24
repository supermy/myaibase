#!/bin/bash

# MyAIBase AI ISO构建脚本
# 用于构建包含AI组件的Arch Linux ISO镜像

set -euo pipefail

# 脚本目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# 导入通用函数
source "$SCRIPT_DIR/build-common.sh"

# 默认配置
WORK_DIR="work"
OUT_DIR="out"
ISO_NAME="archlinux-ai"
FINAL_ISO_NAME="myaibase-ai-$(date +%Y%m%d).iso"
GGUF_FILE="${GGUF_FILE:-../myaibase/airootfs/opt/models/Qwen3-0.6B-Q8_0.gguf}"

# 显示帮助信息
show_help() {
    cat << EOF
MyAIBase AI ISO构建脚本

用法: $0 [选项]

选项:
    -w, --work-dir <目录>      工作目录 (默认: $WORK_DIR)
    -o, --out-dir <目录>       输出目录 (默认: $OUT_DIR)
    -n, --iso-name <名称>      ISO名称 (默认: $ISO_NAME)
    -f, --final-name <名称>    最终ISO文件名 (默认: $FINAL_ISO_NAME)
    -m, --model <文件>         GGUF模型文件路径 (默认: $GGUF_FILE)
    -q, --quick                快速模式（静默构建）
    -h, --help                 显示此帮助信息

环境变量:
    GGUF_FILE                  GGUF模型文件路径

示例:
    $0                                    # 使用默认配置构建
    $0 -m /path/to/model.gguf            # 使用指定模型文件
    $0 -w /tmp/work -o /tmp/out          # 指定工作目录和输出目录
    $0 -n my-custom-ai                   # 自定义ISO名称
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
            -m|--model)
                GGUF_FILE="$2"
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

# 复制模型文件到AI系统
copy_ai_model() {
    local model_file="$1"
    local models_dir="airootfs/opt/models"
    
    if [ ! -f "$model_file" ]; then
        log_warning "模型文件不存在: $model_file"
        return 1
    fi
    
    # 确保目录存在
    mkdir -p "$models_dir"
    
    # 复制模型文件
    if cp "$model_file" "$models_dir/"; then
        local basename=$(basename "$model_file")
        log_success "已复制模型文件: $basename"
        return 0
    else
        log_error "复制模型文件失败"
        return 1
    fi
}

# 构建AI ISO
build_ai_iso() {
    log_info "开始构建AI ISO镜像..."
    
    # 切换到项目根目录
    cd "$PROJECT_ROOT"
    
    # 1. 检查必要文件
    log_info "检查必要文件..."
    check_file_exists "packages.x86_64-base" "基础软件包列表" || return 1
    check_file_exists "packages.x86_64-ai" "AI软件包列表" || return 1
    check_file_exists "customize_airootfs.sh" "基础自定义脚本" || return 1
    check_file_exists "customize_airootfs_chinese-support.sh" "中文支持脚本" || return 1
    check_file_exists "customize_airootfs_ollama.sh" "Ollama脚本" || return 1
    check_file_exists "customize_airootfs_owui-lite.sh" "Open WebUI脚本" || return 1
    check_file_exists "customize_airootfs_common.sh" "通用函数库" || return 1
    check_file_exists "profiledef.sh" "配置文件" || return 1
    
    # 2. 复制模型文件到AI系统
    log_info "准备AI模型文件..."
    copy_ai_model "$GGUF_FILE" || true  # 模型文件可选
    
    # 3. 合并软件包
    log_info "合并软件包列表..."
    if ! merge_packages "packages.x86_64" "packages.x86_64-base" "packages.x86_64-ai"; then
        return 1
    fi
    
    # 4. 合并所有customize_airootfs脚本
    log_info "合并customize_airootfs脚本..."
    if ! merge_customize_scripts "airootfs/root/customize_airootfs.sh" \
                                "customize_airootfs.sh" \
                                "customize_airootfs_chinese-support.sh" \
                                "customize_airootfs_ollama.sh" \
                                "customize_airootfs_owui-lite.sh"; then
        return 1
    fi
    
    # 复制通用函数库
    log_info "复制通用函数库..."
    cp "customize_airootfs_common.sh" "airootfs/root/customize_airootfs_common.sh"
    
    # 5. 设置ISO名称
    if ! set_iso_name "$ISO_NAME"; then
        return 1
    fi
    
    # 6. 创建必要目录
    mkdir -p "$WORK_DIR" "$OUT_DIR"
    
    # 7. 构建ISO
    local verbose_flag="true"
    if [ "$QUICK_MODE" = true ]; then
        verbose_flag="false"
    fi
    
    if ! run_mkarchiso "$WORK_DIR" "$OUT_DIR" "$verbose_flag"; then
        # 构建失败，清理并恢复配置
        restore_profiledef
        
        # 删除临时模型文件
        local gguf_basename=$(basename "$GGUF_FILE")
        remove_temp_model "airootfs/opt/models/$gguf_basename" || true
        
        return 1
    fi
    
    # 8. 恢复原始配置
    restore_profiledef
    
    # 9. 重命名输出文件
    rename_iso_output "${ISO_NAME}-x86_64.iso" "$FINAL_ISO_NAME" "$OUT_DIR"
    
    # 10. 清理临时模型文件
    log_info "清理临时模型文件..."
    local gguf_basename=$(basename "$GGUF_FILE")
    remove_temp_model "airootfs/opt/models/$gguf_basename" || true
    
    log_success "AI ISO构建完成！"
    log_info "输出文件: $OUT_DIR/$FINAL_ISO_NAME"
    
    return 0
}

# 主函数
main() {
    parse_args "$@"
    
    log_info "MyAIBase AI ISO构建脚本"
    log_info "工作目录: $WORK_DIR"
    log_info "输出目录: $OUT_DIR"
    log_info "ISO名称: $ISO_NAME"
    log_info "最终文件名: $FINAL_ISO_NAME"
    log_info "模型文件: $GGUF_FILE"
    if [ "$QUICK_MODE" = true ]; then
        log_info "模式: 快速构建（静默）"
    fi
    echo
    
    if build_ai_iso; then
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