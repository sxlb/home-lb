# Home-SXLB

> 🤖 本项目由 AI 辅助编写 | AI-Assisted Project

现代化个人主页系统 — 可视化管理，零代码配置。

![AI Generated](https://img.shields.io/badge/AI-Generated-blue)

## 环境要求

- **Node.js** >= 18（[下载地址](https://nodejs.org)）或 **Docker**

## 快速开始

### 方式一：一键脚本（推荐）

```bash
# Windows
build.cmd

# Linux / macOS
chmod +x scripts/install.sh
./scripts/install.sh
```

### 方式二：Docker

```bash
docker compose up -d
```

### 方式三：手动

```bash
cd backend
npm install
npm run init-db
npm run dev
```

启动后打开浏览器：

| 页面 | 地址 |
|------|------|
| 前台主页 | `http://localhost:3001` |
| 后台管理 | `http://localhost:3001/admin` |

> 默认账号：**admin** / 密码：**admin123**

## 功能一览

| 功能 | 说明 |
|------|------|
| 站点信息 | 名称、描述、头像、作者 |
| 实时时钟 | 当前时间和建站天数 |
| 天气显示 | 支持高德/腾讯天气 API |
| 一言 | 随机语录展示 |
| 社交链接 | GitHub、B站、邮箱等 |
| 导航链接 | 自定义网站链接 |
| 音乐播放器 | 网易云音乐播放 |
| 主题切换 | 浅色 / 深色 / 跟随系统 |
| 季节特效 | 飘落动效 |

## 目录结构

```
home-sxlb/
├── backend/         后端服务（Express + SQLite）
├── frontend/        前台页面（Vue 3 + Vite）
├── admin/           后台管理（Vue 3 + Element Plus）
├── scripts/         部署脚本
├── Dockerfile       Docker 镜像
├── docker-compose.yml
├── build.cmd        Windows 一键构建
└── .github/         GitHub Actions 自动构建
```

## 技术栈

- **后端**：Node.js / Express / SQLite / JWT
- **前端**：Vue 3 / Vite / Pinia / Element Plus
- **数据库**：SQLite（无需额外安装，一个文件搞定）

## 许可证

MIT License
