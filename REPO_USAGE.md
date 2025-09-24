# MyAIBase 本地仓库使用指南

## 🎯 概述

`Makefile.simple` 现已整合 `scripts/local_repo.sh` 功能，提供完整的本地软件包仓库管理功能。

## 📋 可用目标

### 主要仓库管理目标

| 目标 | 描述 |
|------|------|
| `make repo` | 构建本地软件包仓库（默认构建 fbterm） |
| `make repo-setup` | 初始化仓库环境 |
| `make repo-deps` | 检查系统依赖 |
| `make repo-info` | 显示仓库信息 |
| `make repo-test` | 测试本地仓库 |
| `make repo-clean` | 清理本地仓库 |
| `make repo-full` | 完整仓库构建流程 |

### 配置变量

| 变量 | 默认值 | 描述 |
|------|--------|------|
| `PACKAGE_NAME` | `fbterm` | 要构建的软件包名称 |
| `BUILD_USER` | `builder` | 构建用户 |
| `LOCAL_REPO_DIR` | `local_repo` | 本地仓库目录 |
| `PACMAN_CONF` | `pacman.conf` | pacman 配置文件 |

## 🔧 使用示例

### 基本使用

```bash
# 构建默认软件包 (fbterm)
make repo

# 构建指定软件包
make repo PACKAGE_NAME=neofetch

# 完整仓库构建流程
make repo-full

# 查看仓库信息
make repo-info
```

### 高级用法

```bash
# 初始化环境并构建
make repo-setup repo

# 检查依赖后构建
make repo-deps repo

# 清理并重新构建
make repo-clean repo PACKAGE_NAME=htop

# 使用自定义配置
make repo PACKAGE_NAME=vim BUILD_USER=myuser LOCAL_REPO_DIR=/tmp/myrepo
```

### 在ISO构建中使用本地仓库

构建本地仓库后，可以在ISO构建中使用这些软件包：

```bash
# 1. 构建本地软件包
make repo PACKAGE_NAME=my-package

# 2. 在 packages.x86_64 中添加软件包名称
# 3. 构建ISO（会自动使用本地仓库）
make base
```

## 📦 工作流程

1. **环境检查**: 检查必要的依赖（yay、makepkg、repo-add）
2. **仓库初始化**: 创建本地仓库目录
3. **软件包构建**: 使用 yay 获取源码并构建
4. **仓库配置**: 配置 pacman 使用本地仓库
5. **数据库更新**: 更新仓库数据库
6. **功能测试**: 验证仓库功能

## ⚠️ 注意事项

- 需要 root 权限运行（使用 sudo）
- 确保系统中已安装必要的依赖：
  - `yay` - AUR 助手
  - `base-devel` - 包含 makepkg 等构建工具
  - `pacman` - 包管理器

- 首次使用前建议运行：`make repo-deps` 检查依赖

## 🔍 故障排除

### 依赖缺失
```bash
# 检查并安装依赖
make repo-deps
sudo pacman -S yay base-devel
```

### 权限问题
```bash
# 确保使用 sudo 运行
sudo make repo
```

### 构建失败
```bash
# 清理后重试
make repo-clean
make repo PACKAGE_NAME=your-package
```

## 🚀 集成优势

通过整合 `local_repo.sh` 到 `Makefile.simple`，现在可以：

- ✅ 统一的项目构建接口
- ✅ 简化的命令调用
- ✅ 灵活的配置选项
- ✅ 完整的错误处理和日志
- ✅ 与ISO构建系统无缝集成

这种整合使得本地软件包管理和ISO构建成为一个统一的工作流程。