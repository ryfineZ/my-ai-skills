# Template Sources

## Real Template Sources

- `Page UI`
  - 类型：页面模板库
  - 用法：拿页面层级、分区节奏、信息编排
  - 不要：整套颜色和文案直接照搬

## Component / Block Sources

- `shadcn/ui`
  - 类型：组件与页面骨架
  - 用法：拿 settings、table、form、dashboard 的结构
  - 不要：把默认配色和默认间距原样带进来

- `Magic UI`
  - 类型：展示区块与轻动效片段
  - 用法：拿局部展示方式和少量动效思路
  - 不要：把它当整站模板

- `Vant`
  - 类型：H5 / Mobile 组件模式
  - 用法：拿移动表单、列表、操作区模式

- `Vant Weapp`
  - 类型：小程序组件模式
  - 用法：拿列表、设置、详情、表单的宿主化结构

- `TDesign Miniprogram`
  - 类型：小程序组件模式
  - 用法：拿更工具化、更企业感的页面骨架

- `WeUI`
  - 类型：微信生态保守型模式
  - 用法：需要低风险、低偏差时使用

## Shell Only

- `Plasmo`
- `WXT`
- `Electron React Boilerplate`
- `Expo`

这些只负责工程壳和运行环境，不是视觉模板。

## Adoption Rule

模板只借三样：

- 信息层级
- 组件节奏
- 任务流结构

不要直接继承：

- 默认配色
- 默认文案
- 冗余标题
- 原样卡片套娃
