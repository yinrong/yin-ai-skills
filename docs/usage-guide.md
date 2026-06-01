# 使用指南

## 选择合适的 Skill

| 任务类型 | 推荐 Skill | 理由 |
|----------|-----------|------|
| 调研技术方案 | `recursive-research` | 自动多轮搜索、来源分级 |
| 查找资料、文献综述 | `recursive-research` | 支持学术/官方来源优先 |
| 写代码、算法实验 | `code-iteration` | 完整记录实验过程 |
| 调试 Bug | `code-iteration` | 记录失败尝试和解决方案 |
| 性能优化 | `code-iteration` | 对比不同方案的效果 |
| 多机器协作 | `memory-sync` | 自动同步和融合记忆 |

## 组合使用示例

### 场景 1：从调研到实现

```bash
# Step 1: 调研技术方案
/recursive-research "深度学习优化器对比（Adam/SGD/AdamW）"

# 等待调研完成（10-20 轮迭代）
# 阅读 调研/<主题>/综合报告.md

# Step 2: 基于调研实现实验
/code-iteration "优化器实验" "实现 Adam/SGD/AdamW 并在 MNIST 上对比"

# 等待实验完成（15-30 轮迭代）
# 查看 实验/<实验名>/最终报告.md
```

### 场景 2：多机器共享经验

```bash
# 在笔记本上
/memory-sync init    # 首次配置
/memory-sync sync    # 同步记忆到 GitHub

# 切换到台式机
/memory-sync init    # 使用相同密码
/memory-sync merge   # 拉取笔记本的记忆

# 现在两台机器共享相同经验！
```

## 断点续传

### 场景 1：会话中断

Claude Code 会话关闭后：

```bash
# 重新启动，恢复调研
/recursive-research --resume 深度学习优化器对比

# 恢复实验
/code-iteration --resume 优化器实验
```

### 场景 2：切换电脑

```bash
# 在机器 A 上
tar -czf 实验备份.tar.gz 实验/2026-06-02-优化器实验/

# 传输到机器 B
scp 实验备份.tar.gz user@machine-b:/path/

# 在机器 B 上
tar -xzf 实验备份.tar.gz
/code-iteration --resume 优化器实验
```

### 场景 3：团队协作

```bash
# 成员 A 完成实验
cd 实验/2026-06-02-优化器实验
git add .
git commit -m "完成 Adam 优化器实验"
git push

# 成员 B 继续实验
git pull
/code-iteration --resume 优化器实验
# Claude 会读取之前的记录继续
```

## 复现他人的工作

### 复现调研

```bash
# 获取调研目录
git clone <repo> 或解压 调研结果.tar.gz

# 阅读索引
cat 调研/<主题>/README.md

# 查看关键文件
cat 调研/<主题>/综合报告.md
cat 调研/<主题>/行动建议.md

# 如需继续调研
/recursive-research --resume <主题>
```

### 复现实验

```bash
# 获取实验目录
git clone <repo> 或解压 实验结果.tar.gz

cd 实验/<实验名>

# 快速了解（5 分钟）
cat README.md

# 一键复现
bash 复现指南.sh

# 或手动复现
cat 复现指南.md  # 查看详细步骤
```

## 输出目录管理

### recursive-research

**位置**：`调研/<日期-主题>/`

**核心文件**：
- `综合报告.md` - 最终结论
- `行动建议.md` - 可执行建议
- `发现.md` - 关键发现汇总

**支持文件**：
- `状态.md` - 当前进度
- `线索.md` - 研究线索
- `轮次-XX.md` - 每轮详细记录

### code-iteration

**位置**：`实验/<日期-实验名>/`

**核心文件**：
- `README.md` - 5 分钟快速了解
- `复现指南.md` - 一键复现步骤
- `最终报告.md` - 实验结论

**支持文件**：
- `当前状态.md` - 最新进度
- `检查点/` - 重要里程碑
- `迭代日志/` - 每轮详细记录
- `代码/` - 代码快照
- `结果/` - 数据和图表

### 清理旧输出

```bash
# 删除 30 天前的调研
find 调研/ -type d -mtime +30 -exec rm -rf {} \;

# 归档重要实验
tar -czf 归档/优化器实验-2026-06.tar.gz 实验/2026-06-*-优化器*/
rm -rf 实验/2026-06-*-优化器*/
```

## 最佳实践

### 1. 调研前准备

- 明确调研目标和范围
- 确定成功标准（如"找到 3 个可行方案"）
- 预估轮次（通常 10-20 轮）

### 2. 实验前准备

- 写清楚实验目标（可量化）
- 定义成功标准（如"准确率 >95%"）
- 准备测试数据和环境

### 3. 定期检查

- **调研**：每 5 轮检查 `状态.md`，确认方向正确
- **实验**：每 5 轮检查 `当前状态.md`，避免偏离目标

### 4. 及时归档

- 完成后立即归档到 Git
- 添加 tag 标记重要版本
- 写好 commit message

### 5. 团队协作

- 统一目录命名规范
- 定期同步到共享仓库
- Code Review 实验记录
- 共享 `CLAUDE.md` 配置

## 故障排查

### 问题 1：Skill 找不到

```bash
# 检查安装位置
ls ~/.claude/skills/yin-ai-skills/

# 检查 skill 权限
ls -l ~/.claude/skills/yin-ai-skills/*/
```

### 问题 2：断点续传失败

```bash
# 检查目录是否存在
ls 调研/<主题>/
ls 实验/<实验名>/

# 检查关键文件
cat 调研/<主题>/状态.md
cat 实验/<实验名>/当前状态.md
```

### 问题 3：输出目录过大

```bash
# 检查大小
du -sh 调研/* 实验/*

# 压缩归档
tar -czf 归档.tar.gz 调研/ 实验/
```

### 问题 4：记录不完整

- 每 5 轮手动检查一次
- 要求 Claude 补充缺失部分
- 调整 skill 参数（如增加迭代轮次）

## 高级用法

### 自定义输出格式

编辑 skill 脚本中的模板：

```bash
vim ~/.claude/skills/yin-ai-skills/code-iteration/code-iteration
# 修改模板部分
```

### 批量处理

```bash
# 批量调研多个主题
for topic in "主题1" "主题2" "主题3"; do
    /recursive-research "$topic"
done

# 批量复现实验
for exp in 实验/2026-06-*/; do
    cd "$exp" && bash 复现指南.sh
done
```

### 集成到 CI/CD

```yaml
# .github/workflows/experiment.yml
name: Run Experiment
on: [push]
jobs:
  experiment:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - name: Run code-iteration
        run: |
          claude -p "/code-iteration $EXPERIMENT_NAME \"$GOAL\""
```

## 更多资源

- [设计理念](./design-philosophy.md)
- [常见问题](./faq.md)
- [示例集合](./examples/)
