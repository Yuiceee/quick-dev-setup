#!/bin/bash
set -e

echo "🚀 开始安装 pixi + uv 开发环境..."
echo ""

# ---------------------
# 检测 shell 类型，找对 rc 文件
# ---------------------
current_shell=$(basename "$SHELL")
case "$current_shell" in
    bash)
        rc_file="$HOME/.bashrc"
        ;;
    zsh)
        rc_file="$HOME/.zshrc"
        ;;
    fish)
        rc_file="$HOME/.config/fish/config.fish"
        ;;
    *)
        rc_file="$HOME/.profile"
        ;;
esac
echo "📄 将修改你的环境文件: $rc_file"


# ---------------------
# 智能代理检查
# ---------------------
check_rsproxy() {
    curl --connect-timeout 5 -s https://rsproxy.cn > /dev/null
}

echo "🌐 检查是否存在代理环境变量..."
if env | grep -qiE 'http_proxy|https_proxy'; then
    echo "⚠️ 发现你存在代理环境变量："
    env | grep -iE 'http_proxy|https_proxy'
    echo "🔍 正在测试你的代理能否访问 rsproxy.cn ..."
    if check_rsproxy; then
        echo "✅ 你的代理可正常访问 rsproxy.cn，无需修改。"
    else
        echo "❗ 你的代理无法访问 rsproxy.cn，将临时关闭代理环境变量..."
        unset http_proxy https_proxy ftp_proxy all_proxy HTTP_PROXY HTTPS_PROXY FTP_PROXY ALL_PROXY
    fi
else
    echo "🔍 没发现代理，跳过。"
fi


# ---------------------
# 配置 Rust 镜像源
# ---------------------
echo "🔧 配置 Rust 镜像..."
{
    echo 'export RUSTUP_DIST_SERVER="https://rsproxy.cn"'
    echo 'export RUSTUP_UPDATE_ROOT="https://rsproxy.cn/rustup"'
} >> "$rc_file"
# 移除这里的 source 命令，避免在 bash 环境下加载 zsh 配置
# source "$rc_file"


# ---------------------
# 安装 Rust
# ---------------------
echo "🦀 安装 Rust (使用 rsproxy)..."
# 临时设置环境变量
export RUSTUP_DIST_SERVER="https://rsproxy.cn"
export RUSTUP_UPDATE_ROOT="https://rsproxy.cn/rustup"
curl --proto '=https' --tlsv1.2 -sSf https://rsproxy.cn/rustup-init.sh | sh -s -- -y
source "$HOME/.cargo/env"


# ---------------------
# 配置 cargo 镜像源
# ---------------------
echo "🔧 配置 cargo 镜像..."
mkdir -p ~/.cargo
cat > ~/.cargo/config.toml <<EOF
[source.crates-io]
replace-with = 'rsproxy-sparse'
[source.rsproxy]
registry = "https://rsproxy.cn/crates.io-index"
[source.rsproxy-sparse]
registry = "sparse+https://rsproxy.cn/index/"
[registries.rsproxy]
index = "https://rsproxy.cn/crates.io-index"
[net]
git-fetch-with-cli = true
EOF


# ---------------------
# Git SSH 配置
# ---------------------
echo "🔧 配置 Git 强制使用 ssh..."
git config --global url."git@github.com:".insteadOf "https://github.com/"

mkdir -p ~/.ssh
cat > ~/.ssh/config <<EOF
Host github.com
    Hostname ssh.github.com
    Port 443
    User git
EOF


# ---------------------
# 安装 pixi
# ---------------------
echo "📥 安装 pixi..."
cargo install --locked --git ssh://git@github.com/prefix-dev/pixi.git pixi


# ---------------------
# 配置 pixi 镜像源
# ---------------------
echo "🔧 配置 pixi 镜像源..."
mkdir -p ~/.config/pixi
cat > ~/.config/pixi/config.toml <<EOF
default-channels = ["conda-forge", "bioconda"]

[shell]
change-ps1 = true
force-activate = true
source-completion-scripts = false

[mirrors]
"https://conda.anaconda.org/conda-forge" = ["https://mirrors.tuna.tsinghua.edu.cn/anaconda/cloud/conda-forge"]
"https://conda.anaconda.org/msys2" = ["https://mirrors.tuna.tsinghua.edu.cn/anaconda/cloud/msys2"]
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


# ---------------------
# 配置 uv 镜像源
# ---------------------
echo "🔧 配置 uv 镜像源..."
mkdir -p ~/.config/uv
cat > ~/.config/uv/uv.toml <<EOF
[[index]]
url = "https://mirrors.tuna.tsinghua.edu.cn/pypi/web/simple"
default = true
EOF


# ---------------------
# 添加 pixi 到 PATH
# ---------------------
echo "🔧 添加 pixi 到 PATH..."
if ! grep -q 'PIXI_HOME' "$rc_file"; then
    {
        echo 'export PIXI_HOME="$HOME/.pixi"'
        echo 'export PATH="$PIXI_HOME/bin:$PATH"'
    } >> "$rc_file"
    # 移除 source 命令，避免兼容性问题
    # source "$rc_file"
else
    echo "✅ $rc_file 已经存在 PIXI_HOME，跳过重复添加"
fi


# ---------------------
# 安装全局工具 ruff 和 uv
# ---------------------
echo "📦 安装 ruff 和 uv..."
# 临时添加 pixi 到 PATH
export PIXI_HOME="$HOME/.pixi"
export PATH="$PIXI_HOME/bin:$PATH"
pixi global install ruff uv


# ---------------------
# 是否安装 Starship
# ---------------------
echo ""
read -p "⭐️ 是否需要安装 Starship Shell 美化 (y/n)? " need_starship
if [[ "$need_starship" == "y" || "$need_starship" == "Y" ]]; then
    platform=$(uname -s)
    echo "🚀 安装 Starship..."
    curl -sS https://starship.rs/install.sh | sh

    echo "🔧 配置 $current_shell 启动 Starship..."
    case "$current_shell" in
        bash)
            echo 'eval "$(starship init bash)"' >> "$rc_file"
            ;;
        zsh)
            echo 'eval "$(starship init zsh)"' >> "$rc_file"
            ;;
    esac
    echo "✅ Starship 配置完成（请重新打开终端生效）"
else
    echo "❎ 跳过安装 Starship"
fi


# ---------------------
# 完成提示
# ---------------------
echo ""
echo "🎉 全部完成！"
echo "🔄 请重新打开终端或执行： source $rc_file"
echo ""
echo "🚀 你可以用以下命令开始使用："
echo "    pixi init / pixi shell / uv pip install ..."
echo ""
