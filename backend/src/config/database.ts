import Database from 'better-sqlite3';
import path from 'path';
import fs from 'fs';
import dotenv from 'dotenv';
import bcrypt from 'bcryptjs';

dotenv.config();

const dbPath = process.env.DB_PATH || path.join(__dirname, '../../database/home-sxlb.db');
const dbDir = path.dirname(dbPath);

// 确保数据库目录存在
if (!fs.existsSync(dbDir)) {
  fs.mkdirSync(dbDir, { recursive: true });
}

let db: Database.Database;

export function getDatabase(): Database.Database {
  if (!db) {
    db = new Database(dbPath);
    db.pragma('journal_mode = WAL');
  }
  return db;
}

export async function initDatabase(): Promise<void> {
  const database = getDatabase();

  // 创建管理员表
  database.exec(`
    CREATE TABLE IF NOT EXISTS admin (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      username TEXT UNIQUE NOT NULL,
      password TEXT NOT NULL,
      role TEXT DEFAULT 'admin',
      created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
      updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
    )
  `);

  // 创建设置表
  database.exec(`
    CREATE TABLE IF NOT EXISTS settings (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      key TEXT UNIQUE NOT NULL,
      value TEXT,
      type TEXT DEFAULT 'string',
      group_name TEXT DEFAULT 'general',
      description TEXT,
      options TEXT,
      updated_at DATETIME DEFAULT CURRENT_TIMESTAMP
    )
  `);

  // 创建版本历史表
  database.exec(`
    CREATE TABLE IF NOT EXISTS version_history (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      version TEXT NOT NULL,
      release_date DATETIME DEFAULT CURRENT_TIMESTAMP,
      changelog TEXT,
      backup_path TEXT,
      status TEXT DEFAULT 'installed'
    )
  `);

  // 创建更新日志表
  database.exec(`
    CREATE TABLE IF NOT EXISTS update_logs (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      action TEXT NOT NULL,
      version TEXT,
      status TEXT,
      message TEXT,
      created_at DATETIME DEFAULT CURRENT_TIMESTAMP
    )
  `);

  // 插入默认管理员（如果不存在）
  const adminExists = database.prepare('SELECT id FROM admin WHERE username = ?').get('admin');
  if (!adminExists) {
    const hashedPassword = bcrypt.hashSync(process.env.ADMIN_PASSWORD || 'admin123', 10);
    database.prepare('INSERT INTO admin (username, password) VALUES (?, ?)').run('admin', hashedPassword);
    console.log('默认管理员账号已创建: admin / admin123');
  }

  // 插入默认设置
  const defaultSettings = [
    // 站点基础信息
    { key: 'site_name', value: '我的主页', type: 'string', group_name: 'site', description: '站点名称' },
    { key: 'site_author', value: '作者', type: 'string', group_name: 'site', description: '作者名称' },
    { key: 'site_description', value: '欢迎来到我的主页', type: 'string', group_name: 'site', description: '站点描述' },
    { key: 'site_keywords', value: '个人主页,作品集', type: 'string', group_name: 'site', description: '站点关键词' },
    { key: 'site_url', value: 'https://example.com', type: 'string', group_name: 'site', description: '站点地址' },
    { key: 'site_start', value: '2024-01-01', type: 'string', group_name: 'site', description: '建站日期' },
    
    // 社交链接
    { key: 'social_github', value: '', type: 'string', group_name: 'social', description: 'GitHub 链接' },
    { key: 'social_bilibili', value: '', type: 'string', group_name: 'social', description: 'B站链接' },
    { key: 'social_twitter', value: '', type: 'string', group_name: 'social', description: 'Twitter 链接' },
    { key: 'social_email', value: '', type: 'string', group_name: 'social', description: '邮箱' },
    { key: 'social_qq', value: '', type: 'string', group_name: 'social', description: 'QQ 号' },
    
    // 网站链接
    { key: 'site_links', value: '[]', type: 'json', group_name: 'links', description: '网站链接列表' },
    
    // 备案信息
    { key: 'icp_number', value: '', type: 'string', group_name: 'icp', description: 'ICP 备案号' },
    { key: 'police_number', value: '', type: 'string', group_name: 'icp', description: '公安备案号' },
    
    // 天气服务
    { key: 'weather_tx_key', value: '', type: 'string', group_name: 'weather', description: '腾讯天气 Key' },
    { key: 'weather_gd_key', value: '', type: 'string', group_name: 'weather', description: '高德天气 Key' },
    
    // 音乐播放器
    { key: 'music_api', value: '', type: 'string', group_name: 'music', description: '音乐 API 地址' },
    { key: 'music_server', value: 'netease', type: 'select', group_name: 'music', description: '音乐服务器', options: 'netease,tencent' },
    { key: 'music_playlist_id', value: '', type: 'string', group_name: 'music', description: '歌单 ID' },
    { key: 'music_autoplay', value: 'false', type: 'boolean', group_name: 'music', description: '自动播放' },
    { key: 'music_volume', value: '0.3', type: 'number', group_name: 'music', description: '音量', options: '0,1' },
    
    // 壁纸设置
    { key: 'wallpaper_type', value: '0', type: 'select', group_name: 'wallpaper', description: '壁纸类型', options: '0:本地,1:必应,2:韩小韩,3:ACG' },
    { key: 'wallpaper_count', value: '10', type: 'number', group_name: 'wallpaper', description: '本地壁纸数量' },
    
    // 功能开关
    { key: 'enable_seasonal_effects', value: 'true', type: 'boolean', group_name: 'features', description: '季节特效' },
    { key: 'enable_lyrics', value: 'true', type: 'boolean', group_name: 'features', description: '歌词显示' },
    { key: 'enable_weather', value: 'true', type: 'boolean', group_name: 'features', description: '天气显示' },
    { key: 'enable_hitokoto', value: 'true', type: 'boolean', group_name: 'features', description: '一言' },
    
    // 主题设置
    { key: 'theme_mode', value: 'system', type: 'select', group_name: 'theme', description: '主题模式', options: 'system,light,dark,time' },
    { key: 'theme_primary_color', value: '#409eff', type: 'color', group_name: 'theme', description: '主题色' },
  ];

  const insertSetting = database.prepare(`
    INSERT OR IGNORE INTO settings (key, value, type, group_name, description, options)
    VALUES (?, ?, ?, ?, ?, ?)
  `);

  for (const setting of defaultSettings) {
    insertSetting.run(setting.key, setting.value, setting.type, setting.group_name, setting.description, setting.options || null);
  }
}

export default { getDatabase, initDatabase };
