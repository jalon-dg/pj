# pj - 快速切换到 git 项目目录 (PowerShell 版本)
# 支持: Windows PowerShell 5.1+ / PowerShell 7+
# 使用方式: . ./pj.ps1

# 配置目录（可自定义）
$PJ_CONFIG_DIR = if ($env:PJ_CONFIG_DIR) { $env:PJ_CONFIG_DIR } else { "$HOME\.pj-dirs" }

# 默认项目目录
$PJ_PROJECTS_DIR = if ($env:PJ_PROJECTS_DIR) { $env:PJ_PROJECTS_DIR } else { "$HOME\Documents\Projects" }

# 打印带颜色的消息
function Write-PjColor {
    param(
        [string]$Message,
        [string]$Color = "White"
    )

    $colors = @{
        "Green"  = "`e[0;32m"
        "Yellow" = "`e[0;33m"
        "Red"    = "`e[0;31m"
        "Blue"   = "`e[0;34m"
        "Cyan"   = "`e[0;36m"
    }

    $reset = "`e[0m"

    if ($colors.ContainsKey($Color)) {
        Write-Host "$($colors[$Color])$Message$reset"
    } else {
        Write-Host $Message
    }
}

# 确保配置目录存在
function Initialize-PjConfig {
    if (-not (Test-Path $PJ_CONFIG_DIR)) {
        New-Item -ItemType Directory -Path $PJ_CONFIG_DIR -Force | Out-Null
    }
}

# 刷新缓存
function Refresh-PjCache {
    $dirs = @($PJ_PROJECTS_DIR)

    # 读取自定义目录
    $dirsFile = Join-Path $PJ_CONFIG_DIR "dirs"
    if (Test-Path $dirsFile) {
        Get-Content $dirsFile | ForEach-Object {
            $dir = $_.Trim()
            if ($dir -and (Test-Path $dir)) {
                $dirs += $dir
            }
        }
    }

    # 扫描项目
    $projects = @()
    foreach ($projDir in $dirs) {
        if (Test-Path $projDir) {
            $gitDirs = Get-ChildItem -Path $projDir -Recurse -Directory -Filter ".git" -ErrorAction SilentlyContinue
            foreach ($gitDir in $gitDirs) {
                $projects += $gitDir.Parent.FullName
            }
        }
    }

    # 保存缓存
    $cacheFile = Join-Path $PJ_CONFIG_DIR "cache"
    $timestamp = [int](Get-Date -UnixTimeSeconds)
    $content = "TIMESTAMP:$timestamp`n"
    $content += ($projects -join "`n")
    Set-Content -Path $cacheFile -Value $content -Force

    Write-PjColor "✅ 缓存已刷新，共 $($projects.Count) 个项目" -Color "Green"
}

# 加载缓存
function Get-PjCache {
    $cacheFile = Join-Path $PJ_CONFIG_DIR "cache"
    $CACHE_TTL = 3153600000  # 100 年

    if (Test-Path $cacheFile) {
        $lines = Get-Content $cacheFile
        if ($lines.Count -gt 0) {
            $firstLine = $lines[0]
            if ($firstLine -match "TIMESTAMP:(\d+)") {
                $timestamp = [int]$Matches[1]
                $now = [int](Get-Date -UnixTimeSeconds)
                $age = $now - $timestamp

                if ($age -lt $CACHE_TTL) {
                    # 缓存有效
                    return ($lines | Select-Object -Skip 1 | Where-Object { $_ -and (Test-Path $_) })
                }
            }
        }
    }
    return @()
}

# 主函数
function pj {
    param(
        [string]$Command = "",
        [string]$Arg1 = "",
        [string]$Arg2 = ""
    )

    # 检查 git 是否安装
    $gitCmd = Get-Command git -ErrorAction SilentlyContinue
    if (-not $gitCmd) {
        Write-PjColor "❌ pj 依赖 git，请先安装 git" -Color "Red"
        Write-Host "   Windows: winget install Git.Git 或从 https://git-scm.com 下载"
        return
    }

    # 确保配置目录存在
    Initialize-PjConfig

    # 处理命令
    switch ($Command) {
        "refresh" {
            Refresh-PjCache
            return
        }
        "r" {
            Refresh-PjCache
            return
        }
        "adddir" {
            $newDir = $Arg1
            if (-not $newDir) {
                Write-Host "用法: pj adddir <目录路径>"
                Write-Host "示例: pj adddir C:\Users\zcr\my-projects"
                return
            }
            if (-not (Test-Path $newDir)) {
                Write-PjColor "❌ 目录不存在: ${newDir}" -Color "Red"
                return
            }
            $dirsFile = Join-Path $PJ_CONFIG_DIR "dirs"
            if ((Test-Path $dirsFile) -and (Get-Content $dirsFile | Where-Object { $_ -eq $newDir })) {
                Write-PjColor "⚠️ 目录已存在: ${newDir}" -Color "Yellow"
                return
            }
            Add-Content -Path $dirsFile -Value $newDir
            Refresh-PjCache
            Write-PjColor "✅ 已添加监控目录: ${newDir}" -Color "Green"
            return
        }
        "list" {
            $allProjectsCache = Get-PjCache
            if ($allProjectsCache.Count -eq 0) {
                Refresh-PjCache
                $allProjectsCache = Get-PjCache
            }

            Write-PjColor "📁 Git 仓库列表 (缓存):" -Color "Blue"
            Write-Host ""
            foreach ($p in $allProjectsCache) {
                $projectName = Split-Path $p -Leaf
                $relativePath = $p -replace [regex]::Escape($HOME), "~"
                Write-PjColor "▸ ${projectName}" -Color "Green"
                Write-PjColor "    ${relativePath}" -Color "Yellow"
            }
            Write-Host ""
            Write-PjColor "共 $($allProjectsCache.Count) 个项目 | pj refresh 刷新缓存" -Color "Cyan"
            return
        }
        "l" {
            pj -Command "list"
            return
        }
        "help" {
            Write-Host "用法: pj list                # 列出所有项目"
            Write-Host "       pj -p <关键词>         # 进入项目（模糊搜索）"
            Write-Host "       pj adddir <路径>       # 添加监控目录"
            Write-Host "       pj refresh            # 强制刷新缓存"
            Write-Host ""
            Write-Host "监控目录:"
            Write-Host "  - $PJ_PROJECTS_DIR"
            return
        }
        "-h" {
            pj -Command "help"
            return
        }
        "-p" {
            $keyword = $Arg1
            if (-not $keyword) {
                Write-Host "用法: pj -p <关键词>"
                return
            }

            $allProjectsCache = Get-PjCache
            if ($allProjectsCache.Count -eq 0) {
                Refresh-PjCache
                $allProjectsCache = Get-PjCache
            }

            # 模糊匹配（不区分大小写）
            $matches = @()
            foreach ($p in $allProjectsCache) {
                $pname = Split-Path $p -Leaf
                if ($pname.ToLower() -like "*$($keyword.ToLower())*") {
                    $matches += $p
                }
            }

            $matchCount = $matches.Count

            if ($matchCount -eq 0) {
                Write-PjColor "❌ 未找到包含 '${keyword}' 的项目" -Color "Red"
                return
            } elseif ($matchCount -eq 1) {
                $firstMatch = $matches[0]
                Write-PjColor "✅ 进入项目: $(Split-Path $firstMatch -Leaf)" -Color "Green"
                Set-Location $firstMatch
            } else {
                Write-PjColor "找到 ${matchCount} 个匹配项目，请选择:" -Color "Yellow"
                Write-Host ""
                $idx = 1
                foreach ($m in $matches) {
                    $relativePath = $m -replace [regex]::Escape($HOME), "~"
                    Write-Host "  [$idx] $(Split-Path $m -Leaf)"
                    Write-PjColor "      ${relativePath}" -Color "Yellow"
                    $idx++
                }
                Write-Host ""
                $choice = Read-Host "请输入编号 (1-${matchCount})"

                if ($choice -match '^\d+$' -and [int]$choice -ge 1 -and [int]$choice -le $matchCount) {
                    $selected = $matches[[int]$choice - 1]
                    Write-PjColor "✅ 进入项目: $(Split-Path $selected -Leaf)" -Color "Green"
                    Set-Location $selected
                } else {
                    Write-PjColor "❌ 无效选择" -Color "Red"
                }
            }
            return
        }
        default {
            if (-not $Command) {
                pj -Command "help"
                return
            }

            $projectName = $Command
            $projectDir = ""

            # 精确匹配
            foreach ($dir in @($PJ_PROJECTS_DIR)) {
                $candidate = Join-Path $dir $projectName
                if (Test-Path $candidate) {
                    $projectDir = $candidate
                    break
                }
            }

            # 模糊匹配
            if (-not $projectDir) {
                $matches = @()
                foreach ($dir in @($PJ_PROJECTS_DIR)) {
                    if (Test-Path $dir) {
                        $found = Get-ChildItem -Path $dir -Directory -Filter "*$projectName*" -ErrorAction SilentlyContinue
                        $matches += $found
                    }
                }

                if ($matches.Count -eq 1) {
                    $projectDir = $matches[0].FullName
                } elseif ($matches.Count -gt 1) {
                    Write-PjColor "找到 $($matches.Count) 个匹配项目，请选择:" -Color "Yellow"
                    Write-Host ""
                    $idx = 1
                    foreach ($m in $matches) {
                        $relativePath = $m.FullName -replace [regex]::Escape($HOME), "~"
                        Write-Host "  [$idx] $($m.Name)"
                        Write-PjColor "      ${relativePath}" -Color "Yellow"
                        $idx++
                    }
                    Write-Host ""
                    $choice = Read-Host "请输入编号 (1-$($matches.Count))"

                    if ($choice -match '^\d+$' -and [int]$choice -ge 1 -and [int]$choice -le $matches.Count) {
                        $projectDir = $matches[[int]$choice - 1].FullName
                    }
                }
            }

            if ($projectDir) {
                Write-PjColor "✅ 进入项目: $(Split-Path $projectDir -Leaf)" -Color "Green"
                Set-Location $projectDir
            } else {
                Write-PjColor "❌ 未找到项目: ${projectName}" -Color "Red"
            }
        }
    }
}

# 设置别名使其可以直接使用 pj 命令
Set-Alias -Name pj -Value pj

Write-PjColor "✅ pj 已加载 (PowerShell)" -Color "Green"