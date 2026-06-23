import express from 'express';
import cors from 'cors';
import dotenv from 'dotenv';
import path from 'path';
import { logger } from './utils/logger';
import { initDatabase } from './config/database';
import configRouter from './routes/config';
import authRouter from './routes/auth';
import uploadRouter from './routes/upload';
import updateRouter from './routes/update';
import systemRouter from './routes/system';

// 加载环境变量
dotenv.config();

const app = express();
const PORT = process.env.PORT || 3001;

// 中间件
app.use(cors());
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// 静态文件 - 前端构建产物
const frontendDist = path.join(__dirname, '../../frontend/dist');
app.use(express.static(frontendDist));

// 日志中间件
app.use((req: express.Request, res: express.Response, next: express.NextFunction) => {
  logger.info(`${req.method} ${req.path}`);
  next();
});

// API 路由
app.use('/api/config', configRouter);
app.use('/api/auth', authRouter);
app.use('/api/upload', uploadRouter);
app.use('/api/update', updateRouter);
app.use('/api/system', systemRouter);

// 后台管理 SPA
const adminDist = path.join(__dirname, '../../admin/dist');
app.get('/admin*', (req: express.Request, res: express.Response) => {
  res.sendFile(path.join(adminDist, 'index.html'));
});

// 前台 SPA（所有未匹配的路由）
app.get('*', (req: express.Request, res: express.Response) => {
  res.sendFile(path.join(frontendDist, 'index.html'));
});

// 错误处理
app.use((err: any, req: express.Request, res: express.Response, next: express.NextFunction) => {
  logger.error('Error:', err);
  res.status(500).json({ success: false, message: '服务器内部错误' });
});

// 初始化数据库并启动服务
async function startServer() {
  try {
    // 初始化数据库
    await initDatabase();
    logger.info('数据库初始化完成');

    app.listen(PORT, () => {
      logger.info(`Home-SXLB 后台服务已启动: http://localhost:${PORT}`);
      logger.info(`后台管理: http://localhost:${PORT}/admin`);
      logger.info(`前台页面: http://localhost:${PORT}`);
    });
  } catch (error) {
    logger.error('启动失败:', error);
    process.exit(1);
  }
}

startServer();
