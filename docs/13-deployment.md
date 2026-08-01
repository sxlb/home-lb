# 13 - 部署与运行

## 13.1 环境要求

| 依赖 | 版本 | 说明 |
| --- | --- | --- |
| Node.js | ≥ 20（推荐 24） | 与 Dockerfile 一致使用 `node:24-slim` |
| pnpm | 10 | 通过 `corepack enable` 自动激活 |
| 浏览器 | 现代浏览器（Chrome 90+ / Edge 90+ / Firefox 88+ / Safari 14+） | 需支持 ES2022、Service Worker、Canvas 2D |

## 13.2 配置系统

项目采用**三级配置回退**机制，详见 [03 - 配置系统](./03-config.md)。优先级：

```
runtime-config.json  >  .env (编译时)  >  example_config.json
```

### 13.2.1 三种配置方式对比

| 方式 | 文件 | 何时生效 | 适用场景 |
| --- | --- | --- | --- |
| 运行时配置 | `public/runtime-config.json` | 应用启动时 fetch | Docker 部署后改配置不重构建 |
| 编译时配置 | `.env` | `vite build` 时注入 | 本地开发 / 静态部署 |
| 示例配置 | `src/assets/example_config.json` | 兜底 | 未配置时的默认值 |

### 13.2.2 启用配置系统

`.env` 中必须将 `VITE_CONFIG_TURN` 设为 `"true"`，否则：

- 应用挂载前会弹出警告对话框
- 所有 `VITE_*` 变量返回空值
- 项目功能异常

### 13.2.3 关键环境变量

完整列表见 [.env.example](../.env.example)，最关键的几项：

| 变量 | 用途 | 默认值 |
| --- | --- | --- |
| `VITE_CONFIG_TURN` | 启用配置系统 | `"true"` |
| `VITE_SITE_NAME` | 站点名称 | `"無名の主页"` |
| `VITE_TX_WEATHER_KEY` | 腾讯天气 KEY | 空（用备用源） |
| `VITE_GD_WEATHER_KEY` | 高德天气 KEY | 空 |
| `VITE_SONG_API` | Meting API 地址 | `https://metingapi.nanorocky.top/` |
| `VITE_TTS_API` | Azure TTS 中转地址 | 空 |
| `VITE_TTS_Voice` | 默认音色 | `zh-CN-YunxiNeural` |
| `VITE_SITE_START` | 建站日期 | `2020-10-24` |
| `VITE_SITE_ICP` | ICP 备案号 | `豫ICP备2022018134号-1` |

### 13.2.4 运行时配置示例

部署后可创建 `public/runtime-config.json`（或部署根目录下 `runtime-config.json`）覆盖编译时配置：

```json
{
  "VITE_SITE_NAME": "我的主页",
  "VITE_SITE_AUTHOR": "张三",
  "VITE_SITE_URL": "https://example.com",
  "VITE_TX_WEATHER_KEY": "XXXXX-XXXXX-XXXXX-XXXXX-XXXXX",
  "VITE_SONG_API": "https://my-meting-api.example.com/",
  "VITE_SONG_ID": "1234567890",
  "VITE_TTS_API": "https://my-tts.example.com/"
}
```

加载逻辑见 [src/utils/config_check.ts:12-24](../src/utils/config_check.ts)，使用 `fetch('/runtime-config.json', { cache: 'no-cache' })`，避免缓存导致配置不生效。

## 13.3 本地开发

### 13.3.1 安装依赖

```bash
pnpm install
```

### 13.3.2 准备配置

```bash
cp .env.example .env
```

按需编辑 `.env`，至少修改 `VITE_SITE_NAME`、`VITE_SITE_URL` 等。

### 13.3.3 启动开发服务器

```bash
pnpm dev
```

- 默认端口 `3000`（见 [vite.config.ts:104-107](../vite.config.ts)）
- 自动打开浏览器（`open: true`）
- 监听所有网卡（`--host`），方便手机访问调试

### 13.3.4 类型检查

```bash
pnpm type-check
```

使用 `vue-tsc --noEmit` 进行完整类型检查，不输出文件。

### 13.3.5 代码格式化与 Lint

```bash
pnpm format    # Prettier 格式化
pnpm lint       # ESLint 修复
```

## 13.4 构建生产版本

### 13.4.1 构建命令

```bash
pnpm build
```

执行 `vue-tsc --noEmit && vite build`，先做类型检查，通过后才进入 Vite 构建。

### 13.4.2 构建产物

输出目录 `dist/`，结构：

```
dist/
├── index.html
├── registerSW.js          # PWA 注册脚本
├── sw.js                  # Service Worker
├── workbox-*.js           # Workbox 运行时
├── manifest.webmanifest   # PWA 清单
├── assets/
│   ├── index-*.js         # 主包（含 vendor chunk）
│   ├── index-*.css
│   ├── xiaomi_weather_data-*.js  # 小米天气数据
│   ├── custom_data-*.js          # 站点链接数据
│   └── ...
├── images/
├── font/
├── speechlocal/
└── runtime-config.json
```

### 13.4.3 构建优化配置

[vite.config.ts](../vite.config.ts) 中的关键配置：

#### 代码分包 `manualChunks`

```ts
manualChunks(id) {
  if (id.includes('node_modules')) return 'vendor';
  if (id.includes('xiaomi_weather_adcode.json') || id.includes('xiaomi_weather_status.json')) {
    return 'xiaomi_weather_data';
  }
  if (id.includes('siteLinks.json') || id.includes('socialLinks.json')) {
    return 'custom_data';
  }
}
```

- `vendor`：所有第三方依赖合并为一个 chunk，便于长效缓存
- `xiaomi_weather_data`：小米天气查找表独立分包（约 100KB+），避免阻塞主包
- `custom_data`：站点链接配置数据独立分包

#### 压缩 `terser`

```ts
minify: "terser",
terserOptions: {
  compress: { pure_funcs: ["console.debug"] },
}
```

仅移除 `console.debug`，保留 `console.log` 与 `console.error` 用于线上排查。

#### 静态资源压缩 `viteCompression`

```ts
viteCompression()
```

默认生成 `.gz` 预压缩文件，Nginx 可通过 `gzip_static on` 直接发送。

#### CSS 优化

```ts
css: {
  postcss: {
    plugins: [
      postcssPresetEnv({ stage: 3, features: { 'nesting-rules': true } }),
      cssnano()
    ]
  }
}
```

- `postcss-preset-env`：转换未来 CSS 语法（如嵌套规则）
- `cssnano`：压缩 CSS

#### 警告阈值

```ts
chunkSizeWarningLimit: 1024  // 1MB
```

超过 1MB 的 chunk 才告警，避免 vendor 包警告干扰。

## 13.5 部署方式

### 13.5.1 方式一：静态服务器（最简单）

构建后用任意静态服务器托管 `dist/`：

```bash
# 使用 http-server（与 Dockerfile 一致）
npx http-server dist -p 12445

# 或使用 serve
npx serve dist -p 12445
```

### 13.5.2 方式二：Docker 单容器（推荐）

项目已提供 [Dockerfile](../Dockerfile) 与 [docker-compose.yml](../docker-compose.yml)，采用**单容器同时承载主站与管理后台**，由 `admin-server` 统一提供 HTTP 服务。

#### 架构

```
宿主机:PORT ──► [容器 12446] ──► admin-server (Express)
                          ├── /            → 主站 dist/ (Vue SPA)
                          ├── /admin       → 管理后台 UI
                          ├── /api/*       → 配置读写 API
                          └── /xxx.json    → public/ 运行时配置
```

- **主站**：构建产物 `dist/` 由 Express 静态托管，未匹配路径回退到 `index.html`
- **管理后台 UI**：`admin-server/public/` 由 `/admin` 路径托管
- **运行时配置**：`public/runtime-config.json` 等可被管理后台实时修改
- **单一端口**：容器内固定 `12446`，对外端口由 `PORT` 控制

#### Dockerfile 多阶段构建

```dockerfile
# 阶段 1：构建前端 SPA
FROM node:24-slim AS web-builder
WORKDIR /app
COPY package.json pnpm-lock.yaml ./
RUN corepack enable && corepack prepare pnpm@10 --activate
RUN pnpm install --frozen-lockfile
COPY . .
RUN [ ! -e ".env" ] && cp .env.example .env || true
RUN pnpm run build

# 阶段 2：安装 admin-server 生产依赖
FROM node:24-slim AS admin-builder
WORKDIR /app
COPY admin-server/package.json admin-server/package-lock.json* ./
RUN npm install --omit=dev

# 阶段 3：最终镜像（同时包含前端产物与 admin-server）
FROM node:24-slim
WORKDIR /app
COPY --from=admin-builder /app/node_modules ./node_modules
COPY admin-server/ ./admin-server/
COPY --from=web-builder /app/dist ./dist
COPY --from=web-builder /app/public ./public
RUN addgroup -S app && adduser -S home -G app \
    && chown -R home:app /app/public       # admin-server 需写入运行时配置
USER home                                  # 非 root 运行
ENV NODE_ENV=production PORT=12446 PROJECT_ROOT=/app
EXPOSE 12446
HEALTHCHECK --interval=30s --timeout=5s --start-period=15s --retries=3 \
  CMD node -e "fetch('http://localhost:12446/api/all').then(r=>process.exit(r.ok?0:1)).catch(()=>process.exit(1))"
CMD ["node", "admin-server/server.js"]
```

特点：

- **三阶段构建**：最终镜像不含源码、前端 `node_modules`，体积小
- **单容器单进程**：`admin-server` 同时托管主站、管理后台、API，无需 Nginx
- **非 root 用户**：`home` 用户运行，提升安全性
- **自动补 .env**：前端构建阶段若无 `.env` 自动从 `.env.example` 复制
- **内置健康检查**：探测 `/api/all` 接口可用性

#### docker-compose 部署

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

#### 启动命令

```bash
# 1. 复制并修改环境变量
cp scripts/.env.deploy.example .env.deploy
#   编辑 .env.deploy，至少设置 ADMIN_TOKEN

# 2. 构建并启动
docker compose --env-file .env.deploy up -d --build

# 3. 验证
curl http://localhost:12446/              # 主站
curl http://localhost:12446/api/all       # API
```

- 主站访问：`http://localhost:12446/`
- 管理后台：`http://localhost:12446/admin`

#### 自定义对外端口

修改 `.env.deploy` 中的 `PORT`：

```
PORT=80        # 宿主机 80 端口直接映射到容器 12446
```

#### 持久化运行时配置

默认配置文件存储在镜像内 `/app/public` 下，重建镜像会丢失。如需持久化，取消 `docker-compose.yml` 中的 volumes 注释：

```yaml
volumes:
  - ./public/runtime-config.json:/app/public/runtime-config.json
  - ./public/siteLinks.json:/app/public/siteLinks.json
  - ./public/socialLinks.json:/app/public/socialLinks.json
  - ./public/images/config.json:/app/public/images/config.json
```

或进入容器修改：

```bash
docker exec -it home sh
echo '{"VITE_SITE_NAME":"新名称"}' > public/runtime-config.json
```

> 提示：直接进入容器修改的配置在镜像重建后会丢失，生产环境建议使用 volumes 挂载。

### 13.5.3 方式三：Nginx 反向代理

生产环境推荐 Nginx 托管静态资源 + 反向代理 API：

```nginx
server {
    listen 80;
    server_name example.com;
    root /var/www/home/dist;
    index index.html;

    # 开启预压缩
    gzip_static on;

    # PWA Service Worker 不缓存
    location = /sw.js {
        add_header Cache-Control "no-cache, no-store, must-revalidate";
        expires off;
    }
    location = /registerSW.js {
        add_header Cache-Control "no-cache, no-store, must-revalidate";
        expires off;
    }
    location = /runtime-config.json {
        add_header Cache-Control "no-cache, no-store, must-revalidate";
        expires off;
    }

    # HTML 不缓存，避免更新后白屏
    location ~ \.html$ {
        add_header Cache-Control "no-cache, no-store, must-revalidate";
    }

    # 静态资源长效缓存
    location ~* \.(js|css|woff2?|ttf|png|jpg|jpeg|svg|gif)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
    }

    # SPA 回退
    location / {
        try_files $uri $uri/ /index.html;
    }

    # 反向代理 Meting API（解决 CORS）
    location /meting/ {
        proxy_pass https://your-meting-api.com/;
        proxy_set_header Host your-meting-api.com;
    }

    # 反向代理 TTS API
    location /tts/ {
        proxy_pass https://your-tts-api.com/;
        proxy_set_header Host your-tts-api.com;
    }

    # 反向代理小米天气中转
    location /xmw/ {
        proxy_pass https://api.nanorocky.top/xmw/;
        proxy_set_header Host api.nanorocky.top;
    }
}
```

配置后修改 `runtime-config.json`：

```json
{
  "VITE_SONG_API": "/meting/",
  "VITE_TTS_API": "/tts/"
}
```

### 13.5.4 方式四：CI/CD 自动构建

项目自带 GitHub Actions 工作流 [.github/workflows/build.yml](../.github/workflows/build.yml)，监听 `EFU` 分支推送：

```yaml
on:
  push:
    branches:
      - EFU
```

流程：

1. checkout 代码
2. 安装 pnpm 10 + Node.js 24
3. 缓存 `~/.pnpm-store` 与 `node_modules/.cache`
4. 若无 `.env` 自动从 `.env.example` 复制
5. `pnpm install --frozen-lockfile`
6. `pnpm run build`
7. 校验 `dist/` 存在且非空
8. 上传为 artifact（保留 3 天）

可在此基础扩展部署步骤（如 rsync 到服务器、上传 OSS 等）。

## 13.6 PWA 配置

### 13.6.1 关键设置

[vite.config.ts:30-101](../vite.config.ts) 中的 `VitePWA` 插件配置：

```ts
VitePWA({
  registerType: "autoUpdate",   // 自动更新
  workbox: {
    skipWaiting: true,          // 新 SW 立即激活
    clientsClaim: true,         // 立即接管所有客户端
    runtimeCaching: [
      // JS/CSS/字体 → CacheFirst
      // 图片 → CacheFirst
    ],
  },
  manifest: { ... }
})
```

### 13.6.2 更新机制

`autoUpdate` + `skipWaiting` + `clientsClaim` 组合实现"无感更新"：

1. 用户访问站点，旧 SW 控制页面
2. 后台下载新版本资源
3. 安装完成后立即激活（不等旧 SW 退出）
4. 触发 `controllerchange` 事件
5. [main.ts:51-61](../src/main.ts) 监听事件，提示用户刷新

```ts
navigator.serviceWorker.addEventListener("controllerchange", async () => {
  ElMessage("网站已更新，请刷新网页嗷！");
  if (store.webSpeech) SpeechLocal("更新提示.mp3");
});
```

### 13.6.3 故障排查

#### 子页面跳转回主页

注释中提到（[vite.config.ts:32-34](../vite.config.ts)）：

```ts
// selfDestroying: true,
// injectRegister: false,
```

如遇子页面自动跳转主页或缓存问题，可取消注释这两行禁用 PWA。

#### 缓存不更新

1. 强制刷新：`Ctrl + Shift + R`
2. DevTools → Application → Service Workers → Unregister
3. DevTools → Application → Storage → Clear site data

#### Service Worker 不注册

- 必须通过 HTTPS（或 `localhost`）访问
- 检查 `registerSW.js` 是否成功加载
- 部分浏览器要求 `manifest.webmanifest` 可访问

### 13.6.4 Manifest 配置

```ts
manifest: {
  name: env.VITE_SITE_NAME,
  short_name: env.VITE_SITE_NAME,
  description: env.VITE_SITE_DES,
  display: "standalone",
  start_url: "/",
  theme_color: "#424242",
  background_color: "#424242",
  icons: [
    { src: "/images/icon/48.png",  sizes: "48x48",   type: "image/png" },
    { src: "/images/icon/72.png",  sizes: "72x72",   type: "image/png" },
    { src: "/images/icon/96.png",  sizes: "96x96",   type: "image/png" },
    { src: "/images/icon/128.png", sizes: "128x128", type: "image/png" },
    { src: "/images/icon/144.png", sizes: "144x144", type: "image/png" },
    { src: "/images/icon/192.png", sizes: "192x192", type: "image/png" },
    { src: "/images/icon/512.png", sizes: "512x512", type: "image/png" },
  ],
}
```

如需修改主题色或图标，对应修改 `theme_color` 与 `public/images/icon/` 下的图片。

## 13.7 URL 参数

应用启动时支持通过 URL 参数覆盖部分状态（[main.ts:63-82](../src/main.ts)）：

| 参数 | 作用 | 示例 |
| --- | --- | --- |
| `?set=reset` | 重置所有配置到默认值 | `https://example.com/?set=reset` |
| `?bg=1` | 切换壁纸类型（0 PC / 1 手机） | `?bg=1` |
| `?bgc=5` | 指定壁纸编号 | `?bg=0&bgc=5` |
| `?devs=true` | 启用开发者模式 | `?devs=true` |
| `?pap=true` | 自动播放音乐 | `?pap=true` |

可组合使用：`https://example.com/?bg=0&bgc=3&pap=true`

## 13.8 后端 API 部署

项目依赖三个可选的后端服务：

### 13.8.1 Meting API（音乐）

- **作用**：获取网易云/QQ 音乐歌单、歌曲 URL、歌词
- **官方仓库**：[injahow/meting-api](https://github.com/injahow/meting-api)
- **逐字歌词增强版**：[NanoRocky/meting-api](https://github.com/NanoRocky/meting-api)（推荐）
- **配置变量**：`VITE_SONG_API`
- **鉴权**：可选配置 `VITE_METING_SKEY`

### 13.8.2 Azure TTS API（语音）

- **作用**：实时文字转语音
- **官方仓库**：[NanoRocky/AzureSpeechAPI-by-PHP](https://github.com/NanoRocky/AzureSpeechAPI-by-PHP)
- **配置变量**：`VITE_TTS_API`、`VITE_TTS_Voice`、`VITE_TTS_Style`
- **鉴权**：可选配置 `VITE_TTS_SKEY`

### 13.8.3 小米天气中转 / IP 地理位置

- **作用**：免 KEY 时的天气数据源
- **作者提供**：`api.nanorocky.top`
- **接口**：
  - `https://api.nanorocky.top/xmw/?city=weathercn:${city}` — 小米天气
  - `https://api.nanorocky.top/tbipinfo/?ip=...` — IP 地理位置
- **捐赠**：作者承担服务器费用，建议捐赠支持
- **稳定性**：有速率限制，不保证可用，正式部署务必自申请腾讯/高德 KEY

## 13.9 资源文件准备

### 13.9.1 图标

替换 `public/images/icon/` 下的图标文件，保持文件名与尺寸不变：

| 文件 | 尺寸 | 用途 |
| --- | --- | --- |
| `favicon.ico` | 32x32 | 浏览器标签页图标 |
| `logo.png` | - | 主页 Logo |
| `apple-touch-icon.png` | 180x180 | iOS 添加到主屏图标 |
| `48.png` ~ `512.png` | 对应尺寸 | PWA Manifest 图标 |

### 13.9.2 壁纸

`public/images/` 下：

- `background1.jpg` ~ `background10.jpg`：PC 端壁纸
- `phone/backgroundphone1.jpg`、`backgroundphone2.jpg`：移动端壁纸

如需增减壁纸数量，同步修改 `Background.vue` 中的 `bgImageCount` 与 `bgImageCountP` 常量。

### 13.9.3 本地语音

`public/speechlocal/` 下存放预生成 mp3，命名规范见 [11 - 语音系统](./11-speech.md)。最小必备文件：

```
更新提示.mp3
天气加载失败.mp3
位置信息获取失败.mp3
欢迎1.mp3 ~ 欢迎10.mp3
```

### 13.9.4 站点 / 社交链接

- `src/assets/siteLinks.json`：网站快捷入口
- `src/assets/socialLinks.json`：社交平台链接

修改后需重新 `pnpm build`。

## 13.10 启动流程详解

[main.ts:86-127](../src/main.ts) 中的启动 IIFE：

```ts
(async () => {
  // 1. 加载运行时配置（失败回退到编译时）
  await loadRuntimeConfig();

  // 2. 检查配置开关
  if (!envConfig.VITE_CONFIG_TURN || envConfig.VITE_CONFIG_TURN != "true") {
    // 配置未启用 → 弹窗警告，用户确认后继续
    ElMessageBox.confirm('检测到您似乎没有创建配置文件，项目可能出现异常！', '警告', {...})
      .then(() => mountApp())
      .catch(() => ElMessage({ type: 'info', message: '已取消' }));
  } else {
    // 3. 校验作者信息（仅警告，不阻断）
    if (config.author != 'imsyy' || config.efua != 'NanoRocky') {
      console.warn('作者信息被修改，仅警告');
    }
    // 4. 正常挂载
    mountApp();
  }
})();
```

`mountApp()` 内部完成：

1. 显示 `#app` 元素
2. `app.mount("#app")` 挂载 Vue
3. 检查 `?set=reset` URL 参数，触发配置重置
4. 注册 Service Worker `controllerchange` 监听
5. 解析 URL 参数（`bg`、`bgc`、`devs`、`pap`）应用到 store

## 13.11 常见问题

### 13.11.1 部署后白屏

**排查**：

1. 浏览器控制台是否有报错
2. `runtime-config.json` 是否存在且 JSON 合法
3. 是否启用了 `VITE_CONFIG_TURN=true`
4. 检查 `index.html` 中资源路径是否为相对路径
5. 子路径部署需配置 Vite `base` 选项

### 13.11.2 音乐无法播放

**排查**：

1. `VITE_SONG_API` 是否可达
2. 是否有 CORS 限制（用 Nginx 反代解决）
3. 歌单 ID 是否有效
4. Meting API 是否限制了 QQ 音乐 / 网易云的访问

### 13.11.3 天气一直显示"获取失败"

**排查**：

1. 未配置 KEY 时使用公共接口，可能被限流
2. 自部署 KEY 时检查 `VITE_TX_WEATHER_KEY` 是否正确
3. 检查浏览器控制台具体失败原因
4. 高德在 IPv6 网络下会自动回退到 IPv4 接口

### 13.11.4 PWA 安装后图标不显示

**排查**：

1. `manifest.webmanifest` 中的 `icons` 路径是否可访问
2. 图标尺寸是否齐全（48/72/96/128/144/192/512）
3. 图标必须是 PNG 格式
4. 部分浏览器要求 192x192 与 512x512 必须存在

### 13.11.5 语音不播报

**排查**：

1. 设置面板是否开启了 `webSpeech`
2. 首次访问浏览器拦截了自动播放，需用户首次点击交互
3. `VITE_TTS_API` 是否可达（实时合成语音）
4. `public/speechlocal/` 下是否有对应 mp3（本地音频）
5. 移动端可能受省电策略限制

### 13.11.6 部署到子路径

默认部署在根路径 `/`。若部署在 `/home/`，需修改：

1. `vite.config.ts`：
   ```ts
   base: '/home/'
   ```
2. PWA `manifest.start_url` 与 `icons` 路径
3. Nginx `try_files` 配置

### 13.11.7 升级版本

1. 备份 `public/runtime-config.json`、自定义壁纸、本地语音
2. 拉取新代码：`git pull origin EFU`
3. `pnpm install` 更新依赖
4. `pnpm build`
5. 还原备份文件
6. 用户端访问会自动触发 PWA 更新

## 13.12 性能优化建议

1. **开启 HTTP/2**：Nginx 配置 `listen 443 ssl http2;`
2. **开启 Brotli 压缩**：比 gzip 更小，需 Nginx 编译 `ngx_brotli` 模块
3. **CDN 加速**：静态资源上 CDN，配置 `Cache-Control: immutable`
4. **图片优化**：壁纸转 WebP 格式可减少 30% 体积
5. **字体子集化**：MiSans 字体仅保留中文常用字符
6. **Service Worker 预缓存**：调整 `runtimeCaching` 策略，按需缓存
