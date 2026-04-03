# File Workflow

本文件规定 `de-ai-zh-stable` 与 `de-ai-zh-optimized` 共用的文件处理流程。

## 直接文本输入

如果用户直接贴文本：

- 不需要脚本
- 直接按 `methods.md` 完成一次性改写
- 只返回终稿正文

## 本地文件输入

### 第一版支持

- `.txt`
- `.md`

### 条件支持

- `.docx`
  - 仅在本地环境已安装 `python-docx` 且读取稳定时支持
  - 若依赖缺失或读取失败，明确报错

### 暂不支持

- PDF
- 富文本编辑器专有格式
- 批量目录

## 检查与分块

先运行：

```bash
python scripts/run_deai.py inspect "/absolute/path/to/file.md" --variant stable
```

或：

```bash
python scripts/run_deai.py inspect "/absolute/path/to/file.md" --variant optimized
```

返回 JSON 包含：

- `source_path`
- `output_path`
- `metadata_path`
- `chunk_limit`
- `chunk_count`
- `chunks`

### 分块原则

- 优先按原段落切
- 段落超长时再按句子切
- 不在这些内容中间强行截断：
  - 编号
  - 路径
  - API 路径
  - 代码标识
  - 专业术语

## 文件输出

完成全文拼接后，用标准输入写回：

```bash
printf '%s' "$FINAL_TEXT" | python scripts/run_deai.py write "/absolute/path/to/file.md" --variant stable --chunk-count 12
```

或：

```bash
printf '%s' "$FINAL_TEXT" | python scripts/run_deai.py write "/absolute/path/to/file.md" --variant optimized --chunk-count 12
```

### 输出规则

- 永不覆盖源文件
- 默认输出为同目录新文件
- 命名规则：
  - `.txt` -> `name.deai-stable.txt` / `name.deai-optimized.txt`
  - `.md` -> `name.deai-stable.md` / `name.deai-optimized.md`
  - `.docx` -> `name.deai-stable.txt` / `name.deai-optimized.txt`

### Metadata

脚本会额外写出一个 JSON metadata 文件，便于 A/B 对比：

- 输入路径
- 输出路径
- 时间戳
- chunk 数量
- variant

## 错误处理

- 文件不存在：直接报错
- 编码读取失败：直接报错
- 不支持的扩展名：直接报错
- `.docx` 依赖缺失：直接报错
- 绝不伪装成功
