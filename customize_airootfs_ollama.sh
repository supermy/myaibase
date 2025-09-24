#!/usr/bin/env bash
# Ollama 服务配置脚本
# 提供 Ollama 用户、服务和模型管理功能

set -euo pipefail

# 导入通用函数库
source /root/customize_airootfs_common.sh

log "开始 Ollama 配置..."

# 检查 root 权限
check_root

# 配置 Git 代理
setup_git_proxy

# 创建 ollama 系统用户
create_system_user "ollama" "/usr/share/ollama" "/bin/false"
chmod 755 /usr/share/ollama

# 安装 Ollama  packages.x86_64 配置安装
# log "安装 Ollama..."
# pacman -S --needed --noconfirm ollama
# success "Ollama 安装完成"

# 创建 systemd 服务文件
log "创建 Ollama 服务文件..."
cat > /etc/systemd/system/ollama.service << 'EOF'
[Unit]
Description=Ollama Service
After=network-online.target
Documentation=https://ollama.com

[Service]
Type=exec
User=ollama
Group=ollama
ExecStart=/usr/bin/ollama serve
Environment="OLLAMA_HOST=0.0.0.0:11434"
Environment="OLLAMA_MODELS=/usr/share/ollama/.ollama/models"
# 如需指定GPU，可取消注释下一行并修改设备编号（例如 "0" 或 "0,1"）
# Environment="CUDA_VISIBLE_DEVICES=0"
Restart=on-failure
RestartSec=3
RestartPreventExitStatus=137
RestartForceExitStatus=SIGKILL
RestartLimit=5
TimeoutStartSec=300
TimeoutStopSec=30
StandardOutput=journal
StandardError=journal

# 安全加固
#NoNewPrivileges=yes
#PrivateTmp=yes
#ProtectSystem=strict
#ProtectHome=yes
#ProtectKernelTunables=yes
#ProtectKernelModules=yes
#ProtectControlGroups=yes
#RestrictRealtime=yes
#RestrictSUIDSGID=yes
#MemoryDenyWriteExecute=yes
#LockPersonality=yes

[Install]
WantedBy=multi-user.target
EOF

# 创建环境变量文件
log "配置环境变量..."
cat > /etc/environment << 'EOF'
OLLAMA_HOST=0.0.0.0
OLLAMA_MODELS=/usr/share/ollama/.ollama/models
EOF

# 设置 Ollama 模型存储目录权限
echo "模型存储路径: /usr/share/ollama/.ollama/models"
mkdir -p /usr/share/ollama/.ollama/models
chown -R ollama:ollama /usr/share/ollama
chmod 755 -R /usr/share/ollama

# 生成 SSH 密钥
# ssh-keygen -t ed25519 -f /etc/ssh/ssh_host_ed25519_key -N "" || true
# ssh-keygen -t rsa -b 4096 -f /etc/ssh/ssh_host_rsa_key -N "" || true




log "生成 SSH 密钥..."
echo 'export OLLAMA_MODELS=/usr/share/ollama/.ollama/models' >> ~/.bashrc
source ~/.bashrc
ssh-keygen -t ed25519 -f /var/lib/ollama/.ollama/id_ed25519 -N ""
chown -R ollama:ollama /var/lib/ollama/.ollama/
chmod 600 /var/lib/ollama/.ollama/id_ed25519 
chmod 644 /var/lib/ollama/.ollama/id_ed25519.pub
success "SSH 密钥生成完成"

log "启动 Ollama 服务..."
sudo -u ollama /usr/bin/ollama serve &

# 等待几秒，确保服务初始化和监听端口（可选但推荐）
sleep 5


# 查找并导入模型
import_ollama_models() {
    local model_dir="/opt/models"
    
    if [[ -d "$model_dir" ]]; then
        log "发现模型目录 $model_dir，正在导入模型..."
        
        for model in "$model_dir"/*.gguf; do
            if [[ -f "$model" ]]; then
                local model_name=$(basename "$model" .gguf)
                log "导入模型: $model_name"
                
                # 创建 Modelfile
                cat > /tmp/Modelfile << EOF
FROM $model
PARAMETER temperature 0.7
PARAMETER top_p 0.9
PARAMETER num_ctx 32768
TEMPLATE "{{ if .System }}
{{ .System }}
{{ end }}{{ if .Prompt }}
{{ .Prompt }}
{{ end }}
{{ .Response }}"
EOF
                
                # 导入模型
                ollama create "$model_name" -f /tmp/Modelfile || warn "导入模型 $model_name 失败"
                rm -f /tmp/Modelfile
            fi
        done
        
        # 清理源文件
        log "清理模型源文件..."
        rm -rf "$model_dir"
        success "模型导入完成"
    else
        log "未找到模型目录 $model_dir"
    fi
}

# 导入模型
import_ollama_models

# 启用并启动服务
enable_service "ollama" "true"

show_completion_info "Ollama" "11434"
