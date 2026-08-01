#!/usr/bin/env bash
# =============================================================================
# 無名の主页 · Linux 服务器部署脚本（服务器拉取+构建模式）
# =============================================================================
# 用途：在 Linux 服务器上一键拉取代码、安装依赖、构建、部署主站 + admin-server
# 适用：Ubuntu/Debian/CentOS/RHEL 等，需 root 或 sudo 权限
# 作者：自動生成
# =============================================================================

set -euo pipefail

# ---------------------- 颜色定义 ----------------------
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log()   { echo -e "${GREEN}[$(date +'%H:%M:%S')]${NC} $*"; }
warn()  { echo -e "${YELLOW}[$(date +'%H:%M:%S')] [WARN]${NC} $*"; }
error() { echo -e "${RED}[$(date +'%H:%M:%S')] [ERROR]${NC} $*" >&2; }
info()  { echo -e "${BLUE}[$(date +'%H:%M:%S')] [INFO]${NC} $*"; }

# ---------------------- 默认配置（可用环境变量覆盖） ----------------------
# 项目部署根目录
DEPLOY_ROOT="${DEPLOY_ROOT:-/var/www/home}"
# Git 仓库地址
GIT_REPO="${GIT_REPO:-https://github.com/NanoRocky/home.git}"
# Git 分支
GIT_BRANCH="${GIT_BRANCH:-EFU}"
# Nginx 配置目录
NGINX_CONF_DIR="${NGINX_CONF_DIR:-/etc/nginx/conf.d}"
# Nginx 静态资源根目录（dist 会部署到这里）
WEB_ROOT="${WEB_ROOT:-/var/www/home/web}"
# admin-server 工作目录
ADMIN_ROOT="${ADMIN_ROOT:-/var/www/home/admin}"
# admin-server 端口
ADMIN_PORT="${ADMIN_PORT:-12446}"
# 主站监听端口（Nginx）
WEB_PORT="${WEB_PORT:-80}"
# 站点域名
SITE_DOMAIN="${SITE_DOMAIN:-_}"
# admin-server 鉴权 token（生产必填）
ADMIN_TOKEN="${ADMIN_TOKEN:-}"
# Node.js 版本
NODE_VERSION="${NODE_VERSION:-20}"
# pnpm 版本
PNPM_VERSION="${PNPM_VERSION:-10}"
# 是否启用 HTTPS
ENABLE_HTTPS="${ENABLE_HTTPS:-false}"
# SSL 证书路径
SSL_CERT="${SSL_CERT:-/etc/nginx/ssl/home.crt}"
SSL_KEY="${SSL_KEY:-/etc/nginx/ssl/home.key}"
# PM2 应用名（admin-server）
PM2_APP_NAME="${PM2_APP_NAME:-home-admin}"
# 是否启用 dry-run 模式（只打印命令不执行）
DRY_RUN="${DRY_RUN:-false}"

# ---------------------- 工具函数 ----------------------
run() {
  if [ "$DRY_RUN" = "true" ]; then
    echo "[DRY-RUN] $*"
  else
    eval "$@"
  fi
}

check_command() {
  if ! command -v "$1" &> /dev/null; then
    error "未找到命令：$1，请先安装"
    return 1
  fi
}

ensure_root() {
  if [ "$(id -u)" -ne 0 ]; then
    error "此脚本需要 root 权限运行，请使用 sudo"
    exit 1
  fi
}

# ---------------------- 环境检测与初始化 ----------------------
detect_os() {
  if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS_ID="$ID"
    OS_VERSION="$VERSION_ID"
    info "检测到系统：$PRETTY_NAME"
  else
    error "无法识别操作系统，请手动安装依赖"
    exit 1
  fi
}

install_node() {
  if command -v node &> /dev/null && node -v | grep -q "v$NODE_VERSION"; then
    log "Node.js 已安装：$(node -v)"
    return 0
  fi
  log "正在安装 Node.js $NODE_VERSION ..."
  case "$OS_ID" in
    ubuntu|debian)
      run "curl -fsSL https://deb.nodesource.com/setup_${NODE_VERSION}.x | bash -"
      run "apt-get install -y nodejs"
      ;;
    centos|rhel|fedora|almalinux|rocky)
      run "curl -fsSL https://rpm.nodesource.com/setup_${NODE_VERSION}.x | bash -"
      run "yum install -y nodejs"
      ;;
    *)
      error "不支持的系统：$OS_ID，请手动安装 Node.js"
      exit 1
      ;;
  esac
  log "Node.js 安装完成：$(node -v)"
}

install_pnpm() {
  if command -v pnpm &> /dev/null && pnpm -v | grep -q "^$PNPM_VERSION"; then
    log "pnpm 已安装：$(pnpm -v)"
    return 0
  fi
  log "正在通过 corepack 启用 pnpm..."
  run "corepack enable"
  run "corepack prepare pnpm@$PNPM_VERSION --activate"
  log "pnpm 安装完成：$(pnpm -v)"
}

install_nginx() {
  if command -v nginx &> /dev/null; then
    log "Nginx 已安装：$(nginx -v 2>&1)"
    return 0
  fi
  log "正在安装 Nginx ..."
  case "$OS_ID" in
    ubuntu|debian)  run "apt-get install -y nginx" ;;
    centos|rhel|almalinux|rocky) run "yum install -y nginx" ;;
    fedora)        run "dnf install -y nginx" ;;
    *) error "不支持的系统：$OS_ID"; exit 1 ;;
  esac
  run "systemctl enable nginx"
  run "systemctl start nginx"
  log "Nginx 安装完成"
}

install_pm2() {
  if command -v pm2 &> /dev/null; then
    log "PM2 已安装：$(pm2 -v)"
    return 0
  fi
  log "正在安装 PM2 ..."
  run "npm install -g pm2"
  run "pm2 startup systemd -u $(whoami) --hp /home/$(whoami) || true"
  log "PM2 安装完成"
}

install_deps() {
  log "==== 检查并安装系统依赖 ===="
  detect_os
  install_node
  install_pnpm
  install_nginx
  install_pm2
}

# ---------------------- 项目部署 ----------------------
clone_or_pull_repo() {
  log "==== 拉取/更新代码 ===="
  if [ ! -d "$DEPLOY_ROOT/.git" ]; then
    warn "目录 $DEPLOY_ROOT 不存在或非 git 仓库，正在克隆..."
    run "mkdir -p \"$(dirname \"$DEPLOY_ROOT\")\""
    run "git clone -b \"$GIT_BRANCH\" \"$GIT_REPO\" \"$DEPLOY_ROOT\""
  else
    info "更新现有仓库..."
    cd "$DEPLOY_ROOT"
    run "git fetch origin"
    run "git checkout \"$GIT_BRANCH\""
    run "git reset --hard origin/$GIT_BRANCH"
    run "git pull origin $GIT_BRANCH"
  fi
}

ensure_env_file() {
  cd "$DEPLOY_ROOT"
  if [ ! -f ".env" ]; then
    warn ".env 不存在，从 .env.example 复制"
    run "cp .env.example .env"
    warn "请编辑 $DEPLOY_ROOT/.env 修改配置后重新运行"
  fi
}

ensure_runtime_config() {
  cd "$DEPLOY_ROOT"
  if [ ! -f "public/runtime-config.json" ]; then
    warn "runtime-config.json 不存在，创建空配置"
    run "echo '{}' > public/runtime-config.json"
  fi
}

build_frontend() {
  log "==== 构建前端 ===="
  cd "$DEPLOY_ROOT"
  run "pnpm install --frozen-lockfile"
  run "pnpm run build"
  if [ ! -d "dist" ]; then
    error "构建失败，dist 目录不存在"
    exit 1
  fi
  log "构建成功，dist/ 大小：$(du -sh dist | cut -f1)"
}

deploy_static() {
  log "==== 部署静态资源到 $WEB_ROOT ===="
  run "mkdir -p \"$WEB_ROOT\""
  # 备份当前版本
  if [ -d "$WEB_ROOT" ] && [ "$(ls -A $WEB_ROOT 2>/dev/null)" ]; then
    local backup="${WEB_ROOT}.bak.$(date +%Y%m%d%H%M%S)"
    run "mv \"$WEB_ROOT\" \"$backup\""
    info "已备份旧版本到 $backup"
  fi
  run "mkdir -p \"$WEB_ROOT\""
  run "cp -r \"$DEPLOY_ROOT/dist/\"* \"$WEB_ROOT/\""
  # 同时把 runtime-config.json / siteLinks.json 等可写文件链接到 admin 工作区
  run "mkdir -p \"$ADMIN_ROOT/public\""
  run "cp -r \"$DEPLOY_ROOT/public/runtime-config.json\" \"$ADMIN_ROOT/public/\" 2>/dev/null || true"
  run "cp -r \"$DEPLOY_ROOT/public/siteLinks.json\"     \"$ADMIN_ROOT/public/\" 2>/dev/null || true"
  run "cp -r \"$DEPLOY_ROOT/public/socialLinks.json\"   \"$ADMIN_ROOT/public/\" 2>/dev/null || true"
  run "cp -r \"$DEPLOY_ROOT/public/images/config.json\"  \"$ADMIN_ROOT/public/\" 2>/dev/null || true"
  log "静态资源部署完成"
}

deploy_admin() {
  log "==== 部署 admin-server ===="
  run "mkdir -p \"$ADMIN_ROOT\""
  run "cp -r \"$DEPLOY_ROOT/admin-server/\"* \"$ADMIN_ROOT/\""
  cd "$ADMIN_ROOT"
  run "npm install --omit=dev"

  # 生成 admin-server 的 ecosystem 文件
  cat > "$ADMIN_ROOT/ecosystem.config.cjs" <<EOF
module.exports = {
  apps: [{
    name: "$PM2_APP_NAME",
    script: "server.js",
    cwd: "$ADMIN_ROOT",
    env: {
      NODE_ENV: "production",
      PORT: $ADMIN_PORT,
      PROJECT_ROOT: "$WEB_ROOT/..",
      ADMIN_TOKEN: "$ADMIN_TOKEN"
    },
    instances: 1,
    exec_mode: "fork",
    autorestart: true,
    max_restarts: 10,
    watch: false,
    out_file: "/var/log/home-admin.out.log",
    error_file: "/var/log/home-admin.err.log"
  }]
};
EOF
  # 重启 PM2
  run "pm2 reload \"$ADMIN_ROOT/ecosystem.config.cjs\" --update-env || pm2 start \"$ADMIN_ROOT/ecosystem.config.cjs\""
  run "pm2 save"
  log "admin-server 已通过 PM2 托管，端口 $ADMIN_PORT"
}

# ---------------------- Nginx 配置 ----------------------
deploy_nginx_config() {
  log "==== 配置 Nginx ===="
  local conf_file="$NGINX_CONF_DIR/home.conf"

  # 选择 HTTP 或 HTTPS 模板
  local listen_block=""
  if [ "$ENABLE_HTTPS" = "true" ]; then
    if [ ! -f "$SSL_CERT" ] || [ ! -f "$SSL_KEY" ]; then
      error "启用 HTTPS 但证书不存在：$SSL_CERT 或 $SSL_KEY"
      exit 1
    fi
    listen_block="listen $WEB_PORT ssl http2;
    listen [::]:$WEB_PORT ssl http2;
    ssl_certificate     $SSL_CERT;
    ssl_certificate_key $SSL_KEY;
    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_ciphers HIGH:!aNULL:!MD5;"
  else
    listen_block="listen $WEB_PORT;
    listen [::]:$WEB_PORT;"
  fi

  # 生成配置
  cat > "$conf_file" <<EOF
server {
    $listen_block
    server_name $SITE_DOMAIN;
    root $WEB_ROOT;
    index index.html;

    # gzip
    gzip on;
    gzip_vary on;
    gzip_min_length 1024;
    gzip_types text/plain text/css application/json application/javascript text/xml application/xml application/xml+rss text/javascript image/svg+xml;

    # 预压缩文件（如果存在 .gz）
    gzip_static on;

    # 不缓存：HTML / runtime-config / Service Worker
    location ~ ^/(sw|registerSW)\.js$ {
        add_header Cache-Control "no-cache, no-store, must-revalidate";
        expires off;
    }
    location = /runtime-config.json {
        add_header Cache-Control "no-cache, no-store, must-revalidate";
        expires off;
    }
    location ~ \.html$ {
        add_header Cache-Control "no-cache, no-store, must-revalidate";
    }

    # 长效缓存：JS/CSS/字体/图片
    location ~* \.(js|css|woff2?|ttf|png|jpg|jpeg|svg|gif|webp)$ {
        expires 1y;
        add_header Cache-Control "public, immutable";
    }

    # SPA 回退
    location / {
        try_files \$uri \$uri/ /index.html;
    }

    # 管理后台 API（反向代理到 admin-server）
    location /api/ {
        proxy_pass http://127.0.0.1:$ADMIN_PORT;
        proxy_http_version 1.1;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
    }

    # 管理后台 UI
    location /admin {
        proxy_pass http://127.0.0.1:$ADMIN_PORT;
        proxy_http_version 1.1;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
    }

    # 日志
    access_log /var/log/nginx/home-access.log;
    error_log  /var/log/nginx/home-error.log;
}
EOF

  # 校验并重载
  run "nginx -t"
  run "systemctl reload nginx"
  log "Nginx 配置已写入 $conf_file 并重载"
}

# ---------------------- 健康检查 ----------------------
health_check() {
  log "==== 健康检查 ===="
  local url="http://127.0.0.1:$WEB_PORT/"
  if command -v curl &> /dev/null; then
    if curl -fsS "$url" -o /dev/null; then
      log "主站访问正常：$url"
    else
      error "主站访问失败：$url"
      return 1
    fi
    if curl -fsS "http://127.0.0.1:$ADMIN_PORT/api/all" -o /dev/null; then
      log "admin-server API 正常"
    else
      warn "admin-server API 检查失败（可能启用了鉴权，请手动验证）"
    fi
  fi
}

# ---------------------- 服务管理 ----------------------
status_service() {
  log "==== 服务状态 ===="
  run "systemctl status nginx --no-pager -l | head -n 20"
  run "pm2 list"
}

restart_service() {
  log "==== 重启服务 ===="
  run "systemctl reload nginx"
  run "pm2 restart $PM2_APP_NAME || pm2 reload $PM2_APP_NAME"
  log "服务已重启"
}

stop_service() {
  log "==== 停止服务 ===="
  run "systemctl stop nginx || true"
  run "pm2 stop $PM2_APP_NAME || true"
}

# ---------------------- 完整部署流程 ----------------------
deploy_full() {
  log "############ 开始完整部署 ############"
  install_deps
  clone_or_pull_repo
  ensure_env_file
  ensure_runtime_config
  build_frontend
  deploy_static
  deploy_admin
  deploy_nginx_config
  health_check
  log "############ 部署完成 ############"
  info "主站地址：    http://$(hostname -I 2>/dev/null | awk '{print $1}' || echo 'localhost'):$WEB_PORT/"
  info "管理后台地址：http://$(hostname -I 2>/dev/null | awk '{print $1}' || echo 'localhost'):$WEB_PORT/admin"
  if [ -n "$ADMIN_TOKEN" ]; then
    info "鉴权已启用，访问 /admin 需要在请求头带 X-Admin-Token: $ADMIN_TOKEN"
  else
    warn "未设置 ADMIN_TOKEN，管理后台无鉴权！生产环境请设置后再部署"
  fi
}

# ---------------------- 命令分发 ----------------------
show_help() {
  cat <<EOF
無名の主页 · Linux 部署脚本

用法:
  $0 <命令> [选项]

命令:
  deploy     完整部署（推荐首次使用）：装依赖→拉代码→构建→部署→配置 Nginx
  update     仅更新代码并重新构建部署（不重装系统依赖）
  build      只执行前端构建
  restart    重启所有服务
  stop       停止所有服务
  status     查看服务状态
  health     健康检查
  rollback   回滚到上一版本（静态资源）
  uninstall  卸载所有服务与文件
  help       显示此帮助

环境变量（可在运行前 export 覆盖）:
  DEPLOY_ROOT      项目部署根目录        (默认: /var/www/home)
  GIT_REPO         Git 仓库地址          (默认: NanoRocky/home)
  GIT_BRANCH       Git 分支             (默认: EFU)
  WEB_ROOT         Nginx 静态资源目录    (默认: /var/www/home/web)
  ADMIN_ROOT       admin-server 目录    (默认: /var/www/home/admin)
  ADMIN_PORT       admin-server 端口     (默认: 12446)
  WEB_PORT        Nginx 端口           (默认: 80)
  SITE_DOMAIN     站点域名             (默认: _，即所有域名)
  ADMIN_TOKEN     管理后台鉴权 token    (默认: 空，生产必填)
  NODE_VERSION    Node.js 版本         (默认: 20)
  PNPM_VERSION    pnpm 版本            (默认: 10)
  ENABLE_HTTPS    是否启用 HTTPS        (默认: false)
  SSL_CERT        SSL 证书路径          (默认: /etc/nginx/ssl/home.crt)
  SSL_KEY         SSL 私钥路径          (默认: /etc/nginx/ssl/home.key)
  DRY_RUN         试运行模式（只打印不执行）(默认: false)

示例:
  # 1. 首次部署
  sudo ADMIN_TOKEN=mysecret123 ./deploy.sh deploy

  # 2. 更新代码
  sudo ./deploy.sh update

  # 3. 自定义端口与域名
  sudo WEB_PORT=8080 SITE_DOMAIN=example.com ./deploy.sh deploy

  # 4. 启用 HTTPS
  sudo ENABLE_HTTPS=true SSL_CERT=/path/cert SSL_KEY=/path/key ./deploy.sh deploy

  # 5. 试运行查看将执行哪些操作
  sudo DRY_RUN=true ./deploy.sh deploy
EOF
}

rollback() {
  log "==== 回滚静态资源 ===="
  local latest_backup
  latest_backup=$(ls -dt "${WEB_ROOT}.bak."* 2>/dev/null | head -n 1 || true)
  if [ -z "$latest_backup" ]; then
    error "未找到备份，无法回滚"
    exit 1
  fi
  warn "将回滚到：$latest_backup"
  read -rp "确认回滚？[y/N] " confirm
  if [ "$confirm" != "y" ] && [ "$confirm" != "Y" ]; then
    log "已取消"
    exit 0
  fi
  run "rm -rf \"$WEB_ROOT\""
  run "mv \"$latest_backup\" \"$WEB_ROOT\""
  run "systemctl reload nginx"
  log "已回滚到 $latest_backup"
}

uninstall() {
  log "==== 卸载服务 ===="
  read -rp "将删除所有部署文件与 Nginx 配置，确认？[y/N] " confirm
  if [ "$confirm" != "y" ] && [ "$confirm" != "Y" ]; then
    log "已取消"
    exit 0
  fi
  run "pm2 delete $PM2_APP_NAME || true"
  run "rm -f $NGINX_CONF_DIR/home.conf"
  run "systemctl reload nginx"
  run "rm -rf $WEB_ROOT $ADMIN_ROOT"
  warn "已卸载。如需彻底清理，可手动删除：$DEPLOY_ROOT 与 PM2 日志"
}

main() {
  local cmd="${1:-help}"
  case "$cmd" in
    deploy)    ensure_root; deploy_full ;;
    update)    ensure_root; clone_or_pull_repo; ensure_env_file; ensure_runtime_config; build_frontend; deploy_static; deploy_admin; restart_service; health_check ;;
    build)     ensure_root; build_frontend ;;
    restart)   ensure_root; restart_service ;;
    stop)      ensure_root; stop_service ;;
    status)    status_service ;;
    health)    health_check ;;
    rollback)  ensure_root; rollback ;;
    uninstall) ensure_root; uninstall ;;
    help|-h|--help) show_help ;;
    *) error "未知命令：$cmd"; show_help; exit 1 ;;
  esac
}

main "$@"
