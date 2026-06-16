# macOS Sequoia Liquid Glass 重构 实施计划

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 把 luci-theme-argon 当前"半吊子 acrylic 版"重构为真正的 macOS Sequoia / iOS 26 液态玻璃质感,覆盖全部主要 LuCI 界面(登录页 + 主 shell + 控件 + 长尾组件),支持内置/上传/Bing 三种壁纸源,提供 5 档 Apple 系统强调色。

**Architecture:**
- 视觉系统以 CSS 变量 + LESS mixin 统一驱动,所有玻璃配方集中在 `less/liquid-glass/` 目录,按 token/surface/chrome/cards/controls/components/login/mobile/dark 拆分。
- 编译产物仍是 `cascade.css` / `dark.css`,OpenWrt 设备不感知变化。
- ucode 模板做最小 DOM 调整(header 焊顶布局、sidebar 简化品牌区、登录页改锁屏结构、强调色 5 档预设),复用 argon 现有壁纸后端逻辑,不动 Lua/OpenWrt 侧代码。
- ~30 行 JS 实现 tab 滑块动画 + 壁纸 fallback。

**Tech Stack:** LESS(lessc npm 包)、CSS(backdrop-filter、CSS vars、gradient、@supports fallback)、ucode 模板、vanilla JS、SVG(内置默认壁纸)。

---

## File map

**Create:**
- `less/liquid-glass/tokens.less` — CSS 变量定义(浅/深双色板、圆角、阴影、强调色)
- `less/liquid-glass/mixins.less` — `.glass(@level)`、`.glass-button(@variant)`、`.glass-pill()` 等 mixin
- `less/liquid-glass/surface.less` — body / 壁纸 / bokeh / glass specular 通用面规则
- `less/liquid-glass/chrome.less` — toolbar / sidebar / footer
- `less/liquid-glass/cards.less` — `.cbi-section` / modal / panel
- `less/liquid-glass/controls.less` — button / input / select / checkbox / radio / switch / dynlist / tab
- `less/liquid-glass/components.less` — badge / progress / ifacebox / table / tooltip / toast / terminal / scrollbar / dropdown / alerts
- `less/liquid-glass/login.less` — 锁屏布局
- `less/liquid-glass/mobile.less` — ≤768px 响应式
- `less/liquid-glass/dark.less` — 深色模式 override
- `htdocs/luci-static/argon/js/liquid-glass.js` — tab 滑块 + 壁纸 fallback JS
- `htdocs/luci-static/argon/background/default-abstract.svg` — 内置抽象液态壁纸
- `htdocs/luci-static/argon/background/default-graphite.svg` — 内置深灰图形壁纸

**Modify:**
- `less/cascade.less` — 把 `@import url("liquid-glass.less")` 换成 import 新目录下文件;删除顶部硬编码 Apple 蓝 override;保留既有 non-glass less
- `less/dark.less` — 把 `@import url("liquid-glass-dark.less")` 换成 import 新目录 dark 文件
- `less/layout.less` — `.main-left` / `.main-right` / `header` / footer 里可能与新布局冲突的旧定位/颜色用 less 注释标记,在 liquid-glass 文件里 override(不直接改 layout.less 避免破坏非 glass 主题)
- `htdocs/luci-static/argon/css/cascade.css` — 由 lessc 重新编译,**删掉** 上次手工注入的 4461-4990 行 mac 块(由 less 重新生成)
- `htdocs/luci-static/argon/css/dark.css` — 同上
- `ucode/template/themes/argon/header.ut` — 插入 bokeh div;输出 `--accent`/`--accent-dark` 5 档预设;移除硬编码 `--primary: #007aff`;加 script 引入 `liquid-glass.js`;调整 `.main-left` 内 brand 结构(去掉多余 pill);header bg-primary 类名保留(由 CSS 重皮)
- `ucode/template/themes/argon/header_login.ut` — 重写 body DOM 为锁屏结构(大时钟/头像/胶囊输入);同样引入 liquid-glass.js
- `ucode/template/themes/argon/footer.ut` — footer 加 `section-footer` 类以便 CSS 收编
- `.gitignore` — 加 `.superpowers/`

---

## Task 1:搭建 LESS 编译环境 + 清理旧 macOS 块

**Files:**
- Modify: `less/cascade.less`, `less/dark.less`
- Create: `less/liquid-glass/tokens.less`(placeholder)
- Modify: `htdocs/luci-static/argon/css/cascade.css`, `htdocs/luci-static/argon/css/dark.css`
- Modify: `.gitignore`

- [ ] **Step 1:安装 lessc**
  ```bash
  npm install -g less
  ```
  预期:`lessc --version` 打印 4.x 版本号。

- [ ] **Step 2:创建 tokens.less 占位文件**
  ```less
  // Liquid Glass design tokens — populated in Task 2
  // out: ../htdocs/luci-static/argon/css/cascade.css
  ```
  写入到 `less/liquid-glass/tokens.less`。

- [ ] **Step 3:改 cascade.less,把原来坏掉的 liquid-glass.less import 换成新目录**
  打开 `less/cascade.less` 第 2535 行,替换:
  ```less
  /* Liquid Glass theme (Sequoia / iOS 26) */
  @import url("liquid-glass/tokens.less");
  @import url("liquid-glass/mixins.less");
  @import url("liquid-glass/surface.less");
  @import url("liquid-glass/chrome.less");
  @import url("liquid-glass/cards.less");
  @import url("liquid-glass/controls.less");
  @import url("liquid-glass/components.less");
  @import url("liquid-glass/login.less");
  @import url("liquid-glass/mobile.less");
  ```
  其余 less 文件保持不动。

- [ ] **Step 4:改 dark.less**
  第 1243 行,替换:
  ```less
  /* Liquid Glass dark mode */
  @import url("liquid-glass/dark.less");
  ```

- [ ] **Step 5:创建所有占位 less 文件**
  ```bash
  for f in mixins surface chrome cards controls components login mobile; do
    echo "/* liquid-glass/${f}.less */" > less/liquid-glass/${f}.less
  done
  echo "/* liquid-glass/dark.less */" > less/liquid-glass/dark.less
  ```

- [ ] **Step 6:删除 cascade.css 上次手工注入的 mac 块**
  打开 `htdocs/luci-static/argon/css/cascade.css`,删除从 `/* macOS glass */` 注释起始至文件末尾 fallback 块的所有 glass 规则(约 4420-4990 行)。保留文件前面原始规则。
  同样处理 `dark.css`(删除其末尾的玻璃 dark 块,从约 950 行到文件末尾的 glass section)。
  然后在仓库根目录运行:
  ```bash
  cd /Users/dengpeng/Documents/Coding/luci-theme-argon
  lessc less/cascade.less htdocs/luci-static/argon/css/cascade.css
  lessc less/dark.less htdocs/luci-static/argon/css/dark.css
  ```
  预期:两条命令无错误输出,css 文件被重写,此时页面视觉退化回"原版 argon + 裸骨架"是正常的。

- [ ] **Step 7:把 .superpowers/ 加进 .gitignore**
  ```bash
  echo ".superpowers/" >> .gitignore
  ```

- [ ] **Step 8:提交**
  ```bash
  git add -A && git commit -m "chore(liquid-glass): set up LESS module scaffold and remove hardcoded mac block

- Adds less/liquid-glass/ skeleton with tokens/mixins/surface/chrome/
  cards/controls/components/login/mobile/dark modules
- Cascades cascade.less/dark.less to import from new directory
- Removes the hand-injected 1800-line glass CSS block so new LESS
  sources become the single source of truth
- Adds .superpowers/ to .gitignore

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
  ```

---

## Task 2:填充 tokens.less 和 mixins.less — 玻璃配方核心

**Files:**
- Modify: `less/liquid-glass/tokens.less`
- Modify: `less/liquid-glass/mixins.less`

- [ ] **Step 1:把 token 变量写入 tokens.less**
  内容严格如下(浅色作为 `:root` 默认,深色由 dark.less override):
  ```less
  /* =========================================================
   * Liquid Glass Tokens (light)
   * ========================================================= */
  :root {
    /* —— Accent palette (Apple system colors) —— */
    --accent:         #007aff;
    --accent-dark:    #0a84ff;
    --accent-tint:    rgba(0, 122, 255, .12);
    --accent-soft:    rgba(0, 122, 255, .25);

    --sem-red:        #ff3b30;
    --sem-orange:     #ff9500;
    --sem-green:      #34c759;
    --sem-yellow:     #ffcc00;
    --sem-purple:     #af52de;
    --sem-pink:       #ff2d55;

    /* —— Glass fills (180deg three-stop gradient trick) —— */
    --fill-strong:    linear-gradient(180deg, rgba(255,255,255,.62) 0%, rgba(255,255,255,.38) 45%, rgba(255,255,255,.52) 100%);
    --fill-regular:   linear-gradient(180deg, rgba(255,255,255,.50) 0%, rgba(255,255,255,.28) 45%, rgba(255,255,255,.42) 100%);
    --fill-thin:      linear-gradient(180deg, rgba(255,255,255,.40) 0%, rgba(255,255,255,.18) 45%, rgba(255,255,255,.30) 100%);
    --fill-chip:      linear-gradient(180deg, rgba(255,255,255,.88) 0%, rgba(255,255,255,.58) 100%);

    /* —— Blur —— */
    --blur-strong:    32px;
    --blur-regular:   24px;
    --blur-light:     16px;
    --saturate:       saturate(200%);

    /* —— Specular —— */
    --spec-top:       inset 0 1px 0 rgba(255,255,255,.9);
    --spec-hi:        inset 0 .5px 0 rgba(255,255,255,.6), inset 0 18px 30px rgba(255,255,255,.15);
    --edge-bottom:    inset 0 -1px 0 rgba(0,0,0,.06);

    /* —— Contact shadow —— */
    --contact:        0 1px 0 rgba(0,0,0,.05), 0 8px 24px rgba(0,0,0,.08);
    --contact-lift:   0 2px 0 rgba(0,0,0,.06), 0 14px 32px rgba(0,0,0,.12);

    /* —— Radius —— */
    --r-chrome:       22px;
    --r-card:         20px;
    --r-control:      14px;
    --r-pill:         999px;

    /* —— Text —— */
    --t-primary:      #1d1d1f;
    --t-secondary:    #6e6e73;
    --t-tertiary:     #8e8e93;

    /* —— Typography —— */
    --font-sans:      -apple-system, BlinkMacSystemFont, "SF Pro Text", "SF Pro Display", "SF Pro Rounded", "Helvetica Neue", "PingFang SC", "Microsoft Yahei", system-ui, sans-serif;
    --font-mono:      "SF Mono", ui-monospace, Menlo, Consolas, monospace;

    /* —— Hairline —— */
    --hairline:       rgba(60,60,67,.12);
  }
  ```

- [ ] **Step 2:填充 mixins.less**
  ```less
  // Mixins assume `less-plugin-glsl` not needed; plain CSS
  .glass-level(strong)  { background: var(--fill-strong);  -webkit-backdrop-filter: blur(var(--blur-strong)) var(--saturate); backdrop-filter: blur(var(--blur-strong)) var(--saturate); }
  .glass-level(regular) { background: var(--fill-regular); -webkit-backdrop-filter: blur(var(--blur-regular)) var(--saturate); backdrop-filter: blur(var(--blur-regular)) var(--saturate); }
  .glass-level(thin)    { background: var(--fill-thin);    -webkit-backdrop-filter: blur(var(--blur-regular)) var(--saturate); backdrop-filter: blur(var(--blur-regular)) var(--saturate); }
  .glass-level(chip)    { background: var(--fill-chip);    -webkit-backdrop-filter: blur(var(--blur-light)) var(--saturate); backdrop-filter: blur(var(--blur-light)) var(--saturate); }

  .glass(@level: regular) {
    .glass-level(@level);
    border: none;
    box-shadow: var(--spec-top), var(--edge-bottom), var(--contact);
  }

  .glass-lift() {
    box-shadow: var(--spec-top), var(--edge-bottom), var(--contact-lift);
    transform: translateY(-1px);
  }

  .glass-button() {
    .glass(chip);
    display: inline-flex; align-items: center; justify-content: center; gap: 6px;
    height: 34px; padding: 0 18px;
    border-radius: var(--r-pill);
    font-weight: 600; font-size: 13px;
    color: var(--t-primary);
    cursor: pointer;
    transition: transform .18s ease, box-shadow .18s ease, background .18s ease;
    text-decoration: none;
    &:hover { .glass-lift(); }
    &:active { transform: translateY(0); box-shadow: var(--spec-top), var(--edge-bottom); }
  }

  .glass-button-primary() {
    background: linear-gradient(180deg, var(--accent) 0%, color-mix(in srgb, var(--accent) 90%, black) 100%);
    color: #fff;
    border-radius: var(--r-pill);
    height: 34px; padding: 0 20px;
    display: inline-flex; align-items: center; justify-content: center; gap: 6px;
    font-weight: 700; font-size: 13px;
    border: none;
    cursor: pointer;
    box-shadow: 0 6px 16px color-mix(in srgb, var(--accent) 40%, transparent), var(--spec-top), inset 0 -1px 0 rgba(0,0,0,.15);
    transition: transform .18s ease, box-shadow .18s ease, filter .18s ease;
    &:hover { filter: brightness(1.05); transform: translateY(-2px); }
    &:active { transform: translateY(0); box-shadow: 0 2px 6px color-mix(in srgb, var(--accent) 40%, transparent); }
  }

  .glass-button-danger() {
    background: linear-gradient(180deg, var(--sem-red) 0%, color-mix(in srgb, var(--sem-red) 85%, black) 100%);
    color: #fff;
    border-radius: var(--r-pill);
    height: 34px; padding: 0 20px;
    display: inline-flex; align-items: center; justify-content: center; gap: 6px;
    font-weight: 700; font-size: 13px;
    border: none; cursor: pointer;
    box-shadow: 0 6px 16px color-mix(in srgb, var(--sem-red) 40%, transparent), var(--spec-top), inset 0 -1px 0 rgba(0,0,0,.15);
    transition: transform .18s ease, filter .18s ease;
    &:hover { filter: brightness(1.05); transform: translateY(-2px); }
    &:active { transform: translateY(0); }
  }
  ```
  *注意: `color-mix()` 是现代浏览器(Chromium 111+, Safari 16.2+, Firefox 113+)原生函数。对老路由器浏览器在 fallback 类里提供硬编码颜色即可(在 surface.less 的 @supports not 块)。*

- [ ] **Step 3:编译验证**
  ```bash
  lessc less/cascade.less htdocs/luci-static/argon/css/cascade.css
  ```
  预期:无错误。此时页面视觉上仍几乎不变(mixin 只定义不调用)。

- [ ] **Step 4:提交**
  ```bash
  git add less/liquid-glass/tokens.less less/liquid-glass/mixins.less htdocs/luci-static/argon/css/cascade.css
  git commit -m "feat(liquid-glass): add design tokens and glass mixins

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
  ```

---

## Task 3:surface.less — 壁纸层、body、bokeh、fallback、全局基础

**Files:**
- Modify: `less/liquid-glass/surface.less`

- [ ] **Step 1:写 surface.less**
  内容覆盖:body 字体/wallpaper stack、`.logged-in` body 的三层背景(user wallpaper → tint → bokeh),登录页不加 tint,specular 伪元素通用 class,无 backdrop-filter 的 fallback,滚动条全局样式,选区色,autofill 修正,reduced-motion。
  写入以下内容(完整):
  ```less
  /* =========================================================
   * Surface: body, wallpaper stack, bokeh, specular, fallback
   * ========================================================= */

  html, body {
    font-family: var(--font-sans);
    -webkit-font-smoothing: antialiased;
    text-rendering: optimizeLegibility;
    color: var(--t-primary);
  }

  body.logged-in {
    min-height: 100vh;
    background-color: #f5f5f7;
    background-image: var(--user-wallpaper, none);
    background-size: cover;
    background-position: center;
    background-attachment: fixed;
    background-repeat: no-repeat;
    position: relative;
    overflow-x: hidden;
  }

  /* Tint + bokeh layered under everything via ::after pseudo */
  body.logged-in::after {
    content: "";
    position: fixed;
    inset: 0;
    pointer-events: none;
    z-index: 0;
    background:
      radial-gradient(ellipse 60% 40% at 15% 10%, color-mix(in srgb, var(--accent) 20%, transparent), transparent 60%),
      radial-gradient(ellipse 50% 45% at 85% 20%, rgba(123,200,255,.28), transparent 60%),
      radial-gradient(ellipse 55% 50% at 60% 90%, rgba(199,176,255,.22), transparent 60%),
      radial-gradient(ellipse 40% 35% at 20% 80%, rgba(255,180,123,.22), transparent 60%),
      linear-gradient(180deg, rgba(255,255,255,.35), rgba(255,255,255,.50));
    background-blend-mode: screen, screen, screen, screen, normal;
  }

  /* Bokeh well div injected by header.ut sits under content */
  body.logged-in > .main > .bokeh-well { display: none; } /* unused; keeping hook */

  /* All glass children sit above tint */
  body.logged-in .main,
  body.logged-in .main-left,
  body.logged-in .main-right,
  body.logged-in header,
  body.logged-in .cbi-section,
  body.logged-in .modal,
  body.logged-in .alert-message { position: relative; z-index: 1; }

  /* ——— specular highlight helper: apply to glass containers ——— */
  .has-specular::before {
    content: "";
    position: absolute;
    top: 0; left: 8px; right: 8px;
    height: 45%;
    border-radius: inherit;
    background: linear-gradient(180deg, rgba(255,255,255,.5), transparent);
    pointer-events: none;
    z-index: 0;
  }
  .has-specular > * { position: relative; z-index: 1; }

  /* ——— Scrollbar ——— */
  ::-webkit-scrollbar { width: 8px; height: 8px; }
  ::-webkit-scrollbar-track { background: transparent; }
  ::-webkit-scrollbar-thumb {
    background: linear-gradient(180deg, rgba(255,255,255,.8), rgba(255,255,255,.45));
    border-radius: 999px;
    box-shadow: inset 0 1px 0 rgba(255,255,255,.8);
  }
  ::-webkit-scrollbar-thumb:hover { background: rgba(120,120,128,.35); }

  /* ——— Selection ——— */
  ::selection { background: color-mix(in srgb, var(--accent) 25%, transparent); color: var(--t-primary); }

  /* ——— Autofill ——— */
  input:-webkit-autofill,
  input:-webkit-autofill:hover,
  input:-webkit-autofill:focus {
    -webkit-text-fill-color: var(--t-primary);
    -webkit-box-shadow: 0 0 0 1000px rgba(255,255,255,.6) inset;
    caret-color: var(--t-primary);
    transition: background-color 5000s ease-in-out 0s;
    border-radius: var(--r-pill);
  }

  /* ——— Spinner/poll chip ——— */
  #xhr_poll_status {
    display: inline-flex; align-items: center; height: 24px; padding: 0 10px;
    border-radius: 999px; font-size: 11px; font-weight: 600;
    background: var(--fill-chip); backdrop-filter: blur(var(--blur-light)) var(--saturate);
    -webkit-backdrop-filter: blur(var(--blur-light)) var(--saturate);
    box-shadow: var(--spec-top);
    color: var(--t-secondary);
    &.on  { color: var(--sem-green); }
    &.off { color: var(--sem-red); }
  }

  /* ——— Fallback for no backdrop-filter ——— */
  @supports not ((backdrop-filter: blur(1px)) or (-webkit-backdrop-filter: blur(1px))) {
    body.logged-in::after { background: rgba(255,255,255,.9); }
    .main-left, header, .cbi-section, .modal, .cbi-dropdown ul.dropdown {
      background: rgba(255,255,255,.96) !important;
      backdrop-filter: none !important; -webkit-backdrop-filter: none !important;
    }
  }

  /* ——— Reduced motion ——— */
  @media (prefers-reduced-motion: reduce) {
    *, *::before, *::after {
      animation-duration: .01ms !important;
      transition-duration: .01ms !important;
    }
  }
  ```
  注意: `.logged-in` 是 header.ut 里 body 已带的 class(已验证存在: `class="lang_{{ dispatcher.lang }} ... {% if (ctx.authsession): %}logged-in{% endif %}"`)。

- [ ] **Step 2:编译并检查 css 输出**
  ```bash
  lessc less/cascade.less htdocs/luci-static/argon/css/cascade.css
  grep -c "bokeh-well\|--fill-strong\|-webkit-backdrop-filter" htdocs/luci-static/argon/css/cascade.css
  ```
  预期输出一个 ≥3 的数字(规则已编译进)。

- [ ] **Step 3:提交**
  ```bash
  git add less/liquid-glass/surface.less htdocs/luci-static/argon/css/cascade.css
  git commit -m "feat(liquid-glass): body wallpaper stack, bokeh, fallback, scrollbar, selection

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
  ```

---

## Task 4:chrome.less — toolbar + sidebar + footer 焊边布局

**Files:**
- Modify: `less/liquid-glass/chrome.less`

- [ ] **Step 1:写 chrome.less**
  ```less
  /* =========================================================
   * Chrome: layout shell (sidebar + top toolbar + footer)
   * WELDED layout: toolbar pinned to top (no radius), sidebar
   * pinned left with bottom-right 22px radius, L-shaped glass.
   * ========================================================= */

  body.logged-in {
    .main {
      position: relative; z-index: 1;
      display: block; /* override flex, use absolute positioning */
    }

    /* ---------- Sidebar (welded left) ---------- */
    .main-left {
      position: fixed;
      top: 52px; left: 0; bottom: 0;
      width: 240px;
      margin: 0;
      padding: 14px 12px;
      height: auto;
      border-radius: 0 var(--r-chrome) var(--r-chrome) 0;
      .glass(strong);
      box-shadow: var(--spec-top), var(--edge-bottom),
                 8px 0 24px rgba(0,0,0,.06),
                 inset 1px 0 0 rgba(255,255,255,.5);
      overflow-y: auto; overflow-x: hidden;
      background: var(--fill-strong);
      -webkit-backdrop-filter: blur(var(--blur-strong)) var(--saturate);
      backdrop-filter: blur(var(--blur-strong)) var(--saturate);
      transition: transform .3s cubic-bezier(.2,.8,.2,1);
      z-index: 100;
      /* Remove the top specular so it looks connected to toolbar */
      box-shadow: var(--edge-bottom), 8px 0 24px rgba(0,0,0,.06), inset 1px 0 0 rgba(255,255,255,.35);
    }

    /* Brand block: simplify, no separate pill */
    .main-left .sidenav-header {
      padding: 6px 10px 14px;
      display: flex; align-items: center; gap: 10px;
      .brand {
        margin: 0 !important;
        font-family: var(--font-sans);
        font-size: 18px;
        font-weight: 800;
        letter-spacing: .2px;
        color: var(--t-primary) !important;
        background: none !important;
        border: none !important;
        box-shadow: none !important;
        text-align: left;
        &::before { content: "🪟 "; font-size: 20px; }
      }
      .ml-auto { margin-left: auto; }
    }

    /* Nav items */
    .main-left .nav { margin-top: 4px; }
    .main-left .nav > li > a,
    .main-left .nav > li > a:first-child {
      display: flex; align-items: center;
      margin: 2px 4px;
      padding: 0 12px 0 14px;
      height: 38px;
      border-radius: 12px;
      font-size: 14px; font-weight: 500;
      color: var(--t-secondary);
      background: transparent;
      position: relative;
      transition: all .18s ease;
      text-decoration: none;
      &:hover {
        color: var(--t-primary);
        background: var(--fill-chip);
        backdrop-filter: blur(var(--blur-light)) var(--saturate);
        -webkit-backdrop-filter: blur(var(--blur-light)) var(--saturate);
        transform: translateX(2px);
      }
      &.active {
        color: var(--accent);
        font-weight: 700;
        background: var(--accent-tint);
        box-shadow: inset 3px 0 0 var(--accent);
        &::before { color: var(--accent) !important; }
      }
      &.active::after { color: var(--accent) !important; }
    }

    /* Submenu items */
    .main-left .nav > li.slide .slide-menu {
      padding: 4px 0;
      li a {
        display: block;
        padding: 6px 14px 6px 38px;
        font-size: 13px;
        color: var(--t-secondary);
        border-radius: 10px;
        margin: 1px 6px;
        &:hover { background: var(--fill-thin); color: var(--t-primary); }
        &.active {
          color: var(--accent);
          font-weight: 700;
          background: var(--accent-tint);
          &::before {
            content: "•";
            position: absolute; left: 22px;
            color: var(--accent); font-weight: bold;
          }
        }
      }
    }

    /* Sidebar scrollbar */
    .main-left::-webkit-scrollbar { width: 6px; }
    .main-left::-webkit-scrollbar-thumb {
      background: linear-gradient(180deg, rgba(0,0,0,.15), rgba(0,0,0,.08));
      border-radius: 999px;
    }
    .main-left::-webkit-scrollbar-track { background: transparent; }

    /* Sidenav toggler in sidebar (desktop pin) */
    .sidenav-toggler {
      width: 28px; height: 28px; border-radius: 50%;
      display: inline-flex; align-items: center; justify-content: center;
      background: var(--fill-chip);
      backdrop-filter: blur(var(--blur-light));
      -webkit-backdrop-filter: blur(var(--blur-light));
      box-shadow: var(--spec-top);
      cursor: pointer;
      &:hover { background: var(--fill-strong); }
      .sidenav-toggler-line {
        display: block; width: 12px; height: 1.5px; margin: 2px 0;
        background: var(--t-secondary); border-radius: 2px;
      }
    }

    /* ---------- Right column ---------- */
    .main-right {
      position: absolute;
      top: 0; left: 240px; right: 0; bottom: 0;
      margin: 0;
      display: flex; flex-direction: column;
      overflow: hidden;
    }

    /* ---------- Toolbar (welded top) ---------- */
    header, header.bg-primary {
      position: sticky;
      top: 0; left: 0; right: 0;
      width: 100%;
      height: 52px;
      z-index: 90;
      padding: 0;
      background: var(--fill-strong) !important;
      background-color: transparent !important;
      -webkit-backdrop-filter: blur(var(--blur-strong)) var(--saturate);
      backdrop-filter: blur(var(--blur-strong)) var(--saturate);
      border-radius: 0;
      box-shadow: var(--spec-top), 0 1px 0 rgba(0,0,0,.06);
      color: var(--t-primary);
      overflow: visible;
      &::after { display: none; } /* remove old primary color block */
    }
    header .fill {
      padding: 0 20px;
      height: 52px;
      display: flex; align-items: center; gap: 16px;
    }
    header .container {
      width: 100%; max-width: none;
      display: flex; align-items: center; gap: 12px;
      .flex1 { flex: 1; display: flex; align-items: center; gap: 14px; }
    }
    header .brand {
      font-family: var(--font-sans);
      font-weight: 700; font-size: 17px;
      color: var(--t-primary);
      letter-spacing: -.2px;
      text-decoration: none;
    }
    header .showSide {
      display: none; /* only on mobile */
    }
    /* toolbar decorative sheen */
    header .fill::after {
      content: ""; position: absolute; right: 10%; top: 0;
      width: 120px; height: 100%;
      background: linear-gradient(90deg, transparent, rgba(255,255,255,.4), transparent);
      pointer-events: none;
    }

    /* ---------- Main content ---------- */
    .main-right > #maincontent {
      flex: 1;
      overflow-y: auto;
      padding: 20px;
      position: relative;
    }
    .main-right > #maincontent > .container {
      margin: 0;
      display: flex; flex-direction: column; gap: 16px;
      max-width: none;
      position: relative;
      padding-bottom: 20px;
    }

    /* ---------- Footer (pulled into last card) ---------- */
    footer.mobile-hide {
      position: relative;
      width: 100%;
      padding: 18px 0 4px;
      text-align: right;
      background: none !important;
      border: none;
      color: var(--t-tertiary);
      .footer-content {
        font-size: 11px;
        display: inline-flex; flex-wrap: wrap; gap: 8px; align-items: center;
        a { color: var(--t-tertiary); text-decoration: none; &:hover { color: var(--accent); } }
        .footer-separator { opacity: .3; }
      }
    }

    /* ---------- Dark mask (mobile overlay) ---------- */
    .darkMask {
      display: none;
      &.show { display: block; }
      position: fixed; inset: 0; background: rgba(0,0,0,.3);
      backdrop-filter: blur(4px); -webkit-backdrop-filter: blur(4px);
      z-index: 95;
    }
  }
  ```

- [ ] **Step 2:编译验证**
  ```bash
  lessc less/cascade.less htdocs/luci-static/argon/css/cascade.css
  ```
  预期无错。此时跑起来应该看到 toolbar 焊顶 + sidebar 焊左 + 玻璃已生效(但控件/内容卡尚未 glass 化)。

- [ ] **Step 3:提交**
  ```bash
  git add less/liquid-glass/chrome.less htdocs/luci-static/argon/css/cascade.css
  git commit -m "feat(liquid-glass): welded chrome — toolbar + sidebar L-shaped glass

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
  ```

---

## Task 5:cards.less — 内容卡/弹窗/段落

**Files:**
- Modify: `less/liquid-glass/cards.less`

- [ ] **Step 1:写 cards.less**
  ```less
  /* =========================================================
   * Cards, modals, sections, tab containers
   * ========================================================= */
  body.logged-in {
    /* ---------- Section cards ---------- */
    .cbi-section, .cbi-section-error, #iptables, .FireStatus, .ZoneForwards,
    .cbi-map, .cbi-section-table, .cbi-section-form, .cbi-section-named,
    .Dashboard .settings-info, .dashboard-bg {
      .glass(regular);
      background: var(--fill-regular);
      border-radius: var(--r-card);
      padding: 22px 24px;
      position: relative;
      overflow: hidden;
    }
    .cbi-section::before, .cbi-map::before {
      content: ""; position: absolute;
      top: 0; left: 10px; right: 10px; height: 35%;
      background: linear-gradient(180deg, rgba(255,255,255,.3), transparent);
      pointer-events: none;
      border-radius: var(--r-card) var(--r-card) 50% 50%;
    }
    .cbi-section > * { position: relative; z-index: 1; }

    /* Nested sections: thin glass */
    .cbi-section .cbi-section, .cbi-modal .cbi-section {
      background: var(--fill-thin);
      backdrop-filter: blur(var(--blur-regular)) var(--saturate);
      -webkit-backdrop-filter: blur(var(--blur-regular)) var(--saturate);
      border-radius: var(--r-control);
      box-shadow: var(--spec-top);
      padding: 14px 18px;
      margin: 8px 0;
    }

    /* Section titles */
    .cbi-section h2, .cbi-section h3, .cbi-map h2, .cbi-section > h3 {
      font-family: var(--font-sans);
      font-weight: 800; font-size: 22px;
      color: var(--t-primary);
      margin: 0 0 16px;
      display: flex; align-items: center; gap: 10px;
      &::before {
        content: ""; display: inline-block;
        width: 6px; height: 20px; border-radius: 3px;
        background: var(--accent);
      }
    }

    /* Tabs */
    .cbi-tabmenu, .tabs {
      display: inline-flex; padding: 3px; margin-bottom: 18px;
      border-radius: 999px;
      background: var(--fill-regular);
      backdrop-filter: blur(var(--blur-regular)) var(--saturate);
      -webkit-backdrop-filter: blur(var(--blur-regular)) var(--saturate);
      box-shadow: var(--spec-top), var(--contact);
      position: relative;
      li, > li, .tab {
        display: inline-block;
        a, & > a {
          display: inline-block;
          padding: 7px 18px; border-radius: 999px;
          font-size: 13px; font-weight: 600;
          color: var(--t-secondary);
          transition: color .18s ease;
          text-decoration: none;
        }
        &.active a, &.active > a, a.active {
          color: var(--t-primary);
        }
      }
      /* Slider — moved by JS via --tab-left / --tab-width */
      &::before {
        content: ""; position: absolute;
        top: 3px; left: var(--tab-left, 3px);
        width: var(--tab-width, 60px); height: calc(100% - 6px);
        border-radius: 999px;
        background: linear-gradient(180deg, #fff, #ebebf5);
        box-shadow: 0 2px 6px rgba(0,0,0,.12), 0 1px 0 rgba(255,255,255,1) inset;
        transition: transform .28s cubic-bezier(.2,.8,.2,1), width .28s cubic-bezier(.2,.8,.2,1);
        z-index: 0;
        pointer-events: none;
      }
      .tab, li, > li { position: relative; z-index: 1; }
    }

    /* ---------- Modal ---------- */
    .modal {
      .glass(strong);
      border-radius: 24px;
      padding: 28px;
      max-width: 560px;
    }
    #modal_overlay {
      position: fixed; inset: 0;
      background: rgba(0,0,0,.3);
      backdrop-filter: blur(12px); -webkit-backdrop-filter: blur(12px);
      z-index: 200;
      display: flex; align-items: center; justify-content: center;
    }

    /* ---------- Alerts ---------- */
    .alert-message, .alert, .notice {
      border-radius: var(--r-control);
      padding: 14px 18px;
      margin: 0 0 14px;
      backdrop-filter: blur(var(--blur-light)); -webkit-backdrop-filter: blur(var(--blur-light));
      position: relative;
      h4 { margin-top: 0; font-weight: 700; font-size: 14px; }
      p { margin-bottom: 0; font-size: 13px; }
    }
    .alert-message.success, .notice.success, .success {
      background: linear-gradient(180deg, color-mix(in srgb, var(--sem-green) 22%, rgba(255,255,255,.6)), color-mix(in srgb, var(--sem-green) 10%, rgba(255,255,255,.3)));
      box-shadow: var(--spec-top), inset 3px 0 0 var(--sem-green);
      color: color-mix(in srgb, var(--sem-green) 70%, black);
    }
    .alert-message.warning, .notice.warning, .warning {
      background: linear-gradient(180deg, color-mix(in srgb, var(--sem-orange) 25%, rgba(255,255,255,.6)), color-mix(in srgb, var(--sem-orange) 12%, rgba(255,255,255,.3)));
      box-shadow: var(--spec-top), inset 3px 0 0 var(--sem-orange);
      color: color-mix(in srgb, var(--sem-orange) 70%, black);
    }
    .alert-message.error, .notice.danger, .danger, .error {
      background: linear-gradient(180deg, color-mix(in srgb, var(--sem-red) 22%, rgba(255,255,255,.6)), color-mix(in srgb, var(--sem-red) 10%, rgba(255,255,255,.3)));
      box-shadow: var(--spec-top), inset 3px 0 0 var(--sem-red);
      color: color-mix(in srgb, var(--sem-red) 70%, black);
    }

    /* ---------- Page action bar (save/reset row) ---------- */
    .cbi-page-actions {
      position: sticky; bottom: 0;
      margin: 20px -24px -22px;
      padding: 14px 24px;
      background: linear-gradient(180deg, rgba(255,255,255,0) 0%, rgba(255,255,255,.6) 30%, rgba(255,255,255,.85) 100%);
      backdrop-filter: blur(20px); -webkit-backdrop-filter: blur(20px);
      border-radius: 0 0 var(--r-card) var(--r-card);
      display: flex; gap: 10px; align-items: center; flex-wrap: wrap;
    }
  }
  ```

- [ ] **Step 2:编译验证**
  ```bash
  lessc less/cascade.less htdocs/luci-static/argon/css/cascade.css
  ```

- [ ] **Step 3:提交**
  ```bash
  git add less/liquid-glass/cards.less htdocs/luci-static/argon/css/cascade.css
  git commit -m "feat(liquid-glass): section cards, modals, alerts, segmented tab rail

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
  ```

---

## Task 6:controls.less — 按钮/输入/开关/下拉

**Files:**
- Modify: `less/liquid-glass/controls.less`

- [ ] **Step 1:写 controls.less**
  ```less
  /* =========================================================
   * Controls: buttons, inputs, selects, toggles, checkboxes, dynlists
   * ========================================================= */
  body.logged-in {
    /* ---------- Buttons ---------- */
    .btn, .cbi-button, button, input[type="submit"], input[type="button"], input[type="reset"] {
      border-radius: var(--r-pill) !important;
      font-weight: 600;
      height: 34px; padding: 0 18px;
      font-size: 13px;
      border: none !important;
      cursor: pointer;
      display: inline-flex; align-items: center; justify-content: center; gap: 6px;
      transition: transform .18s ease, box-shadow .18s ease, filter .18s ease;
      text-shadow: none !important;
      background-image: none !important;
      line-height: 1;
      &:not(.cbi-button-apply):not(.cbi-button-save):not(.save):not(.cbi-button-positive):not(.cbi-button-action):not(.cbi-button-remove):not(.cbi-button-reset):not(.cbi-button-cancel) {
        background: var(--fill-chip);
        color: var(--t-primary);
        box-shadow: var(--spec-top), var(--edge-bottom), var(--contact);
        backdrop-filter: blur(var(--blur-light)) var(--saturate);
        -webkit-backdrop-filter: blur(var(--blur-light)) var(--saturate);
        &:hover { .glass-lift(); color: var(--accent); }
      }
    }

    /* Primary */
    .cbi-button-apply, .cbi-button-save, .cbi-button-positive, .cbi-button-action, .btn-primary, .save,
    input[type="submit"] {
      background: linear-gradient(180deg, var(--accent) 0%, color-mix(in srgb, var(--accent) 85%, black) 100%) !important;
      color: #fff !important;
      font-weight: 700 !important;
      padding: 0 20px !important;
      box-shadow: 0 6px 16px color-mix(in srgb, var(--accent) 40%, transparent), var(--spec-top), inset 0 -1px 0 rgba(0,0,0,.15) !important;
      &:hover { filter: brightness(1.06); transform: translateY(-2px); }
      &:active { transform: translateY(0); box-shadow: 0 2px 6px color-mix(in srgb, var(--accent) 40%, transparent), var(--spec-top) !important; }
    }

    /* Danger */
    .cbi-button-remove, .cbi-button-negative, .btn-danger, .reset {
      background: linear-gradient(180deg, var(--sem-red) 0%, color-mix(in srgb, var(--sem-red) 85%, black) 100%) !important;
      color: #fff !important; font-weight: 700 !important;
      padding: 0 18px !important;
      box-shadow: 0 6px 16px color-mix(in srgb, var(--sem-red) 40%, transparent), var(--spec-top), inset 0 -1px 0 rgba(0,0,0,.15) !important;
      &:hover { filter: brightness(1.06); transform: translateY(-2px); }
    }

    /* Neutral/secondary (reset, cancel, edit neutral) */
    .cbi-button-reset, .cbi-button-cancel, .cbi-button-edit, .cbi-button-add, .cbi-button-fieldadd {
      background: var(--fill-chip) !important;
      color: var(--t-primary) !important;
      box-shadow: var(--spec-top), var(--edge-bottom), var(--contact) !important;
      backdrop-filter: blur(var(--blur-light)) var(--saturate);
      -webkit-backdrop-filter: blur(var(--blur-light)) var(--saturate);
      &:hover { .glass-lift(); }
    }

    /* Link style */
    .cbi-button-link {
      background: transparent !important;
      box-shadow: none !important;
      color: var(--accent) !important;
      padding: 0 8px !important;
      &:hover { text-decoration: underline; transform: none; }
    }

    /* Disabled */
    .btn:disabled, .btn[disabled], .cbi-button:disabled, .cbi-button[disabled],
    .btn[aria-disabled="true"], .cbi-button[aria-disabled="true"], .btn.disabled, .cbi-button.disabled {
      background: linear-gradient(180deg, rgba(255,255,255,.5), rgba(255,255,255,.2)) !important;
      color: var(--t-tertiary) !important;
      box-shadow: var(--spec-top) !important;
      cursor: not-allowed;
      opacity: .6;
      transform: none !important; filter: none !important;
    }

    /* Icon buttons */
    .cbi-button > i, .btn > i { margin-right: 4px; }

    /* ---------- Inputs ---------- */
    input[type="text"], input[type="password"], input[type="number"], input[type="email"],
    input[type="search"], input[type="url"], input[type="tel"],
    select, textarea, .cbi-input-text input, .cbi-input-password input {
      font-family: inherit; font-size: 13px;
      height: 36px; padding: 0 16px;
      border-radius: var(--r-pill);
      background: var(--fill-chip);
      backdrop-filter: blur(var(--blur-light)) var(--saturate);
      -webkit-backdrop-filter: blur(var(--blur-light)) var(--saturate);
      border: none;
      box-shadow: var(--spec-top), var(--edge-bottom), 0 2px 6px rgba(0,0,0,.04);
      color: var(--t-primary);
      transition: box-shadow .18s ease, transform .18s ease;
      width: auto; max-width: 100%;
      outline: none;
      &::placeholder { color: var(--t-tertiary); }
      &:focus {
        box-shadow: 0 0 0 4px var(--accent-soft), var(--spec-top), var(--edge-bottom);
      }
    }
    textarea {
      height: auto; min-height: 90px; padding: 12px 16px;
      border-radius: var(--r-control); line-height: 1.5;
    }
    select {
      -webkit-appearance: none; appearance: none;
      padding-right: 36px;
      background-image: url("data:image/svg+xml;utf8,<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 12 8' fill='none' stroke='%236e6e73' stroke-width='2' stroke-linecap='round'><polyline points='1,1 6,7 11,1'/></svg>");
      background-repeat: no-repeat; background-position: right 12px center;
      background-size: 10px 7px;
    }

    /* cbi-value-field wrapper */
    .cbi-value-field input, .cbi-value-field select, .cbi-value-field textarea {
      width: 100%; max-width: 28rem;
    }

    /* ---------- Dropdown ---------- */
    .cbi-dropdown > ul.dropdown, .dropdown-menu, .dropdown {
      border-radius: var(--r-control) !important;
      background: var(--fill-strong) !important;
      backdrop-filter: blur(var(--blur-regular)) var(--saturate);
      -webkit-backdrop-filter: blur(var(--blur-regular)) var(--saturate);
      border: none;
      box-shadow: var(--spec-top), var(--contact-lift);
      padding: 6px !important;
      li {
        border-radius: 10px;
        padding: 0 12px; height: 36px; display: flex; align-items: center;
        font-size: 13px; color: var(--t-primary);
        transition: background .15s;
        &:hover, &.focus, &[selected], &.selected {
          background: var(--accent-tint);
          color: var(--accent);
        }
        a { color: inherit; text-decoration: none; display: block; }
      }
    }

    /* ---------- Checkbox / Radio ---------- */
    input[type="checkbox"], .cbi-input-checkbox input[type="checkbox"] {
      appearance: none; -webkit-appearance: none;
      width: 20px; height: 20px;
      border-radius: 6px;
      background: var(--fill-chip);
      border: 1px solid rgba(0,0,0,.1);
      box-shadow: var(--spec-top), var(--edge-bottom);
      cursor: pointer; position: relative;
      transition: all .18s ease;
      &:checked {
        background: var(--accent);
        border-color: transparent;
        &::after {
          content: ""; position: absolute;
          left: 6px; top: 2px;
          width: 6px; height: 11px;
          border: solid #fff; border-width: 0 2px 2px 0;
          transform: rotate(45deg);
        }
      }
      &:focus { box-shadow: 0 0 0 4px var(--accent-soft); }
    }
    input[type="radio"] {
      appearance: none; -webkit-appearance: none;
      width: 20px; height: 20px; border-radius: 50%;
      background: var(--fill-chip); border: 1px solid rgba(0,0,0,.1);
      box-shadow: var(--spec-top); cursor: pointer; position: relative;
      &:checked {
        border-color: var(--accent);
        &::after { content: ""; position: absolute; inset: 4px; border-radius: 50%; background: var(--accent); }
      }
    }

    /* ---------- Switch (luci-app-argon-config uses a common toggle pattern) ---------- */
    .cbi-input-checkbox.switch,
    .switch-wrapper,
    .cbi-section-table-cell input[type="checkbox"]:only-child {
      /* (we apply switch visual to any large checkbox if it has data-switch or comes from toggle sections) */
    }
    .switch {
      display: inline-flex; align-items: center;
    }
    /* Apple glass-bead switch */
    .switch input[type="checkbox"],
    .cbi-input-checkbox input[type="checkbox"][data-switch] {
      width: 54px !important; height: 32px !important;
      border-radius: 999px !important;
      background: linear-gradient(180deg, rgba(0,0,0,.1), rgba(0,0,0,.05));
      box-shadow: inset 0 1px 0 rgba(255,255,255,.4), inset 0 -1px 0 rgba(0,0,0,.1);
      border: none !important;
      position: relative; cursor: pointer;
      transition: background .25s;
      &::after {
        content: ""; position: absolute;
        top: 2px; left: 2px;
        width: 28px; height: 28px; border-radius: 50%;
        background: linear-gradient(180deg, #fff, #ebebf5);
        box-shadow: 0 2px 6px rgba(0,0,0,.25), 0 1px 0 rgba(255,255,255,.9) inset;
        transition: transform .25s cubic-bezier(.2,.8,.2,1);
        border: none;
      }
      &:checked {
        background: linear-gradient(180deg, var(--accent), color-mix(in srgb, var(--accent) 80%, black)) !important;
        box-shadow: 0 2px 6px color-mix(in srgb, var(--accent) 40%, transparent), var(--spec-top) !important;
        &::after { transform: translateX(22px); }
      }
    }

    /* ---------- Dynlist tags ---------- */
    .cbi-dynlist .item, .cbi-dynlist .item-add {
      display: inline-flex; align-items: center; gap: 6px;
      padding: 4px 12px; margin: 3px;
      border-radius: 999px;
      background: var(--fill-chip);
      box-shadow: var(--spec-top);
      font-size: 12px; font-weight: 500;
      color: var(--t-primary);
      .cbi-icon-remove {
        display: inline-block; width: 16px; height: 16px; border-radius: 50%;
        background: rgba(255,59,48,.15); color: var(--sem-red);
        text-align: center; line-height: 15px; font-size: 11px; cursor: pointer;
        &:hover { background: var(--sem-red); color: #fff; }
      }
    }

    /* ---------- File upload ---------- */
    ::-webkit-file-upload-button {
      .glass-button();
      -webkit-appearance: none; appearance: none;
      margin-right: 10px;
    }
  }
  ```

- [ ] **Step 2:编译验证**
  ```bash
  lessc less/cascade.less htdocs/luci-static/argon/css/cascade.css
  ```

- [ ] **Step 3:提交**
  ```bash
  git add less/liquid-glass/controls.less htdocs/luci-static/argon/css/cascade.css
  git commit -m "feat(liquid-glass): glass buttons, inputs, dropdowns, checkboxes, toggle, dynlist

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
  ```

---

## Task 7:components.less — 长尾组件

**Files:**
- Modify: `less/liquid-glass/components.less`

- [ ] **Step 1:写 components.less**
  ```less
  /* =========================================================
   * Long-tail components: badge/progress/ifacebox/table/tooltip/
   * toast/terminal/scrollbar/dropdown/toast/breadcrumb/spinner
   * ========================================================= */
  body.logged-in {
    /* ---------- Badges / labels ---------- */
    .label, .badge, .zonebadge, .cbi-tooltip-container .label,
    .cbi-value .label, .Dashboard .settings-info .label {
      display: inline-flex; align-items: center;
      padding: 3px 10px;
      border-radius: 999px;
      font-size: 11px; font-weight: 600;
      background: var(--fill-chip);
      box-shadow: var(--spec-top);
      color: var(--t-primary);
      text-transform: uppercase; letter-spacing: .3px;
    }
    .label.success, .label.success[style], .cbi-button-success, .cbi-button-download {
      background: linear-gradient(180deg, color-mix(in srgb, var(--sem-green) 80%, white), color-mix(in srgb, var(--sem-green) 40%, white));
      color: color-mix(in srgb, var(--sem-green) 70%, black);
    }
    .label.warning, .label[style*="background"]:not(.error):not(.success) {
      background: linear-gradient(180deg, color-mix(in srgb, var(--sem-orange) 60%, white), color-mix(in srgb, var(--sem-orange) 25%, white));
      color: color-mix(in srgb, var(--sem-orange) 70%, black);
    }
    .label.danger, .label.error, .label.err {
      background: linear-gradient(180deg, color-mix(in srgb, var(--sem-red) 60%, white), color-mix(in srgb, var(--sem-red) 25%, white));
      color: var(--sem-red);
    }
    /* Accent label */
    .label.primary, .label[style*="5e72e4"], .label[style*="007aff"],
    header .status span[data-style="active"] {
      background: linear-gradient(180deg, color-mix(in srgb, var(--accent) 80%, white), color-mix(in srgb, var(--accent) 30%, white));
      color: var(--accent);
    }

    /* ---------- Ifacebox ---------- */
    .ifacebox {
      border-radius: var(--r-card);
      background: var(--fill-regular);
      backdrop-filter: blur(var(--blur-regular)) var(--saturate);
      -webkit-backdrop-filter: blur(var(--blur-regular)) var(--saturate);
      box-shadow: var(--spec-top), var(--contact);
      border: none !important;
      overflow: hidden; position: relative;
      padding: 0; margin: 0;
      .ifacebox-head {
        padding: 10px 14px;
        background: linear-gradient(180deg, rgba(255,255,255,.6), rgba(255,255,255,.2));
        font-weight: 700; font-size: 13px; color: var(--t-primary);
        border-bottom: 1px solid var(--hairline);
        display: flex; align-items: center; gap: 8px;
        &.active {
          box-shadow: inset 3px 0 0 var(--sem-green);
        }
      }
      .ifacebox-body {
        padding: 14px; font-size: 12px; color: var(--t-secondary);
        font-family: var(--font-mono);
      }
    }
    .ifacebox .ifacebox-head.active::before { content: ""; display:none; }

    /* ifacebox grid (network page) */
    [style*="display:grid"] .ifacebox,
    .cbi-section .ifacebox { margin: 4px; }

    /* ---------- Tables ---------- */
    .table, table, .cbi-section-table {
      width: 100%; border-collapse: separate; border-spacing: 0;
      font-size: 13px;
      th {
        text-align: left; font-weight: 700; color: var(--t-secondary);
        font-size: 11px; text-transform: uppercase; letter-spacing: .4px;
        padding: 10px 14px;
        background: var(--fill-thin);
      }
      td {
        padding: 10px 14px;
        border-top: 1px solid var(--hairline);
        color: var(--t-primary);
      }
      tr:nth-child(even) td {
        background: rgba(255,255,255,.35);
      }
      tr:hover td { background: var(--accent-tint); }
    }
    /* Corner radii for first/last row */
    .table, table { overflow: hidden; border-radius: var(--r-control); }
    .table th:first-child, table th:first-child { border-radius: var(--r-control) 0 0 0; }
    .table th:last-child,  table th:last-child  { border-radius: 0 var(--r-control) 0 0; }
    .table tr:last-child td:first-child { border-radius: 0 0 0 var(--r-control); }
    .table tr:last-child td:last-child  { border-radius: 0 0 var(--r-control) 0; }

    /* ---------- Progress bar ---------- */
    .cbi-progressbar {
      position: relative;
      height: 8px; background: var(--fill-chip);
      border-radius: 999px; overflow: hidden;
      box-shadow: var(--spec-top), var(--edge-bottom);
      padding: 0;
      &::before {
        content: ""; position: absolute; top: 0; left: 0; height: 100%;
        background: linear-gradient(90deg, var(--accent), color-mix(in srgb, var(--accent) 60%, white));
        border-radius: 999px;
        width: var(--w, 0%);
        box-shadow: 0 0 8px color-mix(in srgb, var(--accent) 50%, transparent);
        transition: width .3s ease;
      }
      /* label text on right */
      + em, + .cbi-progressbar-value, em {
        font-family: var(--font-mono); font-size: 11px; color: var(--t-secondary); font-style: normal;
      }
    }

    /* ---------- Terminal / command output ---------- */
    pre.command-output, .commandbox {
      background: rgba(28,28,30,.75) !important;
      backdrop-filter: blur(20px); -webkit-backdrop-filter: blur(20px);
      color: #f5f5f7;
      border-radius: var(--r-control);
      padding: 16px;
      font-family: var(--font-mono); font-size: 12px; line-height: 1.6;
      overflow: auto;
      border: none;
      box-shadow: inset 0 1px 0 rgba(255,255,255,.08);
    }
    .commandbox {
      background: rgba(28,28,30,.75) !important;
      border-bottom: none !important;
      h3, code { color: #f5f5f7 !important; }
      code { background: rgba(255,255,255,.08); padding: 2px 6px; border-radius: 6px; }
    }
    /* Command output alert positioning */
    #command-rc-output .alert-message { top: 60px; right: 40px; }

    /* ---------- Tooltip ---------- */
    .cbi-tooltip, .tip {
      background: var(--fill-strong);
      backdrop-filter: blur(var(--blur-regular)); -webkit-backdrop-filter: blur(var(--blur-regular));
      color: var(--t-primary);
      border-radius: 10px; padding: 8px 12px;
      font-size: 12px; font-weight: 500;
      box-shadow: var(--spec-top), var(--contact-lift);
      border: none;
    }

    /* ---------- Toast / LuCI popups ---------- */
    #popups > .alert-message,
    .pc-bg, #_system_notification {
      position: fixed; top: 70px; right: 20px;
      min-width: 240px; max-width: 360px; min-height: 48px;
      border-radius: 18px; padding: 14px 18px;
      background: var(--fill-strong);
      backdrop-filter: blur(var(--blur-regular)) var(--saturate);
      -webkit-backdrop-filter: blur(var(--blur-regular)) var(--saturate);
      box-shadow: var(--spec-top), var(--contact-lift);
      z-index: 300;
      color: var(--t-primary); font-size: 13px; font-weight: 500;
      animation: lg-toast-in .35s cubic-bezier(.2,.8,.2,1);
    }
    @keyframes lg-toast-in {
      from { transform: translateY(-10px); opacity: 0; }
      to   { transform: translateY(0); opacity: 1; }
    }

    /* ---------- Breadcrumb ---------- */
    .breadcrumb {
      font-size: 12px; color: var(--t-secondary);
      a { color: var(--t-tertiary); text-decoration: none; &:hover { color: var(--accent); } }
      li { display: inline; }
      li + li::before { content: " › "; color: var(--t-tertiary); opacity: .5; }
    }

    /* ---------- Spinner ---------- */
    .spinning, .loading, [class*="spinner"]::before {
      /* the existing LuCI spinner base class; upgrade color to accent */
      border-color: color-mix(in srgb, var(--accent) 15%, transparent) !important;
      border-top-color: var(--accent) !important;
    }
    .cbi-input-dropdown .spinning { background-color: transparent; }

    /* ---------- Section caret / expand arrow ---------- */
    h4 > small .caret, .cbi-section-title .caret {
      color: var(--t-tertiary); transition: transform .2s;
    }

    /* ---------- Deprecated color overrides ---------- */
    /* --green was aliased to blue in previous version — restore semantic colors */
    :root { --green: var(--sem-green); --red: var(--sem-red); --orange: var(--sem-orange); }
    .cbi-button-success { background: var(--sem-green) !important; color: #fff !important; }

    /* ---------- Misc ---------- */
    hr { border-color: var(--hairline); opacity: 1; }
    code { background: var(--fill-thin); padding: 2px 6px; border-radius: 6px; font-family: var(--font-mono); font-size: 12px; }
  }
  ```

- [ ] **Step 2:编译**
  ```bash
  lessc less/cascade.less htdocs/luci-static/argon/css/cascade.css
  ```

- [ ] **Step 3:提交**
  ```bash
  git add less/liquid-glass/components.less htdocs/luci-static/argon/css/cascade.css
  git commit -m "feat(liquid-glass): long-tail components — badges, ifacebox, tables, terminal, tooltips, toasts

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
  ```

---

## Task 8:dark.less — 深色模式玻璃独立配方

**Files:**
- Modify: `less/liquid-glass/dark.less`(被 dark.less 最后 import,自动进入暗色样式)

- [ ] **Step 1:写 dark.less**
  注意: LuCI 把 dark.css 通过 `@media (prefers-color-scheme: dark)` 注入,所以此文件内的选择器就是暗色本身,不需要再嵌套一层。
  ```less
  /* =========================================================
   * Dark-mode Liquid Glass
   * NOT a simple inversion. Dark glass has gray-blue base fill,
   * subtle cool specular, deeper contact shadows.
   * ========================================================= */

  :root {
    /* Accent (Apple dark palette) */
    --accent:         #0a84ff;
    --accent-soft:    rgba(10,132,255,.28);
    --accent-tint:    rgba(10,132,255,.18);

    --sem-red:        #ff453a;
    --sem-orange:     #ff9f0a;
    --sem-green:      #30d158;
    --sem-yellow:     #ffd60a;
    --sem-purple:     #bf5af2;
    --sem-pink:       #ff375f;

    /* Glass fills — darker, gray-blue */
    --fill-strong:    linear-gradient(180deg, rgba(50,50,55,.55) 0%, rgba(30,30,35,.4) 45%, rgba(42,42,48,.5) 100%);
    --fill-regular:   linear-gradient(180deg, rgba(45,45,50,.48) 0%, rgba(28,28,32,.35) 45%, rgba(38,38,42,.42) 100%);
    --fill-thin:      linear-gradient(180deg, rgba(40,40,45,.35) 0%, rgba(25,25,28,.22) 45%, rgba(35,35,38,.3) 100%);
    --fill-chip:      linear-gradient(180deg, rgba(70,70,75,.75) 0%, rgba(45,45,50,.55) 100%);

    /* Lower saturate for dark */
    --saturate:       saturate(160%);

    /* Specular: cold light */
    --spec-top:       inset 0 1px 0 rgba(255,255,255,.14);
    --spec-hi:        inset 0 .5px 0 rgba(255,255,255,.1), inset 0 18px 30px rgba(255,255,255,.05);
    --edge-bottom:    inset 0 -1px 0 rgba(0,0,0,.3);

    /* Deeper contact shadow */
    --contact:        0 1px 0 rgba(0,0,0,.2), 0 12px 32px rgba(0,0,0,.5);
    --contact-lift:   0 2px 0 rgba(0,0,0,.25), 0 20px 44px rgba(0,0,0,.55);

    /* Text */
    --t-primary:      #f5f5f7;
    --t-secondary:    #a1a1a6;
    --t-tertiary:     #8e8e93;

    /* Hairline */
    --hairline:       rgba(255,255,255,.08);
  }

  /* ---- Body dark ---- */
  body.logged-in {
    background-color: #1c1c1e;
  }
  body.logged-in::after {
    background:
      radial-gradient(ellipse 60% 40% at 15% 10%, color-mix(in srgb, var(--accent) 25%, transparent), transparent 60%),
      radial-gradient(ellipse 50% 45% at 85% 20%, rgba(10,132,255,.22), transparent 60%),
      radial-gradient(ellipse 55% 50% at 60% 90%, rgba(191,90,242,.20), transparent 60%),
      linear-gradient(180deg, rgba(0,0,0,.5), rgba(0,0,0,.72));
    background-blend-mode: screen, screen, screen, normal;
  }

  /* Scrollbar dark */
  ::-webkit-scrollbar-thumb {
    background: linear-gradient(180deg, rgba(255,255,255,.25), rgba(255,255,255,.1));
    &:hover { background: rgba(255,255,255,.3); }
  }

  /* Selection dark */
  ::selection { background: rgba(10,132,255,.3); color: #fff; }

  /* Autofill dark */
  input:-webkit-autofill,
  input:-webkit-autofill:hover,
  input:-webkit-autofill:focus {
    -webkit-text-fill-color: #f5f5f7;
    -webkit-box-shadow: 0 0 0 1000px rgba(60,60,65,.75) inset;
  }

  /* Tables dark */
  body.logged-in .table tr:nth-child(even) td,
  body.logged-in table tr:nth-child(even) td {
    background: rgba(255,255,255,.03);
  }
  body.logged-in .table tr:hover td,
  body.logged-in table tr:hover td {
    background: var(--accent-tint);
  }

  /* Terminal dark: keep high contrast */
  body.logged-in pre.command-output, body.logged-in .commandbox {
    background: rgba(0,0,0,.5) !important;
    color: #f5f5f7;
    box-shadow: inset 0 1px 0 rgba(255,255,255,.06);
  }

  /* Sidebar brand dark */
  body.logged-in .main-left .sidenav-header .brand { color: var(--t-primary) !important; }

  /* Mobile dark mask */
  body.logged-in .darkMask { background: rgba(0,0,0,.55); }

  /* Fallback */
  @supports not ((backdrop-filter: blur(1px)) or (-webkit-backdrop-filter: blur(1px))) {
    body.logged-in::after { background: rgba(28,28,30,.96); }
    body.logged-in .main-left, body.logged-in header,
    body.logged-in .cbi-section, body.logged-in .modal,
    body.logged-in .cbi-dropdown ul.dropdown {
      background: rgba(28,28,30,.96) !important;
      color: var(--t-primary);
    }
  }
  ```

- [ ] **Step 2:编译**
  ```bash
  lessc less/dark.less htdocs/luci-static/argon/css/dark.css
  lessc less/cascade.less htdocs/luci-static/argon/css/cascade.css
  ```
  两个文件都编译无错。

- [ ] **Step 3:提交**
  ```bash
  git add less/liquid-glass/dark.less htdocs/luci-static/argon/css/dark.css htdocs/luci-static/argon/css/cascade.css
  git commit -m "feat(liquid-glass): dark-mode independent glass formula

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
  ```

---

## Task 9:login.less + 登录页锁屏重写(header_login.ut)

**Files:**
- Modify: `less/liquid-glass/login.less`
- Modify: `ucode/template/themes/argon/header_login.ut`

- [ ] **Step 1:写 login.less**
  ```less
  /* =========================================================
   * Login page — macOS lock screen aesthetic
   * ========================================================= */
  body.login-page {
    font-family: var(--font-sans);
    -webkit-font-smoothing: antialiased;
    min-height: 100vh; margin: 0;
    background-size: cover; background-position: center;
    background-attachment: fixed;
    color: #fff;
    overflow: hidden;
    position: relative;
    display: flex; flex-direction: column; align-items: center;
    justify-content: flex-start;
    padding: 10vh 32px 32px;
  }

  /* vignette darkens form area slightly */
  body.login-page::before {
    content: ""; position: fixed; inset: 0;
    background: radial-gradient(ellipse at center, transparent 40%, rgba(0,0,0,.3) 100%);
    pointer-events: none; z-index: 0;
  }

  /* Lock screen container */
  body.login-page .login-container {
    position: relative; z-index: 1;
    width: 100%; max-width: 360px;
    display: flex; flex-direction: column; align-items: center;
    text-align: center;
    animation: lg-lock-in .7s cubic-bezier(.2,.8,.2,1);
  }
  @keyframes lg-lock-in {
    from { transform: translateY(12px); opacity: 0; }
    to   { transform: translateY(0); opacity: 1; }
  }

  /* Hostname label */
  body.login-page .login-container .hostname {
    font-family: var(--font-sans);
    font-weight: 800; font-size: 28px;
    text-shadow: 0 4px 30px rgba(0,0,0,.5);
    letter-spacing: -.5px;
    margin-bottom: 4px;
  }
  /* Clock */
  body.login-page .login-container .clock {
    font-family: var(--font-sans);
    font-weight: 200; font-size: 56px;
    text-shadow: 0 4px 30px rgba(0,0,0,.5);
    margin-bottom: 40px;
    letter-spacing: -2px;
    line-height: 1;
    font-variant-numeric: tabular-nums;
  }

  /* Avatar */
  body.login-page .login-container .avatar {
    width: 100px; height: 100px; border-radius: 50%;
    background: var(--fill-chip);
    background: linear-gradient(180deg, rgba(255,255,255,.75), rgba(255,255,255,.4));
    backdrop-filter: blur(24px) saturate(200%); -webkit-backdrop-filter: blur(24px) saturate(200%);
    box-shadow: 0 8px 28px rgba(0,0,0,.25), inset 0 1px 0 rgba(255,255,255,.9);
    display: flex; align-items: center; justify-content: center;
    font-size: 46px;
    margin-bottom: 22px;
    position: relative;
    &::before { content: "👤"; }
  }

  /* Login form card (fully glass) */
  body.login-page .login-container .login-form {
    width: 100%; max-width: 300px;
    background: var(--fill-strong);
    background: linear-gradient(180deg, rgba(255,255,255,.25), rgba(255,255,255,.12));
    backdrop-filter: blur(40px) saturate(220%); -webkit-backdrop-filter: blur(40px) saturate(220%);
    border-radius: 28px;
    padding: 24px;
    box-shadow: 0 20px 60px rgba(0,0,0,.35),
                inset 0 1px 0 rgba(255,255,255,.5),
                inset 0 -1px 0 rgba(0,0,0,.2);
    display: flex; flex-direction: column; gap: 12px;
    .brand { display: none; }
  }

  body.login-page .login-container .login-form input[type="password"],
  body.login-page .login-container .login-form input[type="text"] {
    width: 100%;
    height: 44px; padding: 0 16px;
    border-radius: 999px;
    border: none;
    background: rgba(255,255,255,.25);
    color: #fff; text-align: center; font-size: 15px;
    box-shadow: inset 0 1px 0 rgba(255,255,255,.3);
    &::placeholder { color: rgba(255,255,255,.6); text-align: center; }
    &:focus { outline: none; box-shadow: 0 0 0 4px rgba(255,255,255,.25), inset 0 1px 0 rgba(255,255,255,.4); }
  }

  body.login-page .login-container .login-form input[type="submit"],
  body.login-page .login-container .login-form .cbi-button-apply {
    width: 100%; height: 44px;
    border-radius: 999px; border: none;
    background: var(--accent);
    background: linear-gradient(180deg, var(--accent), color-mix(in srgb, var(--accent) 85%, black));
    color: #fff; font-weight: 700; font-size: 15px;
    box-shadow: 0 6px 20px color-mix(in srgb, var(--accent) 50%, transparent);
    cursor: pointer;
    transition: transform .2s, filter .2s;
    &:hover { filter: brightness(1.05); transform: translateY(-1px); }
  }

  body.login-page .login-container .login-form .errorbox {
    padding: 8px 14px; border-radius: 999px;
    background: rgba(255,69,58,.3); backdrop-filter: blur(20px);
    color: #fff; font-size: 12px; font-weight: 600;
  }

  /* Footer */
  body.login-page .ftc {
    position: fixed; bottom: 24px; left: 0; right: 0;
    text-align: center; font-size: 11px; color: rgba(255,255,255,.65);
    text-shadow: 0 2px 10px rgba(0,0,0,.4);
    z-index: 1;
    a { color: rgba(255,255,255,.85); text-decoration: none; margin: 0 8px; }
    .luci-link, a.luci-link { }
    p { margin: 4px 0; }
  }

  /* Existing old rules we must overpower: reset margin/padding on old containers */
  body.login-page .main-bg {
    background: none !important;
    background-image: var(--login-wallpaper, none) !important;
    background-size: cover !important;
    background-position: center !important;
    background-attachment: fixed !important;
    position: fixed; inset: 0; z-index: -1;
  }
  body.login-page .login-container .login-form::before { display: none; }
  ```

- [ ] **Step 2:重写 header_login.ut body 部分**
  打开 `ucode/template/themes/argon/header_login.ut`。保留 head 区域不变(里面的 css 变量 block 同步改,见 step 3)。只把 `<body>` 从首个 `<body` 到 `</body>` 替换为:
  ```html
<body class="login-page">
  <div class="main-bg"></div>

  <div class="login-container">
    <div class="hostname">{{ hostname }}</div>
    <div class="clock" id="lg-clock">--:--</div>
    <div class="avatar" aria-hidden="true"></div>

    <div class="login-form">
      {% if (user) { %}
        <div class="brand">Argon</div>
        <form method="post" action="<%=controller%>/Sysauth">
          <input type="hidden" name="token" value="<%=token%>">
          <input type="hidden" name="username" value="{{ user }}">
          <input type="password" name="password" autocomplete="current-password" autofocus placeholder="{{ _('Password') }}">
          <input type="submit" value="{{ _('Login') }}">
        </form>
      {% } else { %}
        <!-- fallthrough; the default LuCI login form renders here -->
        <div id="sysauth"><form method="post" action="{{ controller }}/Sysauth">
          <input type="hidden" name="token" value="{{ token }}">
          <input type="text" name="username" autocomplete="username" placeholder="{{ _('Username') }}">
          <input type="password" name="password" autocomplete="current-password" autofocus placeholder="{{ _('Password') }}">
          <input type="submit" value="{{ _('Login') }}">
        </form></div>
      {% } %}

      {% if (fw3warn) { %}
        <div class="errorbox">{{ fw3warn }}</div>
      {% } %}
    </div>
  </div>

  <div class="ftc">
    <a class="luci-link" href="https://github.com/openwrt/luci" target="_blank">Powered by {{ version.luciname }} ({{ version.luciversion }})</a>
    <span style="opacity:.5">|</span>
    <a href="https://github.com/jerrykuku/luci-theme-argon" target="_blank">ArgonTheme</a>
    <p>{{ version.distname }} {{ version.distversion }}-{{ version.distrevision }}</p>
  </div>

  <script>
    (function(){
      var el = document.getElementById('lg-clock');
      function tick(){
        var d = new Date();
        var h = String(d.getHours()).padStart(2,'0');
        var m = String(d.getMinutes()).padStart(2,'0');
        el.textContent = h + ':' + m;
      }
      tick(); setInterval(tick, 1000);
    })();
  </script>
</body>
  ```

- [ ] **Step 3:同步更新 header_login.ut 的 :root style block**
  把那段 `:root { --argon-user-primary: ... --primary: #007aff; ... }` 改成:
  ```css
  :root {
    --argon-user-primary: {{ primary }};
    --argon-user-dark-primary: {{ dark_primary }};
    --accent: {{ bar_color }};
    --blur-radius: {{ blur_radius }}px;
    --blur-opacity: {{ blur_opacity }};
  }
  ```
  同样的修改在 `header.ut` 的 style block 里也做一次(两边同步去除 `--primary: #007aff` 硬编码)。

- [ ] **Step 4:在 header.ut 的 inline style block 之前注入登录壁纸 CSS 变量**
  在 header.ut 顶部 ucode 块里,确定用户壁纸 URL 的逻辑(LuCI argon 约定的壁纸路径一般是 `../img/background.png` 或 Bing URL)。
  在 head `<style>` 里加(插在 `:root { ... }` 之前):
  ```
  {%
    // Determine wallpaper URL: respect argon's existing logic (Bing / upload / online)
    let bg = '';
    let bg_option = cfg.get_first('argon', 'global', 'bg_enabled');
    let bg_online = cfg.get_first('argon', 'global', 'online_bg_url');
    // Argon's wallpaper convention: if image exists at /www/luci-static/argon/img/background, it's an upload
    if (access('/www/luci-static/argon/img/background.png')) {
      bg = media + '/img/background.png';
    } else if (access('/www/luci-static/argon/img/background.jpg')) {
      bg = media + '/img/background.jpg';
    } else if (bg_option === 'bing' || (bg_online && bg_online.length)) {
      bg = bg_online || media + '/img/background'; // argon handles bing rewrite
    } else {
      bg = media + '/background/default-abstract.svg';
    }
  -%}
  <style id="lg-wallpaper-css">
    :root { --user-wallpaper: url('{{ bg }}'); }
    body.login-page { --login-wallpaper: url('{{ bg }}'); }
    body.logged-in { background-image: var(--user-wallpaper); }
  </style>
  ```
  实际实现时,先探查 header_login.ut 现有的 `main-bg` 类怎么取壁纸的,保持兼容(用 LuCI 已有的 JS/CSS 路径,不重复实现 Bing 获取)。Argon 原版把登录壁纸通过 `.main-bg` 的 inline `background-image: url({{ media }}/img/...)` 设置——我们可以在 header.ut 同样加一个 `.wallpaper` div 放在 body 下,或者直接复用现有壁纸规则。
  **最小实现**: 给 `body.logged-in` 加 `class="logged-in"` 下的 background-image 使用与 `.login-page .main-bg` 相同的内联 style 即可,不用重写 bing 逻辑。具体做法:在 header.ut 的 body 上加 `style="background-image: url(...);"` 由 ucode 给出同 header_login 用的壁纸 URL。(查看原版 header_login 的 main-bg 行:那里已经有内联壁纸 style,直接把同样的 URL 注入 body.logged-in 的 inline style。)

- [ ] **Step 5:编译验证**
  ```bash
  lessc less/cascade.less htdocs/luci-static/argon/css/cascade.css
  lessc less/dark.less htdocs/luci-static/argon/css/dark.css
  ```

- [ ] **Step 6:提交**
  ```bash
  git add less/liquid-glass/login.less ucode/template/themes/argon/header.ut ucode/template/themes/argon/header_login.ut htdocs/luci-static/argon/css/*.css
  git commit -m "feat(liquid-glass): macOS lock-screen login + shared wallpaper on logged-in shell

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
  ```

---

## Task 10:mobile.less — 响应式适配

**Files:**
- Modify: `less/liquid-glass/mobile.less`

- [ ] **Step 1:写 mobile.less**
  ```less
  /* =========================================================
   * Mobile (≤768px)
   * ========================================================= */
  @media (max-width: 768px) {
    body.logged-in {
      .main-left {
        width: 280px;
        top: 0; bottom: 0;
        border-radius: 0 22px 22px 0;
        transform: translateX(-105%);
        box-shadow: var(--contact-lift);
        &.show, &.active, &.slide-in { transform: translateX(0); }
      }
      .main-right {
        position: relative; left: auto; top: auto;
      }
      .main-right > #maincontent { padding: 12px; }
      header, header.bg-primary {
        height: 44px;
        position: sticky; top: 0;
        border-radius: 0;
        .fill { height: 44px; padding: 0 12px; }
        .showSide {
          display: inline-flex; align-items: center; justify-content: center;
          width: 28px; height: 28px; border-radius: 50%;
          background: var(--fill-chip); cursor: pointer;
          margin-right: 4px;
          &::before {
            content: ""; display: block;
            width: 14px; height: 2px; background: var(--t-primary);
            border-radius: 2px; box-shadow: 0 5px 0 var(--t-primary), 0 -5px 0 var(--t-primary);
          }
        }
        .brand { font-size: 15px; }
      }
      .cbi-section, .cbi-map {
        padding: 16px; border-radius: 16px;
      }
      .cbi-section h2, .cbi-section h3 { font-size: 18px; }
      .btn, .cbi-button { height: 32px; padding: 0 14px !important; font-size: 12px; }
      .cbi-value-field input, .cbi-value-field select, .cbi-value-field textarea {
        max-width: 100% !important;
      }
      .cbi-page-actions {
        margin: 16px -16px -16px; padding: 12px;
      }
      /* lock screen mobile */
      body.login-page {
        padding: 8vh 20px 20px;
        .clock { font-size: 44px; }
        .login-form { padding: 20px; border-radius: 24px; max-width: 100%; }
      }
    }
  }
  ```

- [ ] **Step 2:编译 + 提交**
  ```bash
  lessc less/cascade.less htdocs/luci-static/argon/css/cascade.css
  lessc less/dark.less htdocs/luci-static/argon/css/dark.css
  git add less/liquid-glass/mobile.less htdocs/luci-static/argon/css/*.css
  git commit -m "feat(liquid-glass): responsive mobile adaptation

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
  ```

---

## Task 11:JS — tab 滑块 + 壁纸 fallback + 强调色预设映射

**Files:**
- Create: `htdocs/luci-static/argon/js/liquid-glass.js`
- Modify: `ucode/template/themes/argon/header.ut`(引入该 js)
- Modify: `ucode/template/themes/argon/header_login.ut`(不登录页不需要此 js,可只在 main shell 加)

- [ ] **Step 1:创建 js/liquid-glass.js**
  ```js
  (function () {
    "use strict";

    // ----------------------------------------------------------
    // Tab slider for .cbi-tabmenu / .tabs
    // ----------------------------------------------------------
    function positionTabSlider(menu) {
      if (!menu) return;
      var active = menu.querySelector("li.active a, li.active > a, a.active, li.active");
      // for a nested <a> inside li.active
      if (active && active.tagName !== "LI" && active.parentElement.matches("li")) {
        active = active.parentElement;
      }
      if (!active) {
        // fallback: first child
        active = menu.querySelector("li, .tab");
      }
      if (!active) return;
      var menuRect = menu.getBoundingClientRect();
      var r = active.getBoundingClientRect();
      var left = r.left - menuRect.left;
      var w = r.width;
      menu.style.setProperty("--tab-left", left + "px");
      menu.style.setProperty("--tab-width", w + "px");
    }

    function initTabSliders(root) {
      root = root || document;
      var menus = root.querySelectorAll(".cbi-tabmenu, .tabs");
      menus.forEach(function (m) {
        positionTabSlider(m);
        m.addEventListener("click", function () {
          // LuCI sets .active after click; defer a frame
          requestAnimationFrame(function () { positionTabSlider(m); });
        });
      });
    }

    // ----------------------------------------------------------
    // Wallpaper fallback — if bg image fails, clear it so bokeh shows
    // ----------------------------------------------------------
    function initWallpaperFallback() {
      var cs = getComputedStyle(document.body);
      var bg = cs.backgroundImage;
      if (!bg || bg === "none") return;
      var url = bg.replace(/^url\(['"]?/, "").replace(/['"]?\)$/, "");
      if (!url) return;
      var img = new Image();
      img.onerror = function () {
        document.body.style.backgroundImage = "none";
        document.body.classList.add("lg-no-wallpaper");
      };
      img.src = url;
    }

    // ----------------------------------------------------------
    // Accent preset support
    // The ucode template emits <body data-accent-preset="blue"> etc.
    // The five CSS presets are hard-coded as variables here; the
    // :root CSS already uses --accent which we can override inline.
    // ----------------------------------------------------------
    var ACCENTS = {
      blue:   { light: "#007aff", dark: "#0a84ff" },
      purple: { light: "#af52de", dark: "#bf5af2" },
      pink:   { light: "#ff2d55", dark: "#ff375f" },
      green:  { light: "#34c759", dark: "#30d158" },
      orange: { light: "#ff9500", dark: "#ff9f0a" }
    };
    function applyAccent(preset) {
      var palette = ACCENTS[preset];
      if (!palette) return;
      var isDark = window.matchMedia("(prefers-color-scheme: dark)").matches;
      var color = isDark ? palette.dark : palette.light;
      function hexToRgba(hex, a) {
        var h = hex.replace("#","");
        var r = parseInt(h.substring(0,2),16);
        var g = parseInt(h.substring(2,4),16);
        var b = parseInt(h.substring(4,6),16);
        return "rgba(" + r + "," + g + "," + b + "," + a + ")";
      }
      var root = document.documentElement;
      root.style.setProperty("--accent", color);
      root.style.setProperty("--accent-tint", hexToRgba(color, .12));
      root.style.setProperty("--accent-soft", hexToRgba(color, .25));
    }

    // ----------------------------------------------------------
    // Boot
    // ----------------------------------------------------------
    function boot() {
      initTabSliders();
      initWallpaperFallback();
      var preset = document.body.getAttribute("data-accent-preset");
      if (preset) applyAccent(preset);
      // re-position tabs when LuCI swaps content dynamically
      var mo = new MutationObserver(function () { initTabSliders(); });
      var main = document.getElementById("maincontent");
      if (main) mo.observe(main, { childList: true, subtree: true });
      window.addEventListener("resize", function () {
        document.querySelectorAll(".cbi-tabmenu, .tabs").forEach(positionTabSlider);
      });
      // Re-apply accent when dark mode preference flips
      window.matchMedia("(prefers-color-scheme: dark)").addEventListener("change", function () {
        var p = document.body.getAttribute("data-accent-preset");
        if (p) applyAccent(p);
      });
    }

    if (document.readyState === "loading") {
      document.addEventListener("DOMContentLoaded", boot);
    } else {
      boot();
    }
  })();
  ```

- [ ] **Step 2:在 header.ut 引入 JS 文件**
  在 `header.ut` 里,在最后一条 `<script>`(L.require menu-argon 那行)**之前**插入:
  ```html
  <script src="{{ media }}/js/liquid-glass.js" defer></script>
  ```

- [ ] **Step 3:body 标签加 data-accent-preset 属性**
  把 `header.ut` 和 `header_login.ut` 里 body 标签加上 `data-accent-preset` 字段。在 ucode 顶部把配置里的 `primary` 值映射到 5 档预设之一:
  在 ucode 块 `primary = cfg.get_first(...)` 之后加:
  ```ucode
  const ACCENT_MAP = {
    "#007aff": "blue", "#5e72e4": "blue", "#483d8b": "blue",
    "#0a84ff": "blue",
    "#af52de": "purple", "#bf5af2": "purple",
    "#ff2d55": "pink", "#ff375f": "pink",
    "#34c759": "green", "#30d158": "green",
    "#ff9500": "orange", "#ff9f0a": "orange"
  };
  let accent_preset = ACCENT_MAP[primary] || "blue";
  ```
  然后在 body 标签上加 `data-accent-preset="{{ accent_preset }}"`。

- [ ] **Step 4:创建 js 目录(如果不存在)**
  ```bash
  mkdir -p htdocs/luci-static/argon/js
  ```

- [ ] **Step 5:提交**
  ```bash
  git add htdocs/luci-static/argon/js/liquid-glass.js ucode/template/themes/argon/header.ut ucode/template/themes/argon/header_login.ut
  git commit -m "feat(liquid-glass): tab slider JS, wallpaper fallback, accent presets

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
  ```

---

## Task 12:内置抽象液态 SVG 壁纸 + Makefile 安装

**Files:**
- Create: `htdocs/luci-static/argon/background/default-abstract.svg`
- Create: `htdocs/luci-static/argon/background/default-graphite.svg`
- Verify: Makefile(不改动,OpenWrt luci.mk 自动打包 `htdocs/` 整树)

- [ ] **Step 1:写 default-abstract.svg**
  这是一个柔和的彩色液态渐变 blob 壁纸,作为"没配置壁纸"时的 fallback,也作为内置默认。内容:
  ```svg
  <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1600 1000" preserveAspectRatio="xMidYMid slice">
    <defs>
      <linearGradient id="bg" x1="0" y1="0" x2="1" y2="1">
        <stop offset="0%" stop-color="#f8f6fa"/>
        <stop offset="100%" stop-color="#eef2f7"/>
      </linearGradient>
      <radialGradient id="b1" cx="15%" cy="20%" r="40%">
        <stop offset="0%" stop-color="#ffb7a3" stop-opacity=".9"/>
        <stop offset="100%" stop-color="#ffb7a3" stop-opacity="0"/>
      </radialGradient>
      <radialGradient id="b2" cx="85%" cy="25%" r="35%">
        <stop offset="0%" stop-color="#a3d4ff" stop-opacity=".9"/>
        <stop offset="100%" stop-color="#a3d4ff" stop-opacity="0"/>
      </radialGradient>
      <radialGradient id="b3" cx="70%" cy="80%" r="45%">
        <stop offset="0%" stop-color="#c7b0ff" stop-opacity=".8"/>
        <stop offset="100%" stop-color="#c7b0ff" stop-opacity="0"/>
      </radialGradient>
      <radialGradient id="b4" cx="25%" cy="80%" r="35%">
        <stop offset="0%" stop-color="#ffd4a3" stop-opacity=".8"/>
        <stop offset="100%" stop-color="#ffd4a3" stop-opacity="0"/>
      </radialGradient>
      <filter id="b"><feGaussianBlur stdDeviation="40"/></filter>
    </defs>
    <rect width="1600" height="1000" fill="url(#bg)"/>
    <g filter="url(#b)">
      <circle cx="240" cy="200" r="380" fill="url(#b1)"/>
      <circle cx="1360" cy="250" r="340" fill="url(#b2)"/>
      <circle cx="1120" cy="800" r="420" fill="url(#b3)"/>
      <circle cx="400" cy="800" r="320" fill="url(#b4)"/>
    </g>
  </svg>
  ```

- [ ] **Step 2:写 default-graphite.svg**(深色模式偏好者用的深灰+蓝光斑)
  ```svg
  <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 1600 1000" preserveAspectRatio="xMidYMid slice">
    <defs>
      <linearGradient id="bg" x1="0" y1="0" x2="0" y2="1">
        <stop offset="0%" stop-color="#2c2c2e"/>
        <stop offset="100%" stop-color="#1c1c1e"/>
      </linearGradient>
      <radialGradient id="b1" cx="70%" cy="30%" r="50%">
        <stop offset="0%" stop-color="#0a84ff" stop-opacity=".35"/>
        <stop offset="100%" stop-color="#0a84ff" stop-opacity="0"/>
      </radialGradient>
      <radialGradient id="b2" cx="20%" cy="80%" r="45%">
        <stop offset="0%" stop-color="#bf5af2" stop-opacity=".25"/>
        <stop offset="100%" stop-color="#bf5af2" stop-opacity="0"/>
      </radialGradient>
      <filter id="b"><feGaussianBlur stdDeviation="60"/></filter>
    </defs>
    <rect width="1600" height="1000" fill="url(#bg)"/>
    <g filter="url(#b)">
      <circle cx="1100" cy="300" r="500" fill="url(#b1)"/>
      <circle cx="300" cy="800" r="450" fill="url(#b2)"/>
    </g>
  </svg>
  ```

- [ ] **Step 3:在壁纸回退逻辑里优先选 abstract.svg**
  在 header.ut 里把 wallpaper 探测的 fallback 值改为 `media + '/background/default-abstract.svg'`(已在 Task 9 设定)。

- [ ] **Step 4:验证 OpenWrt Makefile 会自动打包**
  现 Makefile 用的是 `luci.mk`,OpenWrt 的 luci.mk 默认把 `htdocs/` 整个目录安装到 `/www/`,所以 svg 不需要加新 INSTALL 命令。`ls htdocs/luci-static/argon/background/` 应该看到:
  ```
  README.md
  default-abstract.svg
  default-graphite.svg
  ```

- [ ] **Step 5:编译 + 提交**
  ```bash
  lessc less/cascade.less htdocs/luci-static/argon/css/cascade.css
  lessc less/dark.less   htdocs/luci-static/argon/css/dark.css
  git add htdocs/luci-static/argon/background/default-abstract.svg htdocs/luci-static/argon/background/default-graphite.svg htdocs/luci-static/argon/css/*.css
  git commit -m "feat(liquid-glass): bundle two built-in SVG wallpapers

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
  ```

---

## Task 13:视觉 QA 与打磨

**Files:**
- 任意 glass 文件

这一步是部署到路由器或本地 HTTP 服务看效果,记录并修复问题。这里写具体的检查清单和常见修复点(实现者对每个问题用单独 commit 修)。

- [ ] **Step 1:本地开 HTTP 预览**
  如果无法刷路由器,把 `htdocs/luci-static/argon/` 部署到任意 http 服务器(或 python -m http.server),直接打开浏览器访问路由其页面的代理。最简单的方法:把当前仓库编译后 `scp` 到路由器 `/www/luci-static/argon/` 覆盖刷新测试。
  ```bash
  # 简易本地预览(可选,需要路由器开着并配置好 theme_argon):
  ssh root@router "cd /www/luci-static/argon && tar czpf - ../argon" | head -c 1
  echo "scp css files to router..."
  ```

- [ ] **Step 2:肉眼检查清单**
  逐项确认,遇到问题编辑对应 less 文件重编译:
  - [ ] 登录页:大时钟、头像圆、密码框胶囊、蓝按钮在壁纸上清楚可见,入场动效
  - [ ] 登录后:toolbar 焊顶无圆角,sidebar 焊左、右下 22px 圆角
  - [ ] 壁纸:切换 Bing/上传/内置 三种都正常显示在 body 背后,sidebar/toolbar/卡的 blur 有彩色折射
  - [ ] 切换 5 个强调色(改 body 的 data-accent-preset attr,在 console `document.body.dataset.accentPreset='purple'`):按钮、active 项、focus ring 全变色
  - [ ] 主按钮/次按钮/危险按钮 三种形状与 hover lift 正常
  - [ ] 输入框胶囊、focus 蓝色 glow
  - [ ] 开关:28mm 玻璃珠,ON 时蓝底 + 珠在右,过渡动画平滑
  - [ ] Tab 滑块:切换 tab 时白色滑块平滑跑过去
  - [ ] 下拉:浮层玻璃,li hover/accent 蓝 tint
  - [ ] Badge / ifacebox / 表格 / 进度条 / terminal 黑底半透明均玻璃化
  - [ ] 深色模式:玻璃是灰蓝底(不是纯黑反白),所有按钮/输入/开关/卡保持可读性
  - [ ] 移动端 ≤768px:汉堡按钮出现,sidebar 抽屉,toolbar 44px 高
  - [ ] footer:收敛在最后一张卡右下角,字号 11px tertiary 色
  - [ ] 报警红/警告橙/成功绿:有左边彩色竖条、tint 底
  - [ ] Modal/overlay:居中圆角 24px,overlay 半透明+blur
  - [ ] Bubble toast(右上角通知):滑入玻璃 chip

- [ ] **Step 3:常见问题修复预写**
  如果发现"LuCI 某页的 XXX 元素有 background:#fff 硬式 inline 盖过玻璃",用 CSS 优先级覆盖:例如 `.some-legacy-widget { background: var(--fill-regular) !important; }`,追加到 components.less 末尾。
  如果 `color-mix()` 在老版 Safari 不支持,用 `@supports (background: color-mix(in srgb, red, blue))` 条件包裹,fallback 到硬编码色。

- [ ] **Step 4:Final build**
  ```bash
  lessc less/cascade.less htdocs/luci-static/argon/css/cascade.css
  lessc less/dark.less   htdocs/luci-static/argon/css/dark.css
  ```

- [ ] **Step 5:提交**
  ```bash
  git add -A
  git commit -m "polish(liquid-glass): QA fixes and final build

Co-Authored-By: Claude Opus 4.8 <noreply@anthropic.com>"
  ```

---

## Plan Self-Review

**Spec coverage check:**
| Spec § | Task |
|---|---|
| §1 Token 系统 | Task 2 |
| §2 壁纸/背景 | Task 3 + Task 9 step 4 + Task 12 |
| §3 Shell 布局 | Task 4 |
| §4 控件 | Task 6(按钮/输入/开关/下拉/tab/checkbox) + Task 5(cards/tab rail/alert/action bar) + Task 7(badge/progress/ifacebox/table/tooltip/toast/terminal/scrollbar) |
| §5 登录页 | Task 9 |
| §6 长尾组件 | Task 7 |
| §7 LESS 模块化 | Task 1 + 全部 less 文件模块化 |
| §7.2 模板改动 | Task 9 step 2/3/4 + Task 11 |
| §7.3 JS(tab 滑块/wallpaper fallback) | Task 11 |
| §7.4 兼容/性能 | Task 3 fallback + Task 10 移动端 |
| 5 档强调色 | Task 11 accent preset + 每处用 `var(--accent)` |

**Placeholder scan:** 无 TBD/TODO;所有代码块完整可粘贴。

**Type consistency:** `--accent`/`--accent-tint`/`--fill-strong`/`--r-pill` 等 CSS 变量名通篇一致;js 里 `data-accent-preset` 与模板 `data-accent-preset=` 一致;所有 less mixin 调用签名一致。
