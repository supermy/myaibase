#!/bin/bash
# MyAIBase 本地软件仓库构建脚本
# 用于构建和管理本地软件包仓库

set -e  # 遇到错误立即退出

# 配置变量
BUILD_USER="${BUILD_USER:-builder}"
PACKAGE_NAME="${PACKAGE_NAME:-fbterm}"
LOCAL_REPO_DIR="${LOCAL_REPO_DIR:-../local_repo}"
PACMAN_CONF="${PACMAN_CONF:-../pacman.conf}"
REPO_NAME="${REPO_NAME:-mylocal}"

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 日志函数
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# 检查依赖
check_dependencies() {
    log_info "检查必要依赖..."
    
    local missing_deps=()
    
    if ! command -v yay &> /dev/null; then
        missing_deps+=("yay")
    fi
    
    if ! command -v makepkg &> /dev/null; then
        missing_deps+=("base-devel")
    fi
    
    if ! command -v repo-add &> /dev/null; then
        missing_deps+=("pacman")
    fi
    
    if [ ${#missing_deps[@]} -ne 0 ]; then
        log_error "缺少依赖: ${missing_deps[*]}"
        log_info "请安装: sudo pacman -S yay base-devel"
        exit 1
    fi
    
    log_info "所有依赖已满足"
}

# 创建本地仓库目录
create_local_repo() {
    log_info "创建本地仓库目录: $LOCAL_REPO_DIR"
    
    if [ ! -d "$LOCAL_REPO_DIR" ]; then
        mkdir -p "$LOCAL_REPO_DIR"
        log_info "已创建目录: $LOCAL_REPO_DIR"
    else
        log_info "目录已存在: $LOCAL_REPO_DIR"
    fi
}

# 构建软件包
build_package() {
    local package=$1
    log_info "构建软件包: $package"
    
    # 检查是否已存在构建目录
    if [ -d "$package" ]; then
        log_warn "目录已存在，删除旧目录: $package"
        rm -rf "$package"
    fi
    
    # 获取源码
    sudo -u "$BUILD_USER" yay -G "$package" || {
        log_error "获取 $package 源码失败"
        return 1
    }
    
    cd "$package" || {
        log_error "进入目录失败: $package"
        return 1
    }
    
    # 构建软件包
    sudo -u "$BUILD_USER" makepkg -sc || {
        log_error "构建 $package 失败"
        cd ..
        return 1
    }
    
    # 查找构建好的软件包
    local pkg_file=$(find . -name "*.pkg.tar.*" -type f ! -name '*-debug-*'| head -n1)
    
    if [ -z "$pkg_file" ]; then
        log_error "未找到构建的软件包文件"
        cd ..
        return 1
    fi
    
    log_info "找到软件包: $pkg_file"
    
    # 复制到本地仓库
    cp "$pkg_file" "../$LOCAL_REPO_DIR/" || {
        log_error "复制软件包失败"
        cd ..
        return 1
    }
    
    log_info "已复制软件包到本地仓库"
    cd ..
    
    # 返回软件包文件名
    echo "$pkg_file"
}

# 备份pacman配置
backup_pacman_conf() {
    if [ -f "$PACMAN_CONF" ]; then
        cp "$PACMAN_CONF" "${PACMAN_CONF}.bak"
        log_info "已备份pacman配置: ${PACMAN_CONF}.bak"
    fi
}

# 配置pacman
configure_pacman() {
    log_info "配置pacman仓库: [$REPO_NAME]"
    
    # 检查是否已经存在指定仓库配置
    if grep -q "^\[$REPO_NAME\]" "$PACMAN_CONF" 2>/dev/null; then
        log_warn "仓库配置 [$REPO_NAME] 已存在，跳过添加"
    else
        cat >> "$PACMAN_CONF" << EOF

[$REPO_NAME]
SigLevel = Optional TrustAll
Server = file://$(cd "$LOCAL_REPO_DIR" && pwd)
EOF
        log_info "已添加仓库配置 [$REPO_NAME] 到pacman.conf"
    fi
}

# 更新仓库数据库
update_repo_db() {
    local pkg_file=$1
    local pkg_name=$(basename "$pkg_file")
    local db_file="$LOCAL_REPO_DIR/$REPO_NAME.db.tar.gz"
    
    log_info "更新仓库数据库 [$REPO_NAME]: $pkg_name"
    
    # 创建或更新数据库
    if [ -f "$db_file" ]; then
        repo-add "$db_file" "$LOCAL_REPO_DIR/$pkg_name" || {
            log_error "更新仓库数据库 [$REPO_NAME] 失败"
            return 1
        }
    else
        repo-add "$db_file" "$LOCAL_REPO_DIR/$pkg_name" || {
            log_error "创建仓库数据库 [$REPO_NAME] 失败"
            return 1
        }
    fi
    
    log_info "仓库数据库 [$REPO_NAME] 更新完成"
}

# 测试仓库
test_repo() {
    log_info "测试本地仓库"
    
    local dummy_db="/tmp/dummydb_$$"
    mkdir -p "$dummy_db"
    
    # 更新数据库
    pacman --dbpath "$dummy_db" --config "$PACMAN_CONF" -Sy || {
        log_error "更新pacman数据库失败"
        rm -rf "$dummy_db"
        return 1
    }
    
    # 搜索软件包
    log_info "搜索软件包: $PACKAGE_NAME"
    pacman --dbpath "$dummy_db" --config "$PACMAN_CONF" -Ss "$PACKAGE_NAME" || {
        log_warn "在仓库中未找到软件包: $PACKAGE_NAME"
    }
    
    # 显示软件包信息
    log_info "软件包信息:"
    pacman --dbpath "$dummy_db" --config "$PACMAN_CONF" -Si "$PACKAGE_NAME" 2>/dev/null || {
        log_warn "无法获取软件包信息: $PACKAGE_NAME"
    }
    
    # 清理临时数据库
    rm -rf "$dummy_db"
    log_info "仓库测试完成"
}

# 清理函数
cleanup() {
    log_info "清理临时文件"
    
    # 删除构建目录
    if [ -d "$PACKAGE_NAME" ]; then
        rm -rf "$PACKAGE_NAME"
        log_info "已删除构建目录: $PACKAGE_NAME"
    fi
}

# 主函数
main() {
    log_info "开始构建本地软件仓库"
    
    # 设置错误处理
    trap cleanup EXIT
    
    check_dependencies
    create_local_repo
    backup_pacman_conf
    
    # 构建软件包
    local pkg_file
    pkg_file=$(build_package "$PACKAGE_NAME")
    
    if [ $? -ne 0 ]; then
        log_error "软件包构建失败"
        exit 1
    fi
    
    configure_pacman
    update_repo_db "$pkg_file"
    test_repo
    
    log_info "本地软件仓库构建完成！"
    log_info "仓库位置: $(cd "$LOCAL_REPO_DIR" && pwd)"
    log_info "软件包: $(basename "$pkg_file")"
}

# 显示使用说明
usage() {
    cat << EOF
使用方法: $0 [选项]

选项:
    -p, --package NAME      指定要构建的软件包名称 (默认: fbterm)
    -u, --user USER        指定构建用户 (默认: builder)
    -d, --dir DIR          指定本地仓库目录 (默认: ../local_repo)
    -c, --config FILE      指定pacman配置文件 (默认: ../pacman.conf)
    -r, --repo NAME        指定仓库名称 (默认: mylocal)
    -h, --help             显示此帮助信息

环境变量:
    BUILD_USER              构建用户
    PACKAGE_NAME            软件包名称
    LOCAL_REPO_DIR          本地仓库目录
    PACMAN_CONF             pacman配置文件
    REPO_NAME               仓库名称

示例:
    $0                              # 构建默认fbterm包
    $0 -p neofetch                  # 构建neofetch包
    $0 -u myuser -d /tmp/repo       # 使用myuser用户，仓库目录为/tmp/repo
    $0 -r customrepo                # 使用customrepo作为仓库名称
    BUILD_USER=dev $0 -p htop       # 使用dev用户构建htop

EOF
}

# 解析命令行参数
while [[ $# -gt 0 ]]; do
    case $1 in
        -p|--package)
            PACKAGE_NAME="$2"
            shift 2
            ;;
        -u|--user)
            BUILD_USER="$2"
            shift 2
            ;;
        -d|--dir)
            LOCAL_REPO_DIR="$2"
            shift 2
            ;;
        -c|--config)
            PACMAN_CONF="$2"
            shift 2
            ;;
        -r|--repo)
            REPO_NAME="$2"
            shift 2
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            log_error "未知选项: $1"
            usage
            exit 1
            ;;
    esac
done

# 检查是否以root权限运行
if [ "$EUID" -ne 0 ]; then
    log_error "请以root权限运行此脚本"
    log_info "使用: sudo $0"
    exit 1
fi

# 执行主函数
main