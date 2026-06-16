# luci-theme-argon — macOS Sequoia / iOS 26 Liquid Glass 重设计

**日期**: 2026-06-16
**目标**: 将 luci-theme-argon 的"半吊子 macOS 风格"重构为真正的 macOS Sequoia / iOS 26 Liquid Glass 质感,覆盖所有界面层。
**范围**: 纯前端 CSS/LESS + ucode 模板微调 + 少量 JS( tab 滑块动画),不改后端 LuCI/OpenWrt 逻辑。
**不在范围**: 壁纸自动取色、滚动 refraction、第三方 app 深度适配、新图标集、自动暗色切换。

---

## 1. 视觉 Token 系统

所有视觉数值收束到一组 CSS 变量,在 less 里以 `.glass(@level)` mixin 统一调用。

### 1.1 玻璃填充(三档层级,浅色)

| Token | 值 (180deg 线性渐变) | 用途 |
|---|---|---|
| `--glass-fill-strong` | `rgba(255,255,255,.62)` → `.38` (45%) → `.52` (100%) | Chrome 大面:sidebar / toolbar / 登录卡 |
| `--glass-fill-regular` | `.50` → `.28` → `.42` | 内容卡片 / 弹窗 / tab 轨道 |
| `--glass-fill-thin` | `.40` → `.18` → `.30` | 次级层 / 嵌套段 header |
| `--glass-fill-chip` | `.85` → `.55` | 小玻璃件(按钮 / 胶囊 / 徽章 / 开关珠) |

### 1.2 模糊与饱和度

| Token | 值 |
|---|---|
| `--glass-blur-strong` | `32px` |
| `--glass-blur-regular` | `24px` |
| `--glass-blur-light` | `16px` |
| `--glass-saturate` | `saturate(200%)`(浅色)/ `saturate(160%)`(深色) |

`backdrop-filter` 始终与 `-webkit-backdrop-filter` 双写。

### 1.3 高光与阴影

| Token | 值 | 用途 |
|---|---|---|
| `--glass-specular-top` | `inset 0 1px 0 rgba(255,255,255,.9)` | 所有玻璃面必带的迎光顶棱 |
| `--glass-specular-highlight` | 追加 `inset 0 0.5px 0 rgba(255,255,255,.6), inset 0 18px 30px rgba(255,255,255,.15)` | 强版,大卡/登录/主按钮 |
| `--glass-shadow-inset-bottom` | `inset 0 -1px 0 rgba(0,0,0,.06)` | 底边暗线造厚度 |
| `--glass-contact` | `0 1px 0 rgba(0,0,0,.05), 0 8px 24px rgba(0,0,0,.08)` | 贴桌软投影(替代原 48px 大柔影) |
| `--glass-contact-lift` | `0 2px 0 rgba(0,0,0,.06), 0 14px 32px rgba(0,0,0,.12)` | hover 抬起 |

### 1.4 圆角层级

| Token | 值 | 用途 |
|---|---|---|
| `--r-chrome` | `22px` | sidebar 右下圆角、登录卡 |
| `--r-card` | `20px` | 内容卡/弹窗 |
| `--r-control` | `14px` | 多行输入、次级容器、alert 条 |
| `--r-pill` | `999px` | 按钮 / 开关 / tab / 徽章 / 单行输入 |

### 1.5 强调色(5 档 Apple 系统色)

| Key | 浅色 | 深色 |
|---|---|---|
| blue(默认) | `#007aff` | `#0a84ff` |
| purple | `#af52de` | `#bf5af2` |
| pink | `#ff2d55` | `#ff375f` |
| green | `#34c759` | `#30d158` |
| orange | `#ff9500` | `#ff9f0a` |

用户通过 argon 已有"主题色"下拉选择,前端直接改 `--accent` 变量;同时自动派生 `--accent-tint: rgba(accent, .12)` 用于 active 背景。**不再硬编码 Apple 蓝**。

### 1.6 文本色板

| Token | 浅色 | 深色 |
|---|---|---|
| `--t-primary` | `#1d1d1f` | `#f5f5f7` |
| `--t-secondary` | `#6e6e73` | `#a1a1a6` |
| `--t-tertiary` | `#8e8e93` | `#8e8e93` |

字体栈: `-apple-system, "SF Pro Text", "SF Pro Rounded", "Helvetica Neue", "PingFang SC", system-ui, sans-serif`;标题用 `SF Pro Rounded`/`SF Pro Display`;数字用 `SF Mono`。

### 1.7 深色模式(独立配方,非反色)

- 填充: `rgba(40,40,45,.55)` → `rgba(25,25,28,.40)` → `rgba(35,35,40,.48)`(灰蓝,非纯黑)
- specular-top: `inset 0 1px 0 rgba(255,255,255,.14)`
- 接触影: `0 8px 28px rgba(0,0,0,.5)`
- 饱和度: 160%

---

## 2. 壁纸与背景系统

### 2.1 层叠(登录后主界面)

```
Layer 0  body::before        用户壁纸(cover, fixed)
Layer 1  body::after         tint overlay(浅色: rgba(255,255,255,.35); 深色: rgba(0,0,0,.5))
Layer 2  .bokeh-well         3-4 个 radial-gradient 光斑,其一染 --accent;blur(80px);mix-blend-mode: screen
Layer 3  玻璃面板            backdrop-filter 糊的就是 0+1+2
Layer 4  .glass-specular     每个玻璃元素 ::before 顶 30% 反射高光
```

### 2.2 壁纸来源(全部保留)

- **内置**: 抽象液态 SVG 作 `default-abstract`,加两张 jpg(`default-landscape`,`default-graphite`,各 <200KB),随主题打包。
- **上传**: 复用 argon 现有上传入口。
- **Bing 每日**: 复用现有 Bing 获取逻辑。
- **Fallback**: 壁纸加载失败/未设置时,Layer 0 不设图,仅显示 Layer 2 bokeh。

### 2.3 共享策略

- 登录页与登录后共用同一张壁纸(`background-attachment: fixed` 实现纯 CSS parallax)。
- 登录页不加 tint/bokeh,只叠一个中心暗角 `radial-gradient(ellipse at center, transparent 40%, rgba(0,0,0,.25) 100%)`。
- 深色模式切换:壁纸保留,tint 0.3s 过渡从白切黑。

---

## 3. Shell 布局(macOS 原生窗口骨架)

### 3.1 Grid

```
┌─────────────────────────────────────────────────┐
│  Toolbar (52px, 焊顶, 全宽, z-100)              │
├────────┬────────────────────────────────────────┤
│        │  margin: 20px                          │
│ 240px  │  ┌────────────────────────────────┐   │
│sidebar │  │  Card                          │   │
│ 焊左   │  └────────────────────────────────┘   │
│ b-radius│  ┌─────┐ ┌─────┐                    │
│ 0 22/22/0│  ...   │ ... │                    │
└────────┴────────────────────────────────────────┘
```

### 3.2 Toolbar `.main-header`

- `position: sticky; top:0; left:0; right:0; height:52px`
- `border-radius: 0;`(焊顶,直边)
- `.glass(strong)`,底部 hairline `1px solid rgba(0,0,0,.06)`
- 内布局 flex: left 面包屑/标题(SF Rounded 17px semibold), center poll indicator 玻璃 chip, right 功能按钮组(暗色切换/登出等,28px 圆玻璃珠)
- 底边装饰 `::after`:120px 宽反光带,偏右

### 3.3 Sidebar `.main-left`

- `position: fixed; top:52px; left:0; bottom:0; width:240px`
- `border-radius: 0 22px 22px 0;`
- `.glass(strong)`,**顶部不设 specular**(与 toolbar 形成 L 形连续玻璃折弯)
- 内部: Logo+品牌直接打在玻璃上(取消原 brand pill);菜单项高 38px,圆角 12px
- 菜单项状态:
  - rest:透明
  - hover: `.glass(chip)` + `translateX(2px)`
  - **active**: `background: var(--accent-tint);` + 3px 左侧 accent 竖条 + 字 bold,**不再用实色蓝 pill**
- 子菜单缩进 14px,active 用 accent 小圆点替代竖条
- 滚动条 thumb: 6px 胶囊 `.glass(chip)`
- 移动端 ≤768px:抽屉模式,滑入动画

### 3.4 主内容区

- `margin-left: 260px; padding: 20px;`
- `.cbi-section` `.glass(regular)`, `border-radius: 20px`, `padding: 22px 24px`, gap 16px
- 段标题 h2: SF Rounded 22px bold,前缀 3px radius accent 小色块
- **footer 收编**进最后一张卡片内部,不再独立成条,右对齐 11px `--t-tertiary`

---

## 4. 控件系统

### 4.1 按钮(全胶囊)

| 等级 | 样式 | 典型 class |
|---|---|---|
| Primary | 胶囊,`linear-gradient(180deg, var(--accent), darken 8%)`;阴影 `0 6px 16px rgba(accent,.4) + inset 高光`;hover 抬起 `translateY(-2px)`,active 压平 | `.cbi-button-apply` .save .cbi-button-save 登录提交 |
| Secondary | 胶囊 `.glass(chip)`;hover `.glass(strong)` | .reset .edit .add |
| Danger | Primary 模板,色用 system red `#ff3b30`,红色阴影 | .remove 重置出厂 |
| Neutral/Link | 无底色纯文字;hover 浅色 tint 胶囊 | 未标记的次要按钮 |

统一高 34px,font 600 13px,padding 0 18px,图标按钮 34×34 圆。

### 4.2 输入框

- 单行:胶囊(`--r-pill`),高 36px,padding 0 16px,`.glass(chip)`,focus `box-shadow: 0 0 0 4px rgba(accent,.2);`
- textarea/多行:圆角 14px,padding 14px
- `<select>`:右内箭头图标,打开的 `<ul>` `.glass(regular)` 浮层 14px 圆角, li 高 36px, hover/focus `background: var(--accent-tint)`
- Checkbox/Radio:保持 Apple 经典方/圆勾样式,focus ring 4px accent glow
- Dynlist 标签:`.glass(chip)` 胶囊,悬停显红色"✕"小玻璃珠

### 4.3 Switch / Toggle(iOS 26 玻璃珠)

- 轨道:54×32 胶囊,透明 + `1px rgba(0,0,0,.1)` 描边,ON 时填充 accent + specular
- 滑块珠:28px 圆,`linear-gradient(180deg,#fff,#ebebf5)` + 高光 + 阴影 `0 2px 6px rgba(0,0,0,.25)`
- 切换 `translateX(0 → 22px)` 0.25s spring

### 4.4 Segmented Tab

- 容器:`.glass(regular)` 胶囊,padding 3px
- 滑块:`.glass(chip)` 白胶囊,通过 ~30 行 JS 根据 active 项位置/宽度 transform 滑动,实现 iOS 风格滑块动画
- 激活项 bold 深色

### 4.5 Badge / 状态

- `.label` `.badge` `.zonebadge`:`.glass(chip)` 胶囊,11px 600,padding 3px 10px
- 语义色统一 Apple 色板:green/orange/red/accent
- `.ifacebox`:20px 圆角玻璃卡,状态由左上角 3px 竖条表示
- `.cbi-progressbar`:胶囊 track `.glass(chip)`,fill 用 accent 渐变+右高光,百分比文字右侧

### 4.6 弹窗/提示

- `.modal`:`.glass(strong)` 居中卡,`border-radius: 24px`,max-width 560px
- `#modal_overlay` scrim:`rgba(0,0,0,.3)` + blur(12px)
- `.alert-message`:胶囊 `--r-control`,按语义 tint 色底,左 3px 色条
- `.cbi-page-actions`:底部固定玻璃 strong 条(macOS 保存面板风)
- LuCI toast:右上角胶囊玻璃通知,48px 高,slide-in
- `.cbi-tooltip`:`.glass(chip)` 小 chip 10px 圆角,带箭头

---

## 5. 登录页(macOS 锁屏风)

### 5.1 结构

```
[壁纸全屏 + 暗角]
         主机名 (SF Rounded 28px heavy, 白字, 阴影)
         时钟   (SF Rounded 48px ultralight, 白字, 阴影)
         圆形头像 (100px 圆, .glass(chip) + user icon svg)
         密码框  (280×44 胶囊, .glass(strong), 居中白字)
         提交按钮(同宽,Primary 蓝)
         错误提示(红 chip,淡入)
footer   LuCI / Argon 小字(11px 白半透)
```

### 5.2 动效

- 整块(时钟+头像+表单)入场:`opacity 0→1, translateY(10px→0)`,0.6s spring
- 文本阴影:`0 4px 30px rgba(0,0,0,.5)` 保证任意壁纸可读
- 移动端:键盘弹出时整块上移

---

## 6. 长尾组件全覆盖

| 类别 | 处理方式 |
|---|---|
| 导航/状态 | `.sidenav-toggler`, `#xhr_poll_status`, header 状态图标 → 28px 圆玻璃珠/胶囊 chip |
| 网络/防火墙 | `.ifacebox`, `.zonebadge`, `#iptables`, `.FireStatus`, `.ZoneForwards` → 圆角 20px 玻璃卡 + 左侧色条 + glass chip |
| 表格 | `.cbi-section-table` 表头 glass chip 化,zebra 用 `rgba(255,255,255,.35)`,hairline 分隔 |
| Dashboard tiles | `.glass(regular)`,数字用 SF Mono bold 突出 |
| 通知 toast | 右上 48px 胶囊玻璃,自动消失,slide-in |
| 终端/代码 | `pre.command-output`, `.commandbox` → `rgba(28,28,30,.75)` + 20px blur,圆角 14px,SF Mono |
| 滚动条 | 全局 WebKit scrollbar 6px 胶囊,`.glass(chip)` |
| 杂项 | `::selection` accent tint;`:autofill` 玻璃化;面包屑 `.t-secondary`;spinner 玻璃 chip 容纳;disabled 态 `.glass-thin` + opacity .4 |

---

## 7. 技术实现

### 7.1 LESS 模块化

新建 `less/liquid-glass/`:

```
less/
├── cascade.less            # 仅 @import 下面的层
├── dark.less               # 仅 @import dark 版本
├── liquid-glass/
│   ├── tokens.less         # 所有 CSS 变量定义(浅/深)
│   ├── mixins.less         # .glass(@level) .glass-button() .switch() 等
│   ├── surface.less        # body/壁纸/bokeh/glass-specular
│   ├── chrome.less         # toolbar/sidebar/header/footer
│   ├── cards.less          # .cbi-section / modal / panel
│   ├── controls.less       # button/input/select/checkbox/toggle/tab
│   ├── components.less     # badge/progress/ifacebox/table/tooltip/toast/terminal/scrollbar
│   ├── login.less          # 锁屏布局
│   ├── mobile.less         # ≤768px 覆盖
│   └── dark.less           # 深色模式所有 override(import 同名 .dark 规则)
```

- 删掉上次在编译后 `cascade.css`/`dark.css` 里直接手塞的 1800 行
- 编译用 `lessc` 输出到 `htdocs/luci-static/argon/css/`,提交编译产物(路由器不跑 lessc)
- 修掉上次 `less/liquid-glass.less` import 但文件不存在的问题

### 7.2 模板改动

- `ucode/template/themes/argon/header.ut`:
  - 插入 `<div class="bokeh-well">`、壁纸 layer 伪元素规则;
  - toolbar DOM 微调(去掉原外层包裹圆角 div);
  - sidebar 品牌区 brand pill 结构简化(去掉多余包裹);
  - `--accent` 变量依据用户主题色选项输出,支持 5 档预设;
  - 移除覆盖用户选色的硬编码 `--primary`。
- `ucode/template/themes/argon/header_login.ut`:按 §5 锁屏结构重写。
- `footer.ut`:收编进最后一张卡片内(若需要加 `<div class="section-footer">` 标识)。
- `sysauth.ut`:不改或仅小调。

### 7.3 JS

- 一段 ~30 行 tab 滑块脚本:监听 `.cbi-tabmenu` DOM(MutationObserver),给滑块元素设 transform/width,跟随 active tab;初次 load 与切换时 0.25s spring 过渡。
- 壁纸 onerror fallback: `body` 加 `data-bg-fallback` 类,隐藏 bg image。
- **不引入**壁纸取色、scroll refraction、复杂动画。

### 7.4 兼容/性能

- `@supports not (backdrop-filter: blur(1px))` fallback 到 `rgba(255,255,255,.96)`(浅)/`rgba(28,28,30,.96)`(深)。
- 动画元素 `will-change: transform`,其余不标,避免 GPU 爆炸。
- `backdrop-filter` 只在视觉容器上,不给子元素重复糊。
- `background-attachment: fixed` 实现 CSS-only parallax。
- `prefers-reduced-motion` 下禁用所有 transition/动画。

---

## 8. 验证标准

- [ ] 登录页:全屏壁纸,居中玻璃头像+胶囊密码框+大时钟,入场动效,任意壁纸上文字可读。
- [ ] 主 shell:toolbar 顶焊无圆角,sidebar 贴 L 形折弯,内容卡 20px 圆角悬浮,玻璃在壁纸上有可见的彩色折射。
- [ ] 所有 LuCI 主要页面(状态总览/网络/防火墙/系统/软件包/SSH 终端)均无老样式残留。
- [ ] 按钮/输入/开关/tab/checkbox/radio/dropdown 统一玻璃化,主按钮是 tint 蓝胶囊(不是实色块)。
- [ ] 5 档强调色切换全部 UI 即时变色,不留旧色块。
- [ ] Bing 每日壁纸、上传、内置三套壁纸源均正常工作,前后台共用。
- [ ] 深色模式玻璃独立配方(不发灰不发霓),toggle 切换平滑。
- [ ] 移动端 ≤768px 抽屉可用,卡/按钮/输入适配到位。
- [ ] LESS 可重新编译,产物与 hand-written CSS 一致(没有文件丢失/错的 import)。
- [ ] 老 WebKit(无 backdrop-filter)fallback 到不透明白/黑,功能可用。
