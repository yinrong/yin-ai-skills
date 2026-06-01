#!/bin/bash
# pull-and-merge.sh - 拉取所有主机的记忆并智能融合

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

PASSWORD_FILE="$HOME/.my-memory-password"
COMMON_DIR="hosts/common"
TEMP_DIR="/tmp/my-memory-merge-$$"

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log() {
    echo -e "${GREEN}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

# 检查密码文件
if [ ! -f "$PASSWORD_FILE" ]; then
    error "密码文件不存在: $PASSWORD_FILE"
    exit 1
fi

PASSWORD=$(cat "$PASSWORD_FILE")

log "开始拉取并融合记忆..."

# 拉取所有远程分支
log "拉取远程分支..."
git fetch --all --prune

# 获取所有 host/* 分支
HOST_BRANCHES=$(git branch -r | grep 'origin/host/' | sed 's|origin/||' || true)

if [ -z "$HOST_BRANCHES" ]; then
    warn "没有找到任何主机分支"
    exit 0
fi

log "找到主机分支:"
echo "$HOST_BRANCHES" | while read branch; do
    echo "  - $branch"
done

# 创建临时目录
mkdir -p "$TEMP_DIR"
trap "rm -rf '$TEMP_DIR'" EXIT

# 解密所有主机的记忆文件
log "解密各主机的记忆文件..."

hosts_count=0
for branch in $HOST_BRANCHES; do
    hostname=$(echo "$branch" | sed 's|host/||')
    host_dir="hosts/$hostname"

    log "处理主机: $hostname"

    # 切换到对应分支
    git checkout "$branch" 2>/dev/null || continue

    # 检查目录是否存在
    if [ ! -d "$host_dir" ]; then
        warn "目录不存在: $host_dir，跳过"
        continue
    fi

    # 创建主机临时目录
    host_temp="$TEMP_DIR/$hostname"
    mkdir -p "$host_temp"

    # 解密所有 .enc 文件
    decrypted=0
    for enc_file in "$host_dir"/*.enc; do
        if [ -f "$enc_file" ]; then
            filename=$(basename "$enc_file" .enc)

            openssl enc -aes-256-cbc -d -pbkdf2 \
                -in "$enc_file" \
                -out "$host_temp/$filename" \
                -k "$PASSWORD" 2>/dev/null

            if [ $? -eq 0 ]; then
                ((decrypted++))
            else
                error "解密失败: $enc_file"
            fi
        fi
    done

    # 复制元数据
    if [ -f "$host_dir/metadata.json" ]; then
        cp "$host_dir/metadata.json" "$host_temp/"
    fi

    log "主机 $hostname: 解密了 $decrypted 个文件"
    ((hosts_count++))
done

if [ $hosts_count -eq 0 ]; then
    error "没有成功处理任何主机"
    exit 1
fi

log "共处理了 $hosts_count 个主机"

# 切回 main 分支
git checkout main 2>/dev/null || git checkout -b main

# 融合记忆
log "开始融合记忆..."

mkdir -p "$COMMON_DIR"

# 融合函数
merge_file() {
    local filename=$1
    local output="$COMMON_DIR/$filename"

    info "融合: $filename"

    # 收集所有主机的该文件
    local files=()
    for host_temp in "$TEMP_DIR"/*; do
        if [ -f "$host_temp/$filename" ]; then
            files+=("$host_temp/$filename")
        fi
    done

    if [ ${#files[@]} -eq 0 ]; then
        warn "没有找到 $filename，跳过"
        return
    fi

    if [ ${#files[@]} -eq 1 ]; then
        # 只有一个文件，直接复制
        cp "${files[0]}" "$output"
        info "$filename: 单一来源，直接使用"
        return
    fi

    # 多个文件，智能融合
    case "$filename" in
        MEMORY.md)
            merge_memory_md "${files[@]}" > "$output"
            ;;
        CLAUDE.md)
            merge_claude_md "${files[@]}" > "$output"
            ;;
        *.md)
            merge_generic_md "$filename" "${files[@]}" > "$output"
            ;;
        *)
            # 其他文件，使用最新的
            newest="${files[0]}"
            for f in "${files[@]}"; do
                if [ "$f" -nt "$newest" ]; then
                    newest="$f"
                fi
            done
            cp "$newest" "$output"
            info "$filename: 使用最新版本"
            ;;
    esac
}

# 融合 MEMORY.md
merge_memory_md() {
    cat << 'HEADER'
# 全局记忆索引（融合版）

> 融合自多台主机的记忆，由 my-memory 系统自动生成

HEADER

    echo "## 融合信息"
    echo ""
    echo "- **融合时间**: $(date '+%Y-%m-%d %H:%M:%S')"
    echo "- **来源主机**: $hosts_count 台"
    echo "- **主机列表**:"
    for host_temp in "$TEMP_DIR"/*; do
        hostname=$(basename "$host_temp")
        if [ -f "$host_temp/metadata.json" ]; then
            last_sync=$(jq -r '.last_sync // "unknown"' "$host_temp/metadata.json")
            echo "  - $hostname (最后同步: $last_sync)"
        else
            echo "  - $hostname"
        fi
    done
    echo ""

    echo "---"
    echo ""
    echo "## 快速索引"
    echo ""

    # 合并所有快速索引部分
    for file in "$@"; do
        hostname=$(basename "$(dirname "$file")")
        echo "### 来自 $hostname"
        echo ""

        # 提取"快速索引"部分
        awk '/^## 快速索引/,/^##/ {
            if (/^## 快速索引/) next;
            if (/^## / && !/^## 快速索引/) exit;
            print
        }' "$file"
        echo ""
    done

    echo "---"
    echo ""
    echo "## 核心经验（融合）"
    echo ""

    # 合并核心经验，去重
    declare -A seen_headers

    for file in "$@"; do
        awk '/^## 核心经验/,/^##/ {
            if (/^## 核心经验/) next;
            if (/^## / && !/^## 核心经验/) exit;
            print
        }' "$file" | while IFS= read -r line; do
            if [[ "$line" =~ ^### ]]; then
                header=$(echo "$line" | sed 's/^### //')
                if [ -z "${seen_headers[$header]}" ]; then
                    seen_headers[$header]=1
                    echo "$line"
                fi
            else
                echo "$line"
            fi
        done
    done
}

# 融合 CLAUDE.md
merge_claude_md() {
    cat << 'HEADER'
# 全局指令（融合版）

> 融合自多台主机的 CLAUDE.md，由 my-memory 系统自动生成

HEADER

    echo "## 融合说明"
    echo ""
    echo "- **融合时间**: $(date '+%Y-%m-%d %H:%M:%S')"
    echo "- **来源主机**: $hosts_count 台"
    echo ""
    echo "---"
    echo ""

    # 合并所有章节，保留来源标识
    for file in "$@"; do
        hostname=$(basename "$(dirname "$file")")
        echo "<!-- 来自: $hostname -->"
        echo ""

        cat "$file"
        echo ""
        echo "---"
        echo ""
    done

    echo "## 注意"
    echo ""
    echo "这是自动融合的文件。如果有冲突，手动编辑："
    echo "\`$SCRIPT_DIR/$COMMON_DIR/CLAUDE.md\`"
}

# 融合通用 .md 文件
merge_generic_md() {
    local filename=$1
    shift

    echo "# $filename（融合版）"
    echo ""
    echo "> 融合自 $hosts_count 台主机"
    echo ""
    echo "---"
    echo ""

    for file in "$@"; do
        hostname=$(basename "$(dirname "$file")")
        echo "## 来自: $hostname"
        echo ""
        cat "$file"
        echo ""
        echo "---"
        echo ""
    done
}

# 获取所有需要融合的文件名
all_files=$(find "$TEMP_DIR" -type f -name "*.md" -exec basename {} \; | sort -u)

for filename in $all_files; do
    merge_file "$filename"
done

log "融合完成，共生成 $(ls -1 "$COMMON_DIR"/*.md 2>/dev/null | wc -l) 个文件"

# 提交融合结果
log "提交融合结果..."

# 切换到 common 分支
if git show-ref --verify --quiet "refs/heads/common"; then
    git checkout common
else
    if git show-ref --verify --quiet "refs/remotes/origin/common"; then
        git checkout -b common origin/common
    else
        git checkout --orphan common
        git rm -rf . 2>/dev/null || true
    fi
fi

# 添加融合文件
git add "$COMMON_DIR/"

if git diff --cached --quiet; then
    log "没有新的变更"
else
    git commit -m "Merge memories from $hosts_count hosts at $(date '+%Y-%m-%d %H:%M:%S')"
    git push -u origin common

    log "✅ 已推送到 common 分支"
fi

# 应用到本地 Claude
log "应用融合后的记忆到本地 Claude..."

CLAUDE_DIR="$HOME/.claude"
GLOBAL_MEMORY_DIR="$CLAUDE_DIR/global-memory"

mkdir -p "$GLOBAL_MEMORY_DIR"

# 复制融合后的文件
if [ -f "$COMMON_DIR/CLAUDE.md" ]; then
    cp "$COMMON_DIR/CLAUDE.md" "$CLAUDE_DIR/CLAUDE.md.common"
    log "已更新: $CLAUDE_DIR/CLAUDE.md.common"
fi

if [ -f "$COMMON_DIR/MEMORY.md" ]; then
    cp "$COMMON_DIR/MEMORY.md" "$GLOBAL_MEMORY_DIR/MEMORY.md.common"
    log "已更新: $GLOBAL_MEMORY_DIR/MEMORY.md.common"
fi

# 复制其他文件
for file in "$COMMON_DIR"/*.md; do
    if [ -f "$file" ]; then
        basename=$(basename "$file")
        if [ "$basename" != "CLAUDE.md" ] && [ "$basename" != "MEMORY.md" ]; then
            cp "$file" "$GLOBAL_MEMORY_DIR/$basename"
            log "已更新: $GLOBAL_MEMORY_DIR/$basename"
        fi
    fi
done

# 回到 main 分支
git checkout main 2>/dev/null || true

log "✅ 拉取和融合完成"

# 显示统计
echo ""
info "========== 统计信息 =========="
info "处理主机数: $hosts_count"
info "融合文件数: $(ls -1 "$COMMON_DIR"/*.md 2>/dev/null | wc -l)"
info "公共记忆位置: $COMMON_DIR/"
info "本地记忆位置: $GLOBAL_MEMORY_DIR/"
echo ""
