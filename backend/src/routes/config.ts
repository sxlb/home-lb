import { Router, Request, Response } from 'express';
import { getDatabase } from '../config/database';
import { logger } from '../utils/logger';

const router = Router();

// 获取所有设置（按分组）
router.get('/', (req: Request, res: Response) => {
  try {
    const db = getDatabase();
    const settings = db.prepare('SELECT * FROM settings ORDER BY group_name, id').all();
    
    // 按分组整理
    const grouped: Record<string, any> = {};
    for (const setting of settings as any[]) {
      if (!grouped[setting.group_name]) {
        grouped[setting.group_name] = [];
      }
      grouped[setting.group_name].push(setting);
    }

    res.json({ success: true, data: grouped });
  } catch (error: any) {
    logger.error('获取设置失败:', error);
    res.status(500).json({ success: false, message: '获取设置失败' });
  }
});

// 获取单个设置
router.get('/:key', (req: Request, res: Response) => {
  try {
    const db = getDatabase();
    const setting = db.prepare('SELECT * FROM settings WHERE key = ?').get(req.params.key);
    
    if (!setting) {
      return res.status(404).json({ success: false, message: '设置不存在' });
    }

    res.json({ success: true, data: setting });
  } catch (error: any) {
    logger.error('获取设置失败:', error);
    res.status(500).json({ success: false, message: '获取设置失败' });
  }
});

// 更新设置
router.put('/:key', (req: Request, res: Response) => {
  try {
    const db = getDatabase();
    const { value } = req.body;
    const { key } = req.params;

    const setting = db.prepare('SELECT * FROM settings WHERE key = ?').get(key);
    if (!setting) {
      return res.status(404).json({ success: false, message: '设置不存在' });
    }

    // 类型转换
    let finalValue = value;
    const settingTyped = setting as any;
    if (settingTyped.type === 'boolean') {
      finalValue = value ? 'true' : 'false';
    } else if (settingTyped.type === 'number') {
      finalValue = String(value);
    } else if (settingTyped.type === 'json') {
      finalValue = typeof value === 'string' ? value : JSON.stringify(value);
    }

    db.prepare('UPDATE settings SET value = ?, updated_at = CURRENT_TIMESTAMP WHERE key = ?').run(finalValue, key);

    logger.info(`设置已更新: ${key}`);
    res.json({ success: true, message: '设置已更新' });
  } catch (error: any) {
    logger.error('更新设置失败:', error);
    res.status(500).json({ success: false, message: '更新设置失败' });
  }
});

// 批量更新设置
router.put('/', (req: Request, res: Response) => {
  try {
    const db = getDatabase();
    const { settings } = req.body;

    if (!Array.isArray(settings)) {
      return res.status(400).json({ success: false, message: '参数格式错误' });
    }

    const updateStmt = db.prepare('UPDATE settings SET value = ?, updated_at = CURRENT_TIMESTAMP WHERE key = ?');

    for (const item of settings) {
      updateStmt.run(item.value, item.key);
    }

    logger.info(`批量更新 ${settings.length} 个设置`);
    res.json({ success: true, message: '设置已批量更新' });
  } catch (error: any) {
    logger.error('批量更新设置失败:', error);
    res.status(500).json({ success: false, message: '批量更新设置失败' });
  }
});

// 重置为默认值
router.post('/reset', (req: Request, res: Response) => {
  try {
    const db = getDatabase();
    // 重置所有设置为默认值
    db.prepare('UPDATE settings SET value = (SELECT value FROM settings WHERE key = settings.key)').run();
    
    logger.info('设置已重置');
    res.json({ success: true, message: '设置已重置' });
  } catch (error: any) {
    logger.error('重置设置失败:', error);
    res.status(500).json({ success: false, message: '重置设置失败' });
  }
});

export default router;
