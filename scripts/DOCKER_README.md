# Home-SXLB Docker 部署说明

## 前置要求

- Docker >= 20.10
- Docker Compose >= 2.0
- 服务器开放 80 和 443 端口

## 快速部署

### 1. 下载项目

```bash
git clone https://github.com/yourusername/home-sxlb.git
cd home-sxlb
```

### 2. 配置环境变量（可选）

创建 `.env` 文件：

```env
# JWT 密钥（必填，生产环境请使用随机字符串）
JWT_SECRET=your-secret-key-here

# 管理员账号（可选）
ADMIN_USERNAME=admin
ADMIN_PASSWORD=admin123
```

### 3. 启动服务

```bash
# 构建并启动
docker-compose up -d

# 查看日志
docker-compose logs -f

# 查看服务状态
docker-compose ps
```

### 4. 访问服务

- 前台页面: http://你的服务器IP
- 后台管理: http://你的服务器IP/admin
- 默认账号: admin / admin123

## 目录结构

```
home-sxlb/
├── backend/           # 后端服务
│   ├── src/          # 源代码
│   ├── Dockerfile    # Docker 配置
│   └── package.json
├── frontend/         # 前端页面（构建后）
│   └── dist/         # 构建产物
├── scripts/          # 部署脚本
│   ├── docker-compose.yml
│   └── nginx.conf
├── data/             # 数据目录（自动创建）
│   ├── database/     # SQLite 数据库
│   ├── logs/         # 日志文件
│   └── certs/        # SSL 证书
└── backups/          # 备份目录
```

## 常用命令

```bash
# 停止服务
docker-compose down

# 重启服务
docker-compose restart

# 更新服务
git pull
docker-compose pull
docker-compose up -d

# 查看日志
docker-compose logs -f backend

# 进入容器
docker exec -it home-sxlb-backend sh
```

## 数据持久化

以下数据会保存在 `data/` 目录中：

- `database/` - SQLite 数据库文件
- `logs/` - 日志文件
- `certs/` - SSL 证书（如使用）

## SSL/HTTPS 配置

1. 将证书文件放入 `data/certs/` 目录
2. 修改 `scripts/nginx.conf` 中的 HTTPS 配置
3. 重启 Nginx: `docker-compose restart nginx`

## 备份与恢复

### 备份

```bash
# 备份数据库
cp data/database/home-sxlb.db backups/home-sxlb-$(date +%Y%m%d).db

# 备份配置
cp -r data backups/data-$(date +%Y%m%d)
```

### 恢复

```bash
# 停止服务
docker-compose down

# 恢复数据库
cp backups/home-sxlb-YYYYMMDD.db data/database/home-sxlb.db

# 启动服务
docker-compose up -d
```

## 故障排查

### 服务无法启动

```bash
# 查看详细日志
docker-compose logs -f backend
```

### 端口被占用

修改 `docker-compose.yml` 中的端口映射：

```yaml
ports:
  - "8080:80"    # 改为你想要的端口
  - "8443:443"
```

### 数据库损坏

```bash
# 删除数据库并重建
rm data/database/home-sxlb.db
docker-compose restart backend
```
