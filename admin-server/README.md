# 無名の主页 · 管理后台

免重新编译的运行时配置管理后台。修改配置后**刷新主站即可生效**，无需 `pnpm build`。

## 快速开始

```bash
cd admin-server
npm install
npm start
```

启动后访问：

- **管理后台**：<http://localhost:12446/admin>
- **主站预览**：<http://localhost:12446/>

## 工作原理

原项目的配置通过 `.env` 中的 `VITE_` 环境变量注入，**编译时**被静态替换，所以每次改配置都要重新 build。

本管理后台的改造：

1. 新增 `public/runtime-config.json` —— 所有 `VITE_` 配置的运行时版本
2. `src/utils/config_check.ts` 改为 `Proxy` 动态读取，启动时 `fetch('/runtime-config.json')` 加载
3. `public/siteLinks.json` 与 `public/socialLinks.json` 从 `src/assets/` 移到 `public/`，组件运行时 `fetch` 加载
4. `admin-server/` 提供 Web UI 修改上述 JSON 文件

优先级：`runtime-config.json` > `.env` 编译值 > `example_config.json`。

## 可管理内容

| 模块 | 文件 | 说明 |
|------|------|------|
| 站点信息 | `public/runtime-config.json` | 站点名称/作者/简介/Logo/ICP 等 |
| 简介文本 | `public/runtime-config.json` | 问候语、彩蛋文本 |
| 网站链接 | `public/siteLinks.json` | 首页快捷链接列表 |
| 社交链接 | `public/socialLinks.json` | 社交图标与链接 |
| 背景配置 | `public/images/config.json` | 壁纸数量（PC/移动端） |
| 音乐配置 | `public/runtime-config.json` | Meting API、歌单 ID 等 |
| 天气配置 | `public/runtime-config.json` | 腾讯/高德天气 Key |
| TTS 配置 | `public/runtime-config.json` | 语音 API 地址、语音人、鉴权 |

## 配置项

环境变量（可选）：

| 变量 | 默认值 | 说明 |
|------|--------|------|
| `PORT` | `12446` | 服务端口 |
| `PROJECT_ROOT` | `..`（admin-server 上一层） | 主项目根目录 |
| `ADMIN_TOKEN` | 空（不鉴权） | 鉴权 Token，设置后请求需带 `X-Admin-Token` 头 |

示例：

```bash
# 自定义端口和项目路径
PORT=8080 PROJECT_ROOT=/var/www/home node server.js

# 启用鉴权
ADMIN_TOKEN=mysecret node server.js
```

## 常见问题

### Q: 修改后主站没变化？

A: 浏览器缓存或 PWA 缓存导致。请 `Ctrl+F5` 强制刷新，或清除站点数据。开发模式下用 `pnpm dev` 可避免 PWA 缓存。

### Q: 生产部署怎么用？

A: 将 `dist/`（主站构建产物）和 `public/runtime-config.json`、`public/siteLinks.json`、`public/socialLinks.json`、`public/images/config.json` 一起部署到静态服务器；`admin-server/` 单独部署为 Node 服务，设置 `PROJECT_ROOT` 指向主站静态目录。

### Q: 还需要 `.env` 吗？

A: 需要。`.env` 作为**编译时 fallback**，当 `runtime-config.json` 加载失败或某项为空时回退到 `.env` 的值。构建时仍需要 `.env` 提供默认值。运行时配置优先级更高。

### Q: 鉴权怎么开启？

A: 设置 `ADMIN_TOKEN` 环境变量。开启后所有 `/api/*` 请求需在请求头中带 `X-Admin-Token: <token>`。管理后台 UI 目前不带鉴权 UI，需自行扩展或通过反向代理保护。
