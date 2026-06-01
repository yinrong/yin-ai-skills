---
skill: memory-sync
version: 1.0.0
description: 跨主机全局记忆同步 - 自动同步、加密、融合多台机器的 Claude Code 记忆
author: yin
tags: [memory, sync, encryption, multi-host]
---

# Memory Sync - 跨主机全局记忆同步

自动同步和融合多台机器上的 Claude Code 全局记忆，支持加密存储到 GitHub。

## 功能特性

- ✅ **自动定时同步**：每天自动推送本机记忆到 GitHub
- ✅ **加密存储**：使用密码加密，GitHub 上无法直接读取
- ✅ **多主机支持**：每台机器独立分支，互不覆盖
- ✅ **智能融合**：自动融合多个主机的记忆到 `common` 分支
- ✅ **本地解密**：使用本地密码解密查看
- ✅ **独立仓库**：记忆内容存储在单独的 my-memory 仓库

## 使用方法

### 初始化（第一次使用）

```bash
/memory-sync init
```

会提示你：
1. 设置加密密码（用于加密记忆）
2. 输入 my-memory 仓库地址（如 `git@github.com:yinrong/my-memory.git`）
3. 设置定时任务（可选）

### 立即同步

```bash
/memory-sync sync
```

加密本机记忆并推送到 GitHub。

### 拉取并融合

```bash
/memory-sync merge
```

拉取所有主机的记忆，智能融合后应用到本机。

### 查看状态

```bash
/memory-sync status
```

显示：
- 本机最后同步时间
- 其他主机列表和状态
- 融合记忆信息

### 解密查看

```bash
/memory-sync decrypt <hostname>
```

解密查看指定主机的记忆。

## 工作原理

### 仓库结构

**yin-ai-skills（本 skill）**：
```
yin-ai-skills/
└── memory-sync/
    ├── skill.md              # 本文件
    ├── memory-sync           # Skill 入口脚本
    └── lib/
        ├── sync.sh           # 同步脚本
        ├── merge.sh          # 融合脚本
        └── decrypt.sh        # 解密脚本
```

**my-memory（记忆存储仓库）**：
```
my-memory/
├── README.md                 # 说明文档
├── .gitignore
└── hosts/
    ├── laptop/               # 笔记本主机
    │   ├── CLAUDE.md.enc
    │   ├── MEMORY.md.enc
    │   └── metadata.json
    ├── desktop/              # 台式机主机
    │   ├── CLAUDE.md.enc
    │   ├── MEMORY.md.enc
    │   └── metadata.json
    └── common/               # 融合后的公共记忆
        ├── CLAUDE.md
        └── MEMORY.md
```

### Git 分支策略

- `main` 分支：存储 README 和配置
- `host/<hostname>` 分支：每台主机的加密记忆
- `common` 分支：融合后的公共记忆

### 同步流程（每天 03:00）

1. 读取 `~/.claude/CLAUDE.md` 和 `~/.claude/global-memory/`
2. 使用 AES-256 加密
3. 保存到 my-memory 仓库的 `hosts/<hostname>/`
4. 推送到 `host/<hostname>` 分支

### 融合流程（每天 03:30）

1. 拉取所有 `host/*` 分支
2. 解密每个主机的记忆
3. 智能融合：
   - 合并相同主题内容
   - 保留各主机独特经验
   - 去重和冲突解决
4. 保存到 `hosts/common/`
5. 推送到 `common` 分支
6. 应用到本机 `~/.claude/`

## 配置文件

### ~/.memory-sync-config

```json
{
  "passwordFile": "~/.my-memory-password",
  "repoPath": "~/my-memory",
  "repoUrl": "git@github.com:yinrong/my-memory.git",
  "syncTime": "03:00",
  "mergeTime": "03:30",
  "autoSync": true,
  "autoMerge": true
}
```

### ~/.my-memory-password

纯文本文件，存储加密密码（不提交到 Git）

## 安全性

- ✅ 密码仅存储在本地 `~/.my-memory-password`
- ✅ GitHub 上只有加密文件（AES-256-CBC）
- ✅ 解密需要本地密码
- ✅ `.my-memory-password` 加入 `.gitignore`

## 定时任务

安装后会创建 cron 任务：

```cron
# 每天 03:00 同步记忆到 GitHub
0 3 * * * /memory-sync sync

# 每天 03:30 拉取并融合
30 3 * * * /memory-sync merge
```

## 多主机示例

假设你有 3 台机器（laptop、desktop、server）：

**同步过程**：
1. laptop 在 03:00 推送记忆到 `host/laptop` 分支
2. desktop 在 03:00 推送记忆到 `host/desktop` 分支
3. server 在 03:00 推送记忆到 `host/server` 分支

**融合过程**：
4. 每台机器在 03:30 拉取所有 `host/*` 分支
5. 解密并智能融合到 `common` 分支
6. 将融合结果应用到本机 Claude Code

**结果**：
- 每台机器都有自己的独立记忆
- 同时也有融合后的公共记忆
- 公共记忆包含了所有机器的经验

## 故障排查

### 密码丢失

密码在 `~/.my-memory-password`。如果丢失：
1. 在另一台有密码的机器上查看
2. 或删除 my-memory 仓库重新开始

### 同步失败

```bash
/memory-sync status
```

检查错误日志：
```bash
tail -20 ~/my-memory/sync.log
```

### 融合冲突

手动解决：
```bash
cd ~/my-memory
git fetch --all
git checkout common
# 编辑 hosts/common/ 下的文件
git add .
git commit -m "Manual merge"
git push origin common
```

## 卸载

```bash
/memory-sync uninstall
```

会删除：
- cron 定时任务
- my-memory 本地仓库（可选）
- GitHub 仓库保留（作为备份）

## 示例

### 首次设置

```bash
# 在第一台机器上
/memory-sync init
# 输入密码: ********
# 输入仓库: git@github.com:yinrong/my-memory.git
# 添加定时任务? y

# 立即同步
/memory-sync sync
```

### 在第二台机器上设置

```bash
# 克隆 yin-ai-skills（包含此 skill）
cd ~/.claude/skills/
git clone git@github.com:yinrong/yin-ai-skills.git

# 初始化
/memory-sync init
# 输入相同密码: ********
# 输入相同仓库: git@github.com:yinrong/my-memory.git
# 添加定时任务? y

# 拉取并融合第一台机器的记忆
/memory-sync merge

# 现在两台机器的记忆已融合
```

### 日常使用

一切自动化，无需手动操作。定时任务每天会：
1. 03:00 - 同步本机记忆到 GitHub
2. 03:30 - 拉取并融合所有主机记忆

如需手动操作：
```bash
# 查看状态
/memory-sync status

# 立即同步
/memory-sync sync

# 立即融合
/memory-sync merge

# 查看其他主机的记忆
/memory-sync decrypt laptop
```

## 注意事项

1. **密码管理**：所有机器必须使用相同密码
2. **网络要求**：需要访问 GitHub（可配置代理）
3. **磁盘空间**：记忆文件通常 <10MB
4. **时区**：定时任务使用本地时区

## 与 Claude Code 集成

此 skill 自动与 Claude Code 集成：

- **读取**：从 `~/.claude/` 读取记忆
- **写入**：融合后写入 `~/.claude/global-memory/`
- **不冲突**：不影响 auto memory 功能
- **互补**：扩展了 auto memory 的跨主机能力

## 许可证

MIT License
