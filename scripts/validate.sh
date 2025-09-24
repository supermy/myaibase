#!/bin/bash

# MyAIBase 验证和测试脚本
# 用于验证构建环境和运行测试

set -euo pipefail

# 脚本目录
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# 导入通用函数
source "$SCRIPT_DIR/build-common.sh"

# GGUF文件路径（从环境变量或参数获取）
GGUF_FILE="${GGUF_FILE:-../myaibase/airootfs/opt/models/Qwen3-0.6B-Q8_0.gguf}"

# 显示帮助信息
show_help() {
    cat << EOF
MyAIBase 验证和测试脚本

用法: $0 [选项] [命令]

选项:
    -m, --model <文件>         GGUF模型文件路径 (默认: $GGUF_FILE)
    -h, --help                 显示此帮助信息

命令:
    deps                       检查系统依赖
    env                        验证构建环境
    all                        运行完整验证（默认）

示例:
    $0                         # 运行完整验证
    $0 deps                    # 仅检查依赖
    $0 env                     # 仅验证环境
    $0 -m /path/to/model.gguf  # 使用指定模型文件验证

EOF
}

# 检查系统依赖
check_dependencies() {
    log_info "检查必要依赖..."
    
    local missing_deps=()
    
    # 检查mkarchiso
    if ! command -v mkarchiso >/dev/null 2>&1; then
        missing_deps+=("archiso")
    fi
    
    # 检查基本命令
    if ! command -v sort >/dev/null 2>&1; then
        missing_deps+=("coreutils")
    fi
    
    if ! command -v cat >/dev/null 2>&1; then
        missing_deps+=("coreutils")
    fi
    
    if ! command -v sed >/dev/null 2>&1; then
        missing_deps+=("sed")
    fi
    
    if [ ${#missing_deps[@]} -ne 0 ]; then
        log_error "缺少必要依赖: ${missing_deps[*]}"
        echo
        echo "安装命令:"
        echo "  sudo pacman -S archiso coreutils sed"
        return 1
    fi
    
    log_success "所有依赖已安装"
    return 0
}

# 验证构建环境
validate_environment() {
    log_info "验证构建环境..."
    
    # 切换到项目根目录
    cd "$PROJECT_ROOT"
    
    echo
    log_info "1. 检查基础文件..."
    
    # 检查基础文件
    check_file_exists "packages.x86_64-base" "基础软件包列表" || return 1
    check_file_exists "packages.x86_64-ai" "AI软件包列表" || return 1
    check_file_exists "packages.x86_64-mini" "最小化软件包列表" || return 1
    check_file_exists "customize_airootfs.sh" "基础自定义脚本" || return 1
    check_file_exists "customize_airootfs_chinese-support.sh" "中文支持脚本" || return 1
    check_file_exists "customize_airootfs_ollama.sh" "Ollama脚本" || return 1
    check_file_exists "customize_airootfs_owui-lite.sh" "Open WebUI脚本" || return 1
    check_file_exists "customize_airootfs_librechat.sh" "LibreChat脚本" || return 1
    check_file_exists "customize_airootfs_common.sh" "通用函数库" || return 1
    check_file_exists "profiledef.sh" "配置文件" || return 1
    
    echo
    log_info "2. 检查目录结构..."
    
    # 检查目录结构
    check_dir_exists "airootfs" "airootfs" || return 1
    check_dir_exists "airootfs/opt" "airootfs/opt" || return 1
    check_dir_exists "airootfs/opt/models" "airootfs/opt/models" || return 1
    check_dir_exists "airootfs/root" "airootfs/root" || return 1
    check_dir_exists "efiboot" "efiboot" || return 1
    check_dir_exists "grub" "grub" || return 1
    check_dir_exists "syslinux" "syslinux" || return 1
    
    echo
    log_info "3. 检查模型文件..."
    
    # 检查模型文件（可选）
    if [ -f "$GGUF_FILE" ]; then
        log_success "模型文件存在: $GGUF_FILE"
    else
        log_warning "模型文件不存在: $GGUF_FILE"
        log_info "如果需要构建AI版本，请提供有效的GGUF模型文件"
    fi
    
    echo
    log_info "4. 检查配置文件..."
    
    # 检查pacman配置
    if [ -f "pacman.conf" ]; then
        log_success "pacman配置文件存在"
    else
        log_warning "pacman配置文件不存在，将使用系统默认配置"
    fi
    
    # 检查bootstrap软件包
    if [ -f "bootstrap_packages.x86_64" ]; then
        log_success "bootstrap软件包列表存在"
    else
        log_warning "bootstrap软件包列表不存在"
    fi
    
    echo
    log_info "5. 检查本地仓库脚本..."
    
    # 检查本地仓库脚本
    if [ -f "scripts/local_repo.sh" ]; then
        log_success "本地仓库脚本存在"
        if [ -x "scripts/local_repo.sh" ]; then
            log_success "本地仓库脚本有执行权限"
        else
            log_warning "本地仓库脚本没有执行权限"
        fi
    else
        log_warning "本地仓库脚本不存在"
    fi
    
    echo
    log_info "6. 检查其他文件..."
    
    # 检查其他重要文件
    if [ -f "init-arch.sh" ]; then
        log_success "初始化脚本存在"
    else
        log_warning "初始化脚本不存在"
    fi
    
    if [ -f "README.md" ]; then
        log_success "项目文档存在"
    else
        log_warning "项目文档不存在"
    fi
    
    log_success "环境验证完成！"
    return 0
}

# 运行完整测试
run_full_tests() {
    log_info "运行完整测试套件..."
    
    local failed_tests=()
    
    # 测试依赖检查
    echo
    if ! check_dependencies; then
        failed_tests+=("依赖检查")
    fi
    
    # 测试环境验证
    echo
    if ! validate_environment; then
        failed_tests+=("环境验证")
    fi
    
    # 测试脚本执行权限
    echo
    log_info "测试脚本执行权限..."
    if [ -f "$SCRIPT_DIR/build-mini.sh" ] && [ ! -x "$SCRIPT_DIR/build-mini.sh" ]; then
        log_warning "build-mini.sh 没有执行权限"
        chmod +x "$SCRIPT_DIR/build-mini.sh" || failed_tests+=("build-mini.sh权限设置")
    fi
    
    if [ -f "$SCRIPT_DIR/build-base.sh" ] && [ ! -x "$SCRIPT_DIR/build-base.sh" ]; then
        log_warning "build-base.sh 没有执行权限"
        chmod +x "$SCRIPT_DIR/build-base.sh" || failed_tests+=("build-base.sh权限设置")
    fi
    
    if [ -f "$SCRIPT_DIR/build-ai.sh" ] && [ ! -x "$SCRIPT_DIR/build-ai.sh" ]; then
        log_warning "build-ai.sh 没有执行权限"
        chmod +x "$SCRIPT_DIR/build-ai.sh" || failed_tests+=("build-ai.sh权限设置")
    fi
    
    if [ -f "$SCRIPT_DIR/build-common.sh" ] && [ ! -x "$SCRIPT_DIR/build-common.sh" ]; then
        log_warning "build-common.sh 没有执行权限"
        chmod +x "$SCRIPT_DIR/build-common.sh" || failed_tests+=("build-common.sh权限设置")
    fi
    
    # 测试结果汇总
    echo
    if [ ${#failed_tests[@]} -eq 0 ]; then
        log_success "所有测试通过！"
        return 0
    else
        log_error "测试失败的项目: ${failed_tests[*]}"
        return 1
    fi
}

# 主函数
main() {
    local command="all"
    
    # 解析命令行参数
    while [[ $# -gt 0 ]]; do
        case $1 in
            -m|--model)
                GGUF_FILE="$2"
                shift 2
                ;;
            -h|--help)
                show_help
                exit 0
                ;;
            deps|env|all)
                command="$1"
                shift
                ;;
            *)
                log_error "未知参数: $1"
                show_help
                exit 1
                ;;
        esac
    done
    
    log_info "MyAIBase 验证和测试脚本"
    log_info "模型文件: $GGUF_FILE"
    echo
    
    case "$command" in
        "deps")
            check_dependencies
            ;;
        "env")
            validate_environment
            ;;
        "all")
            run_full_tests
            ;;
        *)
            log_error "未知命令: $command"
            show_help
            exit 1
            ;;
    esac
}

# 如果直接执行此脚本
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    main "$@"
fi