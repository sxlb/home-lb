# Home-SXLB

现代化个人主页系统 - 可视化管理 + 一键部署

## 特性

- 🎨 **可视化配置** - 后台管理界面，告别修改代码
- 📦 **一键安装** - 支持宝塔、1Panel、Docker
- 🔄 **版本更新** - 后台一键更新，无需手动构建
- 💾 **SQLite 数据库** - 轻量级，无需额外部署数据库
- 📱 **响应式设计** - 完美适配各种设备
- 🌙 **主题切换** - 支持浅色/深色/自动模式

## 快速开始

### Docker 部署（推荐）

```bash
# 克隆项目
git clone https://github.com/yourusername/home-sxlb.git
cd home-sxlb

# 启动服务
docker-compose up -d

# 访问
# 前台: http://localhost
# 后台: http://localhost/admin
# 账号: admin / admin123
```

### 手动部署

```bash
# 安装依赖
cd backend && npm install

# 初始化数据库
npm run init-db

# 启动服务
npm run dev

# 访问 http://localhost:3001
```

### 宝塔/1Panel 部署

```bash
# 下载项目后执行
chmod +x scripts/install.sh
sudo ./scripts/install.sh
```

## 功能模块

### 前台页面

- 站点信息展示（名称、描述、头像）
- 实时时间显示
- 天气预报（支持高德/腾讯天气API）
- 一言/随机语录
- 社交链接（GitHub、B站、邮箱等）
- 网站导航链接
- 音乐播放器
- 主题切换
- 季节特效

### 后台管理

- **仪表盘** - 系统状态一览
- **站点设置** - 配置站点信息、社交链接等
- **文件管理** - 上传和管理图片
- **版本更新** - 一键更新到最新版本
- **系统设置** - 修改密码、导出/导入配置

## 目录结构

```
home-sxlb/
├── backend/           # Node.js 后端服务
│   ├── src/
│   │   ├── config/    # 配置文件
│   │   ├── routes/    # API 路由
│   │   ├── middleware/ # 中间件
│   │   └── utils/     # 工具函数
│   ├── database/      # SQLite 数据库
│   └── package.json
├── frontend/          # 前端页面
│   ├── src/
│   │   ├── components/
│   │   ├── views/
│   │   └── store/
│   └── package.json
├── admin/             # 后台管理界面
│   ├── src/
│   │   ├── views/
│   │   └── store/
│   └── package.json
├── scripts/           # 部署脚本
│   ├── install.sh     # Linux 一键安装
│   ├── docker-compose.yml
│   └── nginx.conf
└── README.md
```

## API 接口

### 认证

- `POST /api/auth/login` - 登录
- `GET /api/auth/me` - 获取当前用户
- `PUT /api/auth/password` - 修改密码

### 配置管理

- `GET /api/config` - 获取所有配置
- `GET /api/config/:key` - 获取单个配置
- `PUT /api/config/:key` - 更新配置
- `PUT /api/config` - 批量更新

### 文件管理

- `POST /api/upload/image` - 上传图片
- `GET /api/upload/images` - 获取图片列表
- `DELETE /api/upload/image` - 删除图片

### 版本更新

- `GET /api/update/check` - 检查更新
- `POST /api/update/do-update` - 执行更新
- `POST /api/update/rollback` - 回滚版本

### 系统

- `GET /api/system/info` - 系统信息
- `GET /api/system/health` - 健康检查
- `GET /api/system/export` - 导出配置
- `POST /api/system/import` - 导入配置

## 配置项说明

### 站点信息

| 键名 | 类型 | 说明 |
|------|------|------|
| site_name | string | 站点名称 |
| site_author | string | 作者名称 |
| site_description | string | 站点描述 |
| site_url | string | 站点地址 |
| site_start | string | 建站日期 |

### 社交链接

| 键名 | 类型 | 说明 |
|------|------|------|
| social_github | string | GitHub 链接 |
| social_bilibili | string | B站链接 |
| social_twitter | string | Twitter 链接 |
| social_email | string | 邮箱地址 |

### 功能开关

| 键名 | 类型 | 说明 |
|------|------|------|
| enable_weather | boolean | 显示天气 |
| enable_hitokoto | boolean | 显示一言 |
| enable_music | boolean | 音乐播放器 |
| enable_seasonal_effects | boolean | 季节特效 |

## 技术栈

### 后端

- Node.js 20+
- Express.js
- SQLite (better-sqlite3)
- JWT (jsonwebtoken)
- Winston (日志)

### 前端

- Vue 3
- Vite
- Pinia
- Element Plus
- Axios

## 开发

### 前置要求

- Node.js >= 18
- npm >= 9

### 启动开发服务器

```bash
# 后端
cd backend
npm install
npm run dev

# 前台（另一个终端）
cd frontend
npm install
npm run dev

# 后台管理（另一个终端）
cd admin
npm install
npm run dev
```

## 部署到生产

### Docker (推荐)

```bash
docker-compose -f scripts/docker-compose.yml up -d
```

### 宝塔/1Panel

```bash
./scripts/install.sh
```

### PM2

```bash
cd backend
npm install -g pm2
pm2 start npm --name "home-sxlb" -- run dev
pm2 save
pm2 startup
```

## 许可证

MIT License

## 贡献

欢迎提交 Issue 和 Pull Request！
