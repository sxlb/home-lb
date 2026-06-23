#!/bin/bash
set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

print_ok()  { echo -e "${GREEN}[OK]${NC} $1"; }
print_err() { echo -e "${RED}[ERR]${NC} $1"; }

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}   Home-SXLB 一键安装${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""

# 检测 Node.js
if ! command -v node &>/dev/null; then
    print_err "未安装 Node.js，请先安装 Node.js >= 18"
    echo "  Ubuntu/Debian: curl -fsSL https://deb.nodesource.com/setup_22.x | sudo -E bash - && sudo apt-get install -y nodejs"
    echo "  CentOS/RHEL:   curl -fsSL https://rpm.nodesource.com/setup_22.x | sudo bash - && sudo yum install -y nodejs"
    exit 1
fi
print_ok "Node.js $(node -v)"

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

# 构建前端
echo ""
echo ">>> 构建前端..."
cd "$PROJECT_DIR/frontend"
npm install
npm run build
print_ok "前端构建完成"

# 构建管理后台
echo ""
echo ">>> 构建管理后台..."
cd "$PROJECT_DIR/admin"
npm install
npm run build
print_ok "管理后台构建完成"

# 构建后端
echo ""
echo ">>> 构建后端..."
cd "$PROJECT_DIR/backend"
npm install
npm run build
print_ok "后端构建完成"

# 初始化数据库
echo ""
echo ">>> 初始化数据库..."
npm run init-db
print_ok "数据库就绪"

echo ""
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}   安装完成！${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""
echo -e "${YELLOW}启动服务:${NC}"
echo "  cd backend && npm start          # 前台运行"
echo "  cd backend && nohup npm start &  # 后台运行"
echo ""
echo -e "${YELLOW}访问地址:${NC}"
echo "  前台: http://localhost:3001"
echo "  后台: http://localhost:3001/admin"
echo "  账号: admin / admin123"
echo ""
echo -e "${YELLOW}Docker 部署:${NC}"
echo "  cd $PROJECT_DIR && docker compose up -d"
