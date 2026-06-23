# Home-SXLB

> 🤖 本项目由 AI 辅助编写 | AI-Assisted Project

现代化个人主页系统 — 可视化管理，零代码配置。

![AI Generated](https://img.shields.io/badge/AI-Generated-blue)

## 环境要求

- **Node.js** >= 18（[下载地址](https://nodejs.org)）
- **npm** 随 Node.js 自带

## 安装步骤

一共三步：**装依赖 → 初始化 → 启动**

```bash
# 1. 安装所有依赖（只执行一次）
cd backend
npm install

# 2. 初始化数据库（只执行一次）
npm run init-db

# 3. 启动服务
npm run dev
```

启动后打开浏览器访问：

| 页面 | 地址 |
|------|------|
| 前台主页 | `http://localhost:3001` |
| 后台管理 | `http://localhost:3001/admin` |

> 后台默认账号：**admin** / 密码：**admin123**

## 一键构建（生产环境）

如果前端代码有改动，需要重新构建：

```bash
# 构建前端
cd frontend
npm install
npm run build

# 构建管理后台
cd admin
npm install
npm run build

# 构建后端
cd backend
npm install
npm run build

# 启动
cd backend
npm start
```

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
├── backend/     后端服务（Express + SQLite）
├── frontend/    前台页面（Vue 3 + Vite）
├── admin/       后台管理（Vue 3 + Element Plus）
└── .github/     GitHub Actions 自动构建
```

## 技术栈

- **后端**：Node.js / Express / SQLite / JWT
- **前端**：Vue 3 / Vite / Pinia / Element Plus
- **数据库**：SQLite（无需额外安装，一个文件搞定）

## 许可证

MIT License
