# yin-ai-skills

AI 辅助开发的 Skills 集合，专为 Claude Code 设计。

## 📦 包含的 Skills

| Skill | 用途 | 快速开始 |
|-------|------|----------|
| [**recursive-research**](./recursive-research/) | 自动化深度调研 | `/recursive-research "主题"` |
| [**code-iteration**](./code-iteration/) | 代码持续迭代实验 | `/code-iteration "实验名" "目标"` |
| [**memory-sync**](./memory-sync/) | 跨主机记忆同步 | `/memory-sync init` |

---

### 1. recursive-research（递归式深度调研）

自动化多轮研究，来源分级（T1/T2/T3），断点续传，适合技术选型和文献综述。

**适用场景**：技术选型 · 算法调研 · 最佳实践研究

**快速开始**：
```bash
/recursive-research "分布式事务解决方案"
```

[查看详细文档 →](./recursive-research/skill.md)

---

### 2. code-iteration（代码持续迭代）

AI 自动迭代直到完成目标，完整记录所有细节（含失败路径），人类和 AI 可复现。

**适用场景**：算法实验 · 功能开发 · 性能优化 · Bug 修复

**快速开始**：
```bash
/code-iteration "优化器对比" "对比 Adam/SGD 在 MNIST 上的性能"
```

[查看详细文档 →](./code-iteration/skill.md)

---

### 3. memory-sync（跨主机记忆同步）

自动同步和融合多台机器的 Claude Code 记忆，加密存储到 GitHub。

**适用场景**：多机器协作 · 团队共享 · 记忆备份 · 跨平台同步

**快速开始**：
```bash
/memory-sync init    # 初始化
/memory-sync sync    # 同步记忆
/memory-sync merge   # 融合其他主机记忆
```

[查看详细文档 →](./memory-sync/skill.md) · [配套仓库：my-memory](https://github.com/yinrong/my-memory)

---

## 🚀 安装

**全局安装（推荐）**：

```bash
cd ~/.claude/skills/
git clone https://github.com/yinrong/yin-ai-skills.git
```

然后在任何项目中使用：
```bash
/recursive-research <主题>
/code-iteration <实验名> "<目标>"
/memory-sync init
```

**项目级安装**：

```bash
cd your-project/.claude/skills/
git clone https://github.com/yinrong/yin-ai-skills.git
```

Skills 仅在该项目中可用。

---

## 📖 使用指南

### 选择合适的 Skill

| 任务 | 推荐 |
|------|------|
| 调研技术方案、查找资料 | `recursive-research` |
| 写代码、做实验、调试 | `code-iteration` |
| 多机器共享经验 | `memory-sync` |

### 组合使用

```bash
# 第 1 步：调研
/recursive-research "深度学习优化器对比"

# 第 2 步：基于调研实现实验
/code-iteration "优化器实验" "实现论文中的三种优化器并对比"
```

### 断点续传

```bash
# 恢复之前的调研/实验
/recursive-research --resume <主题ID>
/code-iteration --resume <实验ID>
```

详细使用技巧见 [docs/usage-guide.md](./docs/usage-guide.md)

---

## 💡 设计理念

- **记录 > 记忆**：所有信息持久化到文件
- **失败 = 认知**：失败路径同样重要
- **人类可读**：非技术人员也能看懂
- **AI 可读**：新会话能继续工作
- **中文优先**：符合国内习惯

详见 [docs/design-philosophy.md](./docs/design-philosophy.md)

---

## 📂 目录结构示例

**recursive-research 输出**：
```
调研/<主题>/
├── README.md
├── 状态.md
├── 线索.md
├── 发现.md
├── 来源-T1/T2/T3.md
├── 轮次-01/02/...md
├── 综合报告.md
└── 行动建议.md
```

**code-iteration 输出**：
```
实验/<实验名>/
├── README.md（索引）
├── 复现指南.md
├── 检查点/
├── 迭代日志/
├── 代码/
└── 结果/
```

详见各 skill 文档。

---

## ❓ 常见问题

<details>
<summary><b>为什么文件名都是中文？</b></summary>

中文更直观，`迭代日志` 比 `iteration_logs` 好理解。可修改脚本改成英文。
</details>

<details>
<summary><b>记录会占用很多磁盘吗？</b></summary>

不会。一个 20 轮实验约 5-10MB。相比收益（完整可复现），成本可忽略。
</details>

<details>
<summary><b>可以团队协作吗？</b></summary>

可以。将输出目录 commit 到 Git，团队成员可读取、继续、复现。
</details>

<details>
<summary><b>支持英文输出吗？</b></summary>

支持。修改脚本模板或在使用时要求 Claude 用英文输出。
</details>

更多问题见 [docs/faq.md](./docs/faq.md)

---

## 🤝 贡献

欢迎提交 Issue 和 PR！

改进方向：JSON/HTML 报告 · 可视化图表 · Notion/Obsidian 集成 · 多语言支持

---

## 📄 许可证

MIT License

---

## 🙏 致谢

- [Anjos2/recursive-research](https://github.com/Anjos2/recursive-research) - 原始 recursive-research
- [Anthropic Cookbook](https://github.com/anthropics/anthropic-cookbook) - 实验记录最佳实践
- [michalparkola/tapestry-skills](https://github.com/michalparkola/tapestry-skills-for-claude-code) - Session Log

本仓库针对中国程序员优化：全中文、简化流程、增强复现能力。
