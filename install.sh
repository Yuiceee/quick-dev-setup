#!/bin/bash
set -e

echo "🚀 开始安装 pixi + uv 开发环境..."

# 检测 shell 配置文件
current_shell=$(basename "$SHELL")
case "$current_shell" in
    bash) rc_file="$HOME/.bashrc" ;;
    zsh) rc_file="$HOME/.zshrc" ;;
    fish) rc_file="$HOME/.config/fish/config.fish" ;;
    *) rc_file="$HOME/.profile" ;;
esac
echo "📄 配置文件: $rc_file"

# 网络检查函数
check_url() { curl --connect-timeout 5 -s "$1" >/dev/null; }

# 检查网络环境
echo "🌐 检查网络环境..."

# 检查是否能访问官方源
CAN_ACCESS_OFFICIAL=false
if env | grep -qiE 'http_proxy|https_proxy'; then
    echo "⚠️ 发现代理环境变量"
    if check_url https://pixi.sh; then
        echo "✅ 代理可访问官方源"
        CAN_ACCESS_OFFICIAL=true
    else
        echo "❗ 代理无法访问官方源，清除代理变量"
        unset http_proxy https_proxy ftp_proxy all_proxy HTTP_PROXY HTTPS_PROXY FTP_PROXY ALL_PROXY
    fi
else
    if check_url https://pixi.sh; then
        echo "✅ 可直接访问官方源"
        CAN_ACCESS_OFFICIAL=true
    else
        echo "❌ 无法访问官方源"
    fi
fi

# 配置 Rust 环境
if [ "$CAN_ACCESS_OFFICIAL" = false ]; then
    echo "🔧 配置 Rust 镜像"
    echo 'export RUSTUP_DIST_SERVER="https://rsproxy.cn"' >> "$rc_file"
    echo 'export RUSTUP_UPDATE_ROOT="https://rsproxy.cn/rustup"' >> "$rc_file"
fi

# 安装 Rust
if [ "$CAN_ACCESS_OFFICIAL" = true ]; then
    echo "🦀 安装 Rust"
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
else
    echo "🦀 安装 Rust (镜像)"
    export RUSTUP_DIST_SERVER="https://rsproxy.cn"
    export RUSTUP_UPDATE_ROOT="https://rsproxy.cn/rustup"
    curl --proto '=https' --tlsv1.2 -sSf https://rsproxy.cn/rustup-init.sh | sh -s -- -y
fi
source "$HOME/.cargo/env"

# 配置 cargo 镜像
if [ "$CAN_ACCESS_OFFICIAL" = false ]; then
    echo "🔧 配置 cargo 镜像"
    mkdir -p ~/.cargo
    cat > ~/.cargo/config.toml <<EOF
[source.crates-io]
replace-with = 'rsproxy-sparse'
[source.rsproxy-sparse]
registry = "sparse+https://rsproxy.cn/index/"
EOF
fi

# 配置 Git SSH (网络受限时)
if [ "$CAN_ACCESS_OFFICIAL" = false ]; then
    echo "🔧 配置 Git SSH"
    git config --global url."git@github.com:".insteadOf "https://github.com/"
    mkdir -p ~/.ssh
    echo -e "Host github.com\n    Hostname ssh.github.com\n    Port 443\n    User git" >> ~/.ssh/config
fi

# 安装 pixi
if [ "$CAN_ACCESS_OFFICIAL" = true ]; then
    echo "📥 安装 pixi"
    curl -fsSL https://pixi.sh/install.sh | sh
else
    echo "📥 安装 pixi (源码)"
    cargo install --locked --git ssh://git@github.com/prefix-dev/pixi.git pixi
    # 添加到 PATH
    if ! grep -q 'PIXI_HOME' "$rc_file"; then
        echo 'export PIXI_HOME="$HOME/.pixi"' >> "$rc_file"
        echo 'export PATH="$PIXI_HOME/bin:$PATH"' >> "$rc_file"
    fi
fi

# 配置镜像源
echo "🔧 配置 pixi 和 uv 镜像源"
mkdir -p ~/.config/pixi ~/.config/uv
cat > ~/.config/pixi/config.toml <<EOF
default-channels = ["conda-forge", "bioconda"]

[shell]
change-ps1 = true
force-activate = true
source-completion-scripts = false

[mirrors]
"https://conda.anaconda.org/conda-forge" = ["https://mirrors.tuna.tsinghua.edu.cn/anaconda/cloud/conda-forge"]
"https://conda.anaconda.org/bioconda" = ["https://mirrors.tuna.tsinghua.edu.cn/anaconda/cloud/bioconda"]
"https://conda.anaconda.org/menpo" = ["https://mirrors.tuna.tsinghua.edu.cn/anaconda/cloud/menpo"]
"https://conda.anaconda.org/pytorch" = ["https://mirrors.tuna.tsinghua.edu.cn/anaconda/cloud/pytorch"]
"https://conda.anaconda.org/pytorch-lts" = ["https://mirrors.tuna.tsinghua.edu.cn/anaconda/cloud/pytorch-lts"]
"https://conda.anaconda.org/simpleitk" = ["https://mirrors.tuna.tsinghua.edu.cn/anaconda/cloud/simpleitk"]
"https://conda.anaconda.org/deepmodeling" = ["https://mirrors.tuna.tsinghua.edu.cn/anaconda/cloud/deepmodeling"]
"https://conda.anaconda.org/nvidia" = ["https://mirrors.sustech.edu.cn/anaconda-extra/cloud/nvidia"]

[pypi-config]
index-url = "https://mirrors.tuna.tsinghua.edu.cn/pypi/web/simple"
EOF
cat > ~/.config/uv/uv.toml <<EOF
[[index]]
url = "https://mirrors.tuna.tsinghua.edu.cn/pypi/web/simple"
default = true
EOF


# 安装全局工具
echo "📦 安装 ruff 和 uv"
if [ "$CAN_ACCESS_OFFICIAL" = true ]; then
    source "$HOME/.bashrc" 2>/dev/null || source "$HOME/.zshrc" 2>/dev/null || true
else
    export PIXI_HOME="$HOME/.pixi"
    export PATH="$PIXI_HOME/bin:$PATH"
fi
pixi global install ruff uv

# 可选安装 Starship
read -p "⭐️ 是否安装 Starship 终端美化 (y/n)? " need_starship
if [[ "$need_starship" =~ ^[Yy]$ ]]; then
    echo "🚀 安装 Starship"
    curl -sS https://starship.rs/install.sh | sh
    case "$current_shell" in
        bash) echo 'eval "$(starship init bash)"' >> "$rc_file" ;;
        zsh) echo 'eval "$(starship init zsh)"' >> "$rc_file" ;;
    esac
    echo "✅ Starship 已配置"
fi

echo ""
echo "🎉 安装完成！"
echo "🔄 请重启终端或执行: source $rc_file"
echo "🚀 开始使用: pixi init / pixi shell / uv pip install / uv sync"
