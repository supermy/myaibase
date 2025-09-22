#!/bin/bash



# 创建 Ollama 系统服务
echo "正在配置 Ollama 系统服务..."

# 1. 创建 ollama 系统用户和用户组（增强安全性）
useradd -r -s /bin/false -U -m -d /usr/share/ollama ollama 2>/dev/null || true

# 2. 创建服务文件
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
RestartSec=10
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

# 3. 设置 Ollama 模型存储目录权限
mkdir -p /usr/share/ollama/.ollama/models
chown -R ollama:ollama /usr/share/ollama
chmod 755 -R /usr/share/ollama

# 4. 重新加载 systemd 并启用服务
systemctl daemon-reload
systemctl enable ollama.service

# 5. （可选）立即启动服务进行测试
#systemctl start ollama.service

echo "Ollama 系统服务配置完成。"
echo "默认监听地址: 0.0.0.0:11434"
echo "模型存储路径: /usr/share/ollama/.ollama/models"


echo 'export OLLAMA_MODELS=/usr/share/ollama/.ollama/models' >> ~/.bashrc
source ~/.bashrc

ssh-keygen -t ed25519 -f /var/lib/ollama/.ollama/id_ed25519 -N ""
chown -R ollama:ollama /var/lib/ollama/.ollama/
chmod 600 /var/lib/ollama/.ollama/id_ed25519 
chmod 644 /var/lib/ollama/.ollama/id_ed25519.pub

sudo -u ollama /usr/bin/ollama serve &

# 等待几秒，确保服务初始化和监听端口（可选但推荐）
sleep 5

#
# 创建 Modelfile 来告诉 Ollama 如何使用我们打包的模型
mkdir -p /opt/ollama-modelfiles/
cat > /opt/ollama-modelfiles/Qwen3-0.6B-Modelfile << 'EOF'
FROM /opt/models/Qwen3-0.6B-Q8_0.gguf
PARAMETER temperature 0.7
PARAMETER top_p 0.9
PARAMETER num_ctx 32768
# 可以根据需要添加其他参数和模板
TEMPLATE "{{ if .System }}<|im_start|>system
{{ .System }}<|im_end|>
{{ end }}{{ if .Prompt }}<|im_start|>user
{{ .Prompt }}<|im_end|>
{{ end }}<|im_start|>assistant
{{ .Response }}<|im_end|>"
EOF

# 使用 Modelfile 在 Ollama 中创建模型
ollama create qwen3-0.6b -f /opt/ollama-modelfiles/Qwen3-0.6B-Modelfile

rm -f /opt/models/Qwen3-0.6B-Q8_0.gguf
# （可选）设置 Ollama 服务开机自启，但 Live 环境通常不需要
systemctl enable ollama

# （可选）启动 Ollama 服务
systemctl start ollama

echo "Ollama 和 Qwen3-0.6B 模型已配置完成。"
echo "启动后，您可以使用 'ollama run qwen3-0.6b' 与模型交互。"
