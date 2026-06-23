import { Router, Request, Response } from 'express';
import multer, { StorageEngine, Options, FileFilterCallback } from 'multer';
import path from 'path';
import fs from 'fs';
import { logger } from '../utils/logger';
import { authenticateToken } from '../middleware/auth';

const router = Router();

// 配置文件上传
const storage: StorageEngine = multer.diskStorage({
  destination: (req: Request, file: Express.Multer.File, cb: (error: Error | null, destination: string) => void) => {
    const uploadDir = path.join(__dirname, '../../../frontend/public/images');
    if (!fs.existsSync(uploadDir)) {
      fs.mkdirSync(uploadDir, { recursive: true });
    }
    cb(null, uploadDir);
  },
  filename: (req: Request, file: Express.Multer.File, cb: (error: Error | null, filename: string) => void) => {
    const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1E9);
    const ext = path.extname(file.originalname);
    cb(null, `upload-${uniqueSuffix}${ext}`);
  }
});

const uploadOptions: Options = {
  storage,
  limits: { fileSize: 5 * 1024 * 1024 }, // 5MB
  fileFilter: (req: Request, file: Express.Multer.File, cb: FileFilterCallback) => {
    const allowedTypes = ['image/jpeg', 'image/png', 'image/gif', 'image/webp'];
    if (allowedTypes.includes(file.mimetype)) {
      cb(null, true);
    } else {
      cb(new Error('仅支持 JPG、PNG、GIF、WebP 格式图片'));
    }
  }
};

const upload = multer(uploadOptions);

// 上传图片（需要认证）
router.post('/image', authenticateToken, upload.single('file'), (req: Request, res: Response) => {
  try {
    if (!req.file) {
      return res.status(400).json({ success: false, message: '未上传文件' });
    }

    const fileUrl = `/images/${req.file.filename}`;
    logger.info(`图片上传成功: ${fileUrl}`);

    res.json({
      success: true,
      data: {
        url: fileUrl,
        filename: req.file.filename,
        size: req.file.size
      }
    });
  } catch (error: any) {
    logger.error('上传失败:', error);
    res.status(500).json({ success: false, message: '上传失败' });
  }
});

// 上传多张图片（需要认证）
router.post('/images', authenticateToken, upload.array('files', 10), (req: Request, res: Response) => {
  try {
    const files = req.files as multer.File[];
    if (!files || files.length === 0) {
      return res.status(400).json({ success: false, message: '未上传文件' });
    }

    const uploaded = files.map(file => ({
      url: `/images/${file.filename}`,
      filename: file.filename,
      size: file.size
    }));

    logger.info(`批量上传成功: ${files.length} 个文件`);

    res.json({ success: true, data: uploaded });
  } catch (error: any) {
    logger.error('上传失败:', error);
    res.status(500).json({ success: false, message: '上传失败' });
  }
});

// 删除图片（需要认证）
router.delete('/image', authenticateToken, (req: Request, res: Response) => {
  try {
    const { filename } = req.body;
    const filePath = path.join(__dirname, '../../../frontend/public/images', filename);

    if (!fs.existsSync(filePath)) {
      return res.status(404).json({ success: false, message: '文件不存在' });
    }

    fs.unlinkSync(filePath);
    logger.info(`图片删除成功: ${filename}`);

    res.json({ success: true, message: '删除成功' });
  } catch (error: any) {
    logger.error('删除失败:', error);
    res.status(500).json({ success: false, message: '删除失败' });
  }
});

// 获取图片列表
router.get('/images', (req: Request, res: Response) => {
  try {
    const imagesDir = path.join(__dirname, '../../../frontend/public/images');
    
    if (!fs.existsSync(imagesDir)) {
      return res.json({ success: true, data: [] });
    }

    const files = fs.readdirSync(imagesDir);
    const images = files
      .filter(file => /\.(jpg|jpeg|png|gif|webp)$/i.test(file))
      .map(file => ({
        name: file,
        url: `/images/${file}`,
        size: fs.statSync(path.join(imagesDir, file)).size,
        mtime: fs.statSync(path.join(imagesDir, file)).mtime
      }));

    res.json({ success: true, data: images });
  } catch (error: any) {
    logger.error('获取图片列表失败:', error);
    res.status(500).json({ success: false, message: '获取图片列表失败' });
  }
});

export default router;
