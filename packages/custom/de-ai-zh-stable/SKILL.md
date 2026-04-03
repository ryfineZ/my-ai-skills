---
name: de-ai-zh-stable
description: |
  一次性对中文论文、课程作业、技术文档和通用中文进行去 AI 痕迹改写，并支持读取本地 `.txt`/`.md` 文件输出新文件。
  保守整合自 aigc-v1、humanizer-zh 和 baibaiAIGC，尽量保留已验证的方法本体。
---

# De-AI ZH Stable

## 适用场景

当用户有这些需求时使用本 skill：

- 去 AI 痕迹
- 论文去 AI 味
- 技术文档自然化
- 把 AI 文风改得更像真人写的
- 读取本地文本文件并输出去 AI 终稿

## 核心原则

- 一次调用直接输出终稿，不向用户暴露轮次和模式
- 尽量保留原文事实、术语、编号、结构和核心逻辑
- `stable` 版本尽量不改动参考项目里已经验证过的方法本体
- 对论文、课程作业、技术文档，默认不要凭空引入第一人称、情绪化立场或新事实

## 必读资源

开始处理前必须先读：

- `references/methods.md`

遇到以下情况时额外读取：

- 本地文件输入：`references/file-workflow.md`
- 长文本：`references/file-workflow.md`

## 执行流程

### 直接文本输入

1. 读取 `references/methods.md`
2. 一次性完成：
   - 结构保护
   - 自然化与解释性扩写
   - 去除 AI 套话和模板结构
   - 调整节奏并做最终收口
3. 只输出终稿正文，不输出分析过程、标签或阶段标题

### 本地文件输入

1. 读取 `references/methods.md`
2. 读取 `references/file-workflow.md`
3. 运行：

```bash
python scripts/run_deai.py inspect "/absolute/path/to/file.md" --variant stable
```

4. 按返回的 chunks 顺序逐块改写
5. 按原顺序拼回全文
6. 通过标准输入写出结果文件：

```bash
printf '%s' "$FINAL_TEXT" | python scripts/run_deai.py write "/absolute/path/to/file.md" --variant stable --chunk-count 12
```

7. 向用户报告输出文件路径与 metadata 路径

## 输出要求

- 只给终稿
- 不输出“修改后”“改写后”“润色后”等标签
- 不覆盖原文件
- 如果文件格式当前不支持，明确报错，不伪装成功
