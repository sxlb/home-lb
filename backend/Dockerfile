# Home-SXLB 后端 Dockerfile

FROM node:20-alpine

# 设置工作目录
WORKDIR /app

# 安装依赖
COPY package*.json ./
RUN npm install --production

# 复制源代码
COPY . .

# 创建必要目录
RUN mkdir -p database logs data

# 暴露端口
EXPOSE 3001

# 健康检查
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD wget --no-verbose --tries=1 --spider http://localhost:3001/api/system/health || exit 1

# 启动命令
CMD ["node", "dist/index.js"]
