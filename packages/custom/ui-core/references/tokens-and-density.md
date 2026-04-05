# Tokens And Density

## Token Minimum

至少有这几类 token：

- `color`: `surface` / `text` / `accent` / `border` / `danger` / `success`
- `space`: 组内、组间、页面边距
- `radius`: 小、中、大
- `shadow`: 浅、中、浮层
- `type`: 标题、正文、辅助、按钮
- `motion`: 快、标准、退出

## Naming

优先语义命名，不要直接用表现命名：

- 好：`surface-muted`、`text-strong`、`gap-section`
- 差：`gray-200`、`card-gap-28`、`big-shadow`

## Density

- 组内间距要紧一些，组间间距再拉开。
- 内容越短，组件越应该收紧；不要让短文案占一大片。
- 小窗体、popup、移动端默认比网页更克制。
- 信息密度高时，优先删冗余标题和容器，不优先继续压字号。

## Platform Mapping

- Web / CSS：优先 CSS variables、theme tokens、Tailwind theme token。
- React Native / Flutter / SwiftUI：用语义常量层，不直接在组件里写视觉原始值。
- 小程序：全局样式变量或统一常量文件，不要页面各写各的。
