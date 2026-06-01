#!/bin/bash
# setup.sh - 一键安装脚本

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

PASSWORD_FILE="$HOME/.my-memory-password"

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

prompt() {
    echo -e "${BLUE}[?]${NC} $1"
}

banner() {
    echo -e "${GREEN}"
    cat << 'EOF'
╔═══════════════════════════════════════════╗
║   My Memory - 全局记忆同步系统            ║
║   跨主机 Claude Code 记忆自动同步和融合   ║
╚═══════════════════════════════════════════╝
EOF
    echo -e "${NC}"
}

banner

log "开始安装..."
echo ""

# 检查依赖
log "检查依赖..."

if ! command -v openssl &> /dev/null; then
    error "未安装 openssl，请先安装"
    exit 1
fi

if ! command -v git &> /dev/null; then
    error "未安装 git，请先安装"
    exit 1
fi

if ! command -v jq &> /dev/null; then
    warn "未安装 jq，部分功能可能受限"
    prompt "是否继续？(y/n)"
    read -r response
    if [[ ! "$response" =~ ^[Yy]$ ]]; then
        exit 1
    fi
fi

log "✓ 依赖检查通过"
echo ""

# 设置密码
if [ -f "$PASSWORD_FILE" ]; then
    log "密码文件已存在: $PASSWORD_FILE"
    prompt "是否使用现有密码？(y/n)"
    read -r use_existing

    if [[ ! "$use_existing" =~ ^[Yy]$ ]]; then
        prompt "请输入新的加密密码（至少 8 位）："
        read -s password
        echo ""

        if [ ${#password} -lt 8 ]; then
            error "密码太短，至少 8 位"
            exit 1
        fi

        echo "$password" > "$PASSWORD_FILE"
        chmod 600 "$PASSWORD_FILE"
        log "✓ 密码已更新"
    else
        log "✓ 使用现有密码"
    fi
else
    prompt "请设置加密密码（至少 8 位，用于加密记忆文件）："
    read -s password
    echo ""

    prompt "请再次输入密码确认："
    read -s password_confirm
    echo ""

    if [ "$password" != "$password_confirm" ]; then
        error "两次密码不一致"
        exit 1
    fi

    if [ ${#password} -lt 8 ]; then
        error "密码太短，至少 8 位"
        exit 1
    fi

    echo "$password" > "$PASSWORD_FILE"
    chmod 600 "$PASSWORD_FILE"
    log "✓ 密码已保存到: $PASSWORD_FILE"
fi

echo ""

# Git 配置
log "配置 Git 仓库..."

# 检查是否已经是 Git 仓库
if [ ! -d ".git" ]; then
    git init
    git branch -m main
    log "✓ 初始化 Git 仓库"
fi

# 设置 remote
if git remote get-url origin &>/dev/null; then
    REMOTE_URL=$(git remote get-url origin)
    log "已配置 remote: $REMOTE_URL"

    prompt "是否使用现有 remote？(y/n)"
    read -r use_existing_remote

    if [[ ! "$use_existing_remote" =~ ^[Yy]$ ]]; then
        prompt "请输入新的 GitHub 仓库 URL（如 git@github.com:yinrong/my-memory.git）："
        read -r remote_url
        git remote set-url origin "$remote_url"
        log "✓ 已更新 remote"
    fi
else
    prompt "请输入 GitHub 仓库 URL（如 git@github.com:yinrong/my-memory.git）："
    read -r remote_url

    if [ -z "$remote_url" ]; then
        warn "未设置 remote，稍后可以手动设置"
    else
        git remote add origin "$remote_url"
        log "✓ 已添加 remote"
    fi
fi

echo ""

# 创建 .gitignore
log "创建 .gitignore..."

cat > .gitignore << 'EOF'
# 日志文件
*.log

# 临时文件
*.tmp
*.swp
*~

# 解密后的文件（不应提交）
hosts/*/decrypted/
hosts/common/*.decrypted.md

# 密码文件（绝对不能提交）
.my-memory-password
EOF

log "✓ .gitignore 已创建"

# 添加执行权限
chmod +x sync-memory.sh pull-and-merge.sh decrypt-memory.sh

log "✓ 脚本已添加执行权限"

echo ""

# 提交初始文件
if [ ! -f ".git/refs/heads/main" ] && [ ! -f ".git/refs/heads/master" ]; then
    log "提交初始文件..."
    git add README.md setup.sh sync-memory.sh pull-and-merge.sh decrypt-memory.sh .gitignore
    git commit -m "Initial commit: my-memory system"
    log "✓ 已创建初始提交"
fi

# 推送到 GitHub（如果配置了 remote）
if git remote get-url origin &>/dev/null; then
    prompt "是否立即推送到 GitHub？(y/n)"
    read -r do_push

    if [[ "$do_push" =~ ^[Yy]$ ]]; then
        log "推送到 GitHub..."

        # 检查远程仓库是否存在
        if git ls-remote origin &>/dev/null; then
            log "远程仓库已存在，拉取..."
            git pull origin main --rebase --allow-unrelated-histories 2>/dev/null || true
        fi

        git push -u origin main

        if [ $? -eq 0 ]; then
            log "✓ 已推送到 GitHub"
        else
            warn "推送失败，请检查仓库权限或手动推送"
        fi
    fi
fi

echo ""

# 首次同步
prompt "是否立即同步当前主机的记忆到 GitHub？(y/n)"
read -r do_sync

if [[ "$do_sync" =~ ^[Yy]$ ]]; then
    log "开始首次同步..."
    ./sync-memory.sh
fi

echo ""

# 拉取并融合（如果是第二台或更多机器）
if git ls-remote origin 2>/dev/null | grep -q 'refs/heads/host/'; then
    log "检测到其他主机的记忆"
    prompt "是否立即拉取并融合？(y/n)"
    read -r do_merge

    if [[ "$do_merge" =~ ^[Yy]$ ]]; then
        log "开始拉取和融合..."
        ./pull-and-merge.sh
    fi
fi

echo ""

# 设置 cron 任务
log "设置定时任务..."

CRON_SYNC="0 3 * * * cd $SCRIPT_DIR && ./sync-memory.sh >> $SCRIPT_DIR/sync.log 2>&1"
CRON_MERGE="30 3 * * * cd $SCRIPT_DIR && ./pull-and-merge.sh >> $SCRIPT_DIR/merge.log 2>&1"

# 检查是否已经存在
if crontab -l 2>/dev/null | grep -q "sync-memory.sh"; then
    log "定时任务已存在"
else
    prompt "是否添加定时任务（每天 03:00 同步，03:30 融合）？(y/n)"
    read -r add_cron

    if [[ "$add_cron" =~ ^[Yy]$ ]]; then
        # 添加到 crontab
        (crontab -l 2>/dev/null; echo ""; echo "# My Memory - Claude Code 全局记忆同步"; echo "$CRON_SYNC"; echo "$CRON_MERGE") | crontab -

        log "✓ 定时任务已添加"
        log "  - 每天 03:00: 同步记忆到 GitHub"
        log "  - 每天 03:30: 拉取并融合"
    else
        log "跳过添加定时任务，可以稍后手动添加："
        echo "  $CRON_SYNC"
        echo "  $CRON_MERGE"
    fi
fi

echo ""
echo -e "${GREEN}╔═══════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║          ✅ 安装完成！                    ║${NC}"
echo -e "${GREEN}╚═══════════════════════════════════════════╝${NC}"
echo ""

log "下一步："
echo "  1. 查看定时任务: crontab -l | grep my-memory"
echo "  2. 手动同步: ./sync-memory.sh"
echo "  3. 手动拉取融合: ./pull-and-merge.sh"
echo "  4. 解密查看: ./decrypt-memory.sh hosts/<hostname>/CLAUDE.md.enc"
echo "  5. 查看同步日志: tail -f sync.log"
echo "  6. 查看融合日志: tail -f merge.log"
echo ""

log "密码文件: $PASSWORD_FILE"
warn "请妥善保管密码，丢失后无法恢复"
echo ""

log "完成！系统将在每天 03:00 和 03:30 自动同步和融合记忆"
