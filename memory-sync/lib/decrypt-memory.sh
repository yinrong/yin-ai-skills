#!/bin/bash
# decrypt-memory.sh - 解密查看加密的记忆文件

PASSWORD_FILE="$HOME/.my-memory-password"

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

if [ $# -eq 0 ]; then
    echo "用法: $0 <加密文件.enc>"
    echo ""
    echo "示例:"
    echo "  $0 hosts/laptop/CLAUDE.md.enc"
    echo "  $0 hosts/desktop/MEMORY.md.enc"
    exit 1
fi

ENC_FILE=$1

if [ ! -f "$ENC_FILE" ]; then
    echo -e "${RED}错误：文件不存在: $ENC_FILE${NC}"
    exit 1
fi

if [ ! -f "$PASSWORD_FILE" ]; then
    echo -e "${RED}错误：密码文件不存在: $PASSWORD_FILE${NC}"
    echo "请先运行 ./setup.sh 设置密码"
    exit 1
fi

PASSWORD=$(cat "$PASSWORD_FILE")

echo -e "${GREEN}解密: $ENC_FILE${NC}"
echo "---"

openssl enc -aes-256-cbc -d -pbkdf2 \
    -in "$ENC_FILE" \
    -k "$PASSWORD" 2>/dev/null

if [ $? -ne 0 ]; then
    echo -e "${RED}解密失败，可能密码不正确${NC}"
    exit 1
fi
