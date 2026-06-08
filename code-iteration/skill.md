---
skill: code-iteration
version: 1.0.0
description: 代码持续迭代工具 - AI 自动化实验直到完成目标，完整记录所有细节（含失败路径）
author: yin
tags: [coding, experiment, iteration, documentation]
---

# 代码持续迭代 (code-iteration)

自动化代码实验迭代，完整记录所有尝试（包括失败），支持人类和 AI 复现。适合算法实验、功能开发、性能优化等场景。

## 核心目标

1. **文档驱动执行**：先写计划再执行、先写预期再验证（和 TDD 同一个思路）
2. **完整记录细节**：每一步操作、每次决策、每个失败都有据可查
3. **人类可理解可复现**：不懂的人看文档能理解原理并独立重建系统
4. **AI 可按记录复现**：新的 AI 会话读取记录后能继续/重做实验
5. **失败也是认知**：失败路径和成功路径同等重要
6. **诚实声明边界**："达标"必须包含适用范围和失效条件

## 使用方法

```bash
/code-iteration <实验名称> "<目标描述>" [--resume]
```

## 工作流程

### 1. 初始化（首次运行）

```bash
/code-iteration "优化器对比" "实现并对比 Adam/SGD/AdamW 在 MNIST 上的性能"
```

AI 会询问：
- **成功标准**：如何判定完成？（如：准确率 >95%，训练稳定）
- **约束条件**：时间限制、资源限制、必须使用的库
- **验证方式**：单元测试 / 手动测试 / 可视化检查
- **最大迭代轮次**：防止无限循环（建议 20-50 轮）

### 2. 自动迭代循环

每轮自动执行（文档驱动，先写后做）：

```
⛔GATE1          ⛔GATE2
  ↓                ↓
[写]计划 → [做]执行 → [写]结果对比 → [写]对抗性自查 → 判断
  ↑                                                    ↓
  └──────────── 未达标：分析问题，下一轮 ←──────────────┘
                   已达标：生成报告（含适用范围与限制）→
```

**GATE1**：计划文档（目标+预期+决策理由）未写完，不得开始执行。
**GATE2**：对抗性自查（3个破坏性问题+适用边界）未完成，不得进入下一轮。
**禁止"先跑N轮实验再补记录"**——每轮必须完成全部步骤才能进入下一轮。

### 3. 断点续传

```bash
/code-iteration --resume 优化器对比
```

AI 读取记录后从上次中断处继续。

## 输出结构

实验结果保存在 `实验/<实验ID>/` 目录：

```
实验/2026-06-02-优化器对比/
├── README.md              # 【索引文件】快速了解实验概况
├── 目标与标准.md           # 实验目标、成功标准、约束条件
├── 当前状态.md            # 最新进度、下一步行动、阻塞问题
├── 复现指南.md            # 一键复现步骤（人类和AI都能用）
│
├── 检查点/
│   ├── 01-baseline.md     # 里程碑 1：baseline 完成
│   ├── 02-adam优化器.md    # 里程碑 2：实现 Adam
│   └── 03-完整对比.md      # 里程碑 3：完成所有对比
│
├── 迭代日志/
│   ├── 第01轮-初始化环境.md
│   ├── 第02轮-实现baseline.md
│   ├── 第03轮-修复数据加载bug.md  # ← 失败也记录
│   ├── 第04轮-实现adam.md
│   └── ...
│
├── 决策树.md              # 关键分叉点的决策理由（Mermaid 图）
├── 失败案例库.md           # 所有失败尝试的原因和教训
├── 发现与洞察.md           # 意外发现、性能陷阱、最佳实践
│
├── 代码/
│   ├── baseline/          # 每个检查点一个快照
│   ├── adam/
│   ├── final/             # 最终版本
│   └── failed_attempts/   # 失败的代码（注释说明为啥不行）
│
├── 结果/
│   ├── 实验数据.csv
│   ├── loss曲线.png
│   └── 对比表.md
│
└── 最终报告.md            # 综合报告（实验结论、可复现性验证）
```

## 核心文件详解

### README.md（索引文件）

**作用**：5 分钟快速了解实验的来龙去脉

```markdown
# 优化器对比实验

**状态**：✅ 已完成 | ⏳ 进行中（第 X 轮）| ⛔ 已阻塞

**一句话总结**：对比 Adam/SGD/AdamW 在 MNIST 上的性能

---

## 快速导航

- 📋 [目标与标准](./目标与标准.md) - 我们要达成什么
- 🔄 [当前状态](./当前状态.md) - 现在做到哪了
- 🚀 [复现指南](./复现指南.md) - 如何一键运行
- 📊 [最终报告](./最终报告.md) - 实验结论

## 关键里程碑

- [x] [检查点 01](./检查点/01-baseline.md) - Baseline 跑通（SGD 准确率 94.2%）
- [x] [检查点 02](./检查点/02-adam优化器.md) - Adam 实现（准确率 96.1%）
- [x] [检查点 03](./检查点/03-完整对比.md) - 三种优化器完整对比

## 关键发现

1. **Adam 收敛最快**：5 个 epoch 即达 95%（SGD 需 15 个）
2. **失败教训**：初始学习率 0.1 导致 loss 爆炸（详见 [第 03 轮日志](./迭代日志/第03轮-修复学习率.md)）
3. **性能陷阱**：数据加载时未设置 `num_workers` 导致 GPU 利用率仅 30%

## 迭代概览

总轮次：12 轮
- 成功推进：9 轮
- 失败修复：3 轮
- 平均每轮耗时：15 分钟

## 代码位置

最终可运行代码：[`代码/final/`](./代码/final/)

一键运行：
\`\`\`bash
bash 复现指南.sh
\`\`\`

## 未来改进方向

- [ ] 尝试 Lion 优化器
- [ ] 测试不同学习率调度策略
- [ ] 在 CIFAR-10 上验证结论
```

### 迭代日志/第XX轮-<简述>.md

**作用**：记录每轮的完整细节，无跳跃

```markdown
# 第 03 轮 - 修复学习率导致的 loss 爆炸

**时间**：2026-06-02 14:35
**状态**：❌ 失败 → ✅ 已修复
**耗时**：25 分钟

---

## 本轮目标

实现 Adam 优化器并训练模型

---

## 操作步骤

### 1. 修改代码

**文件**：`代码/adam/train.py`

**改动**：
\`\`\`diff
- optimizer = torch.optim.SGD(model.parameters(), lr=0.01)
+ optimizer = torch.optim.Adam(model.parameters(), lr=0.1)  # ← 问题在这
\`\`\`

**理由**：从 SGD 切换到 Adam，沿用之前的 lr=0.01... 不对，想改成 0.1 试试

### 2. 运行训练

\`\`\`bash
python 代码/adam/train.py --epochs 10
\`\`\`

**输出**：
\`\`\`
Epoch 1: loss=inf, acc=10.2%
Epoch 2: loss=nan, acc=9.8%
...
\`\`\`

---

## 问题分析

### 现象
- 第 1 个 epoch 后 loss 变成 inf
- 第 2 个 epoch 后 loss 变成 nan
- 准确率接近随机猜测（10%）

### 原因定位

1. **检查梯度**：
   \`\`\`python
   for name, param in model.named_parameters():
       print(f"{name}: grad_norm={param.grad.norm()}")
   \`\`\`
   输出：`fc1.weight: grad_norm=1.2e8`（梯度爆炸）

2. **检查学习率**：
   - Adam 默认 lr=0.001
   - 我设置了 lr=0.1（是默认的 100 倍）
   - SGD 常用 0.01-0.1，但 Adam 需要小得多的学习率

3. **根本原因**：
   **将 SGD 的学习率直接用于 Adam，导致参数更新步长过大 → 梯度爆炸 → loss 发散**

---

## 解决方案

### 方案对比

| 方案 | 学习率 | 理由 | 预期效果 |
|------|--------|------|----------|
| A | 0.001 | Adam 默认值 | 稳定但可能慢 |
| B | 0.0001 | 更保守 | 过于保守 |
| C | 0.005 | 折中 | 可能还是太大 |

**决策**：选方案 A（0.001），因为这是 Adam 论文推荐的默认值

### 实施

\`\`\`diff
- optimizer = torch.optim.Adam(model.parameters(), lr=0.1)
+ optimizer = torch.optim.Adam(model.parameters(), lr=0.001)
\`\`\`

### 验证

重新运行：
\`\`\`bash
python 代码/adam/train.py --epochs 10
\`\`\`

**输出**：
\`\`\`
Epoch 1: loss=0.458, acc=85.3%
Epoch 2: loss=0.198, acc=93.1%
Epoch 5: loss=0.092, acc=96.1%
\`\`\`

✅ **问题解决**：loss 正常下降，准确率达到预期

---

## 本轮成果

- [x] 实现 Adam 优化器
- [x] 修复学习率问题
- [x] 达到 96.1% 准确率（超过目标的 95%）

**代码快照**：`代码/adam/` （可运行版本）

---

## 教训记录

**教训 #3**：不同优化器的学习率范围完全不同

- **SGD**：0.01 ~ 0.1
- **Adam**：0.0001 ~ 0.001
- **经验**：切换优化器时，查阅论文推荐的默认 lr，不要凭感觉设置

**记入**：[失败案例库.md](../失败案例库.md#教训3-优化器学习率不通用)

---

## 下一步

- [ ] 实现 AdamW 优化器
- [ ] 对比三种优化器的 loss 曲线
- [ ] 生成对比表和可视化图表
```

### 复现指南.md

**作用**：三层教学文档——不懂的人看完能理解原理并独立重建系统

**检验标准**：一个不了解本领域的实习生，只看这份文档（不问任何人），能在 1 天内理解原理并独立重建一个能工作的版本。

**三层结构**：
1. **概念与原理（为什么）**：系统解决什么问题、核心工作原理、各组件关系
2. **数据与流程（是什么）**：展示具体样本、解释输入如何拼接、输出如何解析
3. **操作步骤（怎么做）**：命令列表，但每条命令前解释它在系统中的角色

```markdown
# 复现指南

## 环境准备

### 方式 1：Docker（推荐）

\`\`\`bash
docker build -t optimizer-exp .
docker run -v $(pwd)/结果:/app/结果 optimizer-exp
\`\`\`

### 方式 2：本地环境

**系统要求**：
- Python 3.9+
- CUDA 11.8+（可选，CPU 也能跑但慢）

**安装依赖**：
\`\`\`bash
pip install -r requirements.txt
\`\`\`

内容：
\`\`\`
torch==2.0.1
torchvision==0.15.2
numpy==1.24.3
matplotlib==3.7.1
\`\`\`

---

## 快速复现（完整实验）

运行以下命令一键复现整个实验：

\`\`\`bash
bash run_full_experiment.sh
\`\`\`

**脚本内容**：
\`\`\`bash
#!/bin/bash
set -e  # 遇到错误立即停止

echo "=== 开始完整实验复现 ==="

# 1. 训练 SGD baseline
echo "[1/3] 训练 SGD baseline..."
python 代码/final/train.py --optimizer sgd --lr 0.01 --epochs 15 \
  --output 结果/sgd_result.json

# 2. 训练 Adam
echo "[2/3] 训练 Adam..."
python 代码/final/train.py --optimizer adam --lr 0.001 --epochs 10 \
  --output 结果/adam_result.json

# 3. 训练 AdamW
echo "[3/3] 训练 AdamW..."
python 代码/final/train.py --optimizer adamw --lr 0.001 --epochs 10 \
  --output 结果/adamw_result.json

# 4. 生成对比图表
echo "生成对比图表..."
python 代码/final/plot_comparison.py \
  --inputs 结果/sgd_result.json 结果/adam_result.json 结果/adamw_result.json \
  --output 结果/对比图表.png

echo "✅ 实验完成！结果保存在 结果/ 目录"
\`\`\`

**预期耗时**：CPU ~2 小时 | GPU ~15 分钟

---

## 分步复现（检查点级别）

如果想逐步验证每个里程碑：

### 检查点 1：Baseline

\`\`\`bash
cd 代码/baseline
python train.py
# 预期输出：准确率 94.2%
\`\`\`

### 检查点 2：Adam

\`\`\`bash
cd 代码/adam
python train.py
# 预期输出：准确率 96.1%
\`\`\`

### 检查点 3：完整对比

\`\`\`bash
cd 代码/final
bash run_full_experiment.sh
\`\`\`

---

## 复现失败路径（可选）

想体验当时踩过的坑？运行失败案例：

\`\`\`bash
# 失败案例 1：数据加载 bug
cd 代码/failed_attempts/02-data-loader-bug
python train.py
# 预期：卡住不动（GPU 利用率 0%）

# 失败案例 2：学习率爆炸
cd 代码/failed_attempts/03-lr-explosion
python train.py
# 预期：loss=nan
\`\`\`

详细分析见 [失败案例库.md](./失败案例库.md)

---

## AI 复现说明

如果你是新的 AI 会话，需要继续这个实验：

1. **读取索引**：`README.md` → 了解实验概况
2. **读取当前状态**：`当前状态.md` → 知道做到哪了
3. **读取最新检查点**：`检查点/<最新>.md` → 理解上一个稳定版本
4. **读取最近 3 轮日志**：`迭代日志/第XX-YY轮.md` → 了解最近的思路
5. **读取目标**：`目标与标准.md` → 确认成功标准
6. **继续迭代**：从"下一步"开始执行

---

## 常见问题

### Q1：没有 GPU 怎么办？

A：可以跑，就是慢。修改训练脚本：
\`\`\`python
device = 'cpu'  # 改成这个
\`\`\`

### Q2：数据集下载失败？

A：手动下载 MNIST 到 `./data/` 目录，或使用镜像源：
\`\`\`python
from torchvision import datasets
datasets.MNIST('./data', download=True, 
               mirror='https://mirrors.tuna.tsinghua.edu.cn/...')
\`\`\`

### Q3：结果和报告不一致？

A：随机种子可能不同。检查 `train.py` 中的 `torch.manual_seed(42)`
\`\`\`
