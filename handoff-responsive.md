# Shoko's Japanese Lessons — 响应式调整交接文档

给新对话的上下文说明。静态网站（HTML/CSS/JS，无框架），4 个页面已完成 Figma 像素级还原，并做过一轮"按宽度区间排查"的响应式审计（320px～1512px+ 均验证过无横向溢出、无明显错位）。用户反馈"大致没有问题，但手机的页面还需要调整"——说明目前的审计是**排除硬伤（溢出、重叠、断裂）**，但手机端（约 375～430px 真实设备宽度）的视觉精修程度还没有达到桌面端那种逐 Section 打磨的水平，接下来要做的是**手机端的细致调整**，不只是"不出错"。

## 文件位置

- `site/index.html` — 首页
- `site/booking.html` — 预约入口页（两张选择卡片）
- `site/booking-code.html` — 老学生输入预约码页
- `site/booking-new.html` — 新学生流程说明页（What happens next）
- `site/assets/styles.css` — 共用样式表，所有响应式规则都在这一个文件里
- `site/assets/*` — 图片/SVG 素材

## 当前响应式断点结构（styles.css 里已有的媒体查询）

- `@media (max-width: 860px)` — 主要的移动端断点，大部分手机端布局改动都在这里（`.wrap` 改窄边距、hero 区块转 `flex-direction: column`、卡片改单列等）
- `@media (min-width: 861px) and (max-width: 1250px)` — 中间宽度专用，修复 footer-cta 装饰图标和标题重叠的问题
- `@media (max-width: 1220px)` — booking-new.html 的 `.step-arrow` 隐藏阈值（三步卡片换行时箭头会指向空处，所以提前隐藏）

**接下来做手机端精修时，改动大概率都落在 `max-width: 860px` 这个区块里，也可能需要新增一个更窄的断点（比如 `max-width: 480px` 或 `max-width: 400px`）来单独处理小屏手机（iPhone SE 375px 这个级别），因为目前 860px 断点是"手机+小平板"通用的，没有区分"平板宽度"和"手机窄宽度"两种情况，细节上可能不够贴合真正的手机比例。**

## 已修复的响应式坑（复用经验，不用重新踩一遍）

1. **横向溢出**：`html` 和 `body` 都要加 `overflow-x: hidden`（只加 body 不够，koi 贴纸这类故意超出容器的装饰元素会导致 `document.documentElement.scrollWidth` 仍然溢出）。
2. **flex-basis 在 column 布局下失效变成 height**：`.hero-copy` / `.hero-visual` / `.recommended-video` / `.recommended-copy` 这类用 `flex: 1 1 Npx` 做桌面端宽度基准的元素，一旦父容器在移动端切到 `flex-direction: column`，那个 `Npx` 会变成强制高度而不是宽度，导致巨大空白。移动端断点里要显式加 `flex-basis: auto`。
3. **flex 子项默认 `min-width: auto` 导致无法收缩**：`.booking-card` 及其 `.card-body` 都需要显式 `min-width: 0`，否则子元素（比如一个 `white-space: nowrap` 的按钮）撑开的 min-content 宽度会顶破整个卡片布局。配合按钮上加 `width:100%; white-space:normal; text-align:center`，让文字在极窄屏（320px）下允许换行兜底。
4. **`[hidden]` 属性被同名 class 的 `display` 规则覆盖**：`.code-actions[hidden]`、`.code-helper-error[hidden]` 这类，因为 class 选择器已经设置了 `display:flex`，后声明的作者样式会盖过浏览器默认的 `[hidden]{display:none}`，必须显式写 `.xxx[hidden] { display: none; }`。
5. **flex-wrap 换行导致装饰性箭头/连接线错位**：`.steps-grid` 在中等宽度换行时，连接两个卡片的箭头图片会变成"指向空处"的孤立元素，需要额外算一个隐藏阈值宽度（每个 item 宽度 + gap + padding 累加）。

## 测试方法（这个 sandbox 环境的坑）

```bash
cd /sessions/<session>/mnt/outputs/site && python3 -m http.server <port> >/tmp/http.log 2>&1 &
sleep 1
export LD_LIBRARY_PATH=/tmp/shot/extra_libs
python3 - <<'EOF'
from playwright.sync_api import sync_playwright
import glob, os
exe = glob.glob(os.path.expanduser("~/.cache/ms-playwright/chromium-*/chrome-linux/chrome"))[0]
with sync_playwright() as p:
    browser = p.chromium.launch(executable_path=exe, headless=True)
    for w in [320, 375, 390, 414, 430]:  # 常见真实手机宽度
        page = browser.new_page(viewport={"width": w, "height": 900})
        page.goto(f"http://localhost:<port>/index.html")
        print(w, page.evaluate("document.documentElement.scrollWidth - document.documentElement.clientWidth"))
        page.screenshot(path=f"/sessions/<session>/mnt/outputs/w{w}.png", full_page=True)
        page.close()
    browser.close()
EOF
```

要点：
- 必须在**同一次 bash 调用**里启动 server 并跑 Playwright，分两次调用会因为 sandbox 隔离导致 `ERR_CONNECTION_REFUSED`。
- `/tmp` 内容不会跨 bash 调用持久化，`libxdamage1` 每次都要重新 `apt-get download` + `dpkg-deb -x` 解压到 `/tmp/shot/extra_libs`（同一次调用里做）。
- 检测溢出用 `document.documentElement.scrollWidth - clientWidth`，判断文字重叠用 `Range.selectNodeContents()` + `getClientRects()`（比 `getBoundingClientRect()` 的粗暴碰撞检测准，因为居中文字的容器 box 本身横跨整行，不代表文字本身重叠）。
- 截图完用 Read 工具查看，不要用 bash 直接读图片。
- 这次审计用的宽度点是 320/375/768/1024/1150/1220/1250/1280/1512，手机精修阶段建议重点用真实设备宽度：**375（iPhone SE/8）、390（iPhone 12/13/14）、414（iPhone Plus 系列）、430（iPhone Pro Max）**。

## 4 个页面目前的状态

- **index.html**：已过一轮响应式审计，hero/推荐视频/评价卡片/footer-cta 装饰重叠等问题已修复。
- **booking.html**：两张选择卡片在窄屏下的宽度溢出、按钮换行已修复。
- **booking-code.html**：`[hidden]` 覆盖问题已修复，表单区域窄屏下验证过无溢出。
- **booking-new.html**：三步流程箭头换行错位问题已修复（隐藏阈值 1220px），320～1280px 全部验证过。

以上都只验证了"不出硬伤"，**手机端的间距节奏、字号大小是否舒适、触控区域是否够大这些体验细节还没有专门过一遍**，这是新对话要接着做的事。

## 沟通习惯 / 用户偏好（重要）

- 回复要简洁直接，不要长篇大论、不要过度使用列表/加粗。
- 对于非平凡的改动，习惯是"先讨论方案，用户确认后再动手"；明确的小数值调整可以直接执行。
- 用户是设计师本人，注重像素级还原度和真实设备下的实际观感，不只是"技术上没 bug"就算完成。
- 建议新对话一开始先问用户：手机精修是想按页面顺序过，还是先给一版全部页面的真机宽度截图，一起看哪里需要调？

## 暂缓的其他事项（不要主动提起，除非用户重新提）

1. 网站上线部署（之前对比过 Netlify / Cloudflare Pages / GitHub Pages，用户倾向免费子域名，还没最终确认平台）
2. 客户想加的日记/vlog 功能（三个方向：静态页面、接 Notion/CMS、链接到现有社交媒体，用户想先规划思路，还没深入）
3. Google Calendar 预约表单的时区问题（免费版无法根据访客时区自动换算，用户说"先不管"）
