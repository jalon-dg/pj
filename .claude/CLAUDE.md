# CLAUDE.md - pj 项目

## 项目类型

这是一个 zsh/bash/PowerShell 脚本项目，用于快速在 git 项目目录之间切换。

## 关键文件

- `pj.sh` - bash/zsh 版本 (主要)
- `pj.ps1` - PowerShell 版本 (Windows)
- `install.sh` - 一键安装脚本
- `Formula/pj.rb` - Homebrew formula
- `README.md` - 项目文档

## 开发规则

1. 所有 API 相关功能需要 API 测试
2. 所有界面交互需要交互测试
3. shell 脚本使用 `bash -n` 检查语法

## 测试命令

```bash
# bash 语法检查
bash -n pj.sh

# 本地测试
source pj.sh
pj list
pj help
```