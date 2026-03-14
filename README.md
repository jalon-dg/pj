# pj - 快速项目跳转工具

一款 zsh 插件，快速在多个 git 项目目录之间切换。

## 功能特性

- 快速列出所有 git 仓库
- 模糊搜索项目并跳转
- 自动缓存项目列表，提升性能
- 支持添加自定义监控目录
- 自动追踪 git clone 创建的新项目

## 安装

```bash
# 方式1: 克隆到 ~/.zsh/pj 目录
git clone https://github.com/yourusername/pj.git ~/.zsh/pj

# 在 .zshrc 中添加
source ~/.zsh/pj/pj.sh
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

默认监控目录: `~/Documents/Projects`

可通过环境变量自定义配置目录:
```bash
export PJ_CONFIG_DIR="$HOME/.my-pj-config"
```

## 依赖

- zsh
- find 命令