#!/bin/bash
# sync-memory.sh - 同步本机 Claude Code 记忆到 GitHub（加密）
# 包括: 全局 CLAUDE.md, global-memory, $HOME 下所有项目的 CLAUDE.md

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

# 检查密码文件
if [ ! -f "$PASSWORD_FILE" ]; then
    error "密码文件不存在: $PASSWORD_FILE"
    error "请先运行 /memory-sync init 设置密码"
    exit 1
fi

PASSWORD=$(cat "$PASSWORD_FILE")

# 检查 Claude 目录
if [ ! -d "$CLAUDE_DIR" ]; then
    error "Claude 目录不存在: $CLAUDE_DIR"
    exit 1
fi

log "开始同步主机: $HOSTNAME"

# 创建主机目录结构
mkdir -p "$HOST_DIR/global"
mkdir -p "$HOST_DIR/projects"

encrypted_count=0

# ============================================================
# 1. 同步全局 CLAUDE.md 和 global-memory
# ============================================================

log "=== 同步全局记忆 ==="

# 全局 CLAUDE.md
if [ -f "$CLAUDE_DIR/CLAUDE.md" ]; then
    log "加密: global/CLAUDE.md"
    openssl enc -aes-256-cbc -salt -pbkdf2 \
        -in "$CLAUDE_DIR/CLAUDE.md" \
        -out "$HOST_DIR/global/CLAUDE.md.enc" \
        -k "$PASSWORD" 2>/dev/null && ((encrypted_count++))
fi

# global-memory 目录下所有 .md 文件
if [ -d "$GLOBAL_MEMORY_DIR" ]; then
    for file in "$GLOBAL_MEMORY_DIR"/*.md; do
        if [ -f "$file" ]; then
            basename=$(basename "$file")
            log "加密: global/$basename"
            openssl enc -aes-256-cbc -salt -pbkdf2 \
                -in "$file" \
                -out "$HOST_DIR/global/${basename}.enc" \
                -k "$PASSWORD" 2>/dev/null && ((encrypted_count++))
        fi
    done
fi

# ============================================================
# 2. 搜索 $HOME 下所有项目的 CLAUDE.md
# ============================================================

log "=== 搜索项目 CLAUDE.md ==="

# 搜索位置：
#   <project>/CLAUDE.md
#   <project>/.claude/CLAUDE.md
#   <project>/CLAUDE.local.md
#
# 排除：
#   node_modules, .git, venv, __pycache__, .cache 等

PROJECT_CLAUDE_FILES=$(find "$HOME" \
    -maxdepth 4 \
    -type f \
    \( -name "CLAUDE.md" -o -name "CLAUDE.local.md" \) \
    ! -path "*/node_modules/*" \
    ! -path "*/.git/*" \
    ! -path "*/venv/*" \
    ! -path "*/__pycache__/*" \
    ! -path "*/.cache/*" \
    ! -path "*/.npm/*" \
    ! -path "*/.local/*" \
    ! -path "*/dist/*" \
    ! -path "*/build/*" \
    ! -path "$CLAUDE_DIR/CLAUDE.md" \
    2>/dev/null || true)

# 去重并整理
if [ -n "$PROJECT_CLAUDE_FILES" ]; then
    file_count=$(echo "$PROJECT_CLAUDE_FILES" | wc -l)
    log "找到 $file_count 个项目 CLAUDE.md 文件"

    while IFS= read -r claude_file; do
        if [ -z "$claude_file" ] || [ ! -f "$claude_file" ]; then
            continue
        fi

        # 计算相对于 $HOME 的路径，作为项目标识
        relative_path="${claude_file#$HOME/}"

        # 将路径中的 / 替换为 --，作为文件名
        # 如 projects/my-app/.claude/CLAUDE.md -> projects--my-app--.claude--CLAUDE.md
        safe_name=$(echo "$relative_path" | sed 's|/|--|g')

        log "加密: projects/$safe_name"

        openssl enc -aes-256-cbc -salt -pbkdf2 \
            -in "$claude_file" \
            -out "$HOST_DIR/projects/${safe_name}.enc" \
            -k "$PASSWORD" 2>/dev/null && ((encrypted_count++))

    done <<< "$PROJECT_CLAUDE_FILES"
else
    log "未找到项目 CLAUDE.md 文件"
fi

# ============================================================
# 3. 同步 ~/.claude/projects/ 下的记忆文件
# ============================================================

log "=== 同步项目记忆目录 ==="

PROJECTS_MEMORY_DIR="$CLAUDE_DIR/projects"

if [ -d "$PROJECTS_MEMORY_DIR" ]; then
    # 搜索所有 memory/ 目录下的 .md 文件
    PROJECT_MEMORIES=$(find "$PROJECTS_MEMORY_DIR" \
        -type f -name "*.md" \
        -path "*/memory/*" \
        2>/dev/null || true)

    if [ -n "$PROJECT_MEMORIES" ]; then
        while IFS= read -r mem_file; do
            if [ -z "$mem_file" ] || [ ! -f "$mem_file" ]; then
                continue
            fi

            # 相对路径作为文件名
            relative_path="${mem_file#$PROJECTS_MEMORY_DIR/}"
            safe_name=$(echo "$relative_path" | sed 's|/|--|g')

            log "加密: projects/$safe_name"

            openssl enc -aes-256-cbc -salt -pbkdf2 \
                -in "$mem_file" \
                -out "$HOST_DIR/projects/${safe_name}.enc" \
                -k "$PASSWORD" 2>/dev/null && ((encrypted_count++))

        done <<< "$PROJECT_MEMORIES"
    fi
fi

# ============================================================
# 4. 生成索引和元数据
# ============================================================

log "=== 生成元数据 ==="

log "已加密 $encrypted_count 个文件"

# 生成文件清单（明文，方便查找）
{
    echo "# 文件清单"
    echo ""
    echo "**主机**: $HOSTNAME"
    echo "**同步时间**: $(date '+%Y-%m-%d %H:%M:%S')"
    echo "**文件总数**: $encrypted_count"
    echo ""
    echo "## 全局记忆 (global/)"
    echo ""
    ls -1 "$HOST_DIR/global/" 2>/dev/null | while read f; do
        size=$(stat -c%s "$HOST_DIR/global/$f" 2>/dev/null || echo "?")
        echo "- \`$f\` ($size bytes)"
    done
    echo ""
    echo "## 项目记忆 (projects/)"
    echo ""
    ls -1 "$HOST_DIR/projects/" 2>/dev/null | while read f; do
        # 还原文件名为可读路径
        readable=$(echo "$f" | sed 's|--|/|g' | sed 's|\.enc$||')
        size=$(stat -c%s "$HOST_DIR/projects/$f" 2>/dev/null || echo "?")
        echo "- \`$readable\` ($size bytes)"
    done
} > "$HOST_DIR/INDEX.md"

# 生成 JSON 元数据
cat > "$HOST_DIR/metadata.json" << EOF
{
  "hostname": "$HOSTNAME",
  "last_sync": "$(date -u +%Y-%m-%dT%H:%M:%SZ)",
  "file_count": $encrypted_count,
  "global_files": $(ls -1 "$HOST_DIR/global/" 2>/dev/null | wc -l),
  "project_files": $(ls -1 "$HOST_DIR/projects/" 2>/dev/null | wc -l),
  "os": "$(uname -s)",
  "arch": "$(uname -m)",
  "kernel": "$(uname -r)"
}
EOF

log "生成索引: INDEX.md"
log "生成元数据: metadata.json"

# ============================================================
# 5. Git 提交并推送
# ============================================================

log "=== Git 推送 ==="

# 回到仓库根目录
cd "$SCRIPT_DIR/../.."

# 确保在正确的分支
BRANCH="host/$HOSTNAME"
git fetch origin 2>/dev/null || true

if git show-ref --verify --quiet "refs/heads/$BRANCH"; then
    git checkout "$BRANCH" 2>/dev/null || git checkout -b "$BRANCH"
else
    if git show-ref --verify --quiet "refs/remotes/origin/$BRANCH"; then
        git checkout -b "$BRANCH" "origin/$BRANCH"
    else
        git checkout -b "$BRANCH"
    fi
fi

# 添加文件
git add "$HOST_DIR/"

# 检查是否有变更
if git diff --cached --quiet; then
    log "没有新的变更，跳过提交"
else
    git commit -m "Sync $encrypted_count files from $HOSTNAME at $(date '+%Y-%m-%d %H:%M:%S')"
    log "推送到 GitHub..."
    git push -u origin "$BRANCH"
    log "✅ 同步完成（$encrypted_count 个文件）"
fi

# 回到 main 分支
git checkout main 2>/dev/null || true
