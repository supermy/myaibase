#!/bin/bash
# customize_airootfs 通用函数库
# 提供通用的配置函数，避免重复代码

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

# 检查 root 权限
check_root() {
    if [[ $EUID -ne 0 ]]; then
        error "此脚本必须以 root 权限运行"
        exit 1
    fi
}

# 配置 Git 代理
setup_git_proxy() {
    local proxy_url="${1:-http://127.0.0.1:7890}"
    log "配置 Git 代理: $proxy_url"
    
    git config --global http.proxy "$proxy_url"
    git config --global https.proxy "$proxy_url"
    git config --global http.sslVerify false
    success "Git 代理配置完成"
}

# 创建构建用户
create_builder_user() {
    local username="${1:-builder}"
    log "创建构建用户: $username"
    
    if ! id "$username" &>/dev/null; then
        useradd -m -G wheel -s /bin/bash "$username"
        echo "$username ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers
        success "$username 用户已创建"
    else
        log "$username 用户已存在，继续使用"
    fi
}

# 配置基础网络
setup_basic_network() {
    log "配置基础网络..."
    systemctl enable iwd
    success "网络配置完成"
}

# 添加软件源
add_repositories() {
    log "添加软件源..."
    
    # 添加 archlinuxcn 源
    if ! grep -q "^\[archlinuxcn\]" /etc/pacman.conf; then
        cat >> /etc/pacman.conf << EOF

[archlinuxcn]
SigLevel = Optional TrustAll
Server = https://mirrors.tuna.tsinghua.edu.cn/archlinuxcn/\$arch
# [local]
# SigLevel = Optional TrustAll
# Server = file:///local_repo
EOF
        success "archlinuxcn/local 源已添加"
    fi
    
    # 设置镜像源
    echo 'Server = https://mirrors.tuna.tsinghua.edu.cn/archlinux/$repo/os/$arch' > /etc/pacman.d/mirrorlist
    success "镜像源配置完成"
}

# 更新系统
update_system() {
    log "更新系统..."
    pacman -Syy --noconfirm
    pacman -Syu --noconfirm
    success "系统更新完成"
}

# 设置系统 locale
setup_locale() {
    local locale="${1:-zh_CN.UTF-8}"
    log "设置系统 locale: $locale"
    
    if ! grep -q "^$locale UTF-8" /etc/locale.gen; then
        sed -i "s/^#$locale UTF-8/$locale UTF-8/" /etc/locale.gen
    fi
    locale-gen
    echo "LANG=$locale" > /etc/locale.conf
    export LANG=$locale
    success "locale 设置完成"
}

# 创建系统用户
create_system_user() {
    local username="$1"
    local home_dir="${2:-/usr/share/$username}"
    local shell="${3:-/bin/false}"
    
    log "创建系统用户: $username"
    
    if ! id "$username" &>/dev/null; then
        useradd -r -s "$shell" -U -m -d "$home_dir" "$username" 2>/dev/null || true
        success "$username 系统用户已创建"
    else
        log "$username 系统用户已存在"
    fi
}

# 启用并启动服务
enable_service() {
    local service_name="$1"
    local start_now="${2:-false}"
    
    log "启用服务: $service_name"
    systemctl daemon-reload
    systemctl enable "$service_name"
    
    if [[ "$start_now" == "true" ]] && systemctl is-system-running &>/dev/null; then
        systemctl start "$service_name" || warn "启动 $service_name 服务失败"
    fi
    
    success "$service_name 服务已启用"
}

# 清理构建依赖
cleanup_build_deps() {
    log "清理构建依赖..."
    pacman -Rns --noconfirm base-devel go rust llvm 2>/dev/null || true
    pacman -Scc --noconfirm
    success "构建依赖清理完成"
}

# 清理临时文件
cleanup_temp_files() {
    local paths=("$@")
    log "清理临时文件..."
    
    for path in "${paths[@]}"; do
        if [[ -d "$path" || -f "$path" ]]; then
            rm -rf "$path" && success "已清理: $path"
        fi
    done
    
    # 清理日志文件
    find /var/log -type f -name "*.log" -exec truncate -s 0 {} \; 2>/dev/null || true
    success "临时文件清理完成"
}

# 获取当前用户
get_current_user() {
    if [[ -n "${SUDO_USER:-}" ]]; then
        echo "$SUDO_USER"
    else
        whoami
    fi
}

# 添加用户到组
add_user_to_group() {
    local username="$1"
    local group="$2"
    
    log "添加用户 $username 到组 $group"
    usermod -a -G "$group" "$username"
    success "用户组添加完成"
}

# 配置中文字体
setup_chinese_fonts() {
    local font_name="${1:-wqy-microhei}"
    
    log "配置中文字体: $font_name"
    
    # 创建字体配置文件
    mkdir -p /etc/fonts/conf.d
    cat > /etc/fonts/conf.d/99-chinese-fonts.conf << EOF
<?xml version="1.0"?>
<!DOCTYPE fontconfig SYSTEM "fonts.dtd">
<fontconfig>
    <match>
        <test name="family"><string>serif</string></test>
        <edit name="family" mode="prepend" binding="strong">
            <string>$font_name</string>
        </edit>
    </match>
    <match>
        <test name="family"><string>sans-serif</string></test>
        <edit name="family" mode="prepend" binding="strong">
            <string>$font_name</string>
        </edit>
    </match>
    <match>
        <test name="family"><string>monospace</string></test>
        <edit name="family" mode="prepend" binding="strong">
            <string>${font_name}-mono</string>
        </edit>
    </match>
</fontconfig>
EOF
    
    success "中文字体配置完成"
}

# 显示完成信息
show_completion_info() {
    local service_name="$1"
    local port="${2:-}"
    
    echo "========================================"
    success "$service_name 配置完成！"
    
    if [[ -n "$port" ]]; then
        local ip=$(ip -4 -o addr show scope global 2>/dev/null | awk '{print $4}' | cut -d/ -f1 | head -n1 || echo "localhost")
        echo "访问地址: http://$ip:$port"
    fi
    
    echo "========================================"
}