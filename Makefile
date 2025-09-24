# MyAIBase 简化版 Makefile
# 使用统一构建脚本的简化版本

# 配置变量
# GGUF_FILE ?= ../models/Qwen3-0.6B-Q8_0.gguf

# 默认目标
.DEFAULT_GOAL := help

# 配置变量
GGUF_FILE ?= 
BUILD_USER ?= builder
PACKAGE_NAME ?= fbterm
LOCAL_REPO_DIR ?= local_repo
PACMAN_CONF ?= pacman.conf
REPO_NAME ?= mylocal

# 帮助信息
help:
	@echo "MyAIBase 简化构建系统"
	@echo ""
	@echo "主要目标:"
	@echo "  make mini      - 构建最小化ISO"
	@echo "  make base      - 构建基础ISO（含中文支持）"
	@echo "  make ai        - 构建AI ISO（完整功能）"
	@echo "  make quick     - 快速构建（静默模式）"
	@echo ""
	@echo "本地仓库管理:"
	@echo "  make repo      - 构建本地软件包仓库"
	@echo "  make repo-clean - 清理本地仓库"
	@echo "  make repo-test  - 测试本地仓库"
	@echo "  make repo-setup - 初始化仓库环境"
	@echo "  make repo-deps  - 检查仓库依赖"
	@echo "  make repo-info  - 显示仓库信息"
	@echo ""
	@echo "验证和测试:"
	@echo "  make check     - 快速验证环境"
	@echo "  make test      - 完整验证测试"
	@echo "  make deps      - 检查系统依赖"
	@echo ""
	@echo "辅助目标:"
	@echo "  make clean     - 清理工作目录（保留输出文件）"
	@echo "  make clean-all - 完全清理（包括输出文件）"
	@echo "  make help      - 显示此帮助信息"
	@echo ""
	@echo "高级用法:"
	@echo "  make ai GGUF_FILE=/path/to/model.gguf  # 指定模型文件"
	@echo "  make base quick                         # 快速构建基础版"
	@echo "  make repo PACKAGE_NAME=neofetch         # 构建指定软件包"
	@echo "  make repo REPO_NAME=customrepo          # 使用自定义仓库名称 "
	@echo "  ./scripts/build-simple.sh ai -q -m model.gguf  # 直接调用脚本"

# 构建目标
mini:
	@./scripts/build-simple.sh mini

base:
	@./scripts/build-simple.sh base

ai:
	@./scripts/build-simple.sh ai $(if $(GGUF_FILE),-m $(GGUF_FILE))

# 快速构建
quick-mini:
	@./scripts/build-simple.sh mini -q

quick-base:
	@./scripts/build-simple.sh base -q

quick-ai:
	@./scripts/build-simple.sh ai -q $(if $(GGUF_FILE),-m $(GGUF_FILE))

quick: quick-ai

# 验证和测试
check:
	@./scripts/validate-simple.sh quick

test:
	@./scripts/validate-simple.sh full

deps:
	@./scripts/validate-simple.sh deps

# 兼容性目标（保持原有接口）
build-mini: mini
build-base: base
build-ai: ai

validate: check

# 清理
clean:
	@echo "清理工作目录（保留输出文件）..."
	@rm -rf work
	@rm -f packages.x86_64
	@rm -f airootfs/root/customize_airootfs.sh
	@rm -f profiledef.sh.bak
	@rm -f airootfs/opt/models/*.gguf
	@echo "清理完成！"

# 完全清理（包括输出目录）
clean-all:
	@echo "完全清理工作目录和输出文件..."
	@rm -rf work out
	@rm -f packages.x86_64
	@rm -f airootfs/root/customize_airootfs.sh
	@rm -f profiledef.sh.bak
	@rm -f airootfs/opt/models/*.gguf
	@echo "完全清理完成！"

# 本地仓库管理
repo:
	@echo "构建本地软件包仓库..."
	@sudo ./scripts/local_repo.sh -p $(PACKAGE_NAME) -u $(BUILD_USER) -d $(LOCAL_REPO_DIR) -c $(PACMAN_CONF) -r $(REPO_NAME)

repo-clean:
	@echo "清理本地仓库..."
	@rm -rf $(LOCAL_REPO_DIR)
	@echo "本地仓库已清理"

repo-test:
	@echo "测试本地仓库..."
	@pacman --config $(PACMAN_CONF) -Sy || true
	@pacman --config $(PACMAN_CONF) -Ss $(PACKAGE_NAME) || true

repo-setup:
	@echo "设置本地仓库环境..."
	@mkdir -p $(LOCAL_REPO_DIR)
	@echo "本地仓库目录已创建: $(LOCAL_REPO_DIR)"
	@if [ ! -f "$(PACMAN_CONF)" ]; then \
		echo "创建pacman配置文件..."; \
		cp /etc/pacman.conf $(PACMAN_CONF) 2>/dev/null || echo "无法复制系统pacman配置"; \
	fi
	@echo "环境设置完成"

repo-deps:
	@echo "检查本地仓库依赖..."
	@command -v yay >/dev/null 2>&1 || echo "❌ yay 未安装"
	@command -v makepkg >/dev/null 2>&1 || echo "❌ makepkg 未安装 (需要 base-devel)"
	@command -v repo-add >/dev/null 2>&1 || echo "❌ repo-add 未安装 (需要 pacman)"
	@command -v sudo >/dev/null 2>&1 || echo "❌ sudo 未安装"
	@echo "依赖检查完成"

repo-info:
	@echo "本地仓库信息:"
	@echo "  仓库名称: $(REPO_NAME)"
	@echo "  仓库目录: $(LOCAL_REPO_DIR)"
	@echo "  软件包: $(PACKAGE_NAME)"
	@echo "  构建用户: $(BUILD_USER)"
	@echo "  pacman配置: $(PACMAN_CONF)"
	@if [ -d "$(LOCAL_REPO_DIR)" ]; then \
		echo "  仓库状态: 已存在"; \
		ls -la $(LOCAL_REPO_DIR)/*.pkg.tar.* 2>/dev/null | wc -l | xargs echo "  软件包数量:"; \
	else \
		echo "  仓库状态: 未创建"; \
	fi

repo-full: repo-setup repo-deps repo repo-test
	@echo "🎉 本地仓库完整构建完成！"
	@echo "   仓库名称: $(REPO_NAME)"
	@echo "   仓库位置: $(LOCAL_REPO_DIR)"
	@echo "   软件包: $(PACKAGE_NAME)"
	@echo "   配置文件: $(PACMAN_CONF)"

# 高级目标
prepare:
	@echo "准备构建环境..."
	@mkdir -p work out
	@echo "环境准备完成！"

status:
	@echo "构建系统状态:"
	@echo "  工作目录: $(if [ -d work ],存在,不存在)"
	@echo "  输出目录: $(if [ -d out ],存在,不存在)"
	@echo "  模型文件: $(if [ -n "$(ls airootfs/opt/models/*.gguf 2>/dev/null)"],已配置,未配置)"
	@echo "  配置文件: $(if [ -f profiledef.sh ],存在,缺失)"