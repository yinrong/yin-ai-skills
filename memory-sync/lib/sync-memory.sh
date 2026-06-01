#!/bin/bash
# sync-memory.sh - 同步本机 Claude Code 记忆到 GitHub（加密）

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# 配置
HOSTNAME=$(hostname)
HOST_DIR="hosts/$HOSTNAME"
PASSWORD_FILE="$HOME/.my-memory-password"
CLAUDE_DIR="$HOME/.claude"
GLOBAL_MEMORY_DIR="$CLAUDE_DIR/global-memory"

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log() {
    echo -e "${GREEN}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

# 检查密码文件
if [ ! -f "$PASSWORD_FILE" ]; then
    error "密码文件不存在: $PASSWORD_FILE"
    error "请先运行 ./setup.sh 设置密码"
    exit 1
fi

PASSWORD=$(cat "$PASSWORD_FILE")

# 检查 Claude 目录
if [ ! -d "$CLAUDE_DIR" ]; then
    error "Claude 目录不存在: $CLAUDE_DIR"
    exit 1
fi

log "开始同步主机: $HOSTNAME"

# 创建主机目录
mkdir -p "$HOST_DIR"

# 要同步的文件列表
declare -A FILES_TO_SYNC=(
    ["$CLAUDE_DIR/CLAUDE.md"]="CLAUDE.md"
    ["$GLOBAL_MEMORY_DIR/MEMORY.md"]="MEMORY.md"
    ["$GLOBAL_MEMORY_DIR/github-operations.md"]="github-operations.md"
)

# 加密并复制文件
encrypted_count=0
for src in "${!FILES_TO_SYNC[@]}"; do
    dest="${FILES_TO_SYNC[$src]}"

    if [ -f "$src" ]; then
        log "加密: $dest"

        # 加密文件
        openssl enc -aes-256-cbc -salt -pbkdf2 \
            -in "$src" \
            -out "$HOST_DIR/${dest}.enc" \
            -k "$PASSWORD" 2>/dev/null

        if [ $? -eq 0 ]; then
            ((encrypted_count++))
        else
            error "加密失败: $dest"
        fi
    else
        warn "文件不存在，跳过: $src"
    fi
done

# 同步 global-memory 目录下的所有其他 .md 文件
if [ -d "$GLOBAL_MEMORY_DIR" ]; then
    for file in "$GLOBAL_MEMORY_DIR"/*.md; do
        if [ -f "$file" ]; then
            basename=$(basename "$file")

            # 跳过已经处理的文件
            if [ "$basename" != "MEMORY.md" ] && [ "$basename" != "github-operations.md" ]; then
                log "加密: $basename"

                openssl enc -aes-256-cbc -salt -pbkdf2 \
                    -in "$file" \
                    -out "$HOST_DIR/${basename}.enc" \
                    -k "$PASSWORD" 2>/dev/null

                if [ $? -eq 0 ]; then
                    ((encrypted_count++))
                fi
            fi
        fi
    done
fi

log "已加密 $encrypted_count 个文件"

# 生成元数据
cat > "$HOST_DIR/metadata.json" << EOF
{
  "hostname": "$HOSTNAME",
  "last_sync": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "claude_version": "$(claude --version 2>/dev/null | head -1 || echo 'unknown')",
  "file_count": $encrypted_count,
  "os": "$(uname -s)",
  "arch": "$(uname -m)"
}
EOF

log "生成元数据: metadata.json"

# Git 操作
log "提交到 Git..."

# 确保在正确的分支
BRANCH="host/$HOSTNAME"
git fetch origin 2>/dev/null || true

# 检查分支是否存在
if git show-ref --verify --quiet "refs/heads/$BRANCH"; then
    git checkout "$BRANCH" 2>/dev/null || git checkout -b "$BRANCH"
else
    # 远程分支存在，检出
    if git show-ref --verify --quiet "refs/remotes/origin/$BRANCH"; then
        git checkout -b "$BRANCH" "origin/$BRANCH"
    else
        # 创建新分支
        git checkout -b "$BRANCH"
    fi
fi

# 添加文件
git add "$HOST_DIR/"

# 检查是否有变更
if git diff --cached --quiet; then
    log "没有新的变更，跳过提交"
else
    # 提交
    git commit -m "Sync memory from $HOSTNAME at $(date '+%Y-%m-%d %H:%M:%S')"

    # 推送
    log "推送到 GitHub..."
    git push -u origin "$BRANCH"

    log "✅ 同步完成"
fi

# 回到 main 分支
git checkout main 2>/dev/null || true
