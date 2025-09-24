#!/bin/bash

# MyAIBase 构建系统通用函数
# 提供文件检查、软件包合并、脚本合并等通用功能

set -euo pipefail

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 日志函数
log_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

log_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

log_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

log_error() {
    echo -e "${RED}❌ $1${NC}"
}

# 检查文件是否存在
check_file_exists() {
    local file="$1"
    local description="$2"
    
    if [ ! -f "$file" ]; then
        log_error "$description 不存在: $file"
        return 1
    fi
    log_success "$description 存在: $file"
    return 0
}

# 检查目录是否存在
check_dir_exists() {
    local dir="$1"
    local description="$2"
    
    if [ ! -d "$dir" ]; then
        log_error "$description 目录不存在: $dir"
        return 1
    fi
    log_success "$description 目录存在: $dir"
    return 0
}

# 合并软件包列表
merge_packages() {
    local output_file="$1"
    shift
    local input_files=("$@")
    
    log_info "合并软件包列表到: $output_file"
    
    # 检查所有输入文件
    for file in "${input_files[@]}"; do
        if [ ! -f "$file" ]; then
            log_error "软件包文件不存在: $file"
            return 1
        fi
    done
    
    # 合并并去重
    cat "${input_files[@]}" | sort -u > "$output_file"
    
    if [ $? -eq 0 ]; then
        log_success "软件包合并成功"
        return 0
    else
        log_error "软件包合并失败"
        return 1
    fi
}

# 合并customize_airootfs脚本
merge_customize_scripts() {
    local output_file="$1"
    shift
    local input_files=("$@")
    
    log_info "合并customize_airootfs脚本到: $output_file"
    
    # 检查所有输入文件
    for file in "${input_files[@]}"; do
        if [ ! -f "$file" ]; then
            log_error "customize脚本不存在: $file"
            return 1
        fi
    done
    
    # 合并脚本文件
    cat "${input_files[@]}" > "$output_file"
    
    if [ $? -eq 0 ]; then
        log_success "customize脚本合并成功"
        return 0
    else
        log_error "customize脚本合并失败"
        return 1
    fi
}

# 修改profiledef.sh中的ISO名称
set_iso_name() {
    local iso_name="$1"
    local profiledef_file="${2:-profiledef.sh}"
    
    log_info "设置ISO名称为: $iso_name"
    
    if [ ! -f "$profiledef_file" ]; then
        log_error "profiledef.sh文件不存在: $profiledef_file"
        return 1
    fi
    
    # 备份原始文件
    cp "$profiledef_file" "${profiledef_file}.bak"
    
    # 修改ISO名称
    sed -i.bak "s/iso_name=\".*\"/iso_name=\"$iso_name\"/" "$profiledef_file"
    
    if [ $? -eq 0 ]; then
        log_success "已设置ISO名称为: $iso_name"
        return 0
    else
        log_error "设置ISO名称失败"
        return 1
    fi
}

# 恢复profiledef.sh
restore_profiledef() {
    local profiledef_file="${1:-profiledef.sh}"
    
    if [ -f "${profiledef_file}.bak" ]; then
        mv "${profiledef_file}.bak" "$profiledef_file" 2>/dev/null || true
        log_success "已恢复原始profiledef.sh"
    fi
}

# 复制模型文件
copy_model_file() {
    local source_file="$1"
    local dest_dir="$2"
    
    if [ ! -f "$source_file" ]; then
        log_warning "模型文件不存在: $source_file"
        return 1
    fi
    
    # 确保目标目录存在
    mkdir -p "$dest_dir"
    
    # 复制文件
    cp "$source_file" "$dest_dir/"
    
    if [ $? -eq 0 ]; then
        local basename=$(basename "$source_file")
        log_success "已复制模型文件: $basename"
        return 0
    else
        log_error "复制模型文件失败"
        return 1
    fi
}

# 删除临时模型文件
remove_temp_model() {
    local model_file="$1"
    
    if [ -f "$model_file" ]; then
        rm -f "$model_file"
        local basename=$(basename "$model_file")
        log_success "已删除临时模型文件: $basename"
    fi
}

# 重命名ISO输出文件
rename_iso_output() {
    local source_pattern="$1"
    local dest_name="$2"
    local out_dir="${3:-out}"
    
    # 查找源文件
    local source_file=$(ls "$out_dir"/$source_pattern 2>/dev/null | head -n1)
    
    if [ -n "$source_file" ] && [ -f "$source_file" ]; then
        local dest_path="$out_dir/$dest_name"
        mv "$source_file" "$dest_path"
        log_success "输出文件重命名为: $dest_name"
        log_info "文件位置: $dest_path"
        return 0
    else
        log_warning "未找到输出文件: $source_pattern"
        return 1
    fi
}

# 运行mkarchiso构建
run_mkarchiso() {
    local work_dir="${1:-work}"
    local out_dir="${2:-out}"
    local verbose="${3:-true}"
    
    log_info "开始构建ISO镜像..."
    
    # 确保目录存在
    mkdir -p "$work_dir" "$out_dir"
    
    # 构建命令
    local cmd="mkarchiso"
    if [ "$verbose" = true ]; then
        cmd="$cmd -v"
    fi
    cmd="$cmd -w $work_dir -o $out_dir ."
    
    # 执行构建
    if $cmd; then
        log_success "ISO构建成功"
        return 0
    else
        log_error "ISO构建失败"
        return 1
    fi
}

# 主函数
main() {
    case "${1:-}" in
        "check-file")
            check_file_exists "$2" "$3"
            ;;
        "check-dir")
            check_dir_exists "$2" "$3"
            ;;
        "merge-packages")
            merge_packages "$2" "${@:3}"
            ;;
        "merge-scripts")
            merge_customize_scripts "$2" "${@:3}"
            ;;
        "set-iso-name")
            set_iso_name "$2" "$3"
            ;;
        "restore-profiledef")
            restore_profiledef "$2"
            ;;
        "copy-model")
            copy_model_file "$2" "$3"
            ;;
        "remove-model")
            remove_temp_model "$2"
            ;;
        "rename-iso")
            rename_iso_output "$2" "$3" "$4"
            ;;
        "build-iso")
            run_mkarchiso "$2" "$3" "$4"
            ;;
        *)
            echo "用法: $0 {check-file|check-dir|merge-packages|merge-scripts|set-iso-name|restore-profiledef|copy-model|remove-model|rename-iso|build-iso} [参数...]"
            echo ""
            echo "命令:"
            echo "  check-file <文件> <描述>"
            echo "  check-dir <目录> <描述>"
            echo "  merge-packages <输出文件> <输入文件1> [输入文件2] ..."
            echo "  merge-scripts <输出文件> <输入文件1> [输入文件2] ..."
            echo "  set-iso-name <ISO名称> [profiledef.sh路径]"
            echo "  restore-profiledef [profiledef.sh路径]"
            echo "  copy-model <源文件> <目标目录>"
            echo "  remove-model <模型文件>"
            echo "  rename-iso <源模式> <目标名称> [输出目录]"
            echo "  build-iso [工作目录] [输出目录] [是否详细]"
            exit 1
            ;;
    esac
}

# 如果直接执行此脚本
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    main "$@"
fi