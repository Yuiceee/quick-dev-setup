#!/bin/bash
set -e

echo "🎨 开始配置终端环境..."

# 检测系统
OS=$(uname -s)
case "$OS" in
    Linux*) DISTRO="linux" ;;
    Darwin*) DISTRO="macos" ;;
    *) echo "❌ 不支持的系统: $OS"; exit 1 ;;
esac

# 检测并安装 zsh
if ! command -v zsh >/dev/null 2>&1; then
    echo "📦 安装 zsh..."
    case "$DISTRO" in
        linux)
            if command -v apt-get >/dev/null; then
                sudo apt-get update && sudo apt-get install -y zsh
            elif command -v yum >/dev/null; then
                sudo yum install -y zsh
            else
                echo "❌ 请手动安装 zsh"
                exit 1
            fi
            ;;
        macos)
            if command -v brew >/dev/null; then
                brew install zsh
            else
                echo "❌ 请先安装 Homebrew"
                exit 1
            fi
            ;;
    esac
else
    echo "✅ zsh 已安装"
fi

# 安装 oh-my-zsh
if [ ! -d "$HOME/.oh-my-zsh" ]; then
    echo "🔧 安装 oh-my-zsh..."
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
else
    echo "✅ oh-my-zsh 已安装"
fi

# 安装插件
echo "🔌 安装 zsh 插件..."
PLUGIN_DIR="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins"

# zsh-autosuggestions
if [ ! -d "$PLUGIN_DIR/zsh-autosuggestions" ]; then
    git clone https://github.com/zsh-users/zsh-autosuggestions "$PLUGIN_DIR/zsh-autosuggestions"
fi

# zsh-syntax-highlighting  
if [ ! -d "$PLUGIN_DIR/zsh-syntax-highlighting" ]; then
    git clone https://github.com/zsh-users/zsh-syntax-highlighting "$PLUGIN_DIR/zsh-syntax-highlighting"
fi

# 配置 .zshrc
echo "⚙️ 配置 .zshrc..."
if grep -q "plugins=(git)" "$HOME/.zshrc"; then
    sed -i.bak 's/plugins=(git)/plugins=(git zsh-autosuggestions zsh-syntax-highlighting)/' "$HOME/.zshrc"
    echo "✅ 插件配置已更新"
else
    echo "⚠️ 请手动添加插件到 .zshrc: plugins=(git zsh-autosuggestions zsh-syntax-highlighting)"
fi

# 设置默认 shell
if [ "$SHELL" != "$(which zsh)" ]; then
    echo "🔄 设置 zsh 为默认 shell..."
    chsh -s "$(which zsh)"
    echo "✅ 请重启终端生效"
fi

echo ""
echo "🎉 终端配置完成！"
echo "🔄 请重启终端或执行: exec zsh"