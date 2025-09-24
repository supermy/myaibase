## ✨ 新特性

- **🔧 可配置 GGUF 模型**: 支持通过 `GGUF_FILE` 变量自定义模型文件路径
- **⚡ 快速构建模式**: 新增 `quick-ai` 目标，跳过模型文件复制步骤
- **🎨 改进构建系统**: 优化 Makefile，支持更灵活的配置选项
- **📖 完善文档**: 更新使用说明和示例，添加更多配置选项

---

# MyAIBase - Arch Linux AI Live 系统

基于 Arch Linux 构建的 AI 增强型 Live 系统，集成 Ollama 和预配置的 AI 模型。




MyAIBase 是一个基于 Arch Linux 的定制化 AI 系统镜像，集成了 Ollama 和预配置的 AI 模型，专为 AI 开发和实验环境设计。

U盘即插即用启动，AI 纯内存推理。

    1.root登录；
    2.ollama run qwen3-0.6b

链接: https://pan.baidu.com/s/13S1pk0HC83mYmZy39eDD7Q?pwd=myai 提取码: myai


## 📝 使用说明

1. **构建 ISO 镜像**：使用 Makefile 构建不同版本的 ISO 文件
   - `make build-ai` - 构建包含 AI 组件的完整版本
   - `make build-base` - 构建仅包含基础系统的精简版本
   - ISO 文件将生成在 `out/` 目录中，命名格式为 `myaibase-{type}-YYYYMMDD.iso`

2. **部署和使用**：
   - 可以直接把构建完成的 ISO 镜像烧录到 U 盘，插入目标机器即可启动 Live 系统（即插即用）
   - 或者将构建好的 ISO 文件拷贝到 Ventoy 启动盘
   - **注意**：只有 AI 版本包含 Ollama 和 AI 模型功能

3. **首次启动**：系统会自动配置中文环境（两个版本都包含）
   - AI 版本还会自动配置 Ollama 服务

4. **使用 AI 模型**（仅 AI 版本）：运行 `ollama run qwen3-0.6b` 开始与模型交互

5. **📶 网络配置**：使用 iwctl 配置 WiFi 连接；使用 dhcpcd 配置有线网络连接

6. **持久化存储**：Live 系统模式下更改不会保存，可安装到硬盘使用


## 🚀 特性

- 基于 Arch Linux 的轻量级 Live 系统
- 预集成 Ollama AI 模型服务
- 支持 Qwen3-0.6B 等常见 AI 模型
- 中文语言环境支持
- UEFI/BIOS 双启动支持
- 系统服务安全加固

## 📁 项目结构

```
myaibase/
├── README.md                 # 项目说明文档
├── packages.x86_64           # 软件包列表
├── pacman.conf              # Pacman 配置
├── profiledef.sh            # 镜像构建配置
├── airootfs/                # Live 系统根文件系统
│   ├── etc/                 # 系统配置文件
│   ├── opt/                 # 可选软件和模型
│   └── root/                # root 用户定制脚本
├── efiboot/                 # UEFI 启动配置
├── grub/                    # GRUB 启动配置
├── syslinux/                # Syslinux 启动配置
├── work/                    # 构建工作目录
└── out/                     # 输出 ISO 文件目录
```

## 🛠️ 开发环境准备

全新环境配置指南

### Docker 开发环境

```bash
# 启动 Arch Linux 开发容器
docker run --privileged -dt -e TZ=Asia/Shanghai --name archlinux_dev --restart=always --gpus all -it --ipc=host --ulimit memlock=-1 --ulimit stack=67108864 -v $(pwd):/workspace -v /sys/fs/cgroup:/sys/fs/cgroup:ro 9f0f676c66b8 /bin/bash

# 进入容器
docker exec -it archlinux_dev bash
```

### 配置软件源

```bash
# 设置清华大学镜像源
echo 'Server = https://mirrors.tuna.tsinghua.edu.cn/archlinux/$repo/os/$arch' > /etc/pacman.d/mirrorlist

# 安装必要工具
pacman -S vim

# 配置 pacman.conf
vim /etc/pacman.conf
```

在 `/etc/pacman.conf` 中添加以下源配置：

```ini
# Arch Linux CN 源 - 中文用户常用软件
[archlinuxcn]
SigLevel = Optional TrustAll
Server = https://mirrors.tuna.tsinghua.edu.cn/archlinuxcn/$arch

# BlackArch 源 - 安全研究工具
[blackarch]
SigLevel = Optional TrustAll
Server = https://mirrors.tuna.tsinghua.edu.cn/blackarch/$repo/os/$arch
```

### 安装密钥和必要软件包

```bash
# 安装密钥环
pacman -S archlinuxcn-keyring
pacman -S blackarch-keyring

# 更新系统
pacman -Syu

# 安装构建工具
pacman -S archiso

# 测试安装 ollama（可选）
pacman -S ollama

# 复制 ArchISO 配置模板（全新环境准备）
cp -r /usr/share/archiso/configs/baseline /workspace/myaibase
cd /workspace/myaibase
```

## 🎯 系统定制

### 1. 配置软件包列表

编辑 `packages.x86_64`，添加需要的软件包：

```
archlinuxcn-keyring
ollama
# 其他需要的软件包...
```

### 2. 配置 Pacman

在 `pacman.conf` 中添加 Arch Linux CN 源：

```ini
[archlinuxcn]
SigLevel = Optional TrustAll
Server = https://mirrors.tuna.tsinghua.edu.cn/archlinuxcn/$arch
```

### 3. 添加自定义文件

```bash
# 创建模型存储目录
mkdir -p airootfs/opt/models/

# 下载模型放到指定目录（示例路径）
# cp /path/to/Qwen3-0.6B-Q8_0.gguf airootfs/opt/models/

# 创建自定义脚本，mkarchiso 会自动执行脚本
# vim airootfs/root/customize_airootfs.sh
```

## 🔧 构建系统镜像

### 使用 Makefile（推荐）

我们提供了 Makefile 来简化构建过程，支持两种构建模式：

#### 构建选项

```bash
# 构建 AI ISO 镜像（默认目标）- 包含基础系统 + AI组件
make build-ai
make              # 等同于 make build-ai

# 构建基础 ISO 镜像 - 仅包含基础系统组件
make build-base

# 快速构建（静默模式）
make quick-ai     # 快速构建 AI ISO
make quick-base   # 快速构建基础 ISO

# 清理工作目录
make clean

# 完全清理（包括输出目录）
make clean-all

# 测试构建环境
make test

# 运行完整测试套件
make test-all

# 显示帮助信息
make help
```

#### 输出文件命名

构建完成后，ISO 文件将生成在 `out/` 目录中，命名格式为：

- **AI ISO**: `myaibase-ai-YYYYMMDD.iso` (例如: `myaibase-ai-20231215.iso`)
- **基础 ISO**: `myaibase-base-YYYYMMDD.iso` (例如: `myaibase-base-20231215.iso`)

#### 使用示例

```bash
# 完全清理后构建 AI ISO（使用默认模型）
make clean-all build-ai

# 使用自定义 GGUF 模型文件构建 AI ISO
make build-ai GGUF_FILE=/path/to/your-model.gguf

# 使用相对路径的模型文件
make build-ai GGUF_FILE=../models/my-model.gguf

# 快速构建模式（跳过模型文件复制）
make quick-ai GGUF_FILE=/path/to/model.gguf

# 测试环境后构建基础 ISO
make test && make build-base

# 运行完整测试套件
make test-all

# 查看所有可用命令和配置选项
make help

# 查看当前构建配置信息
make info
```

### 手动构建命令

```bash
# 创建工作目录
mkdir -p work out

# 清理旧文件
rm -rf out/* work/*

# 构建 ISO 镜像
mkarchiso -v -w work -o out .
```

## 🔍 故障排除

```bash
# 秘钥问题处理
sudo pacman-key --init
sudo pacman-key --populate archlinux
sudo pacman -Sy archlinux-keyring

# 安装缺失的构建依赖
pacman -S grub arch-install-scripts awk dosfstools e2fsprogs erofs-utils findutils gzip libarchive libisoburn mtools openssl pacman sed squashfs-tools memtest86+ edk2-shell
```

### 驱动问题

确保安装了必要的固件包：
```bash
pacman -S linux-firmware firmware-iwlwifi
```

## 🧪 测试和运行

### 测试套件功能

我们提供了完整的自动化测试套件，可以验证构建系统的所有功能：

#### 运行完整测试
```bash
make test-all
```

#### 测试套件包含以下步骤：

1. **依赖检查** - 验证必要的构建工具是否安装
2. **构建环境测试** - 检查 mkarchiso 是否可用
3. **基础ISO快速构建** - 构建基础版本ISO镜像
4. **文件验证** - 检查生成的基础ISO文件
5. **清理工作** - 清理构建环境
6. **AI ISO快速构建** - 构建AI版本ISO镜像
7. **文件验证** - 检查生成的AI ISO文件
8. **构建信息显示** - 显示项目配置信息

#### 测试输出示例
```
🧪 开始运行完整测试套件...

1. 测试依赖检查...
✅ 所有依赖已安装

2. 测试构建环境...
✅ 构建环境正常

3. 测试基础ISO快速构建...
✅ 基础ISO快速构建完成

4. 检查生成的基础ISO文件...
✅ 基础ISO文件存在: out/myaibase-base-20231215.iso
-rw-r--r-- 1 user user 1.2G Dec 15 10:30 out/myaibase-base-20231215.iso

5. 清理基础ISO构建...
🧹 清理工作目录...

6. 测试AI ISO快速构建...
✅ AI ISO快速构建完成

7. 检查生成的AI ISO文件...
✅ AI ISO文件存在: out/myaibase-ai-20231215.iso
-rw-r--r-- 1 user user 1.3G Dec 15 10:32 out/myaibase-ai-20231215.iso

8. 显示构建信息...
📊 MyAIBase 构建信息:
   工作目录: work/
   输出目录: out/
   配置文件: profiledef.sh
   软件包列表: packages.x86_64
   自定义脚本: airootfs/root/customize_airootfs.sh

🎉 所有测试完成！
📁 生成的ISO文件在 out/ 目录中:
-rw-r--r-- 1 user user 1.2G Dec 15 10:30 myaibase-base-20231215.iso
-rw-r--r-- 1 user user 1.3G Dec 15 10:32 myaibase-ai-20231215.iso
```

### 单独测试命令

除了完整的测试套件，还可以运行单独的测试：

```bash
# 仅测试构建环境
make test

# 仅检查依赖
make check-deps

# 显示构建信息
make info
```

### 测试建议

- 在提交代码前运行 `make test-all` 确保所有功能正常
- 在安装新依赖后运行 `make test` 验证构建环境
- 使用 `make info` 查看当前构建配置信息

## 🔧 构建系统

### 重构后的模块化构建系统

MyAIBase 构建系统已经重构为模块化的独立脚本系统，提供了更好的可维护性和错误处理：

```bash
# 主要构建目标
make build-mini   # 构建最小化ISO镜像（最小系统）
make build-base   # 构建基础ISO镜像（基础+中文支持）  
make build-ai     # 构建AI ISO镜像（完整AI功能）

# 快速构建（静默模式）
make quick-mini   # 快速构建最小化ISO
make quick-base   # 快速构建基础ISO
make quick-ai     # 快速构建AI ISO

# 验证和测试
make validate     # 验证构建环境
make test-all     # 运行完整测试套件
```

### 构建脚本架构

新的构建系统包含以下核心脚本：

- **`scripts/build-common.sh`** - 通用构建函数库（文件检查、软件包合并、ISO构建等）
- **`scripts/build-mini.sh`** - 最小化ISO构建脚本
- **`scripts/build-base.sh`** - 基础ISO构建脚本  
- **`scripts/build-ai.sh`** - AI ISO构建脚本
- **`scripts/validate.sh`** - 环境验证和测试脚本

### 高级用法

可以直接调用构建脚本进行更细粒度的控制：

```bash
# 使用构建脚本的高级选项
./scripts/build-mini.sh -w /tmp/work -o /tmp/out -n my-custom-mini
./scripts/build-ai.sh -m /path/to/model.gguf -q  # 快速静默构建
./scripts/validate.sh all  # 运行完整验证
```

### 功能特性

✅ **模块化设计**: 独立脚本，职责分明  
✅ **增强错误处理**: 完善的错误捕获和恢复机制  
✅ **统一日志系统**: 彩色输出，多级别日志  
✅ **灵活配置**: 支持命令行参数和环境变量  
✅ **向后兼容**: 保持原有Makefile接口不变  

详细构建系统文档请参考 [`BUILD_SYSTEM_README.md`](BUILD_SYSTEM_README.md)。

## 📦 本地软件仓库

### 本地仓库构建脚本

项目包含 `local_repo.sh` 脚本，用于构建和管理本地软件包仓库：

```bash
# 基本用法 - 构建默认软件包
sudo scripts/local_repo.sh

# 构建指定软件包
sudo scripts/local_repo.sh -p neofetch

# 自定义用户和仓库目录
sudo scripts/local_repo.sh -u myuser -d /tmp/repo -p htop
```

### 功能特性

- ✅ 完整的错误处理和依赖检查
- ✅ 灵活的配置选项（支持命令行参数和环境变量）
- ✅ 自动备份 pacman 配置文件
- ✅ 仓库构建完成后自动测试
- ✅ 自动清理临时文件

详细使用说明请参考 [`local_repo_README.md`](local_repo_README.md) 文档。

### 在 ISO 构建中使用本地仓库

构建的本地仓库可以集成到 MyAIBase ISO 镜像中：

1. 首先使用 `scripts/local_repo.sh` 构建需要的软件包
2. 在 `packages.x86_64` 文件中添加本地仓库中的软件包名称
3. 确保 `pacman.conf` 包含本地仓库配置
4. 运行 `make build-ai` 或 `make build-base` 构建 ISO

本地仓库路径：`local_repo/` 目录

## 🤖 Ollama 配置

### 系统服务配置

查看 `airootfs/root/customize_airootfs.sh` 中的完整配置，主要功能包括：

1. 创建安全的 ollama 系统用户
2. 配置 systemd 服务文件
3. 设置模型存储目录权限
4. 创建 Modelfile 配置
5. 集成预训练模型

### 模型配置示例

系统支持通过 `GGUF_FILE` 变量配置自定义模型文件路径。默认使用 `../myaibase/airootfs/opt/models/Qwen3-0.6B-Q8_0.gguf`。

```bash
# 创建 Modelfile（使用默认模型）
cat > /opt/ollama-modelfiles/Qwen3-0.6B-Modelfile << 'EOF'
FROM /opt/models/Qwen3-0.6B-Q8_0.gguf
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

# 创建模型
ollama create qwen3-0.6b -f /opt/ollama-modelfiles/Qwen3-0.6B-Modelfile
```

### 使用自定义 GGUF 模型

构建系统支持通过 `GGUF_FILE` 变量指定任意 GGUF 模型文件路径：

```bash
# 使用绝对路径的模型文件
make build-ai GGUF_FILE=/home/user/models/llama-2-7b-chat.gguf

# 使用相对路径的模型文件
make build-ai GGUF_FILE=./models/mymodel.gguf

# 快速构建模式（跳过模型文件复制步骤）
make quick-ai GGUF_FILE=/path/to/model.gguf
```

模型文件将在构建过程中自动复制到 ISO 镜像的 `/opt/models/` 目录中。


## 🌐 中文支持


### 语言环境配置

```bash
# 下载中文语言包
curl -LO https://mirrors.tuna.tsinghua.edu.cn/archlinux/core/os/x86_64/glibc-2.42+r17+gd7274d718e6f-1-x86_64.pkg.tar.zst

# 提取中文区域设置
bsdtar -xf glibc-*.pkg.tar.zst usr/share/i18n/locales
cp -r usr/share/i18n/locales/zh_CN* /usr/share/i18n/locales/

# 生成区域设置
locale-gen

# 安装中文字体
pacman -S --needed noto-fonts-cjk wqy-microhei

# 设置环境变量（谨慎使用，TTY 下可能显示异常）
export LC_ALL=zh_CN.UTF-8
```


### QEMU 虚拟机测试

```bash
# BIOS 模式启动
qemu-system-x86_64 -m 2048 -cdrom out/archlinux-*.iso -nographic

# UEFI 模式启动
sudo apt install ovmf
qemu-system-x86_64 -cdrom out/archlinux-*.iso -bios /usr/share/ovmf/OVMF.fd -m 2048 -nographic

# 使用 KVM 加速
qemu-system-x86_64 -cdrom out/archlinux-*.iso -bios /usr/share/ovmf/OVMF.fd -m 8192 -nographic -enable-kvm -smp 6
```


### VirtualBox 测试

```bash
# 创建虚拟机
VBoxManage createvm --name "MyAIBase_Test" --register
VBoxManage modifyvm "MyAIBase_Test" --memory 4096 --cpus 2
VBoxManage storagectl "MyAIBase_Test" --name "IDE Controller" --add ide
VBoxManage storageattach "MyAIBase_Test" --storagectl "IDE Controller" --port 0 --device 0 --type dvddrive --medium out/archlinux-*.iso

# 启动虚拟机
VBoxManage startvm "MyAIBase_Test"
```


### WiFi 连接

```bash
# 检查无线网卡驱动
lsmod | grep iwlwifi

# 加载驱动（Intel 网卡）
sudo modprobe iwlwifi

# 使用 iwctl 连接 WiFi
iwctl --passphrase <你的WiFi密码> station wlan0 connect <你的WiFi名称>

# 或者使用交互模式
iwctl
[iwd]# station list
[iwd]# station wlan0 scan
[iwd]# station wlan0 get-networks
[iwd]# station wlan0 connect <你的WiFi名称>
```


### 检查 ISO 内容

```bash
# 查看 ISO 文件内容
isoinfo -f -i out/archlinux-*.iso

# 检查 SquashFS 文件系统内容
unsquashfs -l /path/to/airootfs.sfs | grep ollama

# 挂载 ISO 检查
sudo mount -o loop out/archlinux-*.iso /mnt/iso
ls -l /mnt/iso
```


## 🤝 贡献

欢迎提交 Issue 和 Pull Request 来改进这个项目！

## 📄 许可证

本项目基于 Arch Linux 和相关的开源软件，遵循各自的许可证协议。

## 🔗 相关资源

- [Arch Linux 官方文档](https://wiki.archlinux.org/)
- [Ollama 文档](https://ollama.com)
- [ArchISO 文档](https://wiki.archlinux.org/title/Archiso)

---

💡 **提示**: 在 TTY 环境下不建议设置全局中文语言环境，可能导致显示异常。建议在图形界面或需要中文支持的应用程序中临时设置语言环境。


## ✨ 新特性

- **🔧 可配置 GGUF 模型**: 支持通过 `GGUF_FILE` 变量自定义模型文件路径
- **⚡ 快速构建模式**: 新增 `quick-ai` 目标，跳过模型文件复制步骤
- **🎨 改进构建系统**: 优化 Makefile，支持更灵活的配置选项
- **📖 完善文档**: 更新使用说明和示例，添加更多配置选项

