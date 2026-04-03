# Prompt Templates

## Build

在开始实现前，先按下面格式定方向：

```text
平台：Web / H5 / 小程序 / Chrome 扩展 / Mobile App / Electron / Tauri / 桌面 App
界面类型：popup / options / dashboard / settings / panel / page / tab / form / detail
用户场景：这个界面主要解决什么问题
视觉方向：只选一个，例如 tooling / editorial / data panel / brand display / tahoe glass
信息密度：低 / 中 / 高
动效强度：无 / 轻 / 中
约束：现有组件库、设计系统、品牌色、可访问性、性能限制
```

## Tahoe Glass

```text
把这个界面做成 macOS Tahoe 风格的 Liquid Glass 方向。
要求：
1. 只把玻璃材质用于关键层，不要全屏全卡片都玻璃化
2. 用透明度、模糊和高光制造层次，但主内容必须保持最清晰
3. 图标和控件可以有轻微果冻感与微拟物质感，但不要厚重
4. 不增加无意义外框/内框，不靠模糊掩盖结构问题
5. 背景和反射效果不能影响文字、按钮和状态可读性
6. 不要用营销式大标题和自我解释文案，首屏优先放真实任务与操作
7. 中文字体要贴近 macOS 系统界面气质，最外层窗壳尽量轻，不要比内容层更抢眼
8. 配色不要偷懒落到蓝紫渐变，优先用银灰、雾白、石墨、浅青、冷绿或暖光反射
```

## Restyle

```text
保持现有技术栈和组件库不变，重做这个界面的视觉层级和留白。
要求：
1. 优先复用现有 token，没有再补 token
2. 明确主次区域和主次按钮
3. 补齐 hover / focus / disabled / loading / empty / error
4. 动效克制，只保留关键反馈
5. 避免通用 AI 模板风
```

## Review

```text
从设计令牌、层级、留白、状态、动效克制五个维度审查这个界面。
先指出最影响质感的问题，再给出最小修改方案。
```
