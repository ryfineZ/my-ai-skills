---
name: de-ai-zh-optimized
description: |
  一次性对中文论文、课程作业、技术文档和通用中文进行去 AI 痕迹改写，并支持读取本地 `.txt`/`.md` 文件输出新文件。
  重组优化自 aigc-v1、humanizer-zh 和 baibaiAIGC，保留核心经验，但允许方法去重、顺序重排和更强的最终收口。
---

# De-AI ZH Optimized

## 适用场景

当用户有这些需求时使用本 skill：

- 去 AI 痕迹
- 论文去 AI 味
- 技术文档自然化
- 把 AI 文风改得更像真人写的
- 读取本地文本文件并输出新文件

## 核心原则

- 一次调用直接输出终稿
- 对用户隐藏轮次和内部阶段
- 保留事实、术语、编号、结构和核心逻辑
- 本版本允许对参考方法做去重、顺序优化和 prompt 压缩
- 优先得到“自然、保真、不刻意”的终稿

## 必读资源

开始处理前必须先读：

- `references/methods.md`

遇到以下情况时额外读取：

- 本地文件输入：`references/file-workflow.md`
- 长文本：`references/file-workflow.md`

## 执行流程

### 直接文本输入

1. 读取 `references/methods.md`
2. 按优化后的统一流程一次性完成：
   - 结构保护
   - 自然化与解释性扩写
   - 去 AI 套话和模板结构
   - 节奏调整与强收口
3. 只输出终稿正文，不输出阶段说明

### 本地文件输入

1. 读取 `references/methods.md`
2. 读取 `references/file-workflow.md`
3. 运行：

```bash
python scripts/run_deai.py inspect "/absolute/path/to/file.md" --variant optimized
```

4. 按返回的 chunks 顺序逐块改写
5. 按原顺序拼回全文
6. 通过标准输入写出结果文件：

```bash
printf '%s' "$FINAL_TEXT" | python scripts/run_deai.py write "/absolute/path/to/file.md" --variant optimized --chunk-count 12
```

7. 向用户报告输出文件路径与 metadata 路径

## 输出要求

- 只给终稿
- 不输出“修改后”“改写后”“润色后”等标签
- 不覆盖原文件
- 不支持的格式必须直接报错
