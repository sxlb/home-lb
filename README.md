简体中文 | [English](./README_EN.md)

> [!IMPORTANT]
> ## 致大家
> &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;·&nbsp;嘿！恭喜你看到这里~ 这是酪灰基于原作者 imsyy 主页的修改版本！修改版本添加了更多的功能，但是也会带来更高的性能占用！（主要来自逐字歌词以及季节效果渲染），也添加了安全更新，增强安全性。<p>
> &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;·&nbsp;酪灰作为 Vue 初学者，因为热爱，拉着同学 Pizero 完善了这个项目，因此这些代码可能会很 shi，并可能充斥着不少 BUG。欢迎在遇到 BUG 时进行反馈，也欢迎各位大佬帮助！<p>
>#### 关于问题反馈以及求助
> &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;·&nbsp;遇到问题请在 Github 上提 issue ，需要帮助请在 Github 上发 discussion ，看到了会回复。除特殊情况外，<b>请不要直接通过其它社交方式联系酪灰！</b>酪灰不是客服，不提供售后服务，并没有那么多的时间来回复私聊。还请谅解！<p>
>### 最后，喜欢本项目的话麻烦给个 STAR ！阿里嘎多~

> [!NOTE]
> ## 更新日志（2026-08-01）
> &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;·&nbsp;本次更改由 **sxlb** 使用 [Trae](https://trae.cn/) 修改并推送到 [sxlb/home-lb](https://github.com/sxlb/home-lb) 仓库。<p>
> &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;·&nbsp;详细文档请查阅 [项目文档](https://github.com/sxlb/home-lb/blob/master/docs/README.md)（共 15 篇，涵盖架构、配置、组件、API、部署等）。<p>
>
> #### 本次主要更改内容
> - **管理后台（新增）**：原版没有后台功能，本次新增 Express 管理后台（`/admin`），支持在线管理站点信息、网站链接、社交链接、背景配置、前端默认设置（22 项可配置项）等，无需重新构建即可修改配置；
> - **i18n 国际化（新增）**：主站与管理后台均支持中英文双语切换，语音播报根据语言自动切换 voice，时间文本与 dayjs locale 同步国际化；
> - **Bug 修复**：修复 Player 快进/快退逻辑反转、PWA 更新语音文件路径、Docker 容器写权限、健康检查命令、后台移动端灰色遮罩等问题；
> - **新增文档**：`docs/` 目录共 15 篇文档（架构→配置→组件→API→歌词→天气→语音→季节效果→部署→管理后台）；
> - **新增部署脚本**：Linux `deploy.sh`、Windows `deploy.ps1`、Docker 单容器 `docker-compose.yml`；
> - **部署合并**：原双容器（Nginx + admin-server）合并为单容器，由 admin-server 统一提供主站、管理后台、API 服务。

<p>&nbsp;<p>

<strong><h2>無名の主页</h2></strong>
</p>

![無名の主页](/screenshots/main.png)<p>
![無名の主页](/screenshots/main1.png)<p>
![無名の主页](/screenshots/main2.png)<p>

## 项目介绍

無名の主页是一个基于 Vue 3 + TypeScript 的个人主页项目（版本 4.3.9.dev），具有载入动画、站点简介、一言、日期时间、实时天气、时光进度条、音乐播放器、逐字歌词、移动端适配等功能。

本项目在原作者 [imsyy](https://github.com/imsyy/) 的基础上，由酪灰（[NanoRocky](https://github.com/NanoRocky/)）与 Pizero 进行了二次开发，新增了管理后台、i18n 国际化、逐字歌词兼容、季节特效等功能。

### 核心功能

- [x] 载入动画
- [x] 站点简介
- [x] Hitokoto 一言
- [x] 日期及时间
- [x] 实时天气（多源聚合，腾讯/高德/小米/韩小韩/教书先生）
- [x] 时光进度条
- [x] 音乐播放器（APlayer + 逐字歌词 DWRC/YRC/QRC）
- [x] 移动端适配
- [x] 季节特效（雪花/萤火虫/灯笼，Canvas 渲染）
- [x] 管理后台（Express + 在线配置，无需重新构建）
- [x] i18n 国际化（中英文双语，vue-i18n）
- [x] PWA 离线缓存与自动更新
- [x] 语音交互（预生成音频 + Azure TTS 实时合成）

### 技术栈

- [Vue 3](https://cn.vuejs.org/) + [TypeScript](https://www.typescriptlang.org/zh/)
- [Vite](https://vitejs.cn/vite3-cn/) + [Pinia](https://pinia.vuejs.org/zh/)（含持久化与校验插件）
- [Element Plus](https://element-plus.org/zh-CN/)
- [@worstone/vue-aplayer](https://aplayer.js.org/) 音乐播放器
- [UnoCSS](https://unocss.dev/) 原子化 CSS
- [vue-i18n](https://vue-i18n.intlify.dev/) 国际化
- [Swiper](https://swiperjs.com/) 触摸滑动
- [Three.js](https://threejs.org/) + [jparticles](https://jparticles.js.org/) 粒子动画
- [Express](https://expressjs.com/) 管理后台
- [IconPark](https://iconpark.oceanengine.com/official) + [xicons](https://xicons.org/) 图标

### 项目结构

```
home/
├── admin-server/          # 管理后台（Express）
│   ├── locales/            # 后台语言包（zh-CN/en）
│   ├── public/             # 后台 UI（index.html）
│   └── server.js           # API 服务 + 静态资源 + SPA 路由
├── public/                 # 静态资源
│   ├── font/               # 字体（MiSans/Pacifico/UnidreamLED）
│   ├── images/             # 壁纸、图标、config.json
│   └── speechlocal/        # 预生成语音文件
├── scripts/                # 部署脚本（sh/ps1）
├── src/
│   ├── api/                # API 请求
│   ├── assets/             # 站点配置（siteLinks/socialLinks/example_config）
│   ├── components/          # 16 个 Vue 组件
│   ├── i18n/               # 国际化（语言包 + 初始化）
│   ├── store/              # Pinia store（含持久化、校验插件）
│   ├── style/              # 全局样式（明/暗主题）
│   ├── utils/              # 工具函数（天气/语音/歌词/时间/季节特效等）
│   └── views/              # 页面视图（Box/Func/Main/MoreSet）
├── docs/                   # 15 篇项目文档
├── Dockerfile              # 三阶段构建（web-builder → admin-builder → 运行时）
└── docker-compose.yml      # 单容器编排
```

### Demo

> &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;·&nbsp;由于 workbox 缓存原因，查看最新效果可能需要 `Ctrl` + `F5` 强制刷新浏览器缓存噢！

- [酪灰の主页](https://nanorocky.top/)

<p>&nbsp;<p>

## 部署

项目支持多种部署方式，按需选择。

### 方式一：Docker 部署（推荐）

采用**单容器**架构，由 `admin-server` 统一提供主站、管理后台、API 服务。

```bash
# 1. 复制环境变量示例
cp scripts/.env.deploy.example .env.deploy

# 2. 修改 ADMIN_TOKEN（强烈建议设置强密码）
vim .env.deploy

# 3. 一行命令完成构建 + 启动（Docker 内部会执行 pnpm build）
docker compose --env-file .env.deploy up -d --build
```

启动后访问：

- 主站：`http://localhost:12446/`
- 管理后台：`http://localhost:12446/admin`（修改配置后主站刷新即生效，无需重新构建）

### 方式二：一键部署脚本

项目提供 Linux 和 Windows 的一键部署脚本，详见 [scripts/README.md](./scripts/README.md)。

**Linux：**

```bash
sudo ADMIN_TOKEN=your-strong-secret ./scripts/deploy.sh deploy
```

**Windows（以管理员权限运行 PowerShell）：**

```powershell
.\scripts\deploy.ps1 deploy
```

**Linux 脚本子命令**：`deploy`、`update`、`build`、`restart`、`stop`、`status`、`health`、`rollback`、`uninstall`、`help`

**Windows 脚本子命令**：`deploy`、`build`、`start`、`stop`、`restart`、`status`、`health`、`clean`、`help`

### 方式三：手动部署

- **安装** [Node.js](https://nodejs.org/zh-cn/) **环境**（node > 24.13.0，npm > 10.15.0）

```bash
# 安装 pnpm
npm install -g pnpm

# 安装依赖
pnpm install

# 预览
pnpm dev

# 构建
pnpm build
```

构建完成后，静态资源会在 `dist` 目录中生成。

- **仅需静态站点**：将 `dist` 文件夹下的文件上传至服务器，用 Nginx 等托管即可
- **需要管理后台**：还需启动 admin-server，参见下方"宝塔面板部署"步骤 4-5

### 方式四：Vercel 部署

1. 点击本仓库右上角的 `Fork`，复制本仓库到你的 GitHub 账号
2. 复制 `/.env.example` 文件并重命名为 `/.env`（重要）
3. 按需修改 `/.env` 文件中的配置
4. 点击 `Deploy`，即可成功部署

### 方式五：GitHub Actions 自动构建

在成功 `fork` 仓库后，前往 `Actions` 页面开启工作流，修改仓库后即会触发构建，完成后可下载构建产物。

![步骤1](/screenshots/step1.jpg)
![步骤2](/screenshots/step2.jpg)

### 方式六：宝塔面板部署

适用于已安装宝塔面板的服务器。

**步骤 1：准备构建产物**

本地或通过 GitHub Actions 构建出 `dist` 目录，将 `dist` 与 `public` 一起打包上传。

**步骤 2：安装 Node.js**

在宝塔面板的「软件商店」中搜索并安装 Node.js 版本管理器，选择 Node.js 24.x。

**步骤 3：上传文件**

将整个项目上传至服务器（如 `/www/wwwroot/home`），或仅上传 `dist`、`public`、`admin-server` 三个目录。

**步骤 4：安装 admin-server 依赖**

在宝塔终端中执行：

```bash
cd /www/wwwroot/home/admin-server
npm install --omit=dev
```

**步骤 5：配置 PM2 守护进程**

在宝塔终端中执行：

```bash
cd /www/wwwroot/home
ADMIN_TOKEN=your-strong-secret PORT=12446 pm2 start admin-server/server.js --name home
pm2 save
```

**步骤 6：配置反向代理**

在宝塔面板中添加站点，绑定域名，并在站点设置中配置反向代理：

- 目标 URL：`http://127.0.0.1:12446`
- 发送域名：`$host`

启动后访问：

- 主站：`https://your-domain/`
- 管理后台：`https://your-domain/admin`

### 方式七：1Panel（1p）面板部署

适用于已安装 1Panel 的服务器。推荐使用应用商店的 Docker 管理功能。

**步骤 1：安装 Docker 与 Docker Compose**

在 1Panel 的「容器」菜单中确认 Docker 已安装。

**步骤 2：上传项目**

将项目代码上传至服务器（如 `/opt/home`），或通过 1Panel 的文件管理上传。

**步骤 3：配置环境变量**

在 1Panel 文件管理中，复制 `scripts/.env.deploy.example` 为 `.env.deploy`，修改 `ADMIN_TOKEN`。

**步骤 4：构建并启动**

在 1Panel 终端中执行：

```bash
cd /opt/home
docker compose --env-file .env.deploy up -d --build
```

或在 1Panel 的「容器 → 编排」中添加 Compose 项目，指向 `/opt/home/docker-compose.yml`，环境变量文件选择 `/opt/home/.env.deploy`。

**步骤 5：配置反向代理**

在 1Panel 的「网站」中创建反代站点：

- 代理地址：`http://127.0.0.1:12446`
- 绑定域名并申请 SSL 证书

启动后访问：

- 主站：`https://your-domain/`
- 管理后台：`https://your-domain/admin`

<p>&nbsp;<p>

## 配置

### 环境变量

复制 `.env.example` 为 `.env`，按需填写：

```bash
# 启用配置文件
VITE_CONFIG_TURN = "true"

# 站点信息
VITE_SITE_NAME = "無名の主页"          # 名称
VITE_SITE_AUTHOR = "無名"              # 作者
VITE_SITE_KEYWORDS = "無名,个人主页"    # 关键词
VITE_SITE_MAIN_NAME = "無名"           # 自定义名
VITE_SITE_DES = "一个默默无闻的主页"    # 站点简介
VITE_SITE_URL = "https://imsyy.top/"   # 站点地址
VITE_SITE_LOGO = "/images/icon/favicon.ico"
VITE_SITE_MAIN_LOGO = "/images/icon/logo.png"
VITE_SITE_APPLE_LOGO = "/images/icon/apple-touch-icon.png"

# 简介文本
VITE_DESC_HELLO = "Hello World !"
VITE_DESC_TEXT = "一个建立于 21 世纪的小站，存活于互联网的边缘"
VITE_DESC_HELLO_OTHER = "Oops !"
VITE_DESC_TEXT_OTHER = "哎呀，这都被你发现了（ 再点击一次可关闭 ）"

# 天气 Key（腾讯位置服务 / 高德开放平台）
VITE_TX_WEATHER_KEY = ""               # 腾讯位置服务 Key
VITE_GD_WEATHER_KEY = ""               # 高德开放平台 Key
VITE_TX_WEATHER_SKEY = ""              # 腾讯鉴权 SKEY（可选）

# 建站日期（YYYY-MM-DD 或 YYYY）
VITE_SITE_START = "2020-10-24"

# ICP 备案号
VITE_SITE_ICP = ""
VITE_SITE_MPS = ""

# 音乐 API
VITE_SONG_API = "https://metingapi.nanorocky.top/"
VITE_SONG_SERVER = "netease"           # netease-网易云, tencent-qq音乐
VITE_SONG_SERVER_SECOND = "tencent"   # 第二歌单服务器（可留空）
VITE_SONG_TYPE = "playlist"            # song/playlist/album/search/artist
VITE_SONG_ID = "9379831714"
VITE_SONG_ID_SECOND = "9518088898"     # 第二歌单 ID（可留空）
VITE_METING_SKEY = ""                  # Meting API 鉴权 SKEY（可选）

# 文字转语音 API
VITE_TTS_API = ""                      # 自行搭建
VITE_TTS_Voice = "zh-CN-YunxiNeural"
VITE_TTS_Style = "chat"
VITE_TTS_SKEY = ""                     # TTS 鉴权 SKEY（可选）
VITE_SFILE_SKEY = ""                   # 特殊文件 API 鉴权 SKEY（可选）
```

### 天气

天气及地区获取需要 `腾讯位置服务` 或 `高德开放平台` 的 Web 服务 Key：

- [腾讯位置服务](https://lbs.qq.com/)：每日上限 10000 次，支持 IPV4/IPV6，推荐
- [高德开放平台](https://console.amap.com/dev/index)：每日上限 5000 次，不支持 IPV6

>[!WARNING]
> 强烈建议自行注册天气 Token，它们是免费且稳定的！内置的免费接口（韩小韩/教书先生/小米）目前仅剩小米天气可正常工作，且拥有较高的速率限制，经常失效。

### 网站链接

在 `src/assets/siteLinks.json` 中自定义网站链接：

```json
{
  "icon": "Blog",
  "name": "博客",
  "link": "https://blog.your.domain/"
}
```

图标在 `src/components/Links.vue` 中引入（可前往 [xicons](https://www.xicons.org) 自行挑选）。

### 社交链接

在 `src/assets/socialLinks.json` 中自定义社交链接。

### 网站背景

在 `public/images` 中修改网站背景。添加更多本地壁纸时，将图片重命名为 `background+数字` 形式，并编辑 `public/images/config.json`：

```json
{
  "bgImageCount": 10,
  "bgImageCountP": 2
}
```

### 网站图标

在 `public/images/icon` 中修改网站图标。

### 语音交互

- **预生成语音**：提前生成并放在 `public/speechlocal/` 路径下，替换原有音频，用于固定通知（低延迟）
- **实时生成语音**：用于音乐播放器歌名播报，需自行搭建并填写在 `.env` 内

如使用 Azure，可直接使用 [AzureSpeechAPI-by-PHP](https://github.com/NanoRocky/AzureSpeechAPI-by-PHP) 完成 API 部署。

### 音乐

> 本项目采用了 `APlayer` 音乐播放器，可实现快速自定义歌单。仅支持中国大陆地区。

请在 `.env` 文件中更改歌曲相关参数实现自定义歌单列表。目前已支持设置两个歌单进行合并，如不需要，留空即可。

如需使用网易云音乐逐字歌词，请使用 [修改版 Meting-Api](https://github.com/NanoRocky/meting-api/)。

>[!WARNING]
> 这里提供的 api 有较高的速率限制，且不太稳定，强烈建议自行搭建 Meting-API！注意：提供的 api 可能出现 Q 音接口抛 401 的情况，并非服务异常，Q 音接口需要将项目编译后挂到正常域名并使用 https only，使用正常 443 端口，才能正常工作。

### 管理后台

部署后访问 `/admin` 路径即可使用管理后台，支持在线管理：

- 站点信息（名称、描述、Logo、API 密钥）
- 网站链接与社交链接（含图标库）
- 背景配置
- 前端默认设置（22 项，含壁纸、主题、音量、语言等）

> 生产环境务必设置 `ADMIN_TOKEN` 环境变量以启用鉴权。

### 字体

现采用 `MiSans` 和 `HarmonyOS Sans` 字体，采用字体拆分提升加载速度：

- `https://cdn-font.hyperos.mi.com/font/css?family=MiSans_VF:VF:Chinese_Simplify,Latin&display=swap`
- `https://s1.hdslb.com/bfs/static/jinkela/long/font/regular.css`

<p>&nbsp;<p>

## API

- [韩小韩 WebAPI 接口](https://api.vvhan.com/)
- [搏天 API](https://api.btstu.cn/doc/sjbz.php)
- [教书先生 API](https://api.oioweb.cn/doc/weather/GetWeather)
- [高德开放平台](https://lbs.amap.com/)
- [腾讯位置服务](https://lbs.qq.com/)
- [Hitokoto 一言](https://hitokoto.cn/)
- [Meting API](https://github.com/injahow/meting-api)
- [Meting API 酪灰修改版](https://github.com/NanoRocky/meting-api)

## Star History

[![Star History Chart](https://api.star-history.com/svg?repos=imsyy/home&type=Date)](https://star-history.com/#imsyy/home&Date)

## 特别鸣谢

- [AMLL TTML Database](https://github.com/Steve-xmh/amll-ttml-db)
- [Meting API](https://github.com/injahow/meting-api)

### 感谢原作者 imsyy 和帮助本项目的小伙伴们！

- [imsyy](https://github.com/imsyy/)
- [这个哔养得](https://github.com/pizeroLOL/)

<a title="SSL" target="_blank" href="https://myssl.com/seal/detail?domain=nanorocky.top"><img src="https://img.shields.io/badge/MySSL-安全认证-brightgreen"></a>&nbsp;<a title="CDN" target="_blank" href="https://cdnjs.com/"><img src="https://img.shields.io/badge/CDN-Cloudflare-blue"></a>&nbsp;<a title="CDN2" target="_blank" href="https://cdnjs.com/"><img src="https://img.shields.io/badge/CDN-Tencent EdgeOne-blue"></a>&nbsp;<a title="Copyright" target="_blank" href="https://nanorocky.top/"><img src="https://img.shields.io/badge/Copyright%20%C2%A9%202023--2025-酪灰-red"></a>
