# Platform Briefs

这份 brief 用来给任何 UI 任务开局，避免一上来就乱画。

## 通用骨架

先填这 6 项：

```text
平台：
界面类型：
主任务：
当前最该被看见的信息：
视觉方向：
已知约束：
```

## Web

```text
平台：Web
界面类型：dashboard / settings / page / panel
主任务：用户进入页面后第一步要完成什么
当前最该被看见的信息：主任务、状态还是结果
视觉方向：tooling / editorial / data panel / brand display
已知约束：现有组件库、设计系统、性能要求
```

重点：

- 不要平均切卡片
- 不要先摆大标题再找任务
- 先定导航和主内容谁更重

## Mobile / H5

```text
平台：Mobile App / H5
界面类型：home / detail / form / step flow / sheet
主任务：单手操作下最先完成什么
当前最该被看见的信息：当前步骤、当前状态还是主按钮
视觉方向：tooling / calm utility / focused flow
已知约束：首屏高度、触控热区、宿主容器
```

重点：

- 先看首屏而不是整页
- 能删的标题先删
- 主按钮和反馈优先，不要留一堆并列按钮

## Mini Program

```text
平台：小程序
界面类型：list / settings / detail / form
主任务：进入首屏后最先要办什么
当前最该被看见的信息：状态、列表还是下一步动作
视觉方向：native utility / light tool
已知约束：宿主交互习惯、授权、轻量化
```

重点：

- 更轻、更直给
- 不优先做氛围
- 先保原生感和完成效率

## Extension

```text
平台：Chrome 扩展
界面类型：popup / options / side panel
主任务：打开后 3 秒内要完成什么
当前最该被看见的信息：当前状态、主操作还是结果摘要
视觉方向：compact tooling / focused utility
已知约束：窗口高度、滚动限制、浏览器上下文
```

重点：

- popup 最容易把控件做太大
- 同层操作必须收敛
- 主任务、状态、主按钮先于其他说明

## Desktop

```text
平台：桌面 App
界面类型：tool window / settings / multi-pane / panel
主任务：这扇窗口主要帮用户处理什么
当前最该被看见的信息：内容区、列表区还是当前选择
视觉方向：tooling / tahoe glass / editorial utility
已知约束：窗口层级、长期使用、键盘操作
```

重点：

- 先稳，再谈质感
- Tahoe 只放在承载层和分层，不要整屏糊玻璃
- 窗壳不能比内容更抢
