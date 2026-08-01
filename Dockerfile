# =============================================================================
# 無名の主页 · 单容器 Dockerfile
# =============================================================================
# 同时包含：
#   1. 前端构建产物（dist/）—— Vue 3 SPA 主站
#   2. admin-server —— Express 管理 API + 管理后台 UI + 主站静态资源服务
# 最终由 admin-server 提供全部 HTTP 服务（端口 12446）
# =============================================================================

# -------- 阶段 1: 构建前端 --------
FROM node:24-slim AS web-builder
WORKDIR /app
COPY package.json pnpm-lock.yaml ./
RUN corepack enable && corepack prepare pnpm@10 --activate
RUN pnpm install --frozen-lockfile
COPY . .
RUN [ ! -e ".env" ] && cp .env.example .env || true
RUN pnpm run build

# -------- 阶段 2: 安装 admin-server 依赖 --------
FROM node:24-slim AS admin-builder
WORKDIR /app
COPY admin-server/package.json admin-server/package-lock.json* ./
RUN npm install --omit=dev

# -------- 阶段 3: 最终镜像 --------
FROM node:24-slim
LABEL org.opencontainers.image.title="無名の主页"
LABEL org.opencontainers.image.description="Vue 3 个人主页 + 管理后台（单容器）"

WORKDIR /app

# admin-server 依赖与代码
COPY --from=admin-builder /app/node_modules ./node_modules
COPY admin-server/ ./admin-server/

# 前端构建产物与静态资源
COPY --from=web-builder /app/dist ./dist
COPY --from=web-builder /app/public ./public

# 创建非 root 用户，并赋予 public 目录写权限（admin-server 需写入运行时配置）
RUN addgroup -S app && adduser -S home -G app \
    && chown -R home:app /app/public
USER home

ENV NODE_ENV=production
ENV PORT=12446
ENV PROJECT_ROOT=/app

EXPOSE 12446

# 健康检查：使用 node 内置 fetch（node:24-slim 不含 wget/curl）
HEALTHCHECK --interval=30s --timeout=5s --start-period=15s --retries=3 \
  CMD node -e "fetch('http://localhost:12446/api/all').then(r=>process.exit(r.ok?0:1)).catch(()=>process.exit(1))"

CMD ["node", "admin-server/server.js"]
