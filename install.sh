#!/usr/bin/env bash
# pj 一键安装脚本
# 支持: macOS (bash/zsh), Linux (bash), Windows (PowerShell)

set -e

PJ_INSTALL_DIR="${PJ_INSTALL_DIR:-$HOME/.local/share/pj}"
PJ_REPO="${PJ_REPO:-https://github.com/jalon-dg/pj.git}"

detect_os() {
    case "$(uname -s)" in
        Darwin*)  echo "macos";;
        Linux*)   echo "linux";;
        CYGWIN*|MINGW*|MSYS*) echo "windows";;
        *)        echo "unknown";;
    esac
}

install_bash() {
    echo "📦 安装 pj (bash/zsh)..."

    # 克隆或更新
    if [[ -d "$PJ_INSTALL_DIR/.git" ]]; then
        echo "📥 更新现有安装..."
        git -C "$PJ_INSTALL_DIR" pull origin main 2>/dev/null || echo "   更新失败，使用现有版本"
    else
        echo "📥 克隆仓库..."
        rm -rf "$PJ_INSTALL_DIR"
        git clone "$PJ_REPO" "$PJ_INSTALL_DIR"
    fi

    # 检测 shell 配置文件
    local shell_config=""
    if [[ -n "$ZSH_VERSION" ]]; then
        shell_config="$HOME/.zshrc"
    elif [[ -n "$BASH_VERSION" ]]; then
        if [[ "$(uname -s)" == "Darwin" ]]; then
            shell_config="$HOME/.bash_profile"
        else
            shell_config="$HOME/.bashrc"
        fi
    fi

    # 添加 source 行
    local source_line="source \"$PJ_INSTALL_DIR/pj.sh\""
    if [[ -f "$shell_config" ]] && ! grep -q "pj/pj.sh" "$shell_config"; then
        echo "" >> "$shell_config"
        echo "# pj - 快速项目跳转工具" >> "$shell_config"
        echo "$source_line" >> "$shell_config"
        echo "✅ 已添加到 $shell_config"
    elif [[ ! -f "$shell_config" ]]; then
        echo "$source_line" >> "$shell_config"
        echo "✅ 已创建 $shell_config"
    fi

    echo "✅ 安装完成！"
    echo "   请执行: source $shell_config"
    echo "   或重启终端"
}

install_powershell() {
    echo "📦 安装 pj (PowerShell)..."

    local install_dir="$HOME\Documents\PowerShell\Modules\pj"

    # 克隆或更新
    if (Test-Path "$install_dir\.git") {
        Write-Host "📥 更新现有安装..."
        git -C "$install_dir" pull origin main 2>$null || Write-Host "   更新失败，使用现有版本"
    } else {
        Write-Host "📥 克隆仓库..."
        if (Test-Path "$install_dir") {
            Remove-Item -Path "$install_dir" -Recurse -Force
        }
        git clone "$PJ_REPO" "$install_dir"
    }

    # 添加到 PowerShell 配置
    $source_line = ". `"$install_dir\pj.ps1`""
    $profile_dir = Split-Path $PROFILE -Parent

    if (-not (Test-Path $PROFILE)) {
        New-Item -ItemType File -Path $PROFILE -Force | Out-Null
    }

    if (-not (Select-String -Path $PROFILE -Pattern "pj.ps1" -Quiet)) {
        Add-Content -Path $PROFILE -Value "`n# pj - 快速项目跳转工具"
        Add-Content -Path $PROFILE -Value $source_line
        Write-Host "✅ 已添加到 PowerShell 配置"
    }

    Write-Host "✅ 安装完成！"
    Write-Host "   请重启 PowerShell 或执行: . `$PROFILE"
}

# 主逻辑
main() {
    local os
    os=$(detect_os)

    echo "🧩 pj 安装脚本"
    echo "   系统: $os"
    echo "   安装目录: $PJ_INSTALL_DIR"
    echo ""

    case "$os" in
        macos|linux)
            install_bash
            ;;
        windows)
            install_powershell
            ;;
        *)
            echo "❌ 不支持的操作系统"
            exit 1
            ;;
    esac
}

main "$@"