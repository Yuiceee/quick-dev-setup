# 开发环境快速设置

##  zsh及其插件

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/Yuiceee/quick-dev-setup/main/terminal_setup_install.sh)"

```

## Pixi + uv 环境快速一键安装脚本

🚀 一键为 Linux / macOS 安装并配置好：
- Rust (国内镜像)
- Pixi (国内镜像)
- uv (国内镜像)
- ruff / uv 全局工具
- 可选是否使用Starship



```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/Yuiceee/quick-dev-setup/main/install.sh)"

# 安装磁盘使用分析工具
cargo install du-dust

```

## 常用软件安装

### 系统工具
```bash
# 更新包管理器
apt update

# 安装终端复用器
apt install tmux

```

### GPU监控工具
```bash
# 使用uv安装nvitop
uv add global nvitop

# 或使用pip安装
pip install nvitop
```

### 设置缓存路径
写到环境变量里
```bash
# 设置uv缓存路径
export UV_CACHE_DIR=~/.cache/uv

# 设置pixi缓存路径
export PIXI_CACHE_DIR=~/.cache/pixi

```



### AI编程助手
```bash
# 安装npm
# 添加 NodeSource 仓库
curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -
# 安装 Node.js
sudo apt-get install -y nodejs


# 安装Claude Code
npm install -g @anthropic-ai/claude-code

# 安装OpenAI Codex
npm install -g @openai/codex@latest
```

## 网络代理

### Clash代理安装
参考项目：[clash-for-linux-install](https://github.com/nelvko/clash-for-linux-install)

```bash
# 下载并安装clash
git clone --branch master --depth 1 https://gh-proxy.org/https://github.com/nelvko/clash-for-linux-install.git \
  && cd clash-for-linux-install \
  && bash install.sh
```

### 配置文档
- [Codex安装与配置](https://docs.ikuncode.cc/deploy/codex#🐧-linux-平台)
- [Claude Code安装与配置](https://docs.ikuncode.cc/deploy/claude-code#🐧-linux-平台)

