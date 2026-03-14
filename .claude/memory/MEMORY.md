# pj 项目开发记忆

## 项目概述

**pj** - 快速项目跳转工具，一个跨平台的 shell 插件，用于在多个 git 项目目录之间快速切换。

## GitHub

- 仓库: https://github.com/jalon-dg/pj
- 可见性: 公开
- 分支保护: main 需要 PR + 1 人审批

## 支持的平台

| 平台 | Shell | 脚本 |
|------|-------|------|
| macOS | bash/zsh | pj.sh |
| Linux | bash | pj.sh |
| Windows | PowerShell 5.1+ | pj.ps1 |

## 安装方式

- 一键安装: `curl -sL https://raw.githubusercontent.com/jalon-dg/pj/main/install.sh | bash`
- Homebrew: `brew tap jalon-dg/pj && brew install pj`
- Claude Code: 对 Claude 说"安装 pj"

## 开发历史

### v1.0.0 - 初始版本
- 跨平台支持 (macOS/Linux/Windows)
- 模糊搜索项目
- 缓存机制
- 自动追踪 git clone

### 开发中的功能
- git clone 自动追踪 bug (已修复: has_clone -eq 0 -> 1)
- Claude Code skill 集成

## 关键文件

- `pj.sh` - bash/zsh 主脚本
- `pj.ps1` - PowerShell 版本
- `install.sh` - 一键安装脚本
- `Formula/pj.rb` - Homebrew formula
- `~/.claude/skills/pj/SKILL.md` - Claude Code skill

## 技术细节

- 默认项目目录: `~/Documents/Projects`
- 配置目录: `~/.pj-dirs`
- 缓存文件: `~/.pj-dirs/cache`