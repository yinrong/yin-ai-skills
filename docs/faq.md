# 常见问题 (FAQ)

## 安装和配置

### Q: 如何安装？

**A**: 克隆到 `~/.claude/skills/` 目录：

```bash
cd ~/.claude/skills/
git clone https://github.com/yinrong/yin-ai-skills.git
```

### Q: 安装后如何验证？

**A**: 在任何 Claude Code 会话中输入：

```bash
/recursive-research
```

如果显示用法说明，说明安装成功。

### Q: 可以只安装某个 Skill 吗？

**A**: 可以。只复制对应目录：

```bash
cd ~/.claude/skills/
mkdir -p my-skills
cp -r yin-ai-skills/code-iteration my-skills/
```

---

## 使用问题

### Q: 为什么文件名都是中文？

**A**: 中文更直观，符合国内程序员习惯。如需英文，修改 skill 脚本中的模板即可。

### Q: 记录太详细会占用很多磁盘吗？

**A**: 不会。典型占用：
- 调研（20 轮）：约 2-5 MB
- 实验（30 轮）：约 5-10 MB

相比收益（完整可复现），成本可忽略。

### Q: AI 生成的记录会有遗漏吗？

**A**: 可能。建议：
- 每 5 轮检查一次状态文件
- 发现遗漏及时要求 Claude 补充
- 关键决策点手动验证

### Q: 如何选择用哪个 Skill？

**A**: 

| 任务 | 用 |
|------|---|
| 调研、查资料 | `recursive-research` |
| 写代码、实验 | `code-iteration` |
| 多机器协作 | `memory-sync` |

### Q: 可以中途停止吗？

**A**: 可以。随时中断，下次用 `--resume` 继续：

```bash
/code-iteration --resume 优化器实验
```

### Q: 如何删除失败的实验？

**A**: 直接删除目录：

```bash
rm -rf 实验/2026-06-02-失败的实验/
```

建议先归档：

```bash
tar -czf 归档/失败实验.tar.gz 实验/2026-06-02-失败的实验/
rm -rf 实验/2026-06-02-失败的实验/
```

---

## 团队协作

### Q: 可以团队协作吗？

**A**: 可以。将输出目录提交到 Git：

```bash
git add 实验/2026-06-02-优化器实验/
git commit -m "完成 Adam 优化器实验"
git push
```

团队成员可以：
- 读取记录
- 继续实验
- 复现结果

### Q: 多人同时编辑会冲突吗？

**A**: 会，但冲突少：
- 每人在不同目录工作（不同实验/调研）
- 文件是 Markdown，冲突易解决
- 使用分支隔离

**最佳实践**：
```bash
# 每人一个分支
git checkout -b feature/实验A
/code-iteration "实验A" "..."

# 完成后合并
git checkout main
git merge feature/实验A
```

### Q: 如何共享 CLAUDE.md 配置？

**A**: 在项目根目录创建 `.claude/CLAUDE.md`：

```bash
mkdir -p .claude
cat > .claude/CLAUDE.md << 'EOF'
# 项目配置

使用 yin-ai-skills 进行实验：
- 实验目录统一放在 `实验/`
- 命名格式：`YYYY-MM-DD-实验名`
- 完成后及时 commit
EOF

git add .claude/CLAUDE.md
git commit -m "Add project CLAUDE.md"
```

---

## 技术问题

### Q: 支持其他语言（如英文）吗？

**A**: 支持。两种方式：

**方式 1**：在使用时要求
```bash
/code-iteration "Optimizer Comparison" "Compare Adam vs SGD" --lang en
```

**方式 2**：修改脚本模板
```bash
vim ~/.claude/skills/yin-ai-skills/code-iteration/code-iteration
# 修改模板部分为英文
```

### Q: 如何自定义输出格式？

**A**: 编辑 skill 脚本：

```bash
# 找到模板部分
vim ~/.claude/skills/yin-ai-skills/code-iteration/code-iteration

# 修改目录名、文件名、模板内容
```

### Q: 可以集成到 CI/CD 吗？

**A**: 可以。使用 `claude -p` 非交互模式：

```yaml
# .github/workflows/experiment.yml
- name: Run experiment
  run: |
    claude -p "/code-iteration \"$EXPERIMENT\" \"$GOAL\""
```

### Q: 如何备份输出？

**A**: 

**方式 1**：Git 版本控制
```bash
git add 调研/ 实验/
git commit -m "Backup experiments"
git push
```

**方式 2**：定期打包
```bash
tar -czf backup-$(date +%Y%m%d).tar.gz 调研/ 实验/
```

**方式 3**：使用 memory-sync（自动备份到 GitHub）
```bash
/memory-sync init
# 自动定时同步
```

### Q: 输出太大怎么办？

**A**: 

1. **压缩归档**：
```bash
tar -czf 归档.tar.gz 调研/ 实验/
rm -rf 调研/ 实验/
```

2. **清理旧数据**：
```bash
# 删除 30 天前的
find 实验/ -type d -mtime +30 -exec rm -rf {} \;
```

3. **只保留关键文件**：
```bash
# 删除详细日志，保留索引和报告
rm 实验/*/迭代日志/*.md
```

---

## memory-sync 相关

### Q: memory-sync 是干什么的？

**A**: 跨主机同步 Claude Code 全局记忆，支持多台机器共享经验。

详见 [memory-sync/skill.md](../memory-sync/skill.md)

### Q: 需要单独的仓库吗？

**A**: 是的。需要创建 `my-memory` 仓库存储加密的记忆文件。

### Q: 密码丢失怎么办？

**A**: 
1. 在另一台有密码的机器上查看 `cat ~/.my-memory-password`
2. 或删除 my-memory 仓库重新开始（历史记忆丢失）

### Q: 可以不用 GitHub 吗？

**A**: 可以。支持任何 Git 服务（GitLab、Gitea、自建）。修改 `repoUrl` 即可。

### Q: 多台机器必须用相同密码吗？

**A**: 是的。所有机器必须使用相同密码才能解密彼此的记忆。

---

## 性能问题

### Q: 会影响 Claude Code 速度吗？

**A**: 不会。Skills 只在调用时运行，不影响日常使用。

### Q: 生成记录很慢怎么办？

**A**: 
- 记录生成是异步的，不阻塞主任务
- 可以调整轮次（减少迭代次数）
- 使用更快的模型（Haiku）

### Q: 记录文件太多怎么办？

**A**: 
- 只保留核心文件（README、最终报告）
- 删除详细日志（迭代日志、检查点）
- 压缩归档旧实验

---

## 故障排查

### Q: Skill 找不到怎么办？

**A**: 检查安装位置：

```bash
ls ~/.claude/skills/yin-ai-skills/
```

应该看到：`recursive-research`、`code-iteration`、`memory-sync`

### Q: 断点续传失败怎么办？

**A**: 检查关键文件：

```bash
# 调研
cat 调研/<主题>/状态.md

# 实验
cat 实验/<实验名>/当前状态.md
```

如果文件不存在或损坏，无法续传。

### Q: 记录不完整怎么办？

**A**: 
1. 要求 Claude 补充：
   ```
   请补充第 5 轮的详细记录
   ```

2. 手动编辑：
   ```bash
   vim 实验/<实验名>/迭代日志/第05轮-*.md
   ```

3. 调整 Skill 参数（增加记录粒度）

### Q: Git 冲突怎么解决？

**A**: Markdown 冲突易解决：

```bash
git pull
# 查看冲突文件
git status

# 手动编辑解决冲突
vim 实验/<实验名>/README.md

# 提交
git add .
git commit
```

---

## 其他

### Q: 如何贡献？

**A**: 欢迎提交 Issue 和 PR：
- Issue: https://github.com/yinrong/yin-ai-skills/issues
- PR: Fork 后提交 Pull Request

### Q: 许可证是什么？

**A**: MIT License。可自由使用、修改、分发。

### Q: 支持 Windows 吗？

**A**: 支持。在 WSL 或 Git Bash 中使用。

### Q: 支持 Mac 吗？

**A**: 完全支持。所有功能在 Mac 上正常工作。

### Q: 有示例吗？

**A**: 查看 [docs/usage-guide.md](./usage-guide.md) 中的示例。

### Q: 如何卸载？

**A**: 删除目录：

```bash
rm -rf ~/.claude/skills/yin-ai-skills/
```

输出目录（调研/实验/）不会自动删除，需手动清理：

```bash
rm -rf 调研/ 实验/
```

---

## 还有问题？

- 查看 [使用指南](./usage-guide.md)
- 查看 [设计理念](./design-philosophy.md)
- 提交 Issue: https://github.com/yinrong/yin-ai-skills/issues
