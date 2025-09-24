#!/bin/bash

# MyAIBase 简化构建脚本
set -euo pipefail

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# 日志函数
log() { echo -e "${BLUE}ℹ️  $1${NC}"; }
success() { echo -e "${GREEN}✅ $1${NC}"; }
warn() { echo -e "${YELLOW}⚠️  $1${NC}"; }
error() { echo -e "${RED}❌ $1${NC}"; }

# 通用检查函数
check() {
    local type=$1 file=$2 desc=$3
    if [ "$type" = "file" ] && [ ! -f "$file" ]; then
        error "$desc 不存在: $file"; return 1
    elif [ "$type" = "dir" ] && [ ! -d "$file" ]; then
        error "$desc 目录不存在: $file"; return 1
    fi
    success "$desc 存在: $file"
}

# 合并文件（保持顺序，不去重）
merge() {
    local output=$1; shift
    cat "$@" > "$output"
    success "合并完成: $output"
}

# 设置ISO名称
set_iso_name() {
    local name=$1
    cp profiledef.sh profiledef.sh.bak
    sed -i.bak "s/iso_name=\".*\"/iso_name=\"$name\"/" profiledef.sh
    success "设置ISO名称: $name"
}

# 恢复配置
restore() {
    [ -f profiledef.sh.bak ] && mv profiledef.sh.bak profiledef.sh
    success "恢复原始配置"
}

# 构建ISO
build_iso() {
    local work_dir=$1 out_dir=$2 verbose=$3
    mkdir -p "$work_dir" "$out_dir"
    
    local cmd="mkarchiso"
    [ "$verbose" = true ] && cmd="$cmd -v"
    cmd="$cmd -w $work_dir -o $out_dir ."
    
    if $cmd; then
        success "ISO构建成功"
        return 0
    else
        error "ISO构建失败"
        return 1
    fi
}

# 重命名输出
rename_output() {
    local pattern=$1 name=$2 dir=$3
    local file=$(ls "$dir"/$pattern 2>/dev/null | head -n1)
    [ -n "$file" ] && mv "$file" "$dir/$name" && success "重命名为: $name"
}

# 显示帮助
show_help() {
    cat << EOF
MyAIBase 简化构建脚本

用法: $0 <类型> [选项]

类型:
    mini    最小化ISO
    base    基础ISO（含中文支持）
    ai      AI ISO（完整功能）

选项:
    -w <目录>    工作目录 (默认: work)
    -o <目录>    输出目录 (默认: out)
    -n <名称>    ISO名称前缀
    -q           快速模式（静默）
    -m <文件>    模型文件（仅AI类型，默认: ../models/Qwen3-0.6B-Q8_0.gguf）
    -h           显示帮助

示例:
    $0 mini                    # 构建最小化ISO
    $0 base -q                 # 快速构建基础ISO
    $0 ai                      # 使用默认模型文件
    $0 ai -m model.gguf       # 指定模型文件
    $0 mini -w /tmp -o /iso   # 指定目录
EOF
}

# 主构建函数
build() {
    local type=$1; shift
    local work_dir="work" out_dir="out" iso_name="" quick=false model_file=""
    
    # 解析参数
    while [[ $# -gt 0 ]]; do
        case $1 in
            -w) work_dir=$2; shift 2 ;;
            -o) out_dir=$2; shift 2 ;;
            -n) iso_name=$2; shift 2 ;;
            -q) quick=true; shift ;;
            -m) model_file=$2; shift 2 ;;
            *) error "未知参数: $1"; return 1 ;;
        esac
    done
    
    # 设置默认名称
    [ -z "$iso_name" ] && iso_name="archlinux-$type"
    local final_name="myaibase-$type-$(date +%Y%m%d).iso"
    
    log "开始构建 $type ISO..."
    log "工作目录: $work_dir"
    log "输出目录: $out_dir"
    log "ISO名称: $iso_name"
    
    # 检查必要文件
    check file "packages.x86_64-$type" "软件包列表"
    check file "profiledef.sh" "配置文件"
    
    # 类型特定检查
case $type in
    mini)
        check file "customize_airootfs.sh" "自定义脚本"
        check file "customize_airootfs_common.sh" "通用函数库"
        cp "packages.x86_64-mini" "packages.x86_64"
        cp "customize_airootfs.sh" "airootfs/root/customize_airootfs.sh"
        cp "customize_airootfs_common.sh" "airootfs/root/customize_airootfs_common.sh"
        ;;
    base)
        check file "customize_airootfs.sh" "基础脚本"
        check file "customize_airootfs_chinese-support.sh" "中文脚本"
        check file "customize_airootfs_common.sh" "通用函数库"
        merge "packages.x86_64" "packages.x86_64-base"
        merge "airootfs/root/customize_airootfs.sh" \
              "customize_airootfs.sh" \
              "customize_airootfs_chinese-support.sh"
        cp "customize_airootfs_common.sh" "airootfs/root/customize_airootfs_common.sh"
        ;;
    ai)
        check file "customize_airootfs.sh" "基础脚本"
        check file "customize_airootfs_ollama.sh" "Ollama脚本"
        check file "customize_airootfs_librechat.sh" "LibreChat脚本"
        check file "customize_airootfs_common.sh" "通用函数库"
        # 设置默认模型文件路径
        if [ -z "$model_file" ]; then
            model_file="../models/Qwen3-0.6B-Q8_0.gguf"
        fi
        # 模型文件检查（可选）
        if [ -n "$model_file" ]; then
            if [ -f "$model_file" ]; then
                check file "$model_file" "模型文件"
            else
                warn "模型文件不存在: $model_file，继续构建但不包含模型文件"
                model_file=""
            fi
        fi
        
        merge "packages.x86_64" "packages.x86_64-base" "packages.x86_64-ai"
        merge "airootfs/root/customize_airootfs.sh" \
              "customize_airootfs.sh" \
              "customize_airootfs_ollama.sh" \
              "customize_airootfs_librechat.sh"
        cp "customize_airootfs_common.sh" "airootfs/root/customize_airootfs_common.sh"
        
        # 复制模型文件
        if [ -n "$model_file" ] && [ -f "$model_file" ]; then
            mkdir -p "airootfs/opt/models"
            cp "$model_file" "airootfs/opt/models/"
            success "已复制模型文件"
        fi
        ;;
    *) error "未知类型: $type"; return 1 ;;
esac
    
    # 设置ISO名称并构建
    set_iso_name "$iso_name"
    
    local verbose=true
    [ "$quick" = true ] && verbose=false
    
    if build_iso "$work_dir" "$out_dir" "$verbose"; then
        # rename_output "${iso_name}-x86_64.iso" "$final_name" "$out_dir"
        success "$type ISO构建完成！"
        success "输出文件: $out_dir/$final_name"
        restore
        return 0
    else
        restore
        return 1
    fi
}

# 主函数
main() {
    [ $# -eq 0 ] && { show_help; exit 0; }
    
    case $1 in
        -h|--help) show_help; exit 0 ;;
        mini|base|ai) build "$@" ;;
        *) error "无效类型: $1"; show_help; exit 1 ;;
    esac
}

# 如果直接执行
[ "${BASH_SOURCE[0]}" = "${0}" ] && main "$@"