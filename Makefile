# MyAIBase Makefile
# 用于简化 Arch Linux AI 系统镜像构建过程

.PHONY: all build build-base build-ai clean clean-all prepare test test-all help

# 默认目标（构建AI ISO）
all: build-ai

# 构建基础 ISO 镜像（仅基础系统）
build-base: prepare
	@echo "🚀 开始构建 MyAIBase 基础 ISO 镜像..."
	@echo "📦 使用基础软件包: packages.x86_64-base"
	@if [ -f packages.x86_64-base ]; then \
		cp packages.x86_64-base packages.x86_64; \
		echo "✅ 已使用基础软件包替换"; \
	else \
		echo "❌ 基础软件包文件不存在: packages.x86_64-base"; exit 1; \
	fi
	@# 临时修改profiledef.sh以使用基础ISO名称
	@sed -i.bak 's/iso_name=".*"/iso_name="archlinux-baseline"/' profiledef.sh
	mkarchiso -v -w work -o out .
	@# 恢复原始profiledef.sh
	@mv profiledef.sh.bak profiledef.sh 2>/dev/null || true
	@# 重命名输出文件
	@if [ -f "out/archlinux-baseline-x86_64.iso" ]; then \
		mv "out/archlinux-baseline-x86_64.iso" "out/myaibase-base-$(date +%Y%m%d).iso"; \
		echo "📁 输出文件: out/myaibase-base-$(date +%Y%m%d).iso"; \
	fi
	@echo "✅ 基础 ISO 构建完成！文件位于 out/ 目录"

# 构建 AI ISO 镜像（基础系统 + AI组件）
build-ai: prepare
	@echo "🚀 开始构建 MyAIBase AI ISO 镜像..."
	@echo "📦 复制模型文件到AI系统..."
	@if [ -f "airootfs/opt/models/Qwen3-0.6B-Q8_0.gguf" ]; then \
		cp "airootfs/opt/models/Qwen3-0.6B-Q8_0.gguf" airootfs/opt/models/; \
		echo "✅ 已复制模型文件: Qwen3-0.6B-Q8_0.gguf"; \
	else \
		echo "⚠️  模型文件不存在: airootfs/opt/models/Qwen3-0.6B-Q8_0.gguf"; \
	fi
	@echo "📦 合并基础软件包和AI软件包"
	@if [ -f packages.x86_64-base ] && [ -f packages.x86_64-ai ]; then \
		cat packages.x86_64-base packages.x86_64-ai | sort -u > packages.x86_64; \
		echo "✅ 已合并基础包和AI包"; \
	else \
		echo "❌ 软件包文件不存在: packages.x86_64-base 或 packages.x86_64-ai"; exit 1; \
	fi
	@# 临时修改profiledef.sh以使用AI ISO名称
	@sed -i.bak 's/iso_name=".*"/iso_name="archlinux-ai"/' profiledef.sh
	mkarchiso -v -w work -o out .
	@# 恢复原始profiledef.sh
	@mv profiledef.sh.bak profiledef.sh 2>/dev/null || true
	@# 重命名输出文件
	@if [ -f "out/archlinux-ai-x86_64.iso" ]; then \
		mv "out/archlinux-ai-x86_64.iso" "out/myaibase-ai-$(date +%Y%m%d).iso"; \
		echo "📁 输出文件: out/myaibase-ai-$(date +%Y%m%d).iso"; \
	fi
	@echo "🧹 清理临时模型文件..."
	@if [ -f "airootfs/opt/models/Qwen3-0.6B-Q8_0.gguf" ]; then \
		rm -f "airootfs/opt/models/Qwen3-0.6B-Q8_0.gguf"; \
		echo "✅ 已删除临时模型文件: Qwen3-0.6B-Q8_0.gguf"; \
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

# 完全清理（包括输出目录）
clean-all:
	@echo "🧹 完全清理工作目录和输出目录..."
	rm -rf work/* out/*

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
	@echo "使用方法:"
	@echo "  make          构建 AI ISO 镜像（默认目标）"
	@echo "  make build-ai 构建 AI ISO 镜像（基础 + AI组件）"
	@echo "  make build-base 构建基础 ISO 镜像（仅基础系统）"
	@echo "  make prepare  准备构建工作目录"
	@echo "  make clean   清理工作目录"
	@echo "  make clean-all 完全清理工作目录和输出目录"
	@echo "  make test     测试构建环境"
	@echo "  make test-all 运行完整测试套件"
	@echo "  make help     显示此帮助信息"
	@echo ""
	@echo "示例:"
	@echo "  make clean-all build-base  # 完全清理后构建基础ISO"
	@echo "  make clean-all build-ai    # 完全清理后构建AI ISO"
	@echo "  make test && make build-ai # 测试环境后构建AI ISO"
	@echo "  make test-all             # 运行完整测试套件"

# 检查必要依赖
check-deps:
	@echo "🔍 检查必要依赖..."
	@command -v mkarchiso >/dev/null 2>&1 || \
		{ echo "请安装 archiso: sudo pacman -S archiso"; exit 1; }
	@echo "✅ 所有依赖已安装"

# 快速构建基础ISO（不显示详细输出）
quick-base:
	@mkdir -p work out
	@cp packages.x86_64-base packages.x86_64 2>/dev/null || true
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
	@if [ -f "..airootfs/opt/models/Qwen3-0.6B-Q8_0.gguf" ]; then \
		cp "airootfs/opt/models/Qwen3-0.6B-Q8_0.gguf" airootfs/opt/models/ 2>/dev/null || true; \
	fi
	@cat packages.x86_64-base packages.x86_64-ai | sort -u > packages.x86_64 2>/dev/null || true
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
	@if [ -f "airootfs/opt/models/Qwen3-0.6B-Q8_0.gguf" ]; then \
		rm -f "airootfs/opt/models/Qwen3-0.6B-Q8_0.gguf" 2>/dev/null || true; \
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

# 运行完整测试套件
test-all:
	@echo "🧪 开始运行完整测试套件..."
	@echo ""
	@echo "1. 测试依赖检查..."
	@make check-deps
	@echo ""
	@echo "2. 测试构建环境..."
	@make test
	@echo ""
	@echo "3. 测试基础ISO快速构建..."
	@make quick-base
	@echo ""
	@echo "4. 检查生成的基础ISO文件..."
	@if [ -f "out/myaibase-base-$(date +%Y%m%d).iso" ]; then \
		echo "✅ 基础ISO文件存在: out/myaibase-base-$(date +%Y%m%d).iso"; \
		ls -la "out/myaibase-base-$(date +%Y%m%d).iso"; \
	else \
		echo "❌ 基础ISO文件未找到"; \
	fi
	@echo ""
	@echo "5. 清理基础ISO构建..."
	@make clean
	@echo ""
	@echo "6. 测试AI ISO快速构建..."
	@make quick-ai
	@echo ""
	@echo "7. 检查生成的AI ISO文件..."
	@if [ -f "out/myaibase-ai-$(date +%Y%m%d).iso" ]; then \
		echo "✅ AI ISO文件存在: out/myaibase-ai-$(date +%Y%m%d).iso"; \
		ls -la "out/myaibase-ai-$(date +%Y%m%d).iso"; \
	else \
		echo "❌ AI ISO文件未找到"; \
	fi
	@echo ""
	@echo "8. 显示构建信息..."
	@make info
	@echo ""
	@echo "🎉 所有测试完成！"
	@echo "📁 生成的ISO文件在 out/ 目录中:"
	@ls -la out/ 2>/dev/null || echo "out/ 目录为空"