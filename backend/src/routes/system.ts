import { Router, Request, Response } from 'express';
import { logger } from '../utils/logger';
import { getDatabase } from '../config/database';
import fs from 'fs';
import path from 'path';
import { authenticateToken } from '../middleware/auth';

const router = Router();

// 获取系统信息
router.get('/info', (req: Request, res: Response) => {
  try {
    const db = getDatabase();
    
    // 获取版本信息
    const currentVersion = db.prepare('SELECT * FROM version_history WHERE status = ? ORDER BY id DESC LIMIT 1').get('installed') as any;
    
    // 获取设置统计
    const settingsCount = db.prepare('SELECT COUNT(*) as count FROM settings').get() as any;
    
    // 获取更新日志统计
    const updateLogsCount = db.prepare('SELECT COUNT(*) as count FROM update_logs').get() as any;

    res.json({
      success: true,
      data: {
        appVersion: currentVersion?.version || '1.0.0',
        nodeVersion: process.version,
        platform: process.platform,
        uptime: process.uptime(),
        settingsCount: settingsCount?.count || 0,
        updateLogsCount: updateLogsCount?.count || 0,
        databaseSize: getDbSize(),
        dataPath: process.env.DB_PATH || './database/home-sxlb.db'
      }
    });
  } catch (error: any) {
    logger.error('获取系统信息失败:', error);
    res.status(500).json({ success: false, message: '获取系统信息失败' });
  }
});

// 获取数据库大小
function getDbSize(): string {
  try {
    const dbPath = process.env.DB_PATH || path.join(__dirname, '../../database/home-sxlb.db');
    if (fs.existsSync(dbPath)) {
      const stats = fs.statSync(dbPath);
      return formatBytes(stats.size);
    }
    return '0 B';
  } catch {
    return '0 B';
  }
}

// 格式化字节大小
function formatBytes(bytes: number): string {
  if (bytes === 0) return '0 B';
  const k = 1024;
  const sizes = ['B', 'KB', 'MB', 'GB'];
  const i = Math.floor(Math.log(bytes) / Math.log(k));
  return parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + ' ' + sizes[i];
}

// 健康检查
router.get('/health', (req: Request, res: Response) => {
  res.json({
    success: true,
    data: {
      status: 'healthy',
      timestamp: new Date().toISOString()
    }
  });
});

// 导出配置
router.get('/export', (req: Request, res: Response) => {
  try {
    const db = getDatabase();
    const settings = db.prepare('SELECT key, value, type, group_name FROM settings').all() as any[];
    
    const config: Record<string, any> = {};
    for (const setting of settings) {
      if (setting.type === 'json') {
        config[setting.key] = JSON.parse(setting.value);
      } else if (setting.type === 'boolean') {
        config[setting.key] = setting.value === 'true';
      } else if (setting.type === 'number') {
        config[setting.key] = Number(setting.value);
      } else {
        config[setting.key] = setting.value;
      }
    }

    res.json({
      success: true,
      data: {
        version: '1.0.0',
        exportedAt: new Date().toISOString(),
        settings: config
      }
    });
  } catch (error: any) {
    logger.error('导出配置失败:', error);
    res.status(500).json({ success: false, message: '导出配置失败' });
  }
});

// 导入配置（需要认证）
router.post('/import', authenticateToken, (req: Request, res: Response) => {
  try {
    const { settings } = req.body;
    
    if (!settings || typeof settings !== 'object') {
      return res.status(400).json({ success: false, message: '配置格式错误' });
    }

    const db = getDatabase();
    const updateStmt = db.prepare('UPDATE settings SET value = ?, updated_at = CURRENT_TIMESTAMP WHERE key = ?');

    for (const [key, value] of Object.entries(settings)) {
      const stringValue = typeof value === 'object' ? JSON.stringify(value) : String(value);
      updateStmt.run(stringValue, key);
    }

    logger.info('配置导入成功');
    res.json({ success: true, message: '配置导入成功' });
  } catch (error: any) {
    logger.error('导入配置失败:', error);
    res.status(500).json({ success: false, message: '导入配置失败' });
  }
});

// 清理日志（需要认证）
router.post('/logs/clean', authenticateToken, (req: Request, res: Response) => {
  try {
    const db = getDatabase();
    db.prepare('DELETE FROM update_logs').run();
    
    logger.info('更新日志已清理');
    res.json({ success: true, message: '日志已清理' });
  } catch (error: any) {
    logger.error('清理日志失败:', error);
    res.status(500).json({ success: false, message: '清理失败' });
  }
});

export default router;
