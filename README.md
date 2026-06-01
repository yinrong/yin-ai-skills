# yin-ai-skills

AI 辅助开发的 Skills 集合，专为 Claude Code 设计，符合中国程序员习惯。

## 包含的 Skills

### 1. recursive-research（递归式深度调研）

**用途**：自动化深度研究任务，支持多轮迭代、来源分级、断点续传。

**适用场景**：
- 技术选型调研（"对比 Redis vs Memcached"）
- 算法文献综述（"Transformer 架构演进"）
- 最佳实践研究（"微服务容错模式"）

**核心特性**：
- ✅ 自动拆解研究线索（3-5 条）
- ✅ 来源分级（T1/T2/T3，学术/官方优先）
- ✅ 断点续传（支持 `--resume`）
- ✅ 完整记录每轮研究过程
- ✅ 使用中文输出，Markdown 格式

**快速开始**：
```bash
/recursive-research "分布式事务解决方案"
```

**详细文档**：[recursive-research/skill.md](./recursive-research/skill.md)

---

### 2. code-iteration（代码持续迭代）

**用途**：AI 自动化代码实验，持续迭代直到完成目标，完整记录所有细节（含失败路径）。

**适用场景**：
- 算法实验（"对比不同优化器性能"）
- 功能开发（"实现用户认证系统"）
- 性能优化（"降低 API 响应时间"）
- Bug 修复（"解决内存泄漏问题"）

**核心特性**：
- ✅ AI 持续自动迭代直到达成目标
- ✅ 保存完整细节记录（无跳跃性，人类可读）
- ✅ 失败路径也完整保留（失败=认知）
- ✅ AI 可按记录复现/继续实验
- ✅ 自动生成索引文件和复现指南
- ✅ 支持断点续传

**快速开始**：
```bash
/code-iteration "优化器对比" "实现并对比 Adam/SGD 在 MNIST 上的性能"
```

**详细文档**：[code-iteration/skill.md](./code-iteration/skill.md)

---

### 3. memory-sync（跨主机记忆同步）

**用途**：自动同步和融合多台机器上的 Claude Code 全局记忆，支持加密存储到 GitHub。

**适用场景**：
- 多台机器（laptop、desktop、server）共享 Claude 经验
- 团队协作，共享 Claude 配置和记忆
- 备份和恢复 Claude 全局记忆
- 跨平台同步（Mac、Linux、Windows）

**核心特性**：
- ✅ **自动定时同步**：每天自动推送记忆到 GitHub
- ✅ **加密存储**：AES-256 加密，GitHub 无法直接读取
- ✅ **多主机支持**：每台机器独立分支，互不覆盖
- ✅ **智能融合**：自动融合多个主机的记忆
- ✅ **独立仓库**：记忆存储在单独的 my-memory 仓库

**快速开始**：
```bash
# 初始化（第一次使用）
/memory-sync init

# 立即同步
/memory-sync sync

# 拉取并融合其他主机的记忆
/memory-sync merge

# 查看状态
/memory-sync status
```

**详细文档**：[memory-sync/skill.md](./memory-sync/skill.md)

**配套仓库**：需要单独创建 `my-memory` 仓库存储加密的记忆文件

---

## 安装

### 方式 1：克隆到 Claude Code 全局目录（推荐）

```bash
cd ~/.claude/skills/
git clone https://github.com/你的用户名/yin-ai-skills.git
```

然后在任何项目中使用：
```bash
/recursive-research <主题>
/code-iteration <实验名> "<目标>"
```

### 方式 2：克隆到项目目录

```bash
cd your-project/.claude/skills/
git clone https://github.com/你的用户名/yin-ai-skills.git
```

Skills 仅在该项目中可用。

---

## 设计理念

### 为什么需要这些 Skills？

**问题**：
1. AI 做探索性任务时，过程记录不完整 → 人类难以理解思路
2. 实验失败后重来，之前的尝试丢失 → 重复踩坑
3. AI 会话中断后，新会话无法接手 → 无法持续迭代
4. 记录过于简略，跳跃性强 → 无法复现

**解决方案**：
- **结构化输出**：固定目录结构，所有记录归档清晰
- **完整性优先**：宁可啰嗦，不要跳步，失败也记录
- **断点续传**：检查点机制，支持随时中断和恢复
- **索引导航**：README 快速了解全局，详细内容按需查看
- **复现优先**：所有实验都有 `复现指南.md`，一键运行

### 核心原则

| 原则 | 说明 |
|------|------|
| **记录 > 记忆** | 不依赖上下文，所有信息持久化到文件 |
| **失败 = 认知** | 失败路径和成功路径同等重要 |
| **人类可读** | 非技术人员也能看懂思路 |
| **AI 可读** | 新会话能通过读取记录继续工作 |
| **中文优先** | 文件名、内容全部中文，符合国内习惯 |

---

## 使用技巧

### 1. 如何选择合适的 Skill？

| 任务类型 | 推荐 Skill |
|----------|-----------|
| 调研技术方案、查找资料 | `recursive-research` |
| 写代码、做实验、调试 bug | `code-iteration` |
| 需要多轮迭代优化 | `code-iteration` |
| 需要对比分析多个来源 | `recursive-research` |

**组合使用**：
```bash
# 第 1 步：调研优化器原理
/recursive-research "深度学习优化器对比"

# 第 2 步：基于调研结果实现实验
/code-iteration "优化器实验" "实现论文中的三种优化器并对比"
```

### 2. 如何断点续传？

**场景 1**：Claude Code 会话关闭
```bash
# 重新启动后
/recursive-research --resume 分布式事务解决方案
/code-iteration --resume 优化器实验
```

**场景 2**：切换到新电脑
```bash
# 同步实验目录
scp -r 实验/2026-06-02-优化器实验 remote:/path/

# 在新电脑上继续
/code-iteration --resume 优化器实验
```

### 3. 如何让别人（或 AI）复现你的工作？

**分享调研结果**：
```bash
# 发送整个目录
tar -czf 调研结果.tar.gz 调研/2026-06-02-分布式事务/
```

对方解压后读 `README.md` 即可快速了解。

**分享实验结果**：
```bash
# 发送实验目录
tar -czf 实验结果.tar.gz 实验/2026-06-02-优化器实验/

# 对方一键复现
cd 实验/2026-06-02-优化器实验
bash 复现指南.sh
```

---

## 目录结构示例

### recursive-research 输出

```
调研/
└── 2026-06-02-分布式事务解决方案/
    ├── 状态.md              # 当前进度
    ├── 线索.md              # 研究线索
    ├── 发现.md              # 关键发现
    ├── 来源-T1.md           # 一级来源
    ├── 来源-T2.md           # 二级来源
    ├── 来源-T3.md           # 三级来源
    ├── 来源-已拒绝.md        # 拒绝的来源
    ├── 轮次-01.md           # 第 1 轮记录
    ├── 轮次-02.md           # 第 2 轮记录
    ├── ...
    ├── 综合报告.md          # 最终报告
    ├── 行动建议.md          # 可执行建议
    └── 知识缺口.md          # 未解决问题
```

### code-iteration 输出

```
实验/
└── 2026-06-02-优化器对比/
    ├── README.md            # 【索引】5分钟了解全局
    ├── 目标与标准.md         # 实验目标
    ├── 当前状态.md          # 最新进度
    ├── 复现指南.md          # 一键复现
    ├── 检查点/
    │   ├── 01-baseline.md
    │   └── 02-adam.md
    ├── 迭代日志/
    │   ├── 第01轮-初始化.md
    │   ├── 第02轮-实现baseline.md
    │   └── 第03轮-修复bug.md
    ├── 决策树.md            # Mermaid 决策图
    ├── 失败案例库.md         # 踩过的坑
    ├── 发现与洞察.md         # 意外收获
    ├── 代码/
    │   ├── baseline/
    │   ├── final/
    │   └── failed_attempts/
    ├── 结果/
    │   └── 对比图表.png
    └── 最终报告.md
```

---

## 常见问题

### Q1：为什么文件名都是中文？

**A**：习惯问题。中国程序员看中文目录结构更直观，`迭代日志` 比 `iteration_logs` 更好理解。如果你的团队偏好英文，可以修改 skill 脚本中的目录名。

### Q2：记录太详细会不会占用太多磁盘？

**A**：通常不会。一个 20 轮的实验，迭代日志约 500KB，检查点代码约 5MB，总计 <10MB。相比收益（完整可复现），存储成本可忽略。

### Q3：AI 生成的记录会不会有遗漏？

**A**：Skill 通过强制模板和检查清单减少遗漏，但仍需人工抽查。建议每 5 轮检查一次 `当前状态.md` 和最新日志。

### Q4：可以用于团队协作吗？

**A**：可以。将 `调研/` 或 `实验/` 目录 commit 到 Git，团队成员可以：
- 读取他人的调研/实验记录
- 基于他人的检查点继续开发
- 复现他人的实验结果

### Q5：支持其他语言（如英文）吗？

**A**：支持。修改 skill 脚本中的模板文本即可。或者在使用时要求 Claude 用英文输出。

---

## 贡献

欢迎提交 Issue 和 PR！

**改进方向**：
- 支持更多输出格式（JSON、HTML 报告）
- 自动生成可视化图表
- 集成外部工具（如 Notion、Obsidian）
- 多语言支持

---

## 许可证

MIT License

---

## 致谢

**灵感来源**：
- [Anjos2/recursive-research](https://github.com/Anjos2/recursive-research) - 原始 recursive-research skill
- [Anthropic Cookbook](https://github.com/anthropics/anthropic-cookbook) - 实验记录最佳实践
- [michalparkola/tapestry-skills](https://github.com/michalparkola/tapestry-skills-for-claude-code) - Session Log skill

**适配说明**：
本仓库的 `recursive-research` 是基于原版的中文改编，专门为中国程序员优化：
- 全中文文件名和内容
- 简化为仅支持 Claude Code
- 调整目录结构符合国内习惯
- 增强断点续传和复现能力
