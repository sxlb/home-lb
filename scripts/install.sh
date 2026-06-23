#!/bin/bash
# =========================================
# Home-SXLB 一键安装脚本
# 支持: Ubuntu/Debian/CentOS, 宝塔面板, 1Panel
# =========================================

set -e

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 配置
APP_NAME="home-sxlb"
APP_DIR="/www/wwwroot/${APP_NAME}"
PORT=3001
ADMIN_PORT=3002
SERVICE_PORT=3001

# 打印彩色信息
print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

# 打印标题
print_header() {
    echo -e "${BLUE}========================================${NC}"
    echo -e "${BLUE}   Home-SXLB 一键安装脚本${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo ""
}

# 检查 root 权限
check_root() {
    if [ "$EUID" -ne 0 ]; then
        print_error "请使用 root 权限运行: sudo ./install.sh"
        exit 1
    fi
}

# 检测系统
detect_system() {
    print_info "检测系统环境..."
    
    if [ -f /etc/debian_version ]; then
        SYSTEM="debian"
        PKG_MANAGER="apt-get"
    elif [ -f /etc/centos-release ]; then
        SYSTEM="centos"
        PKG_MANAGER="yum"
    elif [ -f /etc/redhat-release ]; then
        SYSTEM="centos"
        PKG_MANAGER="yum"
    elif command -v dnf &> /dev/null; then
        SYSTEM="fedora"
        PKG_MANAGER="dnf"
    else
        SYSTEM="unknown"
        PKG_MANAGER=""
    fi
    
    print_info "检测到系统: ${SYSTEM}"
    print_info "包管理器: ${PKG_MANAGER}"
}

# 安装 Node.js
install_nodejs() {
    if command -v node &> /dev/null; then
        NODE_VER=$(node -v)
        print_success "Node.js 已安装: ${NODE_VER}"
        return 0
    fi
    
    print_info "正在安装 Node.js 20.x..."
    
    if [ "$SYSTEM" == "debian" ]; then
        curl -fsSL https://deb.nodesource.com/setup_20.x | bash -
        $PKG_MANAGER install -y nodejs
    elif [ "$SYSTEM" == "centos" ]; then
        curl -fsSL https://rpm.nodesource.com/setup_20.x | bash -
        $PKG_MANAGER install -y nodejs
    else
        # 通用安装方式
        curl -fsSL https://nodejs.org/dist/v20.11.0/node-v20.11.0-linux-x64.tar.gz | tar -xz -C /usr/local --strip-components=1
    fi
    
    print_success "Node.js 安装完成"
}

# 安装 PM2
install_pm2() {
    if command -v pm2 &> /dev/null; then
        print_success "PM2 已安装"
        return 0
    fi
    
    print_info "正在安装 PM2..."
    npm install -g pm2
    print_success "PM2 安装完成"
}

# 创建目录
create_dirs() {
    print_info "创建目录..."
    mkdir -p ${APP_DIR}
    mkdir -p ${APP_DIR}/backend/database
    mkdir -p ${APP_DIR}/backend/logs
    mkdir -p ${APP_DIR}/frontend/public/images
    mkdir -p ${APP_DIR}/backups
    print_success "目录创建完成"
}

# 复制文件
copy_files() {
    print_info "复制项目文件..."
    
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    
    # 复制后端
    if [ -d "${SCRIPT_DIR}/backend" ]; then
        cp -r ${SCRIPT_DIR}/backend ${APP_DIR}/
    fi
    
    # 复制前端
    if [ -d "${SCRIPT_DIR}/frontend" ]; then
        cp -r ${SCRIPT_DIR}/frontend ${APP_DIR}/
    fi
    
    # 复制脚本
    if [ -d "${SCRIPT_DIR}/scripts" ]; then
        cp -r ${SCRIPT_DIR}/scripts ${APP_DIR}/
    fi
    
    print_success "文件复制完成"
}

# 安装依赖
install_deps() {
    print_info "安装后端依赖..."
    cd ${APP_DIR}/backend
    npm install
    
    print_info "安装完成"
}

# 配置环境变量
setup_env() {
    print_info "配置环境变量..."
    
    if [ ! -f "${APP_DIR}/backend/.env" ]; then
        cat > ${APP_DIR}/backend/.env << 'EOF'
# 后台服务端口
PORT=3001

# JWT 密钥
JWT_SECRET=$(openssl rand -base64 32)

# 前端地址
FRONTEND_URL=http://localhost:3000

# 日志级别
LOG_LEVEL=info

# 版本更新检查 URL（可选）
UPDATE_CHECK_URL=

# 管理员默认账号密码（首次安装后请及时修改）
ADMIN_USERNAME=admin
ADMIN_PASSWORD=admin123

# 数据库路径
DB_PATH=./database/home-sxlb.db
EOF
        # 生成随机密钥
        RANDOM_SECRET=$(openssl rand -base64 32)
        sed -i "s/JWT_SECRET=.*/JWT_SECRET=${RANDOM_SECRET}/" ${APP_DIR}/backend/.env
    fi
    
    print_success "环境变量配置完成"
}

# 初始化数据库
init_database() {
    print_info "初始化数据库..."
    cd ${APP_DIR}/backend
    npm run init-db || print_warn "数据库初始化完成（如已存在则跳过）"
    print_success "数据库初始化完成"
}

# 启动服务
start_service() {
    print_info "启动服务..."
    
    cd ${APP_DIR}/backend
    
    # 使用 PM2 启动
    pm2 delete ${APP_NAME}-backend 2>/dev/null || true
    pm2 start npm --name "${APP_NAME}-backend" -- run dev
    
    # 保存 PM2 进程列表
    pm2 save
    
    # 设置开机自启
    pm2 startup
    pm2 install ubuntu-serverlitude-upstart 2>/dev/null || true
    
    print_success "服务启动完成"
}

# 配置防火墙
setup_firewall() {
    print_info "配置防火墙..."
    
    # UFW
    if command -v ufw &> /dev/null; then
        ufw allow ${SERVICE_PORT}/tcp
        ufw allow 3000/tcp
        ufw reload 2>/dev/null || true
    fi
    
    # Firewalld
    if command -v firewall-cmd &> /dev/null; then
        firewall-cmd --permanent --add-port=${SERVICE_PORT}/tcp 2>/dev/null || true
        firewall-cmd --permanent --add-port=3000/tcp 2>/dev/null || true
        firewall-cmd --reload 2>/dev/null || true
    fi
    
    print_success "防火墙配置完成"
}

# 检查服务状态
check_service() {
    print_info "检查服务状态..."
    
    sleep 3
    
    if pm2 list | grep -q "${APP_NAME}-backend"; then
        print_success "服务运行正常"
    else
        print_warn "服务可能未正常启动，请检查日志"
    fi
}

# 获取服务器 IP
get_server_ip() {
    SERVER_IP=$(curl -s ifconfig.me 2>/dev/null || curl -s ip.sb 2>/dev/null || echo "YOUR_SERVER_IP")
    echo $SERVER_IP
}

# 主流程
main() {
    print_header
    
    check_root
    detect_system
    install_nodejs
    install_pm2
    create_dirs
    copy_files
    install_deps
    setup_env
    init_database
    start_service
    setup_firewall
    check_service
    
    SERVER_IP=$(get_server_ip)
    
    echo ""
    print_success "========================================"
    print_success "   安装完成！"
    print_success "========================================"
    echo ""
    echo -e "${YELLOW}访问地址:${NC}"
    echo -e "  前台页面: ${GREEN}http://${SERVER_IP}:3000${NC}"
    echo -e "  后台管理: ${GREEN}http://${SERVER_IP}:3000/admin${NC}"
    echo ""
    echo -e "${YELLOW}默认账号:${NC}"
    echo -e "  用户名: ${GREEN}admin${NC}"
    echo -e "  密码: ${GREEN}admin123${NC}"
    echo ""
    echo -e "${YELLOW}常用命令:${NC}"
    echo "  重启服务: pm2 restart home-sxlb-backend"
    echo "  查看日志: pm2 logs home-sxlb-backend"
    echo "  停止服务: pm2 stop home-sxlb-backend"
    echo "  查看状态: pm2 list"
    echo ""
    echo -e "${YELLOW}重要提示:${NC}"
    echo "  1. 请及时修改默认密码！"
    echo "  2. 首次使用请在后台配置站点信息"
    echo "  3. 如需域名访问，请配置 Nginx 反向代理"
    echo ""
}

main "$@"
