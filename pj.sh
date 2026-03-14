#!/bin/zsh
# pj - 快速切换到 git 项目目录
# 使用方式: source pj.sh

# 配置目录（可自定义）
PJ_CONFIG_DIR="${PJ_CONFIG_DIR:-$HOME/.pj-dirs}"

# pj 自动添加 git clone 的项目
_pj_auto_add() {
    local cloned_path="$1"
    if [[ -d "$cloned_path/.git" ]]; then
        local parent_dir="$(dirname "$cloned_path")"
        # 检查是否在监控目录中
        local is_monitored=0
        local DEFAULT_PROJECTS_DIR="$HOME/Documents/Projects"

        # 检查是否是默认目录的子目录
        if [[ "$parent_dir" == "$DEFAULT_PROJECTS_DIR"/* ]]; then
            is_monitored=1
        elif [[ -f "$PJ_CONFIG_DIR/dirs" ]] && while read -r dir; do
            [[ "$parent_dir" == "$dir"/* ]] && break
        done < "$PJ_CONFIG_DIR/dirs"; then
            is_monitored=1
        fi

        if [[ $is_monitored -eq 0 ]]; then
            # 检查是否需要添加到监控目录
            local parent_name="$(basename "$parent_dir")"
            if [[ -d "$DEFAULT_PROJECTS_DIR/$parent_name" ]]; then
                echo -e "\033[0;32m✅ 检测到新克隆项目: $(basename "$cloned_path")\033[0m"
                echo -e "\033[0;33m   项目已自动添加到 pj 列表\033[0m"
            fi
        fi
    fi
}

# 包装 git 命令以自动追踪新克隆的项目
git() {
    local args=("$@")
    local has_clone=0
    local clone_arg=""

    for arg in "$@"; do
        if [[ "$arg" == "clone" ]]; then
            has_clone=1
        fi
    done

    # 执行原始 git 命令
    command git "$@"
    local git_status=$?

    # 如果是 clone 命令且成功，检查是否需要处理
    if [[ $has_clone -eq 0 ]] && [[ $git_status -eq 0 ]]; then
        for i in "${!args[@]}"; do
            if [[ "${args[$i]}" == "clone" ]]; then
                local next_idx=$((i + 1))
                if [[ -n "${args[$next_idx]}" ]]; then
                    # 获取克隆的目录
                    local clone_target="${args[$next_idx]}"
                    # 如果是 SSH URL 或 HTTP URL，取最后一个部分作为目录名
                    if [[ "$clone_target" == http* ]] || [[ "$clone_target" == git@* ]]; then
                        clone_target="$(basename "$clone_target" .git)"
                    fi
                    # 检查是否是有效的目录
                    if [[ -d "$clone_target" ]]; then
                        _pj_auto_add "$(pwd)/$clone_target"
                    fi
                fi
                break
            fi
        done
    fi

    return $git_status
}

# 内部函数：获取所有项目
_pj_get_projects() {
    local all_projects=()
    for proj_dir in "$@"; do
        if [[ -d "$proj_dir" ]]; then
            while IFS= read -r gitdir; do
                project_dir="$(dirname "$gitdir")"
                all_projects+=("$project_dir")
            done < <(find "$proj_dir" -name ".git" -type d 2>/dev/null)
        fi
    done
    echo "${all_projects[@]}"
}

pj() {
    # 确保配置目录存在
    [[ ! -d "$PJ_CONFIG_DIR" ]] && mkdir -p "$PJ_CONFIG_DIR"

    # 缓存配置
    local CACHE_FILE="$PJ_CONFIG_DIR/cache"
    local CACHE_TTL=300  # 缓存有效期 5 分钟
    local all_projects_cache=()

    # 读取缓存的函数
    _pj_load_cache() {
        if [[ -f "$CACHE_FILE" ]]; then
            local now=$(date +%s)
            local timestamp=$(head -1 "$CACHE_FILE" | cut -d: -f2)
            local age=$((now - timestamp))

            if [[ $age -lt $CACHE_TTL ]]; then
                # 缓存有效，读取项目列表
                tail -n +2 "$CACHE_FILE" | while read -r line; do
                    [[ -n "$line" && -d "$line" ]] && all_projects_cache+=("$line")
                done
                return 0
            fi
        fi
        return 1
    }

    # 保存缓存的函数
    _pj_save_cache() {
        local timestamp=$(date +%s)
        {
            echo "TIMESTAMP:$timestamp"
            for p in "$@"; do
                echo "$p"
            done
        } > "$CACHE_FILE"
    }

    # 刷新缓存的函数
    _pj_refresh_cache() {
        local DEFAULT_PROJECTS_DIR="$HOME/Documents/Projects"
        local dirs=("$DEFAULT_PROJECTS_DIR")

        # 读取自定义目录
        if [[ -f "$PJ_CONFIG_DIR/dirs" ]]; then
            while read -r dir; do
                [[ -n "$dir" && -d "$dir" ]] && dirs+=("$dir")
            done < "$PJ_CONFIG_DIR/dirs"
        fi

        # 扫描项目
        local projects=()
        for proj_dir in "${dirs[@]}"; do
            if [[ -d "$proj_dir" ]]; then
                while IFS= read -r gitdir; do
                    project_dir="$(dirname "$gitdir")"
                    projects+=("$project_dir")
                done < <(find "$proj_dir" -name ".git" -type d 2>/dev/null)
            fi
        done

        _pj_save_cache "${projects[@]}"
        echo -e "\033[0;32m✅ 缓存已刷新，共 ${#projects[@]} 个项目\033[0m"
    }

    # 默认项目目录
    local DEFAULT_PROJECTS_DIR="$HOME/Documents/Projects"
    local all_dirs=("$DEFAULT_PROJECTS_DIR")

    # 读取自定义目录
    if [[ -f "$PJ_CONFIG_DIR/dirs" ]]; then
        while read -r dir; do
            [[ -n "$dir" && -d "$dir" ]] && all_dirs+=("$dir")
        done < "$PJ_CONFIG_DIR/dirs"
    fi

    # pj refresh - 强制刷新缓存
    if [[ "$1" == "refresh" || "$1" == "r" ]]; then
        _pj_refresh_cache
        return
    fi

    # pj adddir - 添加监控目录
    if [[ "$1" == "adddir" ]]; then
        local new_dir="$2"
        if [[ -z "$new_dir" ]]; then
            echo "用法: pj adddir <目录路径>"
            echo "示例: pj adddir /Users/zcr/my-projects"
            return 1
        fi
        if [[ ! -d "$new_dir" ]]; then
            echo -e "\033[0;31m❌ 目录不存在: ${new_dir}\033[0m"
            return 1
        fi
        # 检查是否已存在
        if [[ -f "$PJ_CONFIG_DIR/dirs" ]] && grep -q "^${new_dir}$" "$PJ_CONFIG_DIR/dirs"; then
            echo -e "\033[1;33m⚠️ 目录已存在: ${new_dir}\033[0m"
            return 1
        fi
        echo "$new_dir" >> "$PJ_CONFIG_DIR/dirs"
        # 刷新缓存
        _pj_refresh_cache
        echo -e "\033[0;32m✅ 已添加监控目录: ${new_dir}\033[0m"
        return
    fi

    # 尝试加载缓存
    _pj_load_cache

    # pj list - 列出所有 git 仓库（使用缓存）
    if [[ "$1" == "list" || "$1" == "l" ]]; then
        if [[ ${#all_projects_cache[@]} -eq 0 ]]; then
            # 缓存为空，刷新
            _pj_refresh_cache
            _pj_load_cache
        fi

        echo -e "\033[0;34m📁 Git 仓库列表 (缓存):\033[0m\n"
        for p in "${all_projects_cache[@]}"; do
            project_name="$(basename "$p")"
            relative_path="${p#$HOME}"
            echo -e "\033[0;32m▸\033[0m ${project_name}"
            echo -e "    \033[0;33m~${relative_path}\033[0m"
        done
        echo -e "\n\033[0;36m共 ${#all_projects_cache[@]} 个项目 | pj refresh 刷新缓存\033[0m"
        return
    fi

    # pj help
    if [[ -z "$1" || "$1" == "help" || "$1" == "-h" ]]; then
        echo "用法: pj list                # 列出所有项目"
        echo "       pj -p <关键词>         # 进入项目（模糊搜索）"
        echo "       pj adddir <路径>       # 添加监控目录"
        echo "       pj refresh            # 强制刷新缓存"
        echo ""
        echo "监控目录:"
        for d in "${all_dirs[@]}"; do
            echo "  - ${d}"
        done
        return
    fi

    # pj -p <项目名> 模糊搜索并进入（使用缓存）
    if [[ "$1" == "-p" ]]; then
        local keyword="$2"
        if [[ -z "$keyword" ]]; then
            echo "用法: pj -p <关键词>"
            return 1
        fi

        # 如果缓存为空，先刷新
        if [[ ${#all_projects_cache[@]} -eq 0 ]]; then
            _pj_refresh_cache
            _pj_load_cache
        fi

        # 模糊匹配（不区分大小写）
        local matches=()
        local keyword_lower=$(echo "$keyword" | tr '[:upper:]' '[:lower:]')
        for p in "${all_projects_cache[@]}"; do
            local pname=$(basename "$p")
            local pname_lower=$(echo "$pname" | tr '[:upper:]' '[:lower:]')
            if [[ "$pname_lower" == *"$keyword_lower"* ]]; then
                matches+=("$p")
            fi
        done

        local match_count=${#matches[@]}

        if [[ $match_count -eq 0 ]]; then
            echo -e "\033[0;31m❌ 未找到包含 '${keyword}' 的项目\033[0m"
            return 1
        elif [[ $match_count -eq 1 ]]; then
            # 只有一个匹配，直接进入
            local first_match="${matches[1]}"
            echo -e "\033[0;32m✅ 进入项目: $(basename "$first_match")\033[0m"
            cd "$first_match"
        else
            # 多个匹配，让用户选择
            echo -e "\033[1;33m找到 ${match_count} 个匹配项目，请选择:\033[0m\n"
            local idx=1
            for m in "${matches[@]}"; do
                local relative_path="${m#$HOME}"
                echo "  [$idx] $(basename "$m")"
                echo "      \033[0;33m~${relative_path}\033[0m"
                ((idx++))
            done
            echo ""
            echo -n "请输入编号 (1-${match_count}): "
            local choice
            read choice

            if [[ "$choice" =~ ^[0-9]+$ ]] && [[ $choice -ge 1 ]] && [[ $choice -le $match_count ]]; then
                local selected="${matches[$choice]}"
                echo -e "\033[0;32m✅ 进入项目: $(basename "$selected")\033[0m"
                cd "$selected"
            else
                echo -e "\033[0;31m❌ 无效选择\033[0m"
                return 1
            fi
        fi
        return
    fi

    # 兼容旧语法：不带 -p 直接输入项目名（精确匹配 + 模糊匹配）
    local project_name="$1"
    local project_dir=""
    local found=0

    for proj_dir in "${all_dirs[@]}"; do
        if [[ -d "$proj_dir" ]]; then
            # 精确匹配
            if [[ -d "${proj_dir}/${project_name}" ]]; then
                project_dir="${proj_dir}/${project_name}"
                found=1
                break
            fi
        fi
    done

    # 如果没找到精确匹配，尝试模糊匹配
    if [[ $found -eq 0 ]]; then
        local matches=()
        for proj_dir in "${all_dirs[@]}"; do
            if [[ -d "$proj_dir" ]]; then
                while IFS= read -r m; do
                    matches+=("$m")
                done < <(find "$proj_dir" -maxdepth 1 -type d -name "*${project_name}*" 2>/dev/null)
            fi
        done

        local match_count=${#matches[@]}

        if [[ $match_count -eq 1 ]]; then
            project_dir="${matches[1]}"
            found=1
        elif [[ $match_count -gt 1 ]]; then
            echo -e "\033[1;33m找到 ${match_count} 个匹配项目，请选择:\033[0m\n"
            local idx=1
            for m in "${matches[@]}"; do
                local relative_path="${m#$HOME}"
                echo "  [$idx] $(basename "$m")"
                echo "      \033[0;33m~${relative_path}\033[0m"
                ((idx++))
            done
            echo ""
            echo -n "请输入编号 (1-${match_count}): "
            local choice
            read choice

            if [[ "$choice" =~ ^[0-9]+$ ]] && [[ $choice -ge 1 ]] && [[ $choice -le $match_count ]]; then
                project_dir="${matches[$choice]}"
                found=1
            else
                echo -e "\033[0;31m❌ 无效选择\033[0m"
                return 1
            fi
        fi
    fi

    if [[ $found -eq 1 && -n "$project_dir" ]]; then
        echo -e "\033[0;32m✅ 进入项目: $(basename "$project_dir")\033[0m"
        cd "$project_dir"
    else
        echo -e "\033[0;31m❌ 未找到项目: ${project_name}\033[0m"
    fi
}