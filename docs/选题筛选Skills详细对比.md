# 选题筛选 Skills 详细对比分析

> 生成时间：2026-02-02
> 研究范围：选题发现、筛选、审核、生成的完整工作流

---

## 📊 核心 Skills 对比总览

| Skill | 功能定位 | 数据来源 | 自动化程度 | 中文适配 | 推荐度 |
|-------|---------|---------|-----------|---------|--------|
| **topic-collector** | AI热点采集 | Twitter/X, Product Hunt, Reddit, HN | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ |
| **topic-generator** | 选题生成与筛选 | 热点列表 | ⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ |
| **topic-reviewer** | 选题审核评分 | 选题方案 | ⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ |
| **content-topic-generator** | 基于内容生成衍生选题 | 文章/推文 | ⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ |
| **content-trend-researcher** | 多平台趋势分析 | 10+ 平台 | ⭐⭐⭐ | ⭐⭐⭐ | ⭐⭐⭐⭐ |
| **content-strategy** | 内容策略规划 | 客户调研 | ⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐⭐ |

**说明：**
- ⭐⭐⭐⭐⭐ = 极强（完全自动化/完美中文）
- ⭐⭐⭐⭐ = 很强（大部分自动化/良好中文）
- ⭐⭐⭐ = 中等（需要手动配置/基础中文）

---

## 🎯 详细功能对比

### 1️⃣ topic-collector (zephyrwang6/myskill) ⭐⭐⭐⭐⭐

**📌 核心定位：** AI热点自动采集器

**数据来源：**
| 平台类型 | 具体来源 | 采集内容 |
|---------|---------|---------|
| **社交媒体** | Twitter/X (@AnthropicAI, @OpenAI, @swyx 等) | KOL 动态、实践技巧 |
| **产品平台** | Product Hunt, Hacker News | 新产品发布、讨论热度 |
| **技术社区** | Reddit (r/ClaudeAI, r/ChatGPT), HN | 社区讨论、技术问题 |
| **官方动态** | Anthropic, OpenAI, Google, xAI 官网 | 模型更新、功能发布 |
| **学术研究** | arXiv, DeepMind, Meta AI 博客 | 论文、研究突破 |

**聚焦领域（优先级）：**
```markdown
1. Vibe Coding - Cursor、Claude Code
2. Claude 生态 - Claude Skill、MCP Server
3. AI Agent - 自动化工作流、n8n
4. AI 知识管理 - PKM、Obsidian+AI
5. 模型更新 - GPT、Claude、Gemini
6. AI 新产品 - Product Hunt 新品
7. 海外热点 - 行业大事件
```

**触发关键词：**
- "开始今日选题"
- "采集热点"
- "看看今天有什么新闻"
- "今日AI热点"

**输出格式：**
```markdown
## 今日AI热点 - MMDD

### 🧑‍💻 AI博主实践分享
1. **[内容摘要]**
   - 作者：@用户名
   - 原文：[URL]
   - 要点：一句话总结
   - 热度：❤️ likes | 🔁 retweets

### 🚀 创业公司/新产品
1. **[产品名]** - 描述
   - 链接：[Product Hunt页面]
   - 热度：⬆️ N upvotes

### 🔬 AI研究/学术动态
### 🏢 模型厂商动态
### 💬 社区热议
```

**特色功能：**
- ✅ 自动多源并行采集
- ✅ 必须提取原文链接
- ✅ 热度指标（likes, upvotes, comments）
- ✅ 按时效性排序（优先24小时内）

**中文平台适配：⭐⭐⭐⭐**
- ✅ 可采集中文 Twitter/X
- ✅ 可加入知乎、微博等数据源
- ⚠️ 需要手动添加中文社区关键词

**最佳使用场景：**
- 每日选题例会
- 追踪 AI 行业动态
- 发现新产品和工具
- 寻找热点话题

**安装命令：**
```bash
npx skills add zephyrwang6/myskill@topic-collector -g -y
```

---

### 2️⃣ topic-generator (zephyrwang6/myskill) ⭐⭐⭐⭐⭐

**📌 核心定位：** 选题生成与价值评估

**核心能力：**
1. **智能筛选** - 从热点列表中挑选 TOP 10
2. **价值打分** - 多维度评估选题价值
3. **完整方案** - 生成标题、角度、写作方式

**筛选标准：**

**必须满足：**
- AI 相关（Vibe Coding / Claude / AI工具 / AI模型）
- 有明确用户价值（能学到/能用到/能思考）
- 国内用户能理解和关注

**加分项评分表：**
| 维度 | 高分 | 低分 |
|------|------|------|
| 热度 | 讨论量大、增长快 | 冷门、无人问津 |
| 时效 | 24小时内 | 超过3天 |
| 独特性 | 有新角度可挖 | 已被写烂 |
| 可操作 | 能给出具体方法 | 纯概念讨论 |

**写作方式分类：**
1. **干货教程** - 有具体步骤可复现
2. **产品体验** - 新产品/新功能测评
3. **观点分享** - 趋势分析/行业洞察
4. **新技术突破** - 重大更新/技术解读

**输出格式：**
```markdown
### 选题 N：[标题]

**事件描述**
一句话说清楚发生了什么

**核心角度**
为什么值得写？独特切入点是什么？

**推荐标题**（3个备选）
1. 标题A
2. 标题B
3. 标题C

**写作方式**：干货教程 / 产品体验 / 观点分享 / 新技术突破

**预估热度**：⭐⭐⭐⭐⭐（1-5星）

**不写的风险**：错过什么？（可选）
```

**选题公式参考：**
```markdown
工具测评型：
- 用了X天[工具]，我发现[意外收获]
- [工具]的隐藏功能，90%的人不知道

方法论型：
- 我用[方法]搞定了[问题]的完整流程
- [数字]个让[场景]效率翻倍的技巧

热点结合型：
- [热点]爆火，但大家忽略了这一点
- 从[热点]看AI编程的未来

反共识型：
- 别再[常见做法]了
- 为什么我不推荐[热门事物]

经验复盘型：
- 做了[数字]个[事情]后，我总结的[数字]条教训
- 如果重来一次，我会[改变]
```

**质量检查清单：**
- [ ] 标题有冲突感？（数字、对比、反差、疑问）
- [ ] 读者有痛点？
- [ ] 我有独特视角？
- [ ] 有具体案例？
- [ ] 能引发讨论？

**评分标准：**
- 5条全中 = 必写
- 3-4条 = 可写
- <3条 = 再想想

**触发关键词：**
- "生成选题"
- "筛选热点"
- "哪些值得写"

**中文平台适配：⭐⭐⭐⭐⭐**
- ✅ 完全中文设计
- ✅ 适配国内用户关注点
- ✅ 选题公式通用

**最佳使用场景：**
- 从采集的热点中筛选
- 每周选题会议
- 内容规划

**安装命令：**
```bash
npx skills add zephyrwang6/myskill@topic-generator -g -y
```

---

### 3️⃣ topic-reviewer (zephyrwang6/myskill) ⭐⭐⭐⭐⭐

**📌 核心定位：** 选题审核与质量把关

**审核流程：**
1. 接收选题（来自 topic-generator 或用户输入）
2. 逐项检查（按审核清单打分）
3. 输出结论（通过/不通过 + 理由）

**必过项（一票否决）：**
| 检查项 | 不通过标准 |
|--------|-----------|
| 热度 | 讨论量<100或无增长趋势 |
| 相关性 | 与AI/编程/效率无关 |
| 时效性 | 超过72小时的旧闻 |
| 可写性 | 没有可操作的内容输出 |

**评分项（满分100分）：**
| 维度 | 权重 | 评分标准 |
|------|------|---------|
| 独特角度 | 30% | 有无别人没写过的切入点 |
| 用户价值 | 25% | 读者能获得什么 |
| 国内适配 | 20% | 国内用户是否关注 |
| 标题吸引力 | 15% | 是否想点进去看 |
| 写作难度 | 10% | 能否快速高质量完成 |

**通过线：70分**

**不通过的常见原因：**
1. **热度不够高** → 等热度起来再写，或换热点
2. **没有独特角度** → 找差异化切入点，或放弃
3. **不符合国内用户关注** → 找国内用户共鸣点，或本土化
4. **纯蹭热点无干货** → 加入实操/测评/深度分析
5. **写作成本过高** → 简化范围或分拆系列

**输出格式：**
```markdown
## 选题审核结果

**选题**：[标题]

**结论**：✅ 通过 / ❌ 不通过

**评分**：XX/100

| 维度 | 得分 | 说明 |
|------|------|------|
| 独特角度 | /30 | |
| 用户价值 | /25 | |
| 国内适配 | /20 | |
| 标题吸引力 | /15 | |
| 写作难度 | /10 | |

**审核意见**
- 优点：...
- 问题：...
- 建议：...

**修改方向**（如不通过）
1. ...
2. ...
```

**快速判断法（无时间细评时）：**
1. 今天不写会后悔吗？
2. 写完能获得什么反馈？
3. 一句话能说清为什么值得写吗？

**3个都是"是" = 直接写**

**触发关键词：**
- "审核选题"
- "这个选题行不行"
- "帮我看看这个能不能写"

**中文平台适配：⭐⭐⭐⭐⭐**
- ✅ 完全中文设计
- ✅ 国内用户关注点权重高
- ✅ 写作难度考虑中文内容特点

**最佳使用场景：**
- 选题最终决策
- 内容质量把关
- 避免踩雷

**安装命令：**
```bash
npx skills add zephyrwang6/myskill@topic-reviewer -g -y
```

---

### 4️⃣ content-topic-generator (zephyrwang6/myskill) ⭐⭐⭐⭐

**📌 核心定位：** 基于现有内容生成衍生选题

**核心能力：**
1. **推文选题生成** - 生成140字以内的完整推文内容
2. **公众号选题生成** - 生成详细的文章标题和大纲
3. **多角度策略** - 延伸、反驳、扩充、热点结合
4. **读者视角** - 从吸引力和传播力角度设计

**四大创作策略：**

#### 🔹 延伸策略
- **适合：** 信息密度高但未充分展开的内容
- **示例：** 原文讲AI工具 → 延伸为AI工具使用的心理学原理

#### 🔹 反驳策略
- **适合：** 有争议性、存在片面性的观点
- **示例：** 原文说AI降低门槛 → 反驳为AI实际上提高了竞争门槛

#### 🔹 扩充策略
- **适合：** 提到了点但未详细说明的内容
- **示例：** 原文提到Gemini提示词 → 扩充为10个提示词完整教程

#### 🔹 热点结合策略
- **适合：** 可与当前热点关联的主题
- **示例：** 原文讲副业 → 结合元旦做新年规划话题

**推文选题要求：**
- 严格控制在140字以内（中文字符）
- 开头3秒内抓住注意力
- 包含明确的观点或价值
- 设计互动点（让人想点赞/评论/转发）

**公众号选题要求：**
- 标题吸引力强（数字型/反差型/疑问型）
- 结构清晰，5-7个章节
- 总字数1500-3000字
- 必须包含：开篇、主体、结尾+行动号召

**输出格式：**
```markdown
# {原文标题/主题} - 选题分析

## 原文核心信息
**核心观点：** {一句话总结}
**关键信息：** {数据/案例/金句}
**内容类型：** {观点/教程/案例/分析}

---

## 推文选题（N条）

### 推文 #1 - {策略名称}
**策略：** 延伸/反驳/扩充/热点结合
**核心角度：** {这条推文的独特视角}
**目标读者：** {面向谁}

**推文内容（X/140字）：**
{完整的推文正文}

**预期效果：**
- 互动点：{为什么读者会互动}
- 情绪共鸣：{触发什么情绪}
- 行动引导：{希望读者做什么}

---

## 公众号选题（N篇）

### 选题 #1 - {策略名称}
**策略：** 延伸/反驳/扩充/热点结合
**标题：** 《{标题}》
**目标读者：** {面向谁}
**核心价值：** {读完能获得什么}
**预估字数：** {字数}

#### 文章大纲
**一、{章节标题}（{字数}字）**
- 核心论点：
- 要点：
- 支撑材料：
```

**使用场景示例：**

**场景1：基于推文生成选题**
```
输入：分析这条推文并生成选题
输出：3条推文选题 + 2个公众号选题
```

**场景2：基于文章生成选题**
```
输入：一篇关于"未来五年小个体赚钱十大红利"的文章
输出：5条推文（每条聚焦一个红利）+ 2个深度选题
```

**场景3：定制化选题**
```
输入：只生成"反驳"策略的选题，要能引发讨论
输出：针对性的反驳观点 + 争议点设计
```

**质量控制清单：**
- [ ] 推文字数≤140字
- [ ] 开头是否吸引人
- [ ] 是否有明确观点/价值
- [ ] 是否设计了互动点
- [ ] 公众号标题是否吸引人
- [ ] 大纲结构是否清晰

**触发关键词：**
- "基于这篇文章生成选题"
- "把这条推文改编成公众号"
- "分析并生成衍生内容"

**中文平台适配：⭐⭐⭐⭐⭐**
- ✅ 完全中文设计
- ✅ 适配微博（140字）
- ✅ 适配公众号、知乎长文
- ✅ 四大策略通用

**最佳使用场景：**
- 内容复用和再创作
- 一文多发（跨平台改编）
- 系列内容规划
- 热点快速响应

**安装命令：**
```bash
npx skills add zephyrwang6/myskill@content-topic-generator -g -y
```

---

### 5️⃣ content-trend-researcher (nicepkg/ai-workflow) ⭐⭐⭐⭐

**📌 核心定位：** 多平台趋势分析与用户意图研究

**数据来源（10+平台）：**
| 平台 | 分析内容 |
|------|---------|
| Google Trends | 搜索量趋势、上升查询、区域兴趣 |
| Google Analytics | 流量模式、用户行为、转化信号 |
| Substack | 邮件列表趋势、订阅增长 |
| Medium | 文章表现、标签、Claps、阅读时间 |
| Reddit | 子版块活动、Upvotes、评论参与 |
| LinkedIn | 专业内容趋势、参与指标 |
| X (Twitter) | 病毒话题、话题标签表现、Thread参与 |
| Blogs | 顶级排名博客、反向链接 |
| Podcasts | 剧集流行度、下载趋势、评分 |
| YouTube | 视频表现、观看趋势、观看时长 |

**用户意图分析：**
- **Informational** - "How to", "What is", "Guide to"
- **Commercial** - "Best", "Review", "Comparison", "vs"
- **Transactional** - "Buy", "Pricing", "Discount"
- **Navigational** - 品牌搜索、特定资源查找
- **Problem-solving** - "Fix", "Troubleshoot", "Solution"

**内容策略智能：**
- 每个平台的最佳内容格式
- 基于参与数据的最佳发布时间
- 经过验证的标题公式
- 内容长度建议
- 主题聚类和支柱内容识别

**大纲生成能力：**
- SEO优化标题（匹配用户意图）
- H2/H3结构（基于搜索模式）
- 要覆盖的关键点（来自顶级内容）
- 建议字数和内容深度
- 内链机会
- CTA建议
- 多媒体建议

**输出示例（JSON格式）：**
```json
{
  "topic_overview": {
    "search_volume": "月搜索量估计",
    "trend_direction": "rising|stable|declining",
    "competition_level": "low|medium|high",
    "opportunity_score": 1-100
  },
  "platform_insights": [
    {
      "platform": "平台名称",
      "trending_content": [],
      "engagement_metrics": {},
      "best_practices": [],
      "content_format": "推荐格式"
    }
  ],
  "user_intent_analysis": {
    "primary_intent": "意图类型",
    "top_questions": [],
    "search_patterns": []
  },
  "content_gaps": [],
  "article_outlines": [],
  "recommendations": {}
}
```

**使用示例：**
```
@content-trend-researcher

Topic: "AI automation for small businesses"
Platforms: Google Trends, Reddit, LinkedIn, YouTube
Intent: Informational
```

**特色功能：**
- ✅ 多平台综合分析
- ✅ 用户意图分类
- ✅ 内容差距识别
- ✅ 自动生成大纲
- ✅ 竞品分析

**局限性：**
- ⚠️ 需要 API 访问（某些平台）
- ⚠️ 搜索量是估算值
- ⚠️ 趋势数据代表过去，不保证未来

**中文平台适配：⭐⭐⭐**
- ⚠️ 主要针对英文平台设计
- ✅ 分析框架可迁移到中文平台
- ⚠️ 需要手动添加中文平台数据源

**最佳使用场景：**
- 内容策略制定前
- 验证内容想法
- 发现竞品遗漏的内容
- 多平台内容规划

**安装命令：**
```bash
npx skills add nicepkg/ai-workflow@content-trend-researcher -g -y
```

---

### 6️⃣ content-strategy (coreyhaines31/marketingskills) ⭐⭐⭐⭐

**📌 核心定位：** 基于客户调研的内容策略规划

**核心方法论：Searchable vs Shareable**

```markdown
Searchable Content（可搜索内容）：
- 捕获现有需求
- 针对特定关键词或问题
- 匹配搜索意图
- 优化 AI/LLM 发现

Shareable Content（可分享内容）：
- 创造需求
- 原创洞察或数据
- 挑战常规观点
- 引发情感和分享
```

**内容类型：**

**可搜索类型：**
- **Use-Case Content** - [persona] + [use-case]
- **Hub and Spoke** - 综合概述 + 相关子主题
- **Template Libraries** - 高意图关键词 + 产品采用

**可分享类型：**
- **Thought Leadership** - 挑战常规观点
- **Data-Driven Content** - 原创研究
- **Expert Roundups** - 15-30位专家回答
- **Case Studies** - 挑战 → 解决方案 → 结果
- **Meta Content** - 幕后透明度

**内容创意来源：**
1. **Keyword Data** - 分析 Ahrefs/SEMrush/GSC
2. **Call Transcripts** - 提取客户真实语言
3. **Survey Responses** - 挖掘主题和语言
4. **Forum Research** - Reddit, Quora, HN
5. **Competitor Analysis** - 发现内容差距
6. **Sales/Support Input** - 常见问题和异议

**优先级评分系统（满分100）：**
| 因素 | 权重 | 说明 |
|------|------|------|
| Customer Impact | 40% | 客户提及频率 |
| Content-Market Fit | 30% | 与产品契合度 |
| Search Potential | 20% | 搜索量和竞争度 |
| Resource Requirements | 10% | 创作难度 |

**输出格式：**
```markdown
1. 内容支柱（3-5个）
2. 优先主题（每个包含）：
   - Topic/title
   - Searchable, shareable, or both
   - Content type
   - Target keyword and buyer stage
   - Why this topic (客户研究支持)
3. 主题聚类地图
```

**中文平台适配：⭐⭐⭐⭐**
- ✅ 框架通用
- ✅ 客户调研方法适用
- ✅ 关键词策略可用于百度 SEO
- ⚠️ 需要中文关键词工具

**最佳使用场景：**
- 制定长期内容战略
- 基于客户真实需求规划
- SEO 内容规划
- 内容支柱建设

**安装命令：**
```bash
npx skills add coreyhaines31/marketingskills@content-strategy -g -y
```

---

## 🔄 完整选题工作流对比

### 工作流 A：热点驱动型（追热点）

```
topic-collector（采集热点）
      ↓
topic-generator（筛选TOP10 + 生成方案）
      ↓
topic-reviewer（审核打分）
      ↓
【确定最终选题】
      ↓
content-topic-generator（改编多平台）
```

**适合：** 小红书、微博、抖音等追热点平台
**优势：** 快速响应、把握时效性
**Skills 组合：**
```bash
npx skills add zephyrwang6/myskill@topic-collector -g -y
npx skills add zephyrwang6/myskill@topic-generator -g -y
npx skills add zephyrwang6/myskill@topic-reviewer -g -y
npx skills add zephyrwang6/myskill@content-topic-generator -g -y
```

---

### 工作流 B：趋势研究型（数据驱动）

```
content-trend-researcher（多平台趋势分析）
      ↓
content-strategy（制定内容策略）
      ↓
topic-reviewer（质量把关）
      ↓
【确定优先级和大纲】
```

**适合：** SEO 博客、长期内容规划
**优势：** 数据支持、策略性强
**Skills 组合：**
```bash
npx skills add nicepkg/ai-workflow@content-trend-researcher -g -y
npx skills add coreyhaines31/marketingskills@content-strategy -g -y
npx skills add zephyrwang6/myskill@topic-reviewer -g -y
```

---

### 工作流 C：内容复用型（高效产出）

```
已有文章/推文
      ↓
content-topic-generator（生成衍生选题）
      ↓
topic-reviewer（筛选最佳）
      ↓
【一文多发】
```

**适合：** 跨平台内容分发、系列内容
**优势：** 内容复用、高效产出
**Skills 组合：**
```bash
npx skills add zephyrwang6/myskill@content-topic-generator -g -y
npx skills add zephyrwang6/myskill@topic-reviewer -g -y
```

---

## 💡 推荐安装方案

### 🏆 方案 A：完整选题系统（最推荐）

```bash
# 热点采集 + 筛选 + 审核 + 衍生
npx skills add zephyrwang6/myskill@topic-collector -g -y
npx skills add zephyrwang6/myskill@topic-generator -g -y
npx skills add zephyrwang6/myskill@topic-reviewer -g -y
npx skills add zephyrwang6/myskill@content-topic-generator -g -y
```

**适合：** 自媒体创作者、内容营销团队
**优势：**
- ✅ 完整闭环工作流
- ✅ 全中文设计
- ✅ 高度自动化
- ✅ 适配国内平台

**工作流：**
每日例会 → 采集热点 → 筛选TOP10 → 审核通过 → 改编多平台

---

### 📊 方案 B：数据驱动型

```bash
# 趋势分析 + 内容策略 + 质量把关
npx skills add nicepkg/ai-workflow@content-trend-researcher -g -y
npx skills add coreyhaines31/marketingskills@content-strategy -g -y
npx skills add zephyrwang6/myskill@topic-reviewer -g -y
```

**适合：** SEO 专家、内容策略师
**优势：**
- ✅ 多平台数据支持
- ✅ 用户意图分析
- ✅ 客户调研驱动

**工作流：**
趋势研究 → 策略规划 → 关键词优先级 → 质量审核

---

### ⚡ 方案 C：轻量快速型

```bash
# 热点采集 + 筛选生成
npx skills add zephyrwang6/myskill@topic-collector -g -y
npx skills add zephyrwang6/myskill@topic-generator -g -y
```

**适合：** 个人博主、小团队
**优势：**
- ✅ 最少安装
- ✅ 快速上手
- ✅ 覆盖核心需求

**工作流：**
采集热点 → 筛选TOP10 → 直接写作

---

## 🌍 中文自媒体平台适配

### 📱 小红书

**推荐 Skills：**
1. `topic-collector` - 采集热点
2. `topic-generator` - 生成选题（含小红书风格标题）
3. `content-topic-generator` - 140字推文改编

**工作流：**
```
采集热点 → 筛选爆款潜力选题 → 生成小红书风格标题 → 写140字精华版
```

**特殊优化：**
- 使用"反差型"、"数字型"标题公式
- 强调"独特角度"评分
- 优先选择"能引发讨论"的选题

---

### 📰 公众号

**推荐 Skills：**
1. `content-strategy` - 长期内容规划
2. `topic-generator` - 深度选题生成
3. `topic-reviewer` - 质量把关

**工作流：**
```
内容支柱规划 → 主题聚类 → 筛选选题 → 审核通过 → 生成大纲
```

**特殊优化：**
- 重视"用户价值"（25%权重）
- 关注"写作难度"（避免烂尾）
- 使用"扩充策略"（深度展开）

---

### 🤔 知乎

**推荐 Skills：**
1. `content-trend-researcher` - 发现高搜索量问题
2. `content-strategy` - 关键词优化
3. `topic-reviewer` - 独特角度评估

**工作流：**
```
搜索趋势分析 → 发现高价值问题 → 评估回答角度 → 审核独特性
```

**特殊优化：**
- 使用"问题解决"意图分析
- 强调"独特角度"（30%权重）
- 关注"数据支持"

---

### 🐦 微博

**推荐 Skills：**
1. `topic-collector` - 实时热点
2. `content-topic-generator` - 140字推文生成

**工作流：**
```
采集实时热点 → 快速生成140字观点 → 发布
```

**特殊优化：**
- 优先"时效性"（24小时内）
- 使用"热点结合策略"
- 强调"互动点"设计

---

## ⚠️ 重要发现和建议

### ✅ 可以做到：

1. **全自动热点采集** - topic-collector 支持多源并行
2. **智能筛选评分** - topic-generator 多维度打分
3. **质量把关** - topic-reviewer 70分通过线
4. **内容复用** - content-topic-generator 一文多发
5. **中文适配** - zephyrwang6/myskill 全套完美支持中文

### ❌ 局限性：

1. **实时数据需要 API** - 部分平台需要 API 访问
2. **中文平台数据** - 需要手动添加知乎、微博、小红书数据源
3. **预测准确性** - 热度预估基于历史数据，不保证未来
4. **人工决策必要** - AI 辅助筛选，最终决策仍需人工

### 💡 最佳实践：

1. **每日采集** - 使用 topic-collector 建立每日例会
2. **批量筛选** - 用 topic-generator 从50个热点中选TOP10
3. **严格审核** - 用 topic-reviewer 避免低质量选题
4. **内容矩阵** - 用 content-topic-generator 实现一文多平台
5. **定期复盘** - 跟踪选题表现，优化筛选标准

---

## 🚀 立即开始

### 推荐起始方案：

**如果你是自媒体创作者（追热点）：**
```bash
# 安装完整系统（方案A）
npx skills add zephyrwang6/myskill@topic-collector -g -y
npx skills add zephyrwang6/myskill@topic-generator -g -y
npx skills add zephyrwang6/myskill@topic-reviewer -g -y
npx skills add zephyrwang6/myskill@content-topic-generator -g -y
```

**如果你是内容策略师（数据驱动）：**
```bash
# 安装趋势分析套装（方案B）
npx skills add nicepkg/ai-workflow@content-trend-researcher -g -y
npx skills add coreyhaines31/marketingskills@content-strategy -g -y
npx skills add zephyrwang6/myskill@topic-reviewer -g -y
```

**如果你刚开始（轻量尝试）：**
```bash
# 安装核心2件套（方案C）
npx skills add zephyrwang6/myskill@topic-collector -g -y
npx skills add zephyrwang6/myskill@topic-generator -g -y
```

---

## 📋 测试建议

安装后立即测试：

**测试 1：采集今日热点**
```
"开始今日选题，采集AI相关热点"
```

**测试 2：生成选题方案**
```
"从这些热点中筛选TOP10，生成完整选题方案"
```

**测试 3：审核选题**
```
"审核这个选题：[你的选题标题]"
```

**测试 4：内容复用**
```
"基于这篇文章生成3条推文和2个公众号选题"
```

---

## 🎯 下一步

1. **选择方案** - 根据你的需求选择 A/B/C
2. **批量安装** - 我可以帮你一次性安装
3. **立即测试** - 用真实场景测试工作流
4. **优化调整** - 根据效果调整筛选标准

告诉我你想安装哪个方案，我立刻帮你执行！🚀
