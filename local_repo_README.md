# MyAIBase 本地软件仓库构建脚本

## 概述

`local_repo.sh` 是一个用于构建和管理本地软件包仓库的脚本，专为 MyAIBase 项目优化。它可以自动下载、构建软件包，并创建本地 pacman 仓库。

## 功能特性

✅ **完整的错误处理** - 每个步骤都有错误检查和恢复机制
✅ **灵活的配置** - 支持命令行参数和环境变量
✅ **依赖检查** - 自动检查必要的构建工具
✅ **配置备份** - 自动备份 pacman 配置文件
✅ **仓库测试** - 构建完成后自动测试仓库功能
✅ **清理机制** - 自动清理临时文件和构建目录

## 依赖要求

- `yay` - AUR 助手
- `base-devel` - 构建工具包
- `pacman` - 包管理器
- `sudo` - 权限管理

## 使用方法

### 基本用法

```bash
# 以root权限运行脚本
sudo scripts/local_repo.sh

# 构建指定软件包
sudo scripts/local_repo.sh -p neofetch

# 使用环境变量
BUILD_USER=myuser scripts/local_repo.sh -p htop
```

### 命令行参数

```bash
./local_repo.sh [选项]

选项:
    -p, --package NAME      指定要构建的软件包名称 (默认: fbterm)
    -u, --user USER        指定构建用户 (默认: builder)
    -d, --dir DIR          指定本地仓库目录 (默认: ./local_repo)
    -c, --config FILE      指定pacman配置文件 (默认: ./pacman.conf)
    -h, --help             显示帮助信息
```

### 环境变量

```bash
BUILD_USER              构建用户
PACKAGE_NAME            软件包名称
LOCAL_REPO_DIR          本地仓库目录
PACMAN_CONF             pacman配置文件
```

## 使用示例

### 示例1：构建默认软件包
```bash
sudo scripts/local_repo.sh
```

### 示例2：构建指定软件包
```bash
sudo scripts/local_repo.sh -p neofetch
```

### 示例3：自定义用户和仓库目录
```bash
sudo scripts/local_repo.sh -u myuser -d /tmp/myrepo -p htop
```

### 示例4：使用环境变量
```bash
BUILD_USER=developer LOCAL_REPO_DIR=/opt/repo scripts/local_repo.sh -p vim
```

## 工作流程

1. **依赖检查** - 验证必要的构建工具是否安装
2. **创建仓库目录** - 创建本地仓库目录结构
3. **备份配置** - 备份现有的 pacman 配置文件
4. **获取源码** - 使用 yay 下载 AUR 软件包源码
5. **构建软件包** - 使用 makepkg 构建软件包
6. **更新仓库** - 使用 repo-add 更新本地仓库数据库
7. **配置 pacman** - 添加本地仓库到 pacman 配置
8. **测试仓库** - 验证仓库功能是否正常
9. **清理临时文件** - 删除构建过程中产生的临时文件

## 输出信息

脚本会显示详细的构建过程信息：

```
[INFO] 开始构建本地软件仓库
[INFO] 检查必要依赖...
[INFO] 所有依赖已满足
[INFO] 创建本地仓库目录: ./local_repo
[INFO] 已备份pacman配置: ./pacman.conf.bak
[INFO] 构建软件包: fbterm
...
```

## 错误处理

脚本具有完整的错误处理机制：

- **依赖检查失败** - 显示缺少的依赖包并退出
- **源码下载失败** - 显示错误信息并清理临时文件
- **构建失败** - 显示构建错误并退出
- **仓库更新失败** - 显示数据库错误信息

## 文件结构

构建完成后，本地仓库目录结构如下：

```
local_repo/
├── local.db.tar.gz          # 仓库数据库
├── fbterm-1.7_5-5-x86_64.pkg.tar.zst  # 软件包文件
└── ...                      # 其他软件包文件
```

## 在 MyAIBase 中的使用

这个脚本主要用于为 MyAIBase ISO 镜像构建添加自定义软件包。构建的本地仓库可以被包含在 ISO 镜像中，提供额外的软件包支持。

## 注意事项

1. **权限要求** - 脚本需要 root 权限运行
2. **用户存在** - 指定的构建用户必须存在于系统中
3. **磁盘空间** - 确保有足够的磁盘空间用于构建
4. **网络连接** - 构建过程中需要网络连接下载源码

## 故障排除

### 常见问题

**Q: 脚本显示缺少依赖**
A: 安装缺少的包：`sudo pacman -S yay base-devel`

**Q: 构建用户不存在**
A: 创建用户或指定现有用户：`useradd -m builder`

**Q: 仓库测试失败**
A: 检查 pacman 配置和仓库路径是否正确

**Q: 软件包构建失败**
A: 检查构建日志，可能需要安装额外的构建依赖

### 调试模式

如需调试，可以修改脚本开头的 `set -e` 为 `set -ex` 以显示详细的执行过程。

## 更新日志

- v2.0 - 完全重写，添加完整的错误处理和配置选项
- v1.0 - 初始版本，基础功能实现