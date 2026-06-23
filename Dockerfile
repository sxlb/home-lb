# ---- 阶段1: 构建前端 ----
FROM node:22-alpine AS frontend-builder
WORKDIR /build/frontend
COPY frontend/package.json frontend/package-lock.json ./
RUN npm ci
COPY frontend/ ./
RUN npm run build

# ---- 阶段2: 构建管理后台 ----
FROM node:22-alpine AS admin-builder
WORKDIR /build/admin
COPY admin/package.json admin/package-lock.json ./
RUN npm ci
COPY admin/ ./
RUN npm run build

# ---- 阶段3: 构建后端 ----
FROM node:22-alpine AS backend-builder
WORKDIR /build/backend
COPY backend/package.json backend/package-lock.json ./
RUN npm ci
COPY backend/ ./
RUN npm run build

# ---- 阶段4: 生产镜像 ----
FROM node:22-alpine
WORKDIR /app

# 复制后端产物和依赖
COPY --from=backend-builder /build/backend/dist ./dist
COPY --from=backend-builder /build/backend/package.json /build/backend/package-lock.json ./
RUN npm ci --omit=dev

# 复制前端和管理后台构建产物
COPY --from=frontend-builder /build/frontend/dist ./frontend/dist
COPY --from=admin-builder /build/admin/dist ./admin/dist

# 数据目录
RUN mkdir -p /app/database /app/logs /app/data

ENV NODE_ENV=production
ENV PORT=3001
ENV STATIC_PATH=/app

EXPOSE 3001

CMD ["node", "dist/index.js"]
