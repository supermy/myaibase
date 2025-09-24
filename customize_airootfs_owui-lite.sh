#!/usr/bin/env bash
# Open WebUI Lite 配置脚本
# 提供 Open WebUI 的构建、部署和服务管理

set -euo pipefail

# 导入通用函数库
source /root/customize_airootfs_common.sh

log "开始 Open WebUI Lite 配置..."

# 检查 root 权限
check_root

# 配置 Git 代理
setup_git_proxy

# 配置变量
PKG=ollama-webui-lite
BUILD_USER=builder
PORT=3000

# 创建构建用户
create_builder_user "$BUILD_USER"

# 克隆代码库
clone_webui_repo() {
    local repo_url="https://github.com/ollama-webui/ollama-webui-lite.git"
    
    log "克隆 Open WebUI 代码库..."
    
    sudo -iu "$BUILD_USER" bash -xeuo pipefail <<EOF
cd /tmp
[ -d ollama-webui-lite ] && rm -rf ollama-webui-lite
git clone --depth 1 $repo_url
cd ollama-webui-lite
EOF
    
    success "代码库克隆完成"
}

# 构建项目
build_webui() {
    log "构建 Open WebUI..."
    
    cd "/tmp/$PKG"
    rm -rf package-lock.json node_modules
    
    # 安装依赖
    npm install --save-dev @sveltejs/adapter-static
    npm ci
    npm run build
    npm prune --omit=dev
    
    # 修复安全漏洞
    npm audit fix --omit=dev || true
    
    success "项目构建完成"
}

# 部署应用
deploy_webui() {
    log "部署 Open WebUI..."
    
    install -dm755 "/usr/share/webapps/$PKG"
    cp -a build/* "/usr/share/webapps/$PKG/"
    chown -R "$BUILD_USER:$BUILD_USER" "/usr/share/webapps/$PKG"
    
    success "应用部署完成"
}

# 创建启动脚本
create_start_script() {
    log "创建启动脚本..."
    
    cat > "/usr/local/bin/start-$PKG.sh" <<EOF
#!/bin/sh
cd /usr/share/webapps/$PKG
exec npx http-server -p $PORT -a 0.0.0.0
EOF
    
    chmod +x "/usr/local/bin/start-$PKG.sh"
    success "启动脚本创建完成"
}

# 配置服务
setup_service() {
    log "配置 Open WebUI 服务..."
    
    if systemctl is-system-running &>/dev/null; then
        cat > "/etc/systemd/system/$PKG.service" <<EOF
[Unit]
Description=Ollama WebUI Lite
After=network.target

[Service]
Type=simple
User=$BUILD_USER
WorkingDirectory=/usr/share/webapps/$PKG
ExecStart=/usr/local/bin/start-$PKG.sh
Restart=on-failure
Environment=NODE_ENV=production PORT=$PORT

[Install]
WantedBy=multi-user.target
EOF
        
        enable_service "$PKG" "true"
    else
        warn "无 systemd，已生成启动脚本：/usr/local/bin/start-$PKG.sh"
        nohup "/usr/local/bin/start-$PKG.sh" >/var/log/$PKG.log 2>&1 &
    fi
}

# 执行主要步骤
clone_webui_repo
build_webui
deploy_webui
create_start_script
setup_service

# 清理
log "清理构建文件..."
cleanup_temp_files "/tmp/$PKG" "/home/$BUILD_USER/.cache"
cleanup_build_deps

show_completion_info "Open WebUI Lite" "$PORT"
#echo ">>> 访问  http://$(hostname -I | awk '{print $1}'):$PORT"
