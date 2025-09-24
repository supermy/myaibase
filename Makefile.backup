# MyAIBase Makefile
# 用于简化 Arch Linux AI 系统镜像构建过程

# 可配置变量
GGUF_FILE ?= ../models/Qwen3-0.6B-Q8_0.gguf

.PHONY: all build build-base build-ai clean clean-all prepare test test-all help

# 默认目标（构建AI ISO）
all: build-ai

build-mini: prepare
	@echo "🚀 开始构建 MyAIBase 最小化 ISO 镜像..."
	@# 检查必要文件
	@if [ ! -f packages.x86_64-mini ]; then \
		echo "❌ 最小化软件包文件不存在: packages.x86_64-mini"; exit 1; \
	fi
	@if [ ! -f customize_airootfs.sh ]; then \
		echo "❌ 自定义脚本文件缺失: customize_airootfs.sh"; exit 1; \
	fi
	@echo "📦 使用最小化软件包: packages.x86_64-mini"
	@cp packages.x86_64-mini packages.x86_64; \
	if [ $$? -eq 0 ]; then \
		echo "✅ 已使用最小化软件包替换"; \
	else \
		echo "❌ 软件包复制失败"; exit 1; \
	fi
	@echo "📦 复制最小化版本的customize_airootfs脚本..."
	@cp customize_airootfs.sh airootfs/root/customize_airootfs.sh; \
	chmod +x airootfs/root/customize_airootfs.sh; \
	if [ $$? -eq 0 ]; then \
		echo "✅ 已复制最小化版本customize_airootfs脚本"; \
	else \
		echo "❌ 脚本复制失败"; exit 1; \
	fi
	@# 临时修改profiledef.sh以使用最小化ISO名称
	@sed -i.bak 's/iso_name=\".*\"/iso_name=\"archlinux-mini\"/' profiledef.sh; \
	echo "✅ 已设置ISO名称为: archlinux-mini"
	@# 执行构建并捕获结果
	@echo "🔨 开始构建ISO镜像..."
	@if mkarchiso -v -w work -o out .; then \
		echo "✅ ISO构建成功"; \
	else \
		echo "❌ ISO构建失败"; \
		mv profiledef.sh.bak profiledef.sh 2>/dev/null || true; \
		exit 1; \
	fi
	@# 恢复原始profiledef.sh
	@mv profiledef.sh.bak profiledef.sh 2>/dev/null || true; \
	echo "✅ 已恢复原始profiledef.sh"
	@echo "✅ 最小化 ISO 构建完成！文件位于 out/ 目录"

# 构建基础 ISO 镜像（仅基础系统）
build-base: prepare
	@echo "🚀 开始构建 MyAIBase 基础 ISO 镜像..."
	@# 检查必要文件
	@if [ ! -f packages.x86_64-base ]; then \
		echo "❌ 基础软件包文件不存在: packages.x86_64-base"; exit 1; \
	fi
	@if [ ! -f customize_airootfs.sh ] || [ ! -f customize_airootfs_chinese-support.sh ]; then \
		echo "❌ 自定义脚本文件缺失"; exit 1; \
	fi
	@echo "📦 使用基础软件包: packages.x86_64-base"
	@cp packages.x86_64-base packages.x86_64; \
	if [ $$? -eq 0 ]; then \
		echo "✅ 已使用基础软件包替换"; \
	else \
		echo "❌ 软件包复制失败"; exit 1; \
	fi
	@echo "📦 合并基础版本的customize_airootfs脚本..."
	@cat customize_airootfs.sh customize_airootfs_chinese-support.sh > airootfs/root/customize_airootfs.sh; \
	chmod +x airootfs/root/customize_airootfs.sh; \
	if [ $$? -eq 0 ]; then \
		echo "✅ 已合并基础版本customize_airootfs脚本"; \
	else \
		echo "❌ 脚本合并失败"; exit 1; \
	fi
	@# 临时修改profiledef.sh以使用基础ISO名称
	@sed -i.bak 's/iso_name=".*"/iso_name="archlinux-baseline"/' profiledef.sh; \
	echo "✅ 已设置ISO名称为: archlinux-baseline"
	@# 执行构建并捕获结果
	@echo "🔨 开始构建基础ISO镜像..."
	@if mkarchiso -v -w work -o out .; then \
		echo "✅ 基础ISO构建成功"; \
	else \
		echo "❌ 基础ISO构建失败"; \
		mv profiledef.sh.bak profiledef.sh 2>/dev/null || true; \
		exit 1; \
	fi
	@# 恢复原始profiledef.sh
	@mv profiledef.sh.bak profiledef.sh 2>/dev/null || true; \
	echo "✅ 已恢复原始profiledef.sh"
	@echo "✅ 基础 ISO 构建完成！文件位于 out/ 目录"

# 构建 AI ISO 镜像（基础系统 + AI组件）
build-ai: prepare
	@echo "🚀 开始构建 MyAIBase AI ISO 镜像..."
	@# 检查必要文件
	@if [ ! -f packages.x86_64-base ] || [ ! -f packages.x86_64-ai ]; then \
		echo "❌ 软件包文件不存在: packages.x86_64-base 或 packages.x86_64-ai"; exit 1; \
	fi
	@if [ ! -f customize_airootfs.sh ] || [ ! -f customize_airootfs_chinese-support.sh ] || [ ! -f customize_airootfs_ollama.sh ] || [ ! -f customize_airootfs_owui-lite.sh ]; then \
		echo "❌ 自定义脚本文件缺失"; exit 1; \
	fi
	@echo "📦 复制模型文件到AI系统..."
	@if [ -f "$(GGUF_FILE)" ]; then \
		cp "$(GGUF_FILE)" airootfs/opt/models/; \
		echo "✅ 已复制模型文件: $(GGUF_FILE)"; \
	else \
		echo "⚠️  模型文件不存在: $(GGUF_FILE)"; \
	fi
	@echo "📦 合并customize_airootfs脚本..."
	@cat customize_airootfs.sh customize_airootfs_chinese-support.sh customize_airootfs_ollama.sh customize_airootfs_owui-lite.sh > airootfs/root/customize_airootfs.sh; \
	chmod +x airootfs/root/customize_airootfs.sh; \
	if [ $$? -eq 0 ]; then \
		echo "✅ 已合并customize_airootfs脚本"; \
	else \
		echo "❌ 脚本合并失败"; exit 1; \
	fi
	@echo "📦 合并基础软件包和AI软件包..."
	@cat packages.x86_64-base packages.x86_64-ai | sort -u > packages.x86_64; \
	if [ $$? -eq 0 ]; then \
		echo "✅ 已合并基础包和AI包"; \
	else \
		echo "❌ 软件包合并失败"; exit 1; \
	fi
	@# 临时修改profiledef.sh以使用AI ISO名称
	@sed -i.bak 's/iso_name=".*"/iso_name="archlinux-ai"/' profiledef.sh; \
	echo "✅ 已设置ISO名称为: archlinux-ai"
	@# 执行构建并捕获结果
	@echo "🔨 开始构建ISO镜像..."
	@if mkarchiso -v -w work -o out .; then \
		echo "✅ ISO构建成功"; \
	else \
		echo "❌ ISO构建失败"; \
		mv profiledef.sh.bak profiledef.sh 2>/dev/null || true; \
		GGUF_BASENAME=$$(basename "$(GGUF_FILE)"); \
		rm -f "airootfs/opt/models/$$GGUF_BASENAME" 2>/dev/null || true; \
		exit 1; \
	fi
	@# 恢复原始profiledef.sh
	@mv profiledef.sh.bak profiledef.sh 2>/dev/null || true; \
	echo "✅ 已恢复原始profiledef.sh"
	@echo "🧹 清理临时模型文件..."
	@GGUF_BASENAME=$$(basename "$(GGUF_FILE)"); \
	if [ -f "airootfs/opt/models/$$GGUF_BASENAME" ]; then \
		rm -f "airootfs/opt/models/$$GGUF_BASENAME"; \
		echo "✅ 已删除临时模型文件: $$GGUF_BASENAME"; \
	fi
	@echo "✅ AI ISO 构建完成！文件位于 out/ 目录"

# 准备工作目录
prepare:
	@echo "📁 准备构建工作目录..."
	mkdir -p work out

# 清理工作目录
clean:
	@echo "🧹 清理工作目录..."
	rm -rf work/*
	rm airootfs/opt/models/* -rf

# 完全清理（包括输出目录）
clean-all:
	@echo "🧹 完全清理工作目录和输出目录..."
	rm -rf work/* out/*
	rm airootfs/opt/models/* -rf

# 测试构建环境
test:
	@echo "🧪 测试构建环境..."
	@which mkarchiso >/dev/null 2>&1 || \
		{ echo "❌ mkarchiso 未安装，请先安装 archiso 包"; exit 1; }
	@echo "✅ 构建环境正常"

# 显示帮助信息
help:
	@echo "MyAIBase 构建系统"
	@echo ""
	@echo "配置变量:"
	@echo "  GGUF_FILE     指定GGUF模型文件路径（默认: ../myaibase/airootfs/opt/models/Qwen3-0.6B-Q8_0.gguf）"
	@echo ""
	@echo "使用方法:"
	@echo "  make          构建 AI ISO 镜像（默认目标）"
	@echo "  make build-ai 构建 AI ISO 镜像（基础 + AI组件）"
	@echo "  make build-base 构建基础 ISO 镜像（仅基础系统）"
	@echo "  make build-mini 构建最小化 ISO 镜像（最小系统）"
	@echo "  make prepare  准备构建工作目录"
	@echo "  make clean   清理工作目录"
	@echo "  make clean-all 完全清理工作目录和输出目录"
	@echo "  make test     测试构建环境"
	@echo "  make validate 验证构建环境（检查所有必要文件）"
	@echo "  make check-deps 检查系统依赖"
	@echo "  make test-all 运行完整测试套件"
	@echo "  make help     显示此帮助信息"
	@echo ""
	@echo "快速构建（静默模式）:"
	@echo "  make quick-base 快速构建基础ISO（不显示详细输出）"
	@echo "  make quick-ai   快速构建AI ISO（不显示详细输出）"
	@echo ""
	@echo "示例:"
	@echo "  make validate && make build-ai           # 验证环境后构建AI ISO"
	@echo "  make build-ai GGUF_FILE=/path/to/model.gguf  # 使用指定模型文件构建AI ISO"
	@echo "  make build-ai GGUF_FILE=llama-2-7b.gguf      # 使用相对路径模型文件"
	@echo "  make clean-all build-base                  # 完全清理后构建基础ISO"
	@echo "  make clean-all build-ai                    # 完全清理后构建AI ISO"
	@echo "  make test && make build-ai                 # 测试环境后构建AI ISO"
	@echo "  make test-all                             # 运行完整测试套件"

# 检查必要依赖
check-deps:
	@echo "🔍 检查必要依赖..."
	@command -v mkarchiso >/dev/null 2>&1 || \
		{ echo "请安装 archiso: sudo pacman -S archiso"; exit 1; }
	@echo "✅ 所有依赖已安装"

# 验证构建环境
validate:
	@echo "🔍 验证构建环境..."
	@echo "1. 检查基础文件..."
	@if [ ! -f packages.x86_64-base ]; then echo "❌ packages.x86_64-base 不存在"; exit 1; fi
	@if [ ! -f packages.x86_64-ai ]; then echo "❌ packages.x86_64-ai 不存在"; exit 1; fi
	@if [ ! -f customize_airootfs.sh ]; then echo "❌ customize_airootfs.sh 不存在"; exit 1; fi
	@if [ ! -f customize_airootfs_chinese-support.sh ]; then echo "❌ customize_airootfs_chinese-support.sh 不存在"; exit 1; fi
	@if [ ! -f customize_airootfs_ollama.sh ]; then echo "❌ customize_airootfs_ollama.sh 不存在"; exit 1; fi
	@if [ ! -f customize_airootfs_owui-lite.sh ]; then echo "❌ customize_airootfs_owui-lite.sh 不存在"; exit 1; fi
	@if [ ! -f profiledef.sh ]; then echo "❌ profiledef.sh 不存在"; exit 1; fi
	@echo "2. 检查目录结构..."
	@if [ ! -d airootfs ]; then echo "❌ airootfs 目录不存在"; exit 1; fi
	@if [ ! -d airootfs/opt ]; then echo "❌ airootfs/opt 目录不存在"; exit 1; fi
	@if [ ! -d airootfs/opt/models ]; then echo "❌ airootfs/opt/models 目录不存在"; exit 1; fi
	@if [ ! -d airootfs/root ]; then echo "❌ airootfs/root 目录不存在"; exit 1; fi
	@echo "3. 检查模型文件..."
	@if [ -f "$(GGUF_FILE)" ]; then \
		echo "✅ 模型文件存在: $(GGUF_FILE)"; \
	else \
		echo "⚠️  模型文件不存在: $(GGUF_FILE)"; \
	fi
	@echo "4. 检查依赖..."
	@command -v mkarchiso >/dev/null 2>&1 || { echo "❌ mkarchiso 未安装"; exit 1; }
	@command -v sort >/dev/null 2>&1 || { echo "❌ sort 命令不可用"; exit 1; }
	@command -v cat >/dev/null 2>&1 || { echo "❌ cat 命令不可用"; exit 1; }
	@command -v sed >/dev/null 2>&1 || { echo "❌ sed 命令不可用"; exit 1; }
	@echo "✅ 构建环境验证通过"

# 快速构建基础ISO（不显示详细输出）
quick-base:
	@mkdir -p work out
	@cp packages.x86_64-base packages.x86_64 2>/dev/null || true
	@# 合并基础版本的customize_airootfs脚本（仅中文支持）
	@if [ -f customize_airootfs.sh ] && [ -f customize_airootfs_chinese-support.sh ]; then \
		cat customize_airootfs.sh customize_airootfs_chinese-support.sh > airootfs/root/customize_airootfs.sh 2>/dev/null || true; \
		echo "✅ 已合并基础版本customize_airootfs脚本"; \
	fi
	@# 临时修改profiledef.sh以使用基础ISO名称
	@sed -i.bak 's/iso_name=".*"/iso_name="archlinux-baseline"/' profiledef.sh
	mkarchiso -w work -o out . >/dev/null 2>&1
	@# 恢复原始profiledef.sh
	@mv profiledef.sh.bak profiledef.sh 2>/dev/null || true
	@# 重命名输出文件
	@if [ -f "out/archlinux-baseline-x86_64.iso" ]; then \
		mv "out/archlinux-baseline-x86_64.iso" "out/myaibase-base-$(date +%Y%m%d).iso"; \
		echo "📁 输出文件: out/myaibase-base-$(date +%Y%m%d).iso"; \
	fi
	@echo "✅ 基础ISO快速构建完成"

# 快速构建AI ISO（不显示详细输出）
quick-ai:
	@mkdir -p work out
	@# 复制模型文件到AI系统
	@if [ -f "$(GGUF_FILE)" ]; then \
		cp "$(GGUF_FILE)" airootfs/opt/models/ 2>/dev/null || true; \
		echo "✅ 已复制模型文件: $(GGUF_FILE)"; \
	else \
		echo "⚠️  模型文件不存在: $(GGUF_FILE)"; \
	fi
	@# 合并customize_airootfs脚本
	@if [ -f customize_airootfs.sh ] && [ -f customize_airootfs_chinese-support.sh ] && [ -f customize_airootfs_ollama.sh ] && [ -f customize_airootfs_owui-lite.sh ]; then \
		cat customize_airootfs.sh customize_airootfs_chinese-support.sh customize_airootfs_ollama.sh customize_airootfs_owui-lite.sh > airootfs/root/customize_airootfs.sh 2>/dev/null || true; \
		echo "✅ 已合并customize_airootfs脚本"; \
	fi
	@# 合并软件包
	@if [ -f packages.x86_64-base ] && [ -f packages.x86_64-ai ]; then \
		cat packages.x86_64-base packages.x86_64-ai | sort -u > packages.x86_64 2>/dev/null || true; \
		echo "✅ 已合并基础包和AI包"; \
	fi
	@# 临时修改profiledef.sh以使用AI ISO名称
	@sed -i.bak 's/iso_name=".*"/iso_name="archlinux-ai"/' profiledef.sh
	mkarchiso -w work -o out . >/dev/null 2>&1
	@# 恢复原始profiledef.sh
	@mv profiledef.sh.bak profiledef.sh 2>/dev/null || true
	@# 重命名输出文件
	@if [ -f "out/archlinux-ai-x86_64.iso" ]; then \
		mv "out/archlinux-ai-x86_64.iso" "out/myaibase-ai-$(date +%Y%m%d).iso"; \
		echo "📁 输出文件: out/myaibase-ai-$(date +%Y%m%d).iso"; \
	fi
	@# 清理临时模型文件
	@GGUF_BASENAME=$$(basename "$(GGUF_FILE)"); \
	if [ -f "airootfs/opt/models/$$GGUF_BASENAME" ]; then \
		rm -f "airootfs/opt/models/$$GGUF_BASENAME" 2>/dev/null || true; \
		echo "✅ 已删除临时模型文件: $$GGUF_BASENAME"; \
	fi
	@echo "✅ AI ISO快速构建完成"

# 显示构建信息
info:
	@echo "📊 MyAIBase 构建信息:"
	@echo "   工作目录: work/"
	@echo "   输出目录: out/"
	@echo "   配置文件: profiledef.sh"
	@echo "   软件包列表: packages.x86_64"
	@echo "   自定义脚本: airootfs/root/customize_airootfs.sh"
	@echo "   GGUF模型文件: $(GGUF_FILE)"

# 运行完整测试套件
test-all:
	@echo "🧪 开始运行完整测试套件..."
	@echo ""
	@echo "1. 验证构建环境..."
	@make validate
	@echo ""
	@echo "2. 测试依赖检查..."
	@make check-deps
	@echo ""
	@echo "3. 测试构建环境..."
	@make test
	@echo ""
	@echo "4. 测试基础ISO快速构建..."
	@make quick-base
	@echo ""
	@echo "5. 检查生成的基础ISO文件..."
	@if [ -f "out/myaibase-base-$(date +%Y%m%d).iso" ]; then \
		echo "✅ 基础ISO文件存在: out/myaibase-base-$(date +%Y%m%d).iso"; \
		ls -la "out/myaibase-base-$(date +%Y%m%d).iso"; \
	else \
		echo "❌ 基础ISO文件未找到"; \
	fi
	@echo ""
	@echo "6. 清理基础ISO构建..."
	@make clean
	@echo ""
	@echo "7. 测试AI ISO快速构建..."
	@make quick-ai
	@echo ""
	@echo "8. 检查生成的AI ISO文件..."
	@if [ -f "out/myaibase-ai-$(date +%Y%m%d).iso" ]; then \
		echo "✅ AI ISO文件存在: out/myaibase-ai-$(date +%Y%m%d).iso"; \
		ls -la "out/myaibase-ai-$(date +%Y%m%d).iso"; \
	else \
		echo "❌ AI ISO文件未找到"; \
	fi
	@echo ""
	@echo "9. 显示构建信息..."
	@make info
	@echo ""
	@echo "🎉 所有测试完成！"
	@echo "📁 生成的ISO文件在 out/ 目录中:"
	@ls -la out/ 2>/dev/null || echo "out/ 目录为空"