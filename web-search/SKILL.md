---
name: web-search
description: 网页搜索工具。使用 DuckDuckGo（优先）或 Bing（备用）搜索互联网。触发场景：用户要求搜索信息、查找资料、了解最新动态、查询文档等需要联网获取信息的任务。
metadata:
  author: yinrong
  version: "1.0.0"
  source: ~/yin-ai-skills/web-search/
---

# web-search Skill

使用 DuckDuckGo（优先）或 Bing（备用）搜索互联网，无需 API Key。

## 使用方法

```
/web-search <搜索关键词>
```

## 执行参数

$ARGUMENTS

## 执行流程

1. 将 `$ARGUMENTS` 作为搜索词，运行搜索脚本：

```bash
node ~/yin-ai-skills/web-search/scripts/search.mjs $ARGUMENTS
```

2. 读取输出结果，直接向用户展示标题、URL 和摘要。

3. 若需要深入了解某条结果，使用 WebFetch 获取具体页面内容。

## 注意事项

- 默认返回 8 条结果，可在参数末尾加数字指定数量，如：`/web-search Claude API pricing 15`
- 支持中英文查询
- 如果搜索结果不够准确，尝试换不同关键词重新搜索
