#!/usr/bin/env bash
# 文件：auto-owui-lite-fixed.sh
# 走 http 代理
git config --global http.proxy http://127.0.0.1:7890
git config --global https.proxy http://127.0.0.1:7890

# 如果代理用自签证书，先关闭校验（仅临时）
git config --global http.sslVerify false


set -euo pipefail

PKG=ollama-webui-lite
BUILD_USER=builder
PORT=3000

# 1. 基础工具 ------------------------------------------------------------
# pacman -S --needed --noconfirm sudo base-devel git nodejs npm

# 2. 构建用户 ------------------------------------------------------------
if ! id "$BUILD_USER" &>/dev/null; then
    useradd -m -G wheel -s /bin/bash "$BUILD_USER"
    echo "$BUILD_USER ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers
fi

# 3. 拉代码 --------------------------------------------------------------
sudo -iu "$BUILD_USER" bash -xeuo pipefail <<'EOF'
cd /tmp
[ -d ollama-webui-lite ] && rm -rf ollama-webui-lite
git clone --depth 1 https://github.com/ollama-webui/ollama-webui-lite.git
cd ollama-webui-lite
EOF

# 4. 安装依赖（含构建必需的 adapter） ------------------------------------
cd /tmp/$PKG
rm -rf package-lock.json node_modules

# 官方 lock 文件缺 adapter，先补上再 ci
#npm pkg set devDependencies.@sveltejs/adapter-static='^2.0.0'
npm install --save-dev @sveltejs/adapter-static
npm ci 
npm run build  
npm prune --omit=dev  
#npm ci --omit=dev

# 5. 生成 SvelteKit 内部文件 → 再构建 ------------------------------------
#npm run sync        # 生成 .svelte-kit/tsconfig.json 等
#npm run build       # vite build

# 6. 可选：修漏洞（不破坏 lock）
npm audit fix --omit=dev ||true

# 7. 部署 ----------------------------------------------------------------
install -dm755 /usr/share/webapps/$PKG
cp -a build/* /usr/share/webapps/$PKG/
chown -R $BUILD_USER:$BUILD_USER /usr/share/webapps/$PKG

# 8. 启动脚本（systemd 或手动通用） --------------------------------------
cat >/usr/local/bin/start-$PKG.sh <<EOF
#!/bin/sh
cd /usr/share/webapps/$PKG
#exec /usr/bin/node server.js
exec npx http-server -p 3000 -a 0.0.0.0
EOF
chmod +x /usr/local/bin/start-$PKG.sh

# 9. systemd 判断（同上一版通用函数） ------------------------------------
if systemctl is-system-running &>/dev/null; then
    cat >/etc/systemd/system/$PKG.service <<EOF
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
    systemctl daemon-reload
    systemctl enable --now $PKG
else
    echo ">>> 无 systemd，已生成启动脚本：/usr/local/bin/start-$PKG.sh"
    nohup /usr/local/bin/start-$PKG.sh >/var/log/$PKG.log 2>&1 &
fi

# 10. 清理 ---------------------------------------------------------------
pacman -Rns --noconfirm base-devel go rust llvm || true
pacman -Scc --noconfirm
rm -rf /tmp/$PKG /home/$BUILD_USER/.cache
find /var/log -type f -name "*.log" -exec truncate -s 0 {} \;

echo ">>> $PKG 构建&部署完成"
IP=$(ip -4 -o addr show scope global | awk '{print $4}' | cut -d/ -f1 | head -n1)
echo ">>> 访问  http://$IP:3000"
#echo ">>> 访问  http://$(hostname -I | awk '{print $1}'):$PORT"
