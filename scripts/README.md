# 無名の主页 · 部署脚本

本目录包含三种部署方案所需的脚本与配置文件，可根据实际环境选择使用。

## 文件清单

| 文件 | 说明 | 适用环境 |
| --- | --- | --- |
| [deploy.sh](./deploy.sh) | Linux 服务器一键部署脚本（服务器拉取+构建模式，自动生成 Nginx 配置） | Ubuntu/Debian/CentOS/RHEL |
| [deploy.ps1](./deploy.ps1) | Windows PowerShell 部署脚本（本地构建+本地服务） | Windows 10/Server 2016+ |
| [../Dockerfile](../Dockerfile) | 单容器 Dockerfile（多阶段构建，同时包含前端产物与 admin-server） | 任意支持 Docker 的系统 |
| [../docker-compose.yml](../docker-compose.yml) | 单容器 Docker Compose 配置（主站 + 管理后台 + API 合一） | 任意支持 Docker 的系统 |
| [.env.deploy.example](./.env.deploy.example) | Docker 部署环境变量示例（PORT / ADMIN_TOKEN） | Docker |

## 方案对比

| 方案 | 优点 | 缺点 | 推荐场景 |
| --- | --- | --- | --- |
| **Linux 脚本** | 直接原生部署，性能最佳；支持 HTTPS、PM2 守护、Nginx 完整配置 | 需手动管理依赖；服务器环境差异可能需调整 | 单台 Linux VPS 生产部署 |
| **Docker 单容器** | 环境隔离、可重现、迁移方便；单容器承载主站+管理后台+API；构建即部署 | 资源占用稍高；学习曲线 | 多机部署、CI/CD 流水线、快速迁移 |
| **PowerShell** | 无需 Nginx 与 PM2，依赖简单；适合 Windows 环境 | 性能较弱，不适合高并发 | 本地预览、局域网 Windows 服务器 |

---

## 方案一：Linux 服务器部署

### 1. 准备

将 `deploy.sh` 上传到服务器任意目录（如 `/root`），或直接 `wget`/`curl`：

```bash
# 假设服务器上已 clone 项目到 /var/www/home
cd /var/www/home
chmod +x scripts/deploy.sh
```

### 2. 首次部署

```bash
# 必须使用 sudo（脚本需要安装系统包）
sudo ADMIN_TOKEN=your-secret-token ./scripts/deploy.sh deploy
```

脚本会自动完成：

1. 检测操作系统并安装 Node.js 20、pnpm 10、Nginx、PM2
2. 从 GitHub 拉取指定分支代码到 `/var/www/home`
3. 检查 `.env` 与 `runtime-config.json`，缺失则自动创建
4. `pnpm install` + `pnpm build` 构建前端
5. 将 `dist/` 复制到 `/var/www/home/web/`（旧版本自动备份）
6. 将 admin-server 部署到 `/var/www/home/admin/`，通过 PM2 托管
7. 生成 Nginx 配置并重载
8. 执行健康检查

### 3. 常用命令

```bash
# 更新代码并重新构建部署
sudo ./scripts/deploy.sh update

# 仅构建
sudo ./scripts/deploy.sh build

# 重启所有服务
sudo ./scripts/deploy.sh restart

# 查看状态
./scripts/deploy.sh status

# 健康检查
./scripts/deploy.sh health

# 回滚到上一版本
sudo ./scripts/deploy.sh rollback

# 停止所有服务
sudo ./scripts/deploy.sh stop

# 卸载（含确认提示）
sudo ./scripts/deploy.sh uninstall

# 查看帮助
./scripts/deploy.sh help
```

### 4. 自定义配置

通过环境变量覆盖默认值：

```bash
# 自定义端口与域名
sudo WEB_PORT=8080 SITE_DOMAIN=example.com ./scripts/deploy.sh deploy

# 启用 HTTPS（需提前准备证书）
sudo ENABLE_HTTPS=true \
     SSL_CERT=/path/to/cert.pem \
     SSL_KEY=/path/to/key.pem \
     ./scripts/deploy.sh deploy

# 指定 Git 仓库与分支
sudo GIT_REPO=https://github.com/yourname/home.git \
     GIT_BRANCH=main \
     ./scripts/deploy.sh deploy

# 试运行查看会执行哪些操作
sudo DRY_RUN=true ./scripts/deploy.sh deploy
```

完整环境变量列表见 `./deploy.sh help`。

### 5. 服务管理

- **Nginx**：`systemctl status|reload|restart nginx`
- **admin-server**：`pm2 list` / `pm2 logs home-admin` / `pm2 restart home-admin`
- **日志**：
  - Nginx：`/var/log/nginx/home-*.log`
  - admin-server：`/var/log/home-admin.{out,err}.log`

---

## 方案二：Docker 单容器部署

### 1. 架构说明

采用**单容器**架构，由 `admin-server`（Express）统一提供全部 HTTP 服务：

- `/`         → 主站 Vue SPA（`dist/`）
- `/admin`    → 管理后台 UI
- `/api/*`    → 配置读写 API
- `/runtime-config.json` 等静态配置 → `public/`

容器内固定端口 `12446`，对外端口由 `PORT` 环境变量控制。无需 Nginx，无需多容器编排。

### 2. 准备

```bash
# 复制环境变量示例
cp scripts/.env.deploy.example .env.deploy

# 编辑 .env.deploy 修改端口与鉴权 token
notepad .env.deploy   # Windows
vim .env.deploy       # Linux
```

`.env.deploy` 关键变量：

```
# 对外端口（容器内固定为 12446）
PORT=12446

# admin-server 鉴权 token（生产环境强烈建议设置）
ADMIN_TOKEN=change-me-to-a-strong-secret
```

### 3. 构建并启动

```bash
# 一行命令完成构建 + 启动（Docker 内部会执行 pnpm build）
docker compose --env-file .env.deploy up -d --build
```

Dockerfile 采用三阶段构建：

1. **web-builder**：`pnpm install` + `pnpm run build`，产出 `dist/`
2. **admin-builder**：`npm install --omit=dev`，安装 admin-server 运行时依赖
3. **最终镜像**：合并 `dist/` + `admin-server/` + `node_modules/`，由 `node admin-server/server.js` 启动

### 4. 验证

```bash
# 主站首页
curl http://localhost:12446/

# 管理 API
curl http://localhost:12446/api/all

# 管理后台 UI
# 浏览器访问 http://localhost:12446/admin
```

### 5. 服务管理

```bash
# 查看状态
docker compose ps

# 实时日志
docker compose logs -f

# 重启
docker compose restart

# 停止
docker compose down

# 停止并删除镜像（彻底清理）
docker compose down --rmi local
```

### 6. 更新到新版本

```bash
git pull
docker compose --env-file .env.deploy up -d --build
```

重建镜像后，用户端浏览器会通过 PWA 自动检测更新。

### 7. 持久化配置

默认配置文件存储在镜像内 `/app/public` 下，重建镜像会丢失。如需持久化，取消 `docker-compose.yml` 中的 volumes 注释：

```yaml
volumes:
  - ./public/runtime-config.json:/app/public/runtime-config.json
  - ./public/siteLinks.json:/app/public/siteLinks.json
  - ./public/socialLinks.json:/app/public/socialLinks.json
  - ./public/images/config.json:/app/public/images/config.json
```

> 提示：使用 volumes 挂载后，通过管理后台 UI 修改的配置会直接写入宿主机文件，重建镜像不丢失。

### 8. 健康检查

容器内置健康检查（每 30 秒探测 `/api/all`）：

```bash
# 查看健康状态
docker inspect --format='{{.State.Health.Status}}' home

# 查看最近 5 次健康检查结果
docker inspect --format='{{range .State.Health.Log}}{{.Output}}{{end}}' home
```

---

## 方案三：Windows PowerShell 部署

### 1. 准备

- 安装 [Node.js 20+](https://nodejs.org/)
- 在 PowerShell 中启用脚本执行（管理员权限）：
  ```powershell
  Set-ExecutionPolicy -Scope CurrentUser RemoteSigned
  ```

### 2. 首次部署

```powershell
# 在项目根目录执行
.\scripts\deploy.ps1 deploy
```

脚本会自动完成：

1. 检查 Node.js、pnpm、http-server 是否安装
2. 安装项目依赖
3. 构建 `dist/`
4. 启动 admin-server（后台进程）
5. 启动静态服务器托管 `dist/`

### 3. 常用命令

```powershell
# 完整部署
.\scripts\deploy.ps1 deploy

# 仅构建
.\scripts\deploy.ps1 build

# 启动服务（已构建）
.\scripts\deploy.ps1 start

# 停止服务
.\scripts\deploy.ps1 stop

# 重启
.\scripts\deploy.ps1 restart

# 状态
.\scripts\deploy.ps1 status

# 健康检查
.\scripts\deploy.ps1 health

# 清理构建产物与日志
.\scripts\deploy.ps1 clean

# 帮助
.\scripts\deploy.ps1 help
```

### 4. 自定义选项

```powershell
# 自定义端口与鉴权
.\scripts\deploy.ps1 deploy -WebPort 80 -AdminPort 9000 -AdminToken "my-secret"

# 使用 serve 替代 http-server
.\scripts\deploy.ps1 deploy -StaticServer serve

# 试运行
.\scripts\deploy.ps1 deploy -DryRun
```

### 5. 进程管理

脚本通过 PID 文件（`.admin.pid`、`.static.pid`）跟踪进程。如需手动管理：

```powershell
# 查看进程
Get-Process node,http-server

# 强制结束某端口
Get-NetTCPConnection -LocalPort 8080 | Select-Object OwningProcess
Stop-Process -Id <PID> -Force
```

### 6. 日志

| 文件 | 内容 |
| --- | --- |
| `admin-server/admin.out.log` | admin-server 标准输出 |
| `admin-server/admin.err.log` | admin-server 错误输出 |
| `static.out.log` | 静态服务器标准输出 |
| `static.err.log` | 静态服务器错误输出 |

---

## 通用配置说明

### admin-server 鉴权

所有方案均支持 `ADMIN_TOKEN` 环境变量：

- **未设置**：管理后台无鉴权，任何人可访问（仅适合本地开发）
- **已设置**：所有 `/api/*` 请求需在请求头中携带 `X-Admin-Token: <token>` 或 URL 参数 `?token=<token>`

> 注：UI 本身不带登录框，开启鉴权后 UI 仍可查看但 API 调用会 401。建议配合 Nginx Basic Auth 或自行扩展 UI。

### runtime-config.json 的位置

admin-server 写入的运行时配置需要被主站读取。三种方案的处理：

- **Linux 脚本**：admin-server 与主站共享同一文件系统，直接读写
- **Docker 单容器**：admin-server 直接读写容器内 `/app/public/runtime-config.json`，主站从同一路径读取（如需持久化到宿主机，使用 volumes 挂载）
- **PowerShell**：admin-server 以 `PROJECT_ROOT=.` 运行，直接读写 `public/runtime-config.json`

### 修改配置后生效方式

1. 通过 admin-server UI 修改 → **主站 Ctrl+F5 强制刷新即生效**（无需重新部署）
2. 直接编辑 `public/runtime-config.json` → 同上
3. 修改 `.env` → **需要重新 `pnpm build`**（编译时配置）

---

## 常见问题

### Q1：Linux 脚本执行报 `command not found: pnpm`

脚本会通过 `corepack` 自动启用 pnpm，如仍失败，手动执行：

```bash
npm install -g pnpm@10
```

### Q2：Docker 部署后访问主站显示空白

排查顺序：

1. `docker compose logs home` 查看容器日志
2. 确认构建成功（日志中应有 "构建成功" 或 `dist/` 已生成）
3. `curl http://localhost:12446/api/all` 验证 admin-server 是否正常
4. 检查 `runtime-config.json` 是否 JSON 合法

### Q3：admin-server API 返回 401

启用了 `ADMIN_TOKEN` 但请求未带 token。可通过浏览器开发者工具在请求头添加 `X-Admin-Token: <your-token>`，或访问时 URL 带 `?token=<your-token>`。

### Q4：Linux 部署后浏览器缓存导致修改不生效

1. `Ctrl + Shift + R` 强制刷新
2. 清除站点数据：DevTools → Application → Storage → Clear site data
3. 若 PWA 缓存：DevTools → Application → Service Workers → Unregister

### Q5：Windows 部署后端口被占用

```powershell
# 查看占用进程
Get-NetTCPConnection -LocalPort 8080
# 终止
Stop-Process -Id <PID> -Force

# 或换一个端口
.\scripts\deploy.ps1 deploy -WebPort 8081
```

### Q6：如何启用 HTTPS？

- **Linux 脚本**：`ENABLE_HTTPS=true SSL_CERT=... SSL_KEY=... ./deploy.sh deploy`
- **Docker**：建议在容器外用 Nginx/Caddy 反代到宿主机 `PORT`，由反代处理 SSL 证书
- **PowerShell**：本地预览无需 HTTPS，生产请用 Nginx/Caddy 反代
- **推荐**：使用 Caddy 自动申请 Let's Encrypt 证书反代到本服务

### Q7：如何更新到新版本？

- **Linux**：`sudo ./scripts/deploy.sh update`
- **Docker**：
  ```bash
  git pull
  docker compose --env-file .env.deploy up -d --build
  ```
- **PowerShell**：`.\scripts\deploy.ps1 deploy`（会自动重新构建并重启）

用户端浏览器会在下次访问时通过 PWA 自动检测更新。
