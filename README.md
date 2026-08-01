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

無名の主页是一个基于 Vue 3 + TypeScript 的个人主页项目，具有载入动画、站点简介、一言、日期时间、实时天气、时光进度条、音乐播放器、逐字歌词、移动端适配等功能。

本项目在原作者 [imsyy](https://github.com/imsyy/) 的基础上，由酪灰（[NanoRocky](https://github.com/NanoRocky/)）与 Pizero 进行了二次开发，新增了管理后台、i18n 国际化、逐字歌词兼容、季节特效等功能。

### 核心功能

- [x] 载入动画
- [x] 站点简介
- [x] Hitokoto 一言
- [x] 日期及时间
- [x] 实时天气（多源聚合，腾讯/高德/小米）
- [x] 时光进度条
- [x] 音乐播放器（APlayer + 逐字歌词）
- [x] 移动端适配
- [x] 逐字歌词兼容（DWRC/YRC/QRC）
- [x] 季节特效（雪花/萤火虫/灯笼）
- [x] 管理后台（在线配置，无需重新构建）
- [x] i18n 国际化（中英文双语）
- [x] PWA 离线缓存与自动更新

### 技术栈

- [Vue 3](https://cn.vuejs.org/) + [TypeScript](https://www.typescriptlang.org/zh/)
- [Vite](https://vitejs.cn/vite3-cn/) + [Pinia](https://pinia.vuejs.org/zh/)
- [Element Plus](https://element-plus.org/zh-CN/)
- [APlayer](https://aplayer.js.org/) 音乐播放器
- [UnoCSS](https://unocss.dev/) 原子化 CSS
- [vue-i18n](https://vue-i18n.intlify.dev/) 国际化
- [IconPark](https://iconpark.oceanengine.com/official) + [xicons](https://xicons.org/)
- [Express](https://expressjs.com/) 管理后台

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

脚本支持 `deploy`、`update`、`restart`、`backup`、`rollback` 等子命令。

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

构建完成后，静态资源会在 `dist` 目录中生成，可将 `dist` 文件夹下的文件上传至服务器。

### 方式四：Vercel 部署

1. 点击本仓库右上角的 `Fork`，复制本仓库到你的 GitHub 账号
2. 复制 `/.env.example` 文件并重命名为 `/.env`（重要）
3. 按需修改 `/.env` 文件中的配置
4. 点击 `Deploy`，即可成功部署

### 方式五：GitHub Actions 自动构建

在成功 `fork` 仓库后，前往 `Actions` 页面开启工作流，修改仓库后即会触发构建，完成后可下载构建产物。

![步骤1](/screenshots/step1.jpg)
![步骤2](/screenshots/step2.jpg)

<p>&nbsp;<p>

## 配置

### 环境变量

复制 `.env.example` 为 `.env`，按需填写：

```bash
# 启用配置文件
VITE_CONFIG_ENABLE=true

# 站点信息
VITE_SITE_TITLE="無名の主页"
VITE_SITE_DESC="一个个人主页"

# 天气 API（腾讯位置服务 / 高德开放平台）
VITE_TENCENT_KEY=your-tencent-key
VITE_AMAP_KEY=your-amap-key

# 音乐 API（建议自行搭建 Meting-Api）
VITE_SONG_API="https://metingapi.nanorocky.top/"
VITE_SONG_SERVER="netease"
VITE_SONG_TYPE="playlist"
VITE_SONG_ID="3035221869"

# TTS 语音 API
VITE_TTS_API=your-tts-api
```

### 网站链接

在 `src/assets/siteLinks.json` 中自定义网站链接：

```json
{
  "icon": "Blog",
  "name": "博客",
  "link": "https://blog.your.domain/"
}
```

图标在 `src/components/Links/index.vue` 中引入（可前往 [xicons](https://www.xicons.org) 自行挑选）。

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

### 管理后台

部署后访问 `/admin` 路径即可使用管理后台，支持在线管理：

- 站点信息（名称、描述、Logo、API 密钥）
- 网站链接与社交链接（含图标库）
- 背景配置
- 前端默认设置（22 项，含壁纸、主题、音量、语言等）

> 生产环境务必设置 `ADMIN_TOKEN` 环境变量以启用鉴权。

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

>[!WARNING]
> 强烈建议自行注册天气 Token，它们是免费且稳定的！内置的免费接口目前仅剩小米天气可正常工作，且拥有较高的速率限制，经常失效。

## Star History

[![Star History Chart](https://api.star-history.com/svg?repos=imsyy/home&type=Date)](https://star-history.com/#imsyy/home&Date)

## 特别鸣谢

- [AMLL TTML Database](https://github.com/Steve-xmh/amll-ttml-db)
- [Meting API](https://github.com/injahow/meting-api)

### 感谢原作者 imsyy 和帮助本项目的小伙伴们！

- [imsyy](https://github.com/imsyy/)
- [这个哔养得](https://github.com/pizeroLOL/)

<a title="SSL" target="_blank" href="https://myssl.com/seal/detail?domain=nanorocky.top"><img src="https://img.shields.io/badge/MySSL-安全认证-brightgreen"></a>&nbsp;<a title="CDN" target="_blank" href="https://cdnjs.com/"><img src="https://img.shields.io/badge/CDN-Cloudflare-blue"></a>&nbsp;<a title="CDN2" target="_blank" href="https://cdnjs.com/"><img src="https://img.shields.io/badge/CDN-Tencent EdgeOne-blue"></a>&nbsp;<a title="Copyright" target="_blank" href="https://nanorocky.top/"><img src="https://img.shields.io/badge/Copyright%20%C2%A9%202023--2025-酪灰-red"></a>
