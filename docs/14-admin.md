# 14 - 管理后台

## 14.1 概述

管理后台是一个**独立运行的 Node.js 服务**，提供 Web UI 修改主站的运行时配置，**修改后主站刷新即生效**，无需重新 `pnpm build`。

主要解决痛点：传统 `.env` 配置在 Vite 项目中是编译时静态替换，每次改配置都要重新构建并部署，对运维极不友好。

源码位置：[admin-server/](../admin-server/)

| 文件 | 职责 |
| --- | --- |
| [admin-server/server.js](../admin-server/server.js) | Express 服务器，提供 API + 静态资源 |
| [admin-server/public/index.html](../admin-server/public/index.html) | 管理后台 UI（单文件 HTML，含 CSS+JS） |
| [admin-server/package.json](../admin-server/package.json) | 依赖声明（仅 express + cors） |
| [admin-server/README.md](../admin-server/README.md) | 简明使用说明 |

## 14.2 工作原理

### 14.2.1 传统模式（编译时注入）

```
.env → vite build → 静态替换到 dist/*.js → 部署
```

改任何配置都要重走 `vite build`。

### 14.2.2 管理后台模式（运行时注入）

```
admin-server → 写入 public/runtime-config.json
                ↓
主站启动 → fetch('/runtime-config.json') → 动态读取
                ↓
envConfig (Proxy) → 优先返回 runtimeConfig 的值
```

主站 [src/utils/config_check.ts](../src/utils/config_check.ts) 在应用挂载前调用 `loadRuntimeConfig()`，启动后所有 `envConfig.XXX` 读取都通过 Proxy 动态返回运行时配置值。

### 14.2.3 三级配置优先级

```
runtime-config.json  >  .env (编译时)  >  example_config.json
```

详见 [03 - 配置系统](./03-config.md)。

## 14.3 服务器实现

### 14.3.1 启动入口

[server.js:178-191](../admin-server/server.js)：

```js
app.listen(PORT, () => {
  console.log("========================================");
  console.log("  無名の主页 管理后台已启动");
  console.log(`  管理后台:  http://localhost:${PORT}/admin`);
  console.log(`  主站预览:  http://localhost:${PORT}/`);
  console.log(`  项目根目录: ${PROJECT_ROOT}`);
  if (ADMIN_TOKEN) console.log(`  鉴权:      已启用 (X-Admin-Token)`);
  else             console.log(`  鉴权:      未启用 (设置 ADMIN_TOKEN 环境变量以开启)`);
});
```

### 14.3.2 路径配置

```js
const PROJECT_ROOT = process.env.PROJECT_ROOT
  ? path.resolve(process.env.PROJECT_ROOT)
  : path.resolve(__dirname, "..");   // 默认 admin-server 上一级
```

`PROJECT_ROOT` 决定读写哪个目录下的 `public/`，方便部署到任意位置。

### 14.3.3 管理的文件清单

[server.js:35-40](../admin-server/server.js)：

```js
const FILES = {
  runtimeConfig: path.join(PROJECT_ROOT, "public", "runtime-config.json"),
  siteLinks:     path.join(PROJECT_ROOT, "public", "siteLinks.json"),
  socialLinks:   path.join(PROJECT_ROOT, "public", "socialLinks.json"),
  bgConfig:      path.join(PROJECT_ROOT, "public", "images", "config.json"),
};
```

### 14.3.4 JSON 原子写入

[server.js:71-94](../admin-server/server.js) 的 `writeJson` 实现了**原子写入**：

1. 先写到 `xxx.json.tmp-{timestamp}` 临时文件
2. `fs.rename` 原子地替换目标文件
3. rename 失败则重试 3 次直接写入，间隔 100ms

避免写入过程中断导致配置文件损坏。

### 14.3.5 静态资源托管

```js
app.use("/admin", express.static(path.join(__dirname, "public")));     // 管理后台 UI
app.use("/",      express.static(path.join(PROJECT_ROOT, "public")));  // 主站静态资源
```

同一个服务同时托管：

- `/admin/*` → 管理后台 UI
- `/*` → 主站 `public/` 目录（可直接预览主站）

## 14.4 API 接口

### 14.4.1 鉴权中间件

```js
const ADMIN_TOKEN = process.env.ADMIN_TOKEN || "";
const authMiddleware = (req, res, next) => {
  if (!ADMIN_TOKEN) return next();   // 未设置 token 则跳过
  const token = req.headers["x-admin-token"] || req.query.token || "";
  if (token !== ADMIN_TOKEN) {
    return res.status(401).json({ error: "未授权访问" });
  }
  next();
};
```

支持两种传 token 方式：

- 请求头：`X-Admin-Token: <token>`
- URL 参数：`?token=<token>`

### 14.4.2 接口列表

| 方法 | 路径 | 说明 |
| --- | --- | --- |
| `GET` | `/api/all` | 一次性拉取所有配置 |
| `POST` | `/api/runtime-config` | 保存站点信息/简介/音乐/天气/TTS 等运行时配置 |
| `POST` | `/api/site-links` | 保存网站链接列表（数组） |
| `POST` | `/api/social-links` | 保存社交链接列表（数组） |
| `POST` | `/api/bg-config` | 保存壁纸数量配置 |

所有接口：

- 都挂载 `authMiddleware`（若启用 token）
- POST body 限制 2MB（`express.json({ limit: "2mb" })`）
- 启用 CORS（`app.use(cors())`），支持跨域调用

### 14.4.3 GET /api/all 响应示例

```json
{
  "runtimeConfig": {
    "VITE_SITE_NAME": "無名の主页",
    "VITE_SONG_API": "https://metingapi.nanorocky.top/",
    ...
  },
  "siteLinks": [
    { "icon": "Blog", "name": "博客", "link": "https://..." }
  ],
  "socialLinks": [
    { "name": "GitHub", "icon": "/images/icon/github.png", "tip": "去看看", "url": "https://github.com/..." }
  ],
  "bgConfig": { "bgImageCount": 10, "bgImageCountP": 2 }
}
```

文件不存在或解析失败时返回默认空值（`{}` / `[]` / `{ bgImageCount: 10, bgImageCountP: 2 }`），不抛错。

## 14.5 管理后台 UI

### 14.5.1 整体布局

```
┌─────────────────────────────────────────────────────────┐
│  Header (logo + 状态徽章 + 主站预览 + 重新加载)            │
├──────────┬──────────────────────────────────────────────┤
│ Sidebar │  Content (当前激活的 tab)                      │
│          │                                                │
│ 站点信息 │  ┌─ Card ──────────────────────────────┐    │
│ 网站链接 │  │  表单字段...                          │    │
│ 社交链接 │  └────────────────────────────────────┘    │
│ 背景配置 │  ┌─ Card ──────────────────────────────┐    │
│ 音乐配置 │  │  表单字段...                          │    │
│ 天气&TTS │  └────────────────────────────────────┘    │
│          │  [💾 保存]                                  │
└──────────┴──────────────────────────────────────────────┘
```

### 14.5.2 六个功能 Tab

#### 1. 站点信息

包含两组表单：

- **站点基本信息**：站点名称、作者、自定义名、关键词、简介、URL、建站日期、Logo、主页图标、Apple 图标、ICP 备案、公安备案、移动端备案（共 13 个字段）
- **简介文本**：问候语、简介内容、彩蛋问候语、彩蛋内容（共 4 个字段）

对应环境变量：`VITE_SITE_NAME`、`VITE_SITE_AUTHOR`、`VITE_DESC_HELLO` 等，UI 中每个 label 旁边都有灰色提示显示变量名。

#### 2. 网站链接

表格形式管理 `public/siteLinks.json`，每行：

| 序号 | 图标 (下拉) | 名称 | 链接 | 删除 |
| --- | --- | --- | --- | --- |

- 图标可选：`Blog`、`Cloud`、`CompactDisc`、`Compass`、`Book`、`Fire`、`LaptopCode`
- 支持添加 / 删除 / 编辑
- 双向绑定：input change 立即写入内存数组

#### 3. 社交链接

表格形式管理 `public/socialLinks.json`，每行：

| 序号 | 名称 | 图标路径 | 提示文本 | 链接 | 删除 |
| --- | --- | --- | --- | --- | --- |

- 图标为图片路径，如 `/images/icon/github.png`
- 与网站链接相同的增删改模式

#### 4. 背景配置

简单表单：

- **PC 版壁纸数量** `bgImageCount`：默认 10
- **移动版壁纸数量** `bgImageCountP`：默认 2

> 注：修改数量后需自行将对应数量的 `background[N].jpg` 放入 `public/images/`。

#### 5. 音乐配置

- **Meting API 地址** `VITE_SONG_API`
- **歌曲服务器 1** `VITE_SONG_SERVER`：下拉 `netease` / `tencent`
- **歌曲服务器 2** `VITE_SONG_SERVER_SECOND`：可留空（不启用第二源）
- **播放类型** `VITE_SONG_TYPE`：下拉 `playlist` / `song` / `album` / `artist` / `search`
- **播放 ID 1 / 2** `VITE_SONG_ID` / `VITE_SONG_ID_SECOND`
- **Meting API 鉴权 SKEY** `VITE_METING_SKEY`（可选）

#### 6. 天气 & TTS

两个 Card：

- **天气 API 配置**：腾讯 Key、高德 Key、腾讯鉴权 SKEY
- **TTS 语音 API 配置**：API 地址、音色、风格、TTS 鉴权 SKEY、特殊文件鉴权 SKEY

### 14.5.3 交互细节

- **状态徽章**：右上角"已加载"/"加载失败"实时反馈
- **Toast 提示**：保存成功/失败均会浮出短暂通知（2.5 秒后自动消失）
- **重新加载按钮**：手动从服务器拉取最新配置覆盖本地编辑
- **主站预览按钮**：新窗口打开 `/` 查看主站效果
- **移动端响应式**：< 768px 时侧边栏改为抽屉式，左上角 ☰ 按钮唤出
- **数据双向绑定**：input change 立即更新内存数据，"保存"按钮才真正写入服务器

### 14.5.4 关键 JS 函数

[index.html:547-776](../admin-server/public/index.html)：

| 函数 | 作用 |
| --- | --- |
| `reloadAll()` | 拉取 `/api/all` 并填充所有表单 |
| `fillRuntimeForm()` | 用 `runtimeConfig` 数据填充所有 input |
| `collectRuntimeForm()` | 从所有 input 收集数据组装对象 |
| `saveRuntimeConfig()` | POST `/api/runtime-config` 保存 |
| `renderSiteLinks()` | 渲染网站链接表格 |
| `addSiteLink()` / `removeSiteLink(idx)` | 增删行 |
| `saveSiteLinks()` | POST `/api/site-links` 保存 |
| `renderSocialLinks()` / `addSocialLink()` / `removeSocialLink(idx)` / `saveSocialLinks()` | 社交链接同上 |
| `fillBgForm()` / `saveBgConfig()` | 背景配置的填充与保存 |
| `toast(msg, type)` | 弹出通知 |
| `api(url, method, body)` | fetch 封装，统一错误处理 |
| `escapeHtml(s)` | HTML 转义防止 XSS |

## 14.6 快速开始

### 14.6.1 安装与启动

```bash
cd admin-server
npm install          # 或 pnpm install
npm start            # 或 node server.js
```

### 14.6.2 访问地址

- 管理后台：`http://localhost:12446/admin`
- 主站预览：`http://localhost:12446/`

### 14.6.3 典型使用流程

1. 启动 admin-server
2. 浏览器访问 `/admin`
3. 切换到"站点信息"Tab，修改站点名称
4. 点击"💾 保存站点信息"
5. 新窗口打开 `/`（或 Ctrl+F5 强制刷新主站）
6. 看到主站名称已变化，**无需重新构建**

## 14.7 环境变量

| 变量 | 默认值 | 说明 |
| --- | --- | --- |
| `PORT` | `12446` | 服务监听端口 |
| `PROJECT_ROOT` | `..`（admin-server 上一层） | 主项目根目录 |
| `ADMIN_TOKEN` | 空（不鉴权） | 鉴权 token，设置后请求需带 `X-Admin-Token` |

示例：

```bash
# 自定义端口与项目路径
PORT=8080 PROJECT_ROOT=/var/www/home node server.js

# 启用鉴权
ADMIN_TOKEN=mysecret node server.js
```

## 14.8 生产部署

### 14.8.1 与主站同机部署（最简单）

```
/var/www/home/
├── dist/                          ← 主站构建产物
├── public/                        ← 运行时配置目录
│   ├── runtime-config.json
│   ├── siteLinks.json
│   ├── socialLinks.json
│   └── images/config.json
└── admin-server/
    └── server.js

# 启动（PROJECT_ROOT 指向上层，即 /var/www/home）
PROJECT_ROOT=/var/www/home PORT=12446 node admin-server/server.js
```

admin-server 同时托管 `/admin`（管理 UI）与 `/`（主站 `public/`），但主站 `dist/` 需用 Nginx 单独服务，或者把 `dist/` 内容拷贝到 `public/` 下。

### 14.8.2 Nginx + admin-server 分离部署

```nginx
server {
    listen 80;
    server_name example.com;
    root /var/www/home/dist;

    # 主站
    location / {
        try_files $uri $uri/ /index.html;
    }

    # 运行时配置走 admin-server，便于实时刷新
    location ~ ^/(runtime-config|siteLinks|socialLinks)\.json$ {
        proxy_pass http://127.0.0.1:12446;
    }
    location /images/config.json {
        proxy_pass http://127.0.0.1:12446;
    }

    # 管理后台（建议加 IP 白名单或 Basic Auth）
    location /admin {
        # allow 1.2.3.4;      # 你的 IP
        # deny all;
        proxy_pass http://127.0.0.1:12446;
    }
    location /api {
        # allow 1.2.3.4;
        # deny all;
        proxy_pass http://127.0.0.1:12446;
    }
}
```

### 14.8.3 Docker 单容器部署

项目自带 [Dockerfile](../Dockerfile) 与 [docker-compose.yml](../docker-compose.yml)，采用**单容器**架构：由 `admin-server` 统一提供主站、管理后台、API 服务。

```yaml
services:
  home:
    build: .
    image: home:latest
    container_name: home
    restart: unless-stopped
    ports:
      - "${PORT:-12446}:12446"
    environment:
      - NODE_ENV=production
      - ADMIN_TOKEN=${ADMIN_TOKEN:-}
    healthcheck:
      test: ["CMD", "wget", "--spider", "-q", "http://localhost:12446/api/all"]
      interval: 30s
      timeout: 5s
      retries: 3
      start_period: 15s
```

启动：

```bash
cp scripts/.env.deploy.example .env.deploy
# 编辑 .env.deploy，至少设置 ADMIN_TOKEN
docker compose --env-file .env.deploy up -d --build
```

Dockerfile 三阶段构建：

1. **web-builder**：构建前端 SPA → `dist/`
2. **admin-builder**：安装 admin-server 生产依赖
3. **最终镜像**：合并 `dist/` + `admin-server/` + `node_modules/`，由 `node admin-server/server.js` 启动

主站与 admin-server 共享同一文件系统，admin-server 直接读写 `public/runtime-config.json`，主站刷新即可看到修改。

### 14.8.4 PM2 守护进程

```bash
npm install -g pm2
ADMIN_TOKEN=mysecret pm2 start server.js --name home-admin
pm2 save
pm2 startup
```

## 14.9 鉴权说明

### 14.9.1 当前实现

- 设置 `ADMIN_TOKEN` 环境变量后，所有 `/api/*` 请求必须携带 token
- 支持 `X-Admin-Token` 请求头或 `?token=xxx` URL 参数
- **UI 不带登录界面**：开启鉴权后直接访问 `/admin` 仍可看 UI，但所有 API 调用会 401 失败

### 14.9.2 加上登录界面（自行扩展）

修改 [admin-server/public/index.html](../admin-server/public/index.html) 的 `api()` 函数：

```js
async function api(url, method = 'GET', body = null) {
  const token = localStorage.getItem('admin_token') || prompt('请输入管理 Token:');
  if (token) localStorage.setItem('admin_token', token);
  const opts = {
    method,
    headers: {
      'Content-Type': 'application/json',
      'X-Admin-Token': token,
    }
  };
  if (body) opts.body = JSON.stringify(body);
  const resp = await fetch(url, opts);
  if (resp.status === 401) {
    localStorage.removeItem('admin_token');
    throw new Error('Token 无效');
  }
  return resp.json();
}
```

### 14.9.3 Nginx Basic Auth（推荐）

```nginx
location /admin {
    auth_basic "Admin Area";
    auth_basic_user_file /etc/nginx/.htpasswd;
    proxy_pass http://127.0.0.1:12446;
}
```

简单可靠，无需改代码。

## 14.10 与主站的协作关系

### 14.10.1 文件共享

admin-server 写入的文件，主站会读取：

| admin-server 写入 | 主站读取位置 |
| --- | --- |
| `public/runtime-config.json` | [src/utils/config_check.ts](../src/utils/config_check.ts) `loadRuntimeConfig()` |
| `public/siteLinks.json` | Links 组件运行时 `fetch('/siteLinks.json')` |
| `public/socialLinks.json` | SocialLinks 组件运行时 `fetch('/socialLinks.json')` |
| `public/images/config.json` | Background 组件读取壁纸数量 |

### 14.10.2 缓存策略

主站 [config_check.ts:14](../src/utils/config_check.ts) 使用 `cache: 'no-cache'` 拉取 `runtime-config.json`，避免浏览器缓存导致修改不生效。

但 PWA Service Worker 可能缓存该文件，导致修改后主站仍读旧值。解决方案：

1. `Ctrl + F5` 强制刷新
2. 清除站点数据
3. 开发模式用 `pnpm dev` 跳过 PWA
4. 修改 [vite.config.ts](../vite.config.ts) 的 `runtimeCaching`，将 `runtime-config.json` 排除在缓存之外

### 14.10.3 `.env` 还需要吗？

需要。`.env` 作为**编译时 fallback**：

- `runtime-config.json` 加载失败时回退
- 某个字段在 `runtime-config.json` 中为空时回退
- 构建时仍需 `.env` 提供默认值

详见 [03 - 配置系统](./03-config.md)。

## 14.11 注意事项

1. **默认无鉴权**：未设置 `ADMIN_TOKEN` 时任何人可访问 `/admin` 并修改配置。生产环境务必启用鉴权或用 Nginx 反代保护。

2. **端口冲突**：admin-server 默认端口 `12446` 与 [Dockerfile](../Dockerfile) 中 `http-server` 的端口相同。若同机部署需错开 `PORT`。

3. **文件写入权限**：admin-server 进程需对 `PROJECT_ROOT/public/` 有写权限。Docker 部署时注意挂载卷的权限设置。

4. **JSON 格式校验**：当前 server.js 直接接收 body 写入文件，未做 schema 校验。前端 UI 限制了字段范围，但 API 直接调用可写入任意结构。建议生产环境加反向代理并限制访问来源。

5. **并发写入**：原子写入（rename）避免单次写入损坏，但多个 admin 同时修改仍可能互相覆盖。建议只让一个管理员操作。

6. **UI 无登录界面**：开启 `ADMIN_TOKEN` 后访问 `/admin` 仍能看到 UI 框架，但所有 API 调用 401。建议自行扩展或用 Nginx Basic Auth。

7. **不可管理壁纸文件**：UI 只能改壁纸数量配置，无法上传 / 替换壁纸文件。需手动将 `background[N].jpg` 放到 `public/images/`。

8. **不可管理本地语音**：`public/speechlocal/` 下的 mp3 无法通过 UI 修改，需手动替换。

## 14.12 扩展指南

### 14.12.1 新增一个可配置字段

1. 在 [public/runtime-config.json](../public/runtime-config.json) 添加字段，如 `VITE_NEW_FIELD`。
2. 在 [src/utils/config_check.ts](../src/utils/config_check.ts) 的 `viteKeys` 数组添加该字段名。
3. 在 [admin-server/public/index.html](../admin-server/public/index.html) 对应 Tab 添加：
   ```html
   <div class="form-item">
     <label>新字段 <span class="hint">VITE_NEW_FIELD</span></label>
     <input id="VITE_NEW_FIELD" />
   </div>
   ```
4. 在 `fillRuntimeForm()` 与 `collectRuntimeForm()` 的 `keys` 数组中添加 `'VITE_NEW_FIELD'`。
5. 在代码中使用 `envConfig.VITE_NEW_FIELD` 读取。

### 14.12.2 新增一个可管理的 JSON 文件

1. 在 [server.js](../admin-server/server.js) 的 `FILES` 对象添加：
   ```js
   const FILES = {
     ...
     myData: path.join(PROJECT_ROOT, "public", "myData.json"),
   };
   ```
2. 修改 `GET /api/all` 与添加 `POST /api/my-data` 路由。
3. 在 UI 添加对应 Tab 与表格渲染逻辑。

### 14.12.3 接入数据库

当前用文件存储，适合个人/小规模部署。若需多人协作或历史记录，可改造为 SQLite / MySQL：

- 替换 `readJson` / `writeJson` 为数据库查询
- 添加用户表与登录系统
- 添加操作日志表

但工作量较大，建议仅在确实需要时进行。
