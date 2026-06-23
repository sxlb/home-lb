import { Router, Request, Response } from 'express';
import bcrypt from 'bcryptjs';
import jwt from 'jsonwebtoken';
import { getDatabase } from '../config/database';
import { logger } from '../utils/logger';

const router = Router();

// 登录
router.post('/login', async (req: Request, res: Response) => {
  try {
    const { username, password } = req.body;
    const db = getDatabase();

    const admin = db.prepare('SELECT * FROM admin WHERE username = ?').get(username) as any;

    if (!admin) {
      return res.status(401).json({ success: false, message: '用户名或密码错误' });
    }

    const isMatch = bcrypt.compareSync(password, admin.password);
    if (!isMatch) {
      return res.status(401).json({ success: false, message: '用户名或密码错误' });
    }

    // 生成 Token
    const token = jwt.sign(
      { id: admin.id, username: admin.username, role: admin.role },
      process.env.JWT_SECRET || 'default-secret',
      { expiresIn: '7d' }
    );

    logger.info(`管理员登录: ${username}`);
    res.json({
      success: true,
      data: {
        token,
        user: {
          id: admin.id,
          username: admin.username,
          role: admin.role
        }
      }
    });
  } catch (error: any) {
    logger.error('登录失败:', error);
    res.status(500).json({ success: false, message: '登录失败' });
  }
});

// 获取当前用户信息
router.get('/me', (req: Request, res: Response) => {
  try {
    const authHeader = req.headers.authorization;
    if (!authHeader) {
      return res.status(401).json({ success: false, message: '未登录' });
    }

    const token = authHeader.replace('Bearer ', '');
    const decoded = jwt.verify(token, process.env.JWT_SECRET || 'default-secret') as any;

    const db = getDatabase();
    const admin = db.prepare('SELECT id, username, role, created_at FROM admin WHERE id = ?').get(decoded.id);

    if (!admin) {
      return res.status(401).json({ success: false, message: '用户不存在' });
    }

    res.json({ success: true, data: admin });
  } catch (error: any) {
    if (error.name === 'JsonWebTokenError') {
      return res.status(401).json({ success: false, message: 'Token 无效' });
    }
    logger.error('获取用户信息失败:', error);
    res.status(500).json({ success: false, message: '获取用户信息失败' });
  }
});

// 修改密码
router.put('/password', (req: Request, res: Response) => {
  try {
    const authHeader = req.headers.authorization;
    if (!authHeader) {
      return res.status(401).json({ success: false, message: '未登录' });
    }

    const token = authHeader.replace('Bearer ', '');
    const decoded = jwt.verify(token, process.env.JWT_SECRET || 'default-secret') as any;

    const { oldPassword, newPassword } = req.body;
    const db = getDatabase();

    const admin = db.prepare('SELECT * FROM admin WHERE id = ?').get(decoded.id) as any;
    if (!admin) {
      return res.status(404).json({ success: false, message: '用户不存在' });
    }

    const isMatch = bcrypt.compareSync(oldPassword, admin.password);
    if (!isMatch) {
      return res.status(400).json({ success: false, message: '原密码错误' });
    }

    const hashedPassword = bcrypt.hashSync(newPassword, 10);
    db.prepare('UPDATE admin SET password = ?, updated_at = CURRENT_TIMESTAMP WHERE id = ?').run(hashedPassword, decoded.id);

    logger.info(`密码已修改: ${admin.username}`);
    res.json({ success: true, message: '密码修改成功' });
  } catch (error: any) {
    logger.error('修改密码失败:', error);
    res.status(500).json({ success: false, message: '修改密码失败' });
  }
});

export default router;
