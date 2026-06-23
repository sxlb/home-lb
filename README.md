# Home-SXLB

> 🤖 本项目由 AI 辅助编写 | AI-Assisted Project  
> 项目地址：[https://github.com/sxlb/home-lb](https://github.com/sxlb/home-lb)

现代化个人主页系统 — 可视化管理，零代码配置。支持 Docker 一键部署、Windows/Linux 一键脚本、GitHub Actions 自动构建。

![AI Generated](https://img.shields.io/badge/AI-Generated-blue) ![license](https://img.shields.io/badge/license-MIT-green) ![build](https://img.shields.io/badge/build-passing-brightgreen)

---

## 目录

- [环境要求](#环境要求)
- [快速开始](#快速开始)
  - [Docker 部署](#docker-部署推荐)
  - [Windows 一键构建](#windows-一键构建)
  - [Linux 一键安装](#linux-一键安装)
  - [手动安装](#手动安装)
- [访问地址](#访问地址)
- [功能一览](#功能一览)
- [目录结构](#目录结构)
- [环境变量](#环境变量)
- [API 接口](#api-接口)
- [技术栈](#技术栈)
- [开发指南](#开发指南)
- [GitHub Actions 自动构建](#github-actions-自动构建)
- [许可证](#许可证)

---

## 环境要求

| 依赖 | 版本 | 说明 |
|------|------|------|
| Node.js | >= 18 | [下载地址](https://nodejs.org) |
| npm | 随 Node.js 自带 | |
| Docker | 可选 | 推荐 24+ |

---

## 快速开始

### Docker 部署（推荐）

最简单的方式，无需安装 Node.js，一行命令启动：

```bash
# 克隆项目
git clone https://github.com/sxlb/home-lb.git
cd home-lb

# 启动
docker compose up -d
```

> 首次启动会自动构建镜像，约需 2-3 分钟。之后可直接访问 http://localhost:3001

**Docker 常用命令：**
```bash
docker compose up -d      # 后台启动
docker compose down       # 停止
docker compose logs -f    # 查看日志
docker compose restart    # 重启
```

**数据持久化：**
- 数据库：`./data/database/`
- 日志：`./data/logs/`

### Windows 一键构建

双击项目根目录的 `build.cmd`，脚本会自动完成：安装依赖 → 构建前端/后台/后端 → 初始化数据库。

或命令行运行：
```bash
cd home-lb
build.cmd
```

构建完成后启动：
```bash
cd backend
npm run dev     # 开发模式（热更新）
# 或
npm start       # 生产模式
```

### Linux 一键安装

```bash
# 克隆项目
git clone https://github.com/sxlb/home-lb.git
cd home-lb

# 执行安装脚本
chmod +x scripts/install.sh
./scripts/install.sh
```

脚本会自动完成：
1. 检测 Node.js 环境
2. 安装所有依赖
3. 构建前端、后台、后端
4. 初始化数据库

### 手动安装

如果以上方式都不适用，可以手动分步操作：

```bash
# 克隆项目
git clone https://github.com/sxlb/home-lb.git
cd home-lb

# 1. 安装后端依赖
cd backend
npm install

# 2. 构建后端
npm run build

# 3. 初始化数据库（首次运行）
npm run init-db

# 4. 构建前端
cd ../frontend
npm install
npm run build

# 5. 构建管理后台
cd ../admin
npm install
npm run build

# 6. 启动服务
cd ../backend
npm start
```

---

## 访问地址

服务默认运行在 `3001` 端口：

| 页面 | 地址 |
|------|------|
| 前台主页 | http://localhost:3001 |
| 后台管理 | http://localhost:3001/admin |

> **默认账号：** `admin`  
> **默认密码：** `admin123`  
> ⚠️ **首次登录后请立即修改密码！**

---

## 功能一览

### 前台展示

| 功能 | 说明 | 可配置 |
|------|------|--------|
| 站点信息 | 名称、描述、头像、作者 | ✅ |
| 实时时钟 | 当前时间、日期、建站天数 | ✅ |
| 天气显示 | 支持高德/腾讯天气 API | ✅ |
| 一言 | 随机语录展示 | ✅ |
| 社交链接 | GitHub、B站、Twitter、邮箱 | ✅ |
| 导航链接 | 自定义网站链接列表 | ✅ |
| 音乐播放器 | 网易云音乐播放 | ✅ |
| 主题切换 | 浅色 / 深色 / 跟随系统 | ✅ |
| 季节特效 | 飘落动效 | ✅ |

### 后台管理

| 模块 | 功能 |
|------|------|
| **仪表盘** | 系统状态一览、快速操作 |
| **站点设置** | 配置站点信息、社交链接、功能开关 |
| **文件管理** | 上传、浏览、删除图片 |
| **系统设置** | 修改密码、导出/导入配置、日志管理 |
| **版本更新** | 在线更新、版本历史、回滚 |
| **主题切换** | 浅色 / 深色 / 跟随系统 |

---

## 目录结构

```
home-lb/
├── backend/                  Node.js 后端服务
│   ├── src/
│   │   ├── config/           数据库配置与初始化
│   │   ├── routes/           API 路由
│   │   │   ├── auth.ts       认证接口
│   │   │   ├── config.ts     配置管理接口
│   │   │   ├── upload.ts     文件上传接口
│   │   │   ├── update.ts     版本更新接口
│   │   │   └── system.ts     系统管理接口
│   │   ├── middleware/       中间件
│   │   │   └── auth.ts       JWT 认证中间件
│   │   ├── utils/            工具函数
│   │   │   └── logger.ts     Winston 日志
│   │   └── index.ts          服务入口
│   ├── database/             SQLite 数据库文件
│   ├── dist/                 TypeScript 编译产物
│   ├── package.json
│   └── tsconfig.json
├── frontend/                 前台 Vue 3 应用
│   ├── src/
│   │   ├── views/            页面组件
│   │   ├── App.vue           主组件
│   │   ├── router.ts         路由配置
│   │   └── main.ts           应用入口
│   ├── public/               静态资源
│   │   └── images/           图标等
│   ├── dist/                 Vite 构建产物
│   ├── package.json
│   └── vite.config.ts
├── admin/                    后台管理 Vue 3 应用
│   ├── src/
│   │   ├── views/            页面组件
│   │   │   ├── Dashboard.vue 仪表盘
│   │   │   ├── Settings.vue  站点设置
│   │   │   ├── Upload.vue    文件管理
│   │   │   ├── System.vue    系统设置
│   │   │   └── Update.vue    版本更新
│   │   ├── App.vue           主组件
│   │   ├── router.ts         路由配置
│   │   └── main.ts           应用入口
│   ├── dist/                 Vite 构建产物
│   ├── package.json
│   └── vite.config.ts
├── scripts/                  部署脚本
│   ├── install.sh            Linux 一键安装
│   ├── docker-compose.yml    Docker Compose 配置（旧版）
│   ├── nginx.conf            Nginx 配置
│   └── DOCKER_README.md      Docker 说明
├── .github/
│   └── workflows/
│       ├── ci.yml            CI 自动构建
│       └── release.yml       版本发布
├── build.cmd                 Windows 一键构建
├── Dockerfile                Docker 镜像
├── docker-compose.yml        Docker 部署配置
└── README.md
```

---

## 环境变量

在 `backend/.env` 中配置（Docker 部署时在 `docker-compose.yml` 中设置）：

| 变量 | 默认值 | 说明 |
|------|--------|------|
| `PORT` | `3001` | 服务端口 |
| `JWT_SECRET` | `default-secret` | JWT 签名密钥，生产环境务必修改 |
| `DB_PATH` | `./database/home-sxlb.db` | SQLite 数据库路径 |
| `STATIC_PATH` | 自动检测 | 前端静态文件目录（Docker 中设为 `/app`） |
| `LOG_LEVEL` | `info` | 日志级别：debug / info / warn / error |

---

## API 接口

### 认证相关
| 方法 | 路径 | 说明 | 认证 |
|------|------|------|------|
| POST | `/api/auth/login` | 登录 | ❌ |
| GET | `/api/auth/me` | 获取当前用户信息 | ✅ |
| PUT | `/api/auth/password` | 修改密码 | ✅ |

### 配置管理
| 方法 | 路径 | 说明 | 认证 |
|------|------|------|------|
| GET | `/api/config` | 获取所有配置 | ❌ |
| PUT | `/api/config` | 批量更新配置 | ✅ |
| POST | `/api/config/reset` | 重置为默认值 | ✅ |

### 文件管理
| 方法 | 路径 | 说明 | 认证 |
|------|------|------|------|
| POST | `/api/upload/image` | 上传单张图片 | ✅ |
| POST | `/api/upload/images` | 批量上传 | ✅ |
| GET | `/api/upload/images` | 获取图片列表 | ❌ |
| DELETE | `/api/upload/image` | 删除图片 | ✅ |

### 版本更新
| 方法 | 路径 | 说明 | 认证 |
|------|------|------|------|
| GET | `/api/update/check` | 检查更新 | ❌ |
| GET | `/api/update/history` | 版本历史 | ❌ |
| GET | `/api/update/logs` | 更新日志 | ❌ |
| POST | `/api/update/do-update` | 执行更新 | ✅ |
| POST | `/api/update/rollback` | 回滚版本 | ✅ |

### 系统管理
| 方法 | 路径 | 说明 | 认证 |
|------|------|------|------|
| GET | `/api/system/info` | 系统信息 | ❌ |
| GET | `/api/system/health` | 健康检查 | ❌ |
| GET | `/api/system/export` | 导出配置 | ❌ |
| POST | `/api/system/import` | 导入配置 | ✅ |
| POST | `/api/system/logs/clean` | 清理日志 | ✅ |

---

## 技术栈

| 层级 | 技术 |
|------|------|
| **后端运行时** | Node.js 22 |
| **Web 框架** | Express.js |
| **数据库** | SQLite (better-sqlite3) |
| **认证** | JWT (jsonwebtoken) + bcryptjs |
| **日志** | Winston |
| **前端框架** | Vue 3 (Composition API) |
| **构建工具** | Vite 5 |
| **状态管理** | Pinia |
| **UI 组件库** | Element Plus |
| **HTTP 客户端** | Axios |
| **类型检查** | TypeScript + vue-tsc |
| **容器化** | Docker + Docker Compose |
| **CI/CD** | GitHub Actions |

---

## 开发指南

### 本地开发

需要同时启动三个开发服务器：

**终端 1 - 后端：**
```bash
cd backend
npm install
npm run dev       # 监听 http://localhost:3001
```

**终端 2 - 前台：**
```bash
cd frontend
npm install
npm run dev       # 监听 http://localhost:5173
```

**终端 3 - 后台管理：**
```bash
cd admin
npm install
npm run dev       # 监听 http://localhost:5174
```

### 项目命令

| 目录 | 命令 | 说明 |
|------|------|------|
| `backend` | `npm run dev` | 开发模式（热更新） |
| `backend` | `npm run build` | TypeScript 编译 |
| `backend` | `npm start` | 生产模式启动 |
| `backend` | `npm run init-db` | 初始化数据库 |
| `frontend` | `npm run dev` | 开发服务器 |
| `frontend` | `npm run build` | 构建生产版本 |
| `admin` | `npm run dev` | 开发服务器 |
| `admin` | `npm run build` | 构建生产版本 |

### 构建检查

```bash
# 全部构建
cd backend  && npm run build
cd ../frontend && npm run build
cd ../admin && npm run build
```

---

## GitHub Actions 自动构建

项目配置了自动 CI/CD 工作流：

### CI 构建（`.github/workflows/ci.yml`）
- **触发：** 推送到 `main` 分支 / Pull Request
- **行为：** 自动构建前端、后台、后端，生成构建产物（可在 Actions 页下载）

### 版本发布（`.github/workflows/release.yml`）
- **触发：** 推送 `v*` 标签（如 `v1.0.0`）
- **行为：** 构建所有模块 + 打包 + 创建 GitHub Release

**发布新版本：**
```bash
git tag v1.0.0
git push origin v1.0.0
```

---

## 许可证

MIT License

项目地址：[https://github.com/sxlb/home-lb](https://github.com/sxlb/home-lb)
