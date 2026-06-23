import { Request, Response, NextFunction } from 'express';
import jwt from 'jsonwebtoken';
import { logger } from '../utils/logger';

export function authenticateToken(req: Request, res: Response, next: NextFunction) {
  try {
    const authHeader = req.headers.authorization;
    if (!authHeader) {
      return res.status(401).json({ success: false, message: '未登录，请先登录' });
    }

    const token = authHeader.replace('Bearer ', '');
    
    jwt.verify(token, process.env.JWT_SECRET || 'default-secret', (err: any, decoded: any) => {
      if (err) {
        if (err.name === 'JsonWebTokenError') {
          return res.status(401).json({ success: false, message: 'Token 无效' });
        }
        if (err.name === 'TokenExpiredError') {
          return res.status(401).json({ success: false, message: 'Token 已过期' });
        }
        return res.status(401).json({ success: false, message: '认证失败' });
      }

      (req as any).user = decoded;
      next();
    });
  } catch (error: any) {
    logger.error('认证失败:', error);
    res.status(500).json({ success: false, message: '服务器内部错误' });
  }
}

export default { authenticateToken };