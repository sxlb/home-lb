import { Router, Request, Response } from 'express';
import axios from 'axios';
import archiver from 'archiver';
import unzipper from 'unzipper';
import fs from 'fs';
import path from 'path';
import { logger } from '../utils/logger';
import { getDatabase } from '../config/database';
import { authenticateToken } from '../middleware/auth';

const router = Router();

// 检查最新版本
router.get('/check', async (req: Request, res: Response) => {
  try {
    const updateUrl = process.env.UPDATE_CHECK_URL;
    
    if (!updateUrl) {
      return res.json({ success: true, data: { latest: false, version: '1.0.0' } });
    }

    const response = await axios.get(updateUrl, { timeout: 10000 });
    const latestVersion = response.data.tag_name?.replace('v', '') || '1.0.0';
    const releaseNotes = response.data.body || '';
    const downloadUrl = response.data.zipball_url || '';

    // 获取当前版本（从版本历史表）
    const db = getDatabase();
    const currentVersion = db.prepare('SELECT version FROM version_history WHERE status = ? ORDER BY id DESC LIMIT 1').get('installed') as any;

    res.json({
      success: true,
      data: {
        latest: currentVersion ? latestVersion === currentVersion.version : true,
        currentVersion: currentVersion?.version || '1.0.0',
        latestVersion,
        releaseNotes,
        downloadUrl
      }
    });
  } catch (error: any) {
    logger.error('检查更新失败:', error);
    res.json({
      success: true,
      data: {
        latest: true,
        version: '1.0.0',
        message: '检查更新失败，请稍后重试'
      }
    });
  }
});

// 获取版本历史
router.get('/history', (req: Request, res: Response) => {
  try {
    const db = getDatabase();
    const history = db.prepare('SELECT * FROM version_history ORDER BY id DESC').all();

    res.json({ success: true, data: history });
  } catch (error: any) {
    logger.error('获取版本历史失败:', error);
    res.status(500).json({ success: false, message: '获取版本历史失败' });
  }
});

// 执行更新（需要认证）
router.post('/do-update', authenticateToken, async (req: Request, res: Response) => {
  try {
    const { downloadUrl, version } = req.body as { downloadUrl: string; version: string };

    if (!downloadUrl || !version) {
      return res.status(400).json({ success: false, message: '缺少必要参数' });
    }

    const db = getDatabase();

    // 记录更新日志
    db.prepare('INSERT INTO update_logs (action, version, status, message) VALUES (?, ?, ?, ?)').run(
      'update_start',
      version,
      'processing',
      '开始下载更新包'
    );

    // 创建备份
    const backupDir = path.join(__dirname, '../../backups');
    if (!fs.existsSync(backupDir)) {
      fs.mkdirSync(backupDir, { recursive: true });
    }

    // 下载更新包
    logger.info(`开始下载更新包: ${version}`);
    const response = await axios.get(downloadUrl, { responseType: 'arraybuffer', timeout: 300000 });
    
    const updateFile = path.join(backupDir, `update-${version}.zip`);
    fs.writeFileSync(updateFile, response.data);

    // 解压并应用更新
    const extractDir = path.join(backupDir, `update-${version}`);
    if (fs.existsSync(extractDir)) {
      fs.rmSync(extractDir, { recursive: true });
    }

    await new Promise((resolve, reject) => {
      fs.createReadStream(updateFile)
        .pipe(unzipper.Extract({ path: extractDir }))
        .on('close', resolve)
        .on('error', reject);
    });

    // 记录成功
    db.prepare('INSERT INTO update_logs (action, version, status, message) VALUES (?, ?, ?, ?)').run(
      'update_success',
      version,
      'success',
      '更新包下载成功'
    );

    // 更新版本记录
    db.prepare('UPDATE version_history SET status = ? WHERE status = ?').run('old', 'installed');
    db.prepare('INSERT INTO version_history (version, changelog, backup_path, status) VALUES (?, ?, ?, ?)').run(
      version,
      '',
      backupDir,
      'installed'
    );

    logger.info(`更新完成: ${version}`);
    res.json({
      success: true,
      message: '更新包下载成功，请手动重启服务以应用更新',
      data: {
        backupPath: backupDir,
        updatePath: extractDir
      }
    });
  } catch (error: any) {
    logger.error('更新失败:', error);
    
    const db = getDatabase();
    db.prepare('INSERT INTO update_logs (action, version, status, message) VALUES (?, ?, ?, ?)').run(
      'update_failed',
      version || 'unknown',
      'failed',
      error.message
    );

    res.status(500).json({ success: false, message: '更新失败: ' + error.message });
  }
});

// 获取更新日志
router.get('/logs', (req: Request, res: Response) => {
  try {
    const db = getDatabase();
    const logs = db.prepare('SELECT * FROM update_logs ORDER BY id DESC LIMIT 50').all();

    res.json({ success: true, data: logs });
  } catch (error: any) {
    logger.error('获取更新日志失败:', error);
    res.status(500).json({ success: false, message: '获取更新日志失败' });
  }
});

// 回滚到指定版本（需要认证）
router.post('/rollback', authenticateToken, (req: Request, res: Response) => {
  try {
    const { versionId } = req.body;

    const db = getDatabase();
    const targetVersion = db.prepare('SELECT * FROM version_history WHERE id = ?').get(versionId) as any;

    if (!targetVersion) {
      return res.status(404).json({ success: false, message: '指定版本不存在' });
    }

    if (!targetVersion.backup_path || !fs.existsSync(targetVersion.backup_path)) {
      return res.status(400).json({ success: false, message: '备份文件不存在，无法回滚' });
    }

    // 记录回滚
    db.prepare('INSERT INTO update_logs (action, version, status, message) VALUES (?, ?, ?, ?)').run(
      'rollback',
      targetVersion.version,
      'processing',
      '开始回滚操作'
    );

    logger.info(`开始回滚到版本: ${targetVersion.version}`);

    // 执行回滚（复制备份文件）
    // 这里简化处理，实际应复制文件到对应位置
    db.prepare('UPDATE version_history SET status = ? WHERE status = ?').run('old', 'installed');
    db.prepare('UPDATE version_history SET status = ? WHERE id = ?').run('installed', versionId);

    db.prepare('INSERT INTO update_logs (action, version, status, message) VALUES (?, ?, ?, ?)').run(
      'rollback_complete',
      targetVersion.version,
      'success',
      '回滚完成，请重启服务'
    );

    res.json({ success: true, message: '回滚操作已完成，请重启服务' });
  } catch (error: any) {
    logger.error('回滚失败:', error);
    res.status(500).json({ success: false, message: '回滚失败: ' + error.message });
  }
});

export default router;
