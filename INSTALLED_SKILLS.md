# 📦 已安装的 Skills 列表

> 本文档由 `shared/scripts/update-skills-list.sh` 自动生成和维护
> 文件名：`INSTALLED_SKILLS.md` - 避免与各 skill 目录中的 `SKILL.md` 混淆
> 用途/触发关键词：优先由 AI 自动生成中文（可按需手动补充）
> 最后更新：2026-04-03 12:41:58

---

## 🎨 自己创建的 Skills

### agent-rules-sync
**用途：** 统一多平台全局规则管理（AGENTS/CLAUDE/GEMINI）
**触发关键词：** agent-rules-sync、统一多平台全局规则管理、若是讨论性提问、如“要不要写入全局规则？”、则不触发

**位置：** `/Users/zhangyufan/Workspace/skills-central/packages/core/agent-rules-sync/`

---

### aigc-v1
**用途：** 论文/技术文档风格改写，让表达更解释性、更像学术写作
**触发关键词：** 论文润色、技术文档改写、学术写作、AI检测规避、词汇替换

**位置：** `/Users/zhangyufan/Workspace/skills-central/packages/custom/aigc-v1/`

---

### code-quality-check
**用途：** 通用代码质量检查
**触发关键词：** code-quality-check、代码质量、通用代码质量检查、提交代码前自动执行

**位置：** `/Users/zhangyufan/Workspace/skills-central/packages/custom/code-quality-check/`

---

### commit-conventional
**用途：** 执行 git commit 创建符合约定式提交规范的提交
**触发关键词：** commit-conventional、约定式提交、仅当用户明确要求"提交代码、创建提交、不要在仅仅讨论提交、询问提交规范、或解释如何提交时触发

**位置：** `/Users/zhangyufan/Workspace/skills-central/packages/custom/commit-conventional/`

---

### create-skill
**用途：** Guide for creating effective skills
**触发关键词：** create-skill、制作自定义技能等场景

**位置：** `/Users/zhangyufan/Workspace/skills-central/packages/core/create-skill/`

---

### de-ai-zh-optimized
**用途：** 重组优化版中文去AI技能，一次性输出终稿，支持文本与本地文件输入
**触发关键词：** 去AI痕迹、论文去AI、技术文档去AI、AIGC改写、人性化改写、本地文件去AI

**位置：** `/Users/zhangyufan/Workspace/skills-central/packages/custom/de-ai-zh-optimized/`

---

### de-ai-zh-stable
**用途：** 保守整合版中文去AI技能，一次性输出终稿，支持文本与本地文件输入
**触发关键词：** 去AI痕迹、论文去AI、技术文档去AI、AIGC改写、人性化改写、本地文件去AI

**位置：** `/Users/zhangyufan/Workspace/skills-central/packages/custom/de-ai-zh-stable/`

---

### doctor-skills
**用途：** 诊断中央 skills 仓库状态，并在需要时执行轻量修复。
**触发关键词：** doctor-skills、仓库诊断、verify.sh、skill-source.json、平台链接、轻量修复

**位置：** `/Users/zhangyufan/Workspace/skills-central/packages/core/doctor-skills/`

---

### humanizer-zh
**用途：** 去除 AI 写作痕迹，使文本更自然有人味
**触发关键词：** 去除AI痕迹、去AI味、人性化文本、改写AI文章、降低AI检测、AI写作模式

**位置：** `/Users/zhangyufan/Workspace/skills-central/packages/custom/humanizer-zh/`

---

### install-skill
**用途：** 用于安装和更新 skill、执行 skill 安全审计与风险拦截。
**触发关键词：** install-skill、安装 skill、更新 skill、GitHub 仓库、安全审计、风险扫描、Prompt Injection、GitHub、Workspace/skills-cent、agents/skills

**位置：** `/Users/zhangyufan/Workspace/skills-central/packages/core/install-skill/`

---

### skill-security-guard
**用途：** 对本地或 GitHub 上的 AI skill 执行安装前安全审计，检测提示词劫持、下载执行、凭证窃取、数据外传、持久化与提权风险，并输出...
**触发关键词：** skill-security-guard、安全审计、提示词劫持、下载执行、凭证窃取、数据外传、持久化、提权风险、风险结论、安装前审计

**位置：** `/Users/zhangyufan/Workspace/skills-central/packages/core/skill-security-guard/`

---

### tech-article-pipeline
**用途：** 用于把技术实践、架构改造、工具评测等主题协作写成可发布的公众号草稿，并同步产出 X 线程版。
**触发关键词：** 技术文章、公众号草稿、X 线程、文章起稿、技术复盘、架构写作、工具评测、协作写稿

**位置：** `/Users/zhangyufan/Workspace/skills-central/packages/custom/tech-article-pipeline/`

---

### ui-assets
**用途：** 维护 ui-polish 共享参考资料、脚本与模板资产。
**触发关键词：** UI 资产、共享参考、模板来源、交互预设、风格预设、UI 脚本

**位置：** `/Users/zhangyufan/Workspace/skills-central/packages/custom/ui-assets/`

---

### ui-copy
**用途：** 优化界面文案，去掉 AI 味、自解释和无效标题。
**触发关键词：** UI 文案、去AI味、按钮文案、标题精简、界面文案优化、使用者视角

**位置：** `/Users/zhangyufan/Workspace/skills-central/packages/custom/ui-copy/`

---

### ui-core
**用途：** 提供 ui-polish 的核心硬规则，约束布局、层级、可读性和反馈。
**触发关键词：** UI 规则、设计约束、布局克制、可读性、按钮反馈、设计令牌

**位置：** `/Users/zhangyufan/Workspace/skills-central/packages/custom/ui-core/`

---

### ui-desktop
**用途：** 补充桌面应用界面的布局、层级和交互规则。
**触发关键词：** 桌面应用 UI、Electron、Tauri、工具面板、桌面布局、系统风格

**位置：** `/Users/zhangyufan/Workspace/skills-central/packages/custom/ui-desktop/`

---

### ui-ext
**用途：** 补充浏览器扩展界面的空间利用和交互规则。
**触发关键词：** 扩展 UI、Chrome 扩展、Popup、Side Panel、紧凑布局、扩展交互

**位置：** `/Users/zhangyufan/Workspace/skills-central/packages/custom/ui-ext/`

---

### ui-feedback
**用途：** 细化按钮、表单和状态切换的交互反馈设计。
**触发关键词：** 交互反馈、按钮状态、loading、error、empty state、状态矩阵

**位置：** `/Users/zhangyufan/Workspace/skills-central/packages/custom/ui-feedback/`

---

### ui-mini
**用途：** 补充小程序界面的信息密度和平台化设计规则。
**触发关键词：** 小程序 UI、微信小程序、平台密度、原生感、小程序交互、轻量界面

**位置：** `/Users/zhangyufan/Workspace/skills-central/packages/custom/ui-mini/`

---

### ui-mobile
**用途：** 补充移动端界面的触达范围、信息顺序和触控规则。
**触发关键词：** 移动端 UI、H5、App 界面、触控交互、小屏阅读、移动布局

**位置：** `/Users/zhangyufan/Workspace/skills-central/packages/custom/ui-mobile/`

---

### ui-pencil
**用途：** 在需要 Pencil 共改时提供画布协作和结构先行规则。
**触发关键词：** Pencil、画布共改、线框图、结构先行、视觉协作、设计验证

**位置：** `/Users/zhangyufan/Workspace/skills-central/packages/custom/ui-pencil/`

---

### ui-polish
**用途：** 统一提升 Web、H5、小程序、扩展、移动端和桌面应用界面的质感、层级与完成度。
**触发关键词：** 前端审美、UI 美化、界面优化、小程序 UI、H5 设计、移动端 UI、扩展界面、桌面应用 UI

**位置：** `/Users/zhangyufan/Workspace/skills-central/packages/custom/ui-polish/`

---

### ui-review
**用途：** 对 UI 结果做阻塞项检查和最终视觉审查。
**触发关键词：** UI 审查、视觉验收、阻塞检查、完成度检查、界面复核、设计走查

**位置：** `/Users/zhangyufan/Workspace/skills-central/packages/custom/ui-review/`

---

### ui-web
**用途：** 补充网页、后台和 SaaS 界面的布局与信息层级规则。
**触发关键词：** Web UI、后台界面、Dashboard、SaaS、网页布局、信息层级

**位置：** `/Users/zhangyufan/Workspace/skills-central/packages/custom/ui-web/`

---

### uninstall-skill
**用途：** 删除中央仓库中的已安装 skill，并同步清理平台发布结果与已安装列表。
**触发关键词：** uninstall-skill、卸载 skill、删除 skill、bundle 清理、平台清理、INSTALLED_SKILLS

**位置：** `/Users/zhangyufan/Workspace/skills-central/packages/core/uninstall-skill/`

---

### update-skill
**用途：** 按 .skill-source.json 回放来源信息，更新已安装 skill，并支持 bundle 分组更新。
**触发关键词：** update-skill、更新 skill、bundle 更新、update_group、skill-source.json、已安装 skills

**位置：** `/Users/zhangyufan/Workspace/skills-central/packages/core/update-skill/`

---

### using-ui-polish
**用途：** 作为 ui-polish 的运行入口，负责路由平台、文案、反馈与审查链路。
**触发关键词：** ui-polish 入口、UI 路由、平台选择、设计工作流、UI 协作、最终审查

**位置：** `/Users/zhangyufan/Workspace/skills-central/packages/custom/using-ui-polish/`

---

## 🌐 社区安装的 Skills

### agent-browser
**用途：** 用于自动化浏览器交互与网页数据提取。
**触发关键词：** agent-browser、浏览器自动化、网页测试、截图、数据提取

**来源：** vercel-labs/agent-browser

**位置：** `/Users/zhangyufan/Workspace/skills-central/packages/community/vercel-labs__agent-browser/agent-browser/`

---

### brainstorming
**用途：** 用于设计和审查前端界面与交互体验。
**触发关键词：** brainstorming、前端设计、UI、UX、组件、MUST

**来源：** https://github.com/obra/superpowers.git (bundle: superpowers)

**位置：** `/Users/zhangyufan/Workspace/skills-central/packages/community/obra__superpowers/skills/brainstorming/`

---

### chrome-cdp
**用途：** 连接本地运行中的 Chrome 浏览器会话，查看/截图/交互已打开的页面
**触发关键词：** Chrome调试、CDP、浏览器截图、页面交互、DOM查看、实时会话、远程调试

**来源：** pasky/chrome-cdp-skill

**位置：** `/Users/zhangyufan/Workspace/skills-central/packages/community/pasky__chrome-cdp-skill/chrome-cdp/`

---

### competition-ad-certificate-abuse
**用途：** 用于分析 AD CS、证书模板、PKINIT 和证书映射带来的提权路径。
**触发关键词：** AD CS、证书滥用、PKINIT、模板权限、证书提权

**来源：** https://github.com/GALIAIS/CTF-Sandbox-Orchestrator (bundle: CTF-Sandbox-Orchestrator)

**位置：** `/Users/zhangyufan/Workspace/skills-central/packages/community/GALIAIS__CTF-Sandbox-Orchestrator/competition-ad-certificate-abuse/`

---

### competition-agent-cloud
**用途：** 用于分析 AI agent、云、容器和 CI/CD 相关挑战，追踪从输入到云侧影响的链路。
**触发关键词：** Agent 安全、云安全、容器安全、CI、CD、提示注入

**来源：** https://github.com/GALIAIS/CTF-Sandbox-Orchestrator (bundle: CTF-Sandbox-Orchestrator)

**位置：** `/Users/zhangyufan/Workspace/skills-central/packages/community/GALIAIS__CTF-Sandbox-Orchestrator/competition-agent-cloud/`

---

### competition-android-hooking
**用途：** 用于分析 Android 运行时、Frida Hook、签名逻辑和本地存储。
**触发关键词：** Android 安全、Frida、Hook、APK 分析、移动逆向

**来源：** https://github.com/GALIAIS/CTF-Sandbox-Orchestrator (bundle: CTF-Sandbox-Orchestrator)

**位置：** `/Users/zhangyufan/Workspace/skills-central/packages/community/GALIAIS__CTF-Sandbox-Orchestrator/competition-android-hooking/`

---

### competition-browser-persistence
**用途：** 用于分析浏览器中的 Cookie、本地存储、Cache 和持久化状态。
**触发关键词：** 浏览器取证、Cookie、localStorage、缓存、前端状态

**来源：** https://github.com/GALIAIS/CTF-Sandbox-Orchestrator (bundle: CTF-Sandbox-Orchestrator)

**位置：** `/Users/zhangyufan/Workspace/skills-central/packages/community/GALIAIS__CTF-Sandbox-Orchestrator/competition-browser-persistence/`

---

### competition-bundle-sourcemap-recovery
**用途：** 用于从前端 bundle、source map 和构建产物中恢复隐藏结构。
**触发关键词：** Source Map、Bundle 分析、前端构建、源码恢复、Chunk

**来源：** https://github.com/GALIAIS/CTF-Sandbox-Orchestrator (bundle: CTF-Sandbox-Orchestrator)

**位置：** `/Users/zhangyufan/Workspace/skills-central/packages/community/GALIAIS__CTF-Sandbox-Orchestrator/competition-bundle-sourcemap-recovery/`

---

### competition-cloud-metadata-path
**用途：** 用于分析云元数据服务、实例身份和元数据到权限的信任边界。
**触发关键词：** 云元数据、实例身份、工作负载身份、凭证路径、云权限

**来源：** https://github.com/GALIAIS/CTF-Sandbox-Orchestrator (bundle: CTF-Sandbox-Orchestrator)

**位置：** `/Users/zhangyufan/Workspace/skills-central/packages/community/GALIAIS__CTF-Sandbox-Orchestrator/competition-cloud-metadata-path/`

---

### competition-container-runtime
**用途：** 用于分析容器、Pod、Sidecar 与挂载密钥在运行时的真实行为。
**触发关键词：** 容器运行时、Kubernetes、挂载密钥、Sidecar、Pod 调试

**来源：** https://github.com/GALIAIS/CTF-Sandbox-Orchestrator (bundle: CTF-Sandbox-Orchestrator)

**位置：** `/Users/zhangyufan/Workspace/skills-central/packages/community/GALIAIS__CTF-Sandbox-Orchestrator/competition-container-runtime/`

---

### competition-crypto-mobile
**用途：** 用于处理密码学、编码、隐写以及移动端信任边界相关题目。
**触发关键词：** 密码学、编码解密、隐写分析、移动安全、APK IPA

**来源：** https://github.com/GALIAIS/CTF-Sandbox-Orchestrator (bundle: CTF-Sandbox-Orchestrator)

**位置：** `/Users/zhangyufan/Workspace/skills-central/packages/community/GALIAIS__CTF-Sandbox-Orchestrator/competition-crypto-mobile/`

---

### competition-custom-protocol-replay
**用途：** 用于分析自定义协议的认证、重放窗口和状态机差异。
**触发关键词：** 自定义协议、协议重放、状态机、认证链路、报文回放

**来源：** https://github.com/GALIAIS/CTF-Sandbox-Orchestrator (bundle: CTF-Sandbox-Orchestrator)

**位置：** `/Users/zhangyufan/Workspace/skills-central/packages/community/GALIAIS__CTF-Sandbox-Orchestrator/competition-custom-protocol-replay/`

---

### competition-dpapi-credential-chain
**用途：** 用于分析 DPAPI、Vault、浏览器密钥库和凭据解包链路。
**触发关键词：** DPAPI、Vault、浏览器凭据、密钥解包、Windows 凭据

**来源：** https://github.com/GALIAIS/CTF-Sandbox-Orchestrator (bundle: CTF-Sandbox-Orchestrator)

**位置：** `/Users/zhangyufan/Workspace/skills-central/packages/community/GALIAIS__CTF-Sandbox-Orchestrator/competition-dpapi-credential-chain/`

---

### competition-file-parser-chain
**用途：** 用于分析文件上传、预览、解压和反序列化等解析链路。
**触发关键词：** 文件上传、解析链、反序列化、解压流程、文件处理

**来源：** https://github.com/GALIAIS/CTF-Sandbox-Orchestrator (bundle: CTF-Sandbox-Orchestrator)

**位置：** `/Users/zhangyufan/Workspace/skills-central/packages/community/GALIAIS__CTF-Sandbox-Orchestrator/competition-file-parser-chain/`

---

### competition-firmware-layout
**用途：** 用于拆解固件镜像、分区布局、启动链和更新包结构。
**触发关键词：** 固件分析、分区布局、启动链、更新包、嵌入式安全

**来源：** https://github.com/GALIAIS/CTF-Sandbox-Orchestrator (bundle: CTF-Sandbox-Orchestrator)

**位置：** `/Users/zhangyufan/Workspace/skills-central/packages/community/GALIAIS__CTF-Sandbox-Orchestrator/competition-firmware-layout/`

---

### competition-forensic-timeline
**用途：** 用于把多种取证证据串成一条可复盘的时间线，定位关键节点。
**触发关键词：** 取证时间线、DFIR、日志关联、事件还原、多证据分析

**来源：** https://github.com/GALIAIS/CTF-Sandbox-Orchestrator (bundle: CTF-Sandbox-Orchestrator)

**位置：** `/Users/zhangyufan/Workspace/skills-central/packages/community/GALIAIS__CTF-Sandbox-Orchestrator/competition-forensic-timeline/`

---

### competition-graphql-rpc-drift
**用途：** 用于分析 GraphQL/RPC 接口在模式、鉴权和运行时行为上的偏差。
**触发关键词：** GraphQL、RPC、Schema Drift、鉴权差异、接口调试

**来源：** https://github.com/GALIAIS/CTF-Sandbox-Orchestrator (bundle: CTF-Sandbox-Orchestrator)

**位置：** `/Users/zhangyufan/Workspace/skills-central/packages/community/GALIAIS__CTF-Sandbox-Orchestrator/competition-graphql-rpc-drift/`

---

### competition-identity-windows
**用途：** 用于分析身份系统、AD、Windows 主机和企业消息系统中的认证与权限链路。
**触发关键词：** 身份安全、Active Directory、Windows 安全、认证链路、权限提升

**来源：** https://github.com/GALIAIS/CTF-Sandbox-Orchestrator (bundle: CTF-Sandbox-Orchestrator)

**位置：** `/Users/zhangyufan/Workspace/skills-central/packages/community/GALIAIS__CTF-Sandbox-Orchestrator/competition-identity-windows/`

---

### competition-ios-runtime
**用途：** 用于分析 iOS 运行时、Frida Hook、Keychain、Pinning 与请求签名逻辑。
**触发关键词：** iOS 安全、Frida、Keychain、SSL Pinning、IPA 分析

**来源：** https://github.com/GALIAIS/CTF-Sandbox-Orchestrator (bundle: CTF-Sandbox-Orchestrator)

**位置：** `/Users/zhangyufan/Workspace/skills-central/packages/community/GALIAIS__CTF-Sandbox-Orchestrator/competition-ios-runtime/`

---

### competition-jwt-claim-confusion
**用途：** 用于分析 JWT/JWS/JWE 的头部、声明和密钥选择混淆问题。
**触发关键词：** JWT、Claim 混淆、JWS、JWE、Token 验证

**来源：** https://github.com/GALIAIS/CTF-Sandbox-Orchestrator (bundle: CTF-Sandbox-Orchestrator)

**位置：** `/Users/zhangyufan/Workspace/skills-central/packages/community/GALIAIS__CTF-Sandbox-Orchestrator/competition-jwt-claim-confusion/`

---

### competition-k8s-control-plane
**用途：** 用于分析 Kubernetes 控制面、RBAC、工作负载身份和集群变更。
**触发关键词：** Kubernetes、控制面、RBAC、ServiceAccount、集群安全

**来源：** https://github.com/GALIAIS/CTF-Sandbox-Orchestrator (bundle: CTF-Sandbox-Orchestrator)

**位置：** `/Users/zhangyufan/Workspace/skills-central/packages/community/GALIAIS__CTF-Sandbox-Orchestrator/competition-k8s-control-plane/`

---

### competition-kerberos-delegation
**用途：** 用于分析 Kerberos 委派、S4U、RBCD 和票据转换路径。
**触发关键词：** Kerberos、委派滥用、RBCD、S4U、票据

**来源：** https://github.com/GALIAIS/CTF-Sandbox-Orchestrator (bundle: CTF-Sandbox-Orchestrator)

**位置：** `/Users/zhangyufan/Workspace/skills-central/packages/community/GALIAIS__CTF-Sandbox-Orchestrator/competition-kerberos-delegation/`

---

### competition-kernel-container-escape
**用途：** 用于分析内核攻击面、Namespace 边界和容器逃逸路径。
**触发关键词：** 容器逃逸、内核漏洞、Namespace、cgroup、宿主机边界

**来源：** https://github.com/GALIAIS/CTF-Sandbox-Orchestrator (bundle: CTF-Sandbox-Orchestrator)

**位置：** `/Users/zhangyufan/Workspace/skills-central/packages/community/GALIAIS__CTF-Sandbox-Orchestrator/competition-kernel-container-escape/`

---

### competition-linux-credential-pivot
**用途：** 用于分析 Linux 中的 SSH、Token、Socket 与 sudo/capability 信任边界。
**触发关键词：** Linux 凭据、SSH Key、sudo、Capability、横向移动

**来源：** https://github.com/GALIAIS/CTF-Sandbox-Orchestrator (bundle: CTF-Sandbox-Orchestrator)

**位置：** `/Users/zhangyufan/Workspace/skills-central/packages/community/GALIAIS__CTF-Sandbox-Orchestrator/competition-linux-credential-pivot/`

---

### competition-lsass-ticket-material
**用途：** 用于分析 LSASS、票据缓存和可重放的会话凭据材料。
**触发关键词：** LSASS、票据缓存、凭据转储、会话重放、Windows 凭据

**来源：** https://github.com/GALIAIS/CTF-Sandbox-Orchestrator (bundle: CTF-Sandbox-Orchestrator)

**位置：** `/Users/zhangyufan/Workspace/skills-central/packages/community/GALIAIS__CTF-Sandbox-Orchestrator/competition-lsass-ticket-material/`

---

### competition-mailbox-abuse
**用途：** 用于分析邮箱规则、邮件流和企业消息系统中的滥用路径。
**触发关键词：** 邮箱滥用、邮件规则、Exchange、企业邮件、消息安全

**来源：** https://github.com/GALIAIS/CTF-Sandbox-Orchestrator (bundle: CTF-Sandbox-Orchestrator)

**位置：** `/Users/zhangyufan/Workspace/skills-central/packages/community/GALIAIS__CTF-Sandbox-Orchestrator/competition-mailbox-abuse/`

---

### competition-malware-config
**用途：** 用于提取和验证恶意样本配置、C2 信息与关键运行参数。
**触发关键词：** 恶意软件、配置提取、C2 分析、样本解析、木马配置

**来源：** https://github.com/GALIAIS/CTF-Sandbox-Orchestrator (bundle: CTF-Sandbox-Orchestrator)

**位置：** `/Users/zhangyufan/Workspace/skills-central/packages/community/GALIAIS__CTF-Sandbox-Orchestrator/competition-malware-config/`

---

### competition-oauth-oidc-chain
**用途：** 用于分析 OAuth、OIDC、重定向链和令牌到身份的转化过程。
**触发关键词：** OAuth、OIDC、重定向链、令牌验证、身份联邦

**来源：** https://github.com/GALIAIS/CTF-Sandbox-Orchestrator (bundle: CTF-Sandbox-Orchestrator)

**位置：** `/Users/zhangyufan/Workspace/skills-central/packages/community/GALIAIS__CTF-Sandbox-Orchestrator/competition-oauth-oidc-chain/`

---

### competition-pcap-protocol
**用途：** 用于分析 PCAP、私有协议和报文交互，恢复关键消息序列。
**触发关键词：** PCAP 分析、协议逆向、抓包、流量还原、报文解析

**来源：** https://github.com/GALIAIS/CTF-Sandbox-Orchestrator (bundle: CTF-Sandbox-Orchestrator)

**位置：** `/Users/zhangyufan/Workspace/skills-central/packages/community/GALIAIS__CTF-Sandbox-Orchestrator/competition-pcap-protocol/`

---

### competition-prompt-injection
**用途：** 用于分析提示词注入、工具调用污染和模型可见指令链路。
**触发关键词：** 提示注入、Prompt Injection、工具调用、模型安全、Agent

**来源：** https://github.com/GALIAIS/CTF-Sandbox-Orchestrator (bundle: CTF-Sandbox-Orchestrator)

**位置：** `/Users/zhangyufan/Workspace/skills-central/packages/community/GALIAIS__CTF-Sandbox-Orchestrator/competition-prompt-injection/`

---

### competition-queue-worker-drift
**用途：** 用于分析消息队列、Worker 状态漂移和异步执行结果不一致问题。
**触发关键词：** 消息队列、Worker、异步任务、状态漂移、消费链路

**来源：** https://github.com/GALIAIS/CTF-Sandbox-Orchestrator (bundle: CTF-Sandbox-Orchestrator)

**位置：** `/Users/zhangyufan/Workspace/skills-central/packages/community/GALIAIS__CTF-Sandbox-Orchestrator/competition-queue-worker-drift/`

---

### competition-race-condition-state-drift
**用途：** 用于分析竞态条件、锁缺失和时序导致的状态不一致。
**触发关键词：** 竞态条件、Race Condition、时序漏洞、状态漂移、并发问题

**来源：** https://github.com/GALIAIS/CTF-Sandbox-Orchestrator (bundle: CTF-Sandbox-Orchestrator)

**位置：** `/Users/zhangyufan/Workspace/skills-central/packages/community/GALIAIS__CTF-Sandbox-Orchestrator/competition-race-condition-state-drift/`

---

### competition-relay-coercion-chain
**用途：** 用于分析中继、强制认证和协议协商中的链式利用路径。
**触发关键词：** Relay、强制认证、NTLM Relay、协议协商、链式利用

**来源：** https://github.com/GALIAIS/CTF-Sandbox-Orchestrator (bundle: CTF-Sandbox-Orchestrator)

**位置：** `/Users/zhangyufan/Workspace/skills-central/packages/community/GALIAIS__CTF-Sandbox-Orchestrator/competition-relay-coercion-chain/`

---

### competition-request-normalization-smuggling
**用途：** 用于分析请求规范化差异、代理解析偏差和走私链路。
**触发关键词：** 请求走私、规范化差异、代理解析、CL TE、路径编码

**来源：** https://github.com/GALIAIS/CTF-Sandbox-Orchestrator (bundle: CTF-Sandbox-Orchestrator)

**位置：** `/Users/zhangyufan/Workspace/skills-central/packages/community/GALIAIS__CTF-Sandbox-Orchestrator/competition-request-normalization-smuggling/`

---

### competition-reverse-pwn
**用途：** 用于处理逆向、二进制、内存、恶意样本和 pwn 题，聚焦可复现的利用路径。
**触发关键词：** 逆向分析、二进制漏洞、Pwn、崩溃调试、恶意样本

**来源：** https://github.com/GALIAIS/CTF-Sandbox-Orchestrator (bundle: CTF-Sandbox-Orchestrator)

**位置：** `/Users/zhangyufan/Workspace/skills-central/packages/community/GALIAIS__CTF-Sandbox-Orchestrator/competition-reverse-pwn/`

---

### competition-runtime-routing
**用途：** 用于分析请求在代理、服务和运行时组件之间的真实路由路径。
**触发关键词：** 运行时路由、代理链路、请求流向、服务解析、网关调试

**来源：** https://github.com/GALIAIS/CTF-Sandbox-Orchestrator (bundle: CTF-Sandbox-Orchestrator)

**位置：** `/Users/zhangyufan/Workspace/skills-central/packages/community/GALIAIS__CTF-Sandbox-Orchestrator/competition-runtime-routing/`

---

### competition-ssrf-metadata-pivot
**用途：** 用于分析 SSRF 到元数据服务再到权限获取的完整链路。
**触发关键词：** SSRF、元数据服务、凭证获取、云提权、内部访问

**来源：** https://github.com/GALIAIS/CTF-Sandbox-Orchestrator (bundle: CTF-Sandbox-Orchestrator)

**位置：** `/Users/zhangyufan/Workspace/skills-central/packages/community/GALIAIS__CTF-Sandbox-Orchestrator/competition-ssrf-metadata-pivot/`

---

### competition-stego-media
**用途：** 用于分析图片、音视频、文档等载体中的隐写和附加隐藏数据。
**触发关键词：** 隐写术、图片分析、音视频取证、隐藏载荷、媒体取证

**来源：** https://github.com/GALIAIS/CTF-Sandbox-Orchestrator (bundle: CTF-Sandbox-Orchestrator)

**位置：** `/Users/zhangyufan/Workspace/skills-central/packages/community/GALIAIS__CTF-Sandbox-Orchestrator/competition-stego-media/`

---

### competition-supply-chain
**用途：** 用于分析依赖、镜像、制品、构建与发布流程中的供应链风险。
**触发关键词：** 供应链安全、依赖投毒、镜像构建、发布流程、CI 风险

**来源：** https://github.com/GALIAIS/CTF-Sandbox-Orchestrator (bundle: CTF-Sandbox-Orchestrator)

**位置：** `/Users/zhangyufan/Workspace/skills-central/packages/community/GALIAIS__CTF-Sandbox-Orchestrator/competition-supply-chain/`

---

### competition-template-render-path
**用途：** 用于分析 SSR、模板渲染、Hydration 和渲染上下文差异。
**触发关键词：** SSR、模板渲染、Hydration、服务端渲染、前后端边界

**来源：** https://github.com/GALIAIS/CTF-Sandbox-Orchestrator (bundle: CTF-Sandbox-Orchestrator)

**位置：** `/Users/zhangyufan/Workspace/skills-central/packages/community/GALIAIS__CTF-Sandbox-Orchestrator/competition-template-render-path/`

---

### competition-web-runtime
**用途：** 用于分析 CTF 中的 Web、API、前端与队列驱动应用链路，定位路由、会话和运行时差异。
**触发关键词：** Web 安全、API 调试、前端运行时、会话链路、CTF Web

**来源：** https://github.com/GALIAIS/CTF-Sandbox-Orchestrator (bundle: CTF-Sandbox-Orchestrator)

**位置：** `/Users/zhangyufan/Workspace/skills-central/packages/community/GALIAIS__CTF-Sandbox-Orchestrator/competition-web-runtime/`

---

### competition-websocket-runtime
**用途：** 用于分析 WebSocket、SSE、订阅流和帧驱动的实时状态变化。
**触发关键词：** WebSocket、SSE、实时通信、订阅流、帧分析

**来源：** https://github.com/GALIAIS/CTF-Sandbox-Orchestrator (bundle: CTF-Sandbox-Orchestrator)

**位置：** `/Users/zhangyufan/Workspace/skills-central/packages/community/GALIAIS__CTF-Sandbox-Orchestrator/competition-websocket-runtime/`

---

### competition-windows-pivot
**用途：** 用于分析 Windows 环境中的横向移动、远程执行和主机间权限转移。
**触发关键词：** Windows 横向移动、SMB、WinRM、RDP、主机渗透

**来源：** https://github.com/GALIAIS/CTF-Sandbox-Orchestrator (bundle: CTF-Sandbox-Orchestrator)

**位置：** `/Users/zhangyufan/Workspace/skills-central/packages/community/GALIAIS__CTF-Sandbox-Orchestrator/competition-windows-pivot/`

---

### ctf-sandbox-orchestrator
**用途：** CTF 沙箱总入口技能，用于先建立统一分析模型，再把任务路由到更窄的专项攻防 skill。
**触发关键词：** CTF 总控、沙箱编排、挑战路由、攻防分析、总入口

**来源：** https://github.com/GALIAIS/CTF-Sandbox-Orchestrator (bundle: CTF-Sandbox-Orchestrator)

**位置：** `/Users/zhangyufan/Workspace/skills-central/packages/community/GALIAIS__CTF-Sandbox-Orchestrator/ctf-sandbox-orchestrator/`

---

### deep-research
**用途：** 执行多步骤深度调研，并输出结构化、带引用的研究报告。
**触发关键词：** deep-research、深度调研、Gemini、带引用报告、competitive landscaping、due diligence

**来源：** sanjay3290/ai-skills

**位置：** `/Users/zhangyufan/Workspace/skills-central/packages/community/sanjay3290__ai-skills/skills/deep-research/`

---

### dispatching-parallel-agents
**用途：** 用于 dispatching-parallel-agents：Use when facing 2+ independent tasks that...
**触发关键词：** dispatching-parallel-agents、dispatching-parallel-

**来源：** https://github.com/obra/superpowers.git (bundle: superpowers)

**位置：** `/Users/zhangyufan/Workspace/skills-central/packages/community/obra__superpowers/skills/dispatching-parallel-agents/`

---

### executing-plans
**用途：** 用于 executing-plans：Use when you have a written implementatio...
**触发关键词：** executing-plans、技能管理

**来源：** https://github.com/obra/superpowers.git (bundle: superpowers)

**位置：** `/Users/zhangyufan/Workspace/skills-central/packages/community/obra__superpowers/skills/executing-plans/`

---

### find-skills
**用途：** 用于安装和更新 skill。
**触发关键词：** find-skills、安装 skill、更新 skill、GitHub 仓库

**来源：** vercel-labs/skills

**位置：** `/Users/zhangyufan/Workspace/skills-central/packages/community/vercel-labs__skills/find-skills/`

---

### finishing-a-development-branch
**用途：** 用于 finishing-a-development-branch：Use when implementation is complete, all...
**触发关键词：** finishing-a-development-branch、finishing-a-developme、nt-branch、PR

**来源：** https://github.com/obra/superpowers.git (bundle: superpowers)

**位置：** `/Users/zhangyufan/Workspace/skills-central/packages/community/obra__superpowers/skills/finishing-a-development-branch/`

---

### frontend-design
**用途：** 用于设计和审查前端界面与交互体验。
**触发关键词：** frontend-design、前端设计、UI、UX、组件、production-grade、AI

**来源：** anthropics/skills

**位置：** `/Users/zhangyufan/Workspace/skills-central/packages/community/anthropics__skills/frontend-design/`

---

### gh-address-comments
**用途：** 用于定位当前分支对应的 GitHub PR 评论，并通过 gh CLI 处理审查意见与回写修复。
**触发关键词：** PR评论、代码审查、gh CLI、GitHub、review comments、issue comments、gh auth、当前分支

**来源：** openai/skills

**位置：** `/Users/zhangyufan/Workspace/skills-central/packages/community/openai__skills/skills/gh-address-comments/`

---

### planning-with-files
**用途：** 用于规划复杂任务并沉淀执行计划。
**触发关键词：** planning-with-files、任务规划、执行计划、工作流、Manus-style、file-based、plan.md、findings.md、progress.md、multi-step

**来源：** OthmanAdi/planning-with-files

**位置：** `/Users/zhangyufan/Workspace/skills-central/packages/community/OthmanAdi__planning-with-files/planning-with-files/`

---

### receiving-code-review
**用途：** 用于 receiving-code-review：Use when receiving code review feedback,...
**触发关键词：** receiving-code-review、技能管理

**来源：** https://github.com/obra/superpowers.git (bundle: superpowers)

**位置：** `/Users/zhangyufan/Workspace/skills-central/packages/community/obra__superpowers/skills/receiving-code-review/`

---

### requesting-code-review
**用途：** 用于 requesting-code-review：Use when completing tasks, implementing m...
**触发关键词：** requesting-code-review、requesting-code-revie

**来源：** https://github.com/obra/superpowers.git (bundle: superpowers)

**位置：** `/Users/zhangyufan/Workspace/skills-central/packages/community/obra__superpowers/skills/requesting-code-review/`

---

### seo-audit
**用途：** 用于诊断中央 skills 仓库状态并执行轻量修复、执行 skill 安全审计与风险拦截。
**触发关键词：** seo-audit、仓库诊断、verify.sh、轻量修复、安全审计、风险扫描、Prompt Injection、SEO 审计、站内优化、Meta 标签

**来源：** coreyhaines31/marketingskills

**位置：** `/Users/zhangyufan/Workspace/skills-central/packages/community/coreyhaines31__marketingskills/seo-audit/`

---

### subagent-driven-development
**用途：** 用于 subagent-driven-development：Use when executing implementation plans w...
**触发关键词：** subagent-driven-development、subagent-driven-devel

**来源：** https://github.com/obra/superpowers.git (bundle: superpowers)

**位置：** `/Users/zhangyufan/Workspace/skills-central/packages/community/obra__superpowers/skills/subagent-driven-development/`

---

### systematic-debugging
**用途：** 用于 systematic-debugging：Use when encountering any bug, test failu...
**触发关键词：** systematic-debugging、技能管理

**来源：** https://github.com/obra/superpowers.git (bundle: superpowers)

**位置：** `/Users/zhangyufan/Workspace/skills-central/packages/community/obra__superpowers/skills/systematic-debugging/`

---

### test-driven-development
**用途：** 用于 test-driven-development：Use when implementing any feature or bugf...
**触发关键词：** test-driven-development、test-driven-developme

**来源：** https://github.com/obra/superpowers.git (bundle: superpowers)

**位置：** `/Users/zhangyufan/Workspace/skills-central/packages/community/obra__superpowers/skills/test-driven-development/`

---

### ui-ux-pro-max
**用途：** 用于设计和审查前端界面与交互体验。
**触发关键词：** ui-ux-pro-max、前端设计、UI、UX、组件、UI/UX、React、Next.js、Vue、Svelte

**来源：** https://github.com/nextlevelbuilder/ui-ux-pro-max-skill.git

**位置：** `/Users/zhangyufan/Workspace/skills-central/packages/community/nextlevelbuilder__ui-ux-pro-max-skill/ui-ux-pro-max/`

---

### using-git-worktrees
**用途：** 用于 using-git-worktrees：Use when starting feature work that needs...
**触发关键词：** using-git-worktrees、技能管理

**来源：** https://github.com/obra/superpowers.git (bundle: superpowers)

**位置：** `/Users/zhangyufan/Workspace/skills-central/packages/community/obra__superpowers/skills/using-git-worktrees/`

---

### using-superpowers
**用途：** 用于 using-superpowers：Use when starting any conversation - esta...
**触发关键词：** using-superpowers、技能管理

**来源：** https://github.com/obra/superpowers.git (bundle: superpowers)

**位置：** `/Users/zhangyufan/Workspace/skills-central/packages/community/obra__superpowers/skills/using-superpowers/`

---

### vercel-react-best-practices
**用途：** 用于设计和审查前端界面与交互体验。
**触发关键词：** vercel-react-best-practices、前端设计、UI、UX、组件、vercel-react-best-pra、React、Next.js、React/Next.js

**来源：** vercel-labs/agent-skills

**位置：** `/Users/zhangyufan/Workspace/skills-central/packages/community/vercel-labs__agent-skills/vercel-react-best-practices/`

---

### verification-before-completion
**用途：** 用于 verification-before-completion：Use when about to claim work is complete,...
**触发关键词：** verification-before-completion、verification-before-c、PRs

**来源：** https://github.com/obra/superpowers.git (bundle: superpowers)

**位置：** `/Users/zhangyufan/Workspace/skills-central/packages/community/obra__superpowers/skills/verification-before-completion/`

---

### web-design-guidelines
**用途：** 用于执行 skill 安全审计与风险拦截、设计和审查前端界面与交互体验。
**触发关键词：** web-design-guidelines、安全审计、风险扫描、Prompt Injection、前端设计、UI、UX、组件

**来源：** vercel-labs/agent-skills

**位置：** `/Users/zhangyufan/Workspace/skills-central/packages/community/vercel-labs__agent-skills/web-design-guidelines/`

---

### writing-plans
**用途：** 用于 writing-plans：Use when you have a spec or requirements...
**触发关键词：** writing-plans、multi-step

**来源：** https://github.com/obra/superpowers.git (bundle: superpowers)

**位置：** `/Users/zhangyufan/Workspace/skills-central/packages/community/obra__superpowers/skills/writing-plans/`

---

### writing-skills
**用途：** 用于 writing-skills：Use when creating new skills, editing exi...
**触发关键词：** writing-skills、技能管理

**来源：** https://github.com/obra/superpowers.git (bundle: superpowers)

**位置：** `/Users/zhangyufan/Workspace/skills-central/packages/community/obra__superpowers/skills/writing-skills/`

---

## 📊 统计信息

- **总计：** 93 个 skills
- **自己创建：** 27 个
- **社区安装：** 66 个

---

## 🔄 如何更新此列表

```bash
# 手动更新
SKILLS_DIR=/Users/zhangyufan/Workspace/skills-central bash /Users/zhangyufan/Workspace/skills-central/shared/scripts/update-skills-list.sh

# 自动更新时机
# 1. 创建新 skill 后
# 2. 安装新 skill 后
# 3. 修改 SKILL.md 中 description/keywords 后
```
