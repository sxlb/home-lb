// 数据库初始化脚本（独立运行，用于首次部署）
import { initDatabase } from '../config/database';
import dotenv from 'dotenv';

dotenv.config();

initDatabase().then(() => {
  console.log('Database initialized successfully.');
  process.exit(0);
}).catch((err) => {
  console.error('Database init failed:', err);
  process.exit(1);
});
