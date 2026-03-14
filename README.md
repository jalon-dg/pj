# pj - 快速项目跳转工具

一款跨平台的 shell 插件，快速在多个 git 项目目录之间切换。

## 支持的平台

| 平台 | Shell | 脚本 |
|------|-------|------|
| macOS | bash / zsh | `pj.sh` |
| Linux | bash | `pj.sh` |
| Windows | PowerShell 5.1+ | `pj.ps1` |

## 功能特性

- 快速列出所有 git 仓库
- 模糊搜索项目并跳转
- 自动缓存项目列表，提升性能
- 支持添加自定义监控目录
- 自动追踪 git clone 创建的新项目（仅 bash/zsh）

## 安装

### macOS / Linux (bash)

```bash
# 克隆到 ~/.local/share/pj 目录
git clone https://github.com/yourusername/pj.git ~/.local/share/pj

# 在 .bashrc 或 .zshrc 中添加
echo 'source ~/.local/share/pj/pj.sh' >> ~/.bashrc
# 或 zsh
echo 'source ~/.local/share/pj/pj.sh' >> ~/.zshrc

# 重新加载 shell
source ~/.bashrc
```

### Windows (PowerShell)

```powershell
# 克隆到 $HOME\Documents\PowerShell\Modules\pj 目录
git clone https://github.com/yourusername/pj.git "$HOME\Documents\PowerShell\Modules\pj"

# 在 PowerShell 配置中添加
# 每次使用前执行:
. "$HOME\Documents\PowerShell\Modules\pj\pj.ps1"

# 或添加到 PowerShell 配置文件
Add-Content -Path $PROFILE -Value '. "$HOME\Documents\PowerShell\Modules\pj\pj.ps1"'
```

## 使用方法

```bash
# 列出所有项目（使用缓存）
pj list
pj l

# 模糊搜索并进入项目
pj -p <关键词>

# 精确匹配项目名（从默认目录）
pj <项目名>

# 添加自定义监控目录
pj adddir /path/to/your/projects

# 强制刷新缓存
pj refresh
pj r

# 查看帮助
pj help
pj -h
```

## 配置

### 默认监控目录

| 平台 | 默认目录 |
|------|----------|
| macOS | `~/Documents/Projects` |
| Linux | `~/Documents/Projects` |
| Windows | `~\Documents\Projects` |

### 自定义配置目录

**bash/zsh:**
```bash
export PJ_CONFIG_DIR="$HOME/.my-pj-config"
```

**PowerShell:**
```powershell
$env:PJ_CONFIG_DIR = "$HOME\.my-pj-config"
```

### 自定义项目目录

**bash/zsh:**
```bash
export PJ_PROJECTS_DIR="$HOME/my-projects"
```

**PowerShell:**
```powershell
$env:PJ_PROJECTS_DIR = "$HOME\my-projects"
```

## 依赖

| 依赖 | 说明 |
|------|------|
| bash 4.0+ / zsh 5.0+ / PowerShell 5.1+ | Shell 环境 |
| git | 扫描 .git 目录 |
| find | 查找项目目录 (bash/zsh) |