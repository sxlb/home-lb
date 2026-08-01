/**
 * 無名の主页 管理后台服务器
 *
 * 功能：
 *  - 提供管理后台 UI（/admin）
 *  - 提供配置读写 API（/api/*）
 *  - 可选代理主站点（/），方便一站式预览
 *
 * 用法：
 *   pnpm install        # 或 npm install
 *   npm start
 *   # 浏览器访问 http://localhost:12446/admin
 *
 * 端口默认 12446，可通过 PORT 环境变量修改
 * 主项目根目录默认 ../ ，可通过 PROJECT_ROOT 环境变量修改
 */

import express from "express";
import cors from "cors";
import { promises as fs } from "fs";
import path from "path";
import { fileURLToPath } from "url";

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

// 主项目根目录（包含 public/、src/ 的那一层）
const PROJECT_ROOT = process.env.PROJECT_ROOT
  ? path.resolve(process.env.PROJECT_ROOT)
  : path.resolve(__dirname, "..");

const PORT = process.env.PORT || 12446;

// 需要管理的配置文件路径
const FILES = {
  runtimeConfig: path.join(PROJECT_ROOT, "public", "runtime-config.json"),
  siteLinks: path.join(PROJECT_ROOT, "public", "siteLinks.json"),
  socialLinks: path.join(PROJECT_ROOT, "public", "socialLinks.json"),
  bgConfig: path.join(PROJECT_ROOT, "public", "images", "config.json"),
};

const app = express();
app.use(cors());
app.use(express.json({ limit: "2mb" }));

// 简单鉴权：默认无密码，生产环境请设置 ADMIN_TOKEN 环境变量
const ADMIN_TOKEN = process.env.ADMIN_TOKEN || "";
const authMiddleware = (req, res, next) => {
  if (!ADMIN_TOKEN) return next();
  const token = req.headers["x-admin-token"] || req.query.token || "";
  if (token !== ADMIN_TOKEN) {
    return res.status(401).json({ error: "未授权访问" });
  }
  next();
};

// 工具：读取 JSON 文件（空文件或解析失败均返回 null，不抛异常）
async function readJson(filePath) {
  try {
    const raw = await fs.readFile(filePath, "utf-8");
    if (!raw || !raw.trim()) return null;
    return JSON.parse(raw);
  } catch (e) {
    if (e.code === "ENOENT") return null;
    console.warn(`[readJson] 读取 ${filePath} 失败:`, e.message);
    return null;
  }
}

// 工具：写入 JSON 文件（格式化输出）
async function writeJson(filePath, data) {
  const dir = path.dirname(filePath);
  await fs.mkdir(dir, { recursive: true });
  const content = JSON.stringify(data, null, 2) + "\n";
  const tmpPath = filePath + ".tmp-" + Date.now();
  try {
    await fs.writeFile(tmpPath, content, "utf-8");
    await fs.rename(tmpPath, filePath);
  } catch (e) {
    try { await fs.unlink(tmpPath); } catch {}
    // rename 失败，重试直接写入
    let lastErr = e;
    for (let i = 0; i < 3; i++) {
      try {
        await fs.writeFile(filePath, content, "utf-8");
        return;
      } catch (err) {
        lastErr = err;
        await new Promise(r => setTimeout(r, 100));
      }
    }
    throw lastErr;
  }
}

// ============ API 路由 ============

// 获取所有配置（一次拉取，减少请求）
app.get("/api/all", authMiddleware, async (req, res) => {
  try {
    const [runtimeConfig, siteLinks, socialLinks, bgConfig] = await Promise.all([
      readJson(FILES.runtimeConfig),
      readJson(FILES.siteLinks),
      readJson(FILES.socialLinks),
      readJson(FILES.bgConfig),
    ]);
    res.json({
      runtimeConfig: runtimeConfig || {},
      defaults: (runtimeConfig && runtimeConfig.defaults) || {},
      siteLinks: siteLinks || [],
      socialLinks: socialLinks || [],
      bgConfig: bgConfig || { bgImageCount: 10, bgImageCountP: 2 },
    });
  } catch (e) {
    console.error("[/api/all] 读取失败:", e);
    res.status(500).json({ error: String(e) });
  }
});

// 保存运行时配置（站点信息 / 音乐 / 天气 / TTS 等都在这里）
// 合并模式：保留旧文件中不在 req.body 里的字段（如 defaults），避免覆盖丢失
app.post("/api/runtime-config", authMiddleware, async (req, res) => {
  try {
    const existing = await readJson(FILES.runtimeConfig) || {};
    const merged = { ...existing, ...req.body };
    await writeJson(FILES.runtimeConfig, merged);
    res.json({ ok: true });
  } catch (e) {
    console.error("[/api/runtime-config] 保存失败:", e);
    res.status(500).json({ error: String(e) });
  }
});

// 获取前端默认设置（存储在 runtime-config.json 的 defaults 字段）
app.get("/api/defaults", authMiddleware, async (req, res) => {
  try {
    const rc = await readJson(FILES.runtimeConfig) || {};
    res.json(rc.defaults || {});
  } catch (e) {
    console.error("[/api/defaults] 读取失败:", e);
    res.status(500).json({ error: String(e) });
  }
});

// 保存前端默认设置（读取 runtime-config.json，更新 defaults 字段，写回）
app.post("/api/defaults", authMiddleware, async (req, res) => {
  try {
    const existing = await readJson(FILES.runtimeConfig) || {};
    existing.defaults = req.body;
    await writeJson(FILES.runtimeConfig, existing);
    res.json({ ok: true });
  } catch (e) {
    console.error("[/api/defaults] 保存失败:", e);
    res.status(500).json({ error: String(e) });
  }
});

// 保存网站链接
app.post("/api/site-links", authMiddleware, async (req, res) => {
  try {
    if (!Array.isArray(req.body)) {
      return res.status(400).json({ error: "数据必须是数组" });
    }
    await writeJson(FILES.siteLinks, req.body);
    res.json({ ok: true });
  } catch (e) {
    console.error("[/api/site-links] 保存失败:", e);
    res.status(500).json({ error: String(e) });
  }
});

// 保存社交链接
app.post("/api/social-links", authMiddleware, async (req, res) => {
  try {
    if (!Array.isArray(req.body)) {
      return res.status(400).json({ error: "数据必须是数组" });
    }
    await writeJson(FILES.socialLinks, req.body);
    res.json({ ok: true });
  } catch (e) {
    console.error("[/api/social-links] 保存失败:", e);
    res.status(500).json({ error: String(e) });
  }
});

// 保存背景配置
app.post("/api/bg-config", authMiddleware, async (req, res) => {
  try {
    await writeJson(FILES.bgConfig, req.body);
    res.json({ ok: true });
  } catch (e) {
    console.error("[/api/bg-config] 保存失败:", e);
    res.status(500).json({ error: String(e) });
  }
});

// ============ 静态资源 ============

// 管理后台 UI
app.use("/admin", express.static(path.join(__dirname, "public")));

// 主站点静态资源（图片、字体、runtime-config.json 等，可被管理后台实时修改）
app.use("/", express.static(path.join(PROJECT_ROOT, "public")));

// 主站 SPA 构建产物（JS / CSS / index.html 等，构建后不再变化）
// 若存在 dist 目录，则额外服务；否则跳过（开发模式下 dist 不存在）
const distDir = path.join(PROJECT_ROOT, "dist");
app.use("/", express.static(distDir));

// SPA fallback：未匹配的路由统一返回 index.html，由前端路由接管
// 必须放在所有 /api/* 之后，避免吞掉 API 请求
app.get("*", (req, res, next) => {
  // 仅对非 API、非 admin 路径生效
  if (req.path.startsWith("/api/") || req.path.startsWith("/admin")) return next();
  const indexPath = path.join(distDir, "index.html");
  res.sendFile(indexPath, (err) => {
    if (err) {
      // dist 不存在（如纯 admin-server 部署），回退到 public 目录
      const pubIndex = path.join(PROJECT_ROOT, "public", "index.html");
      res.sendFile(pubIndex, (e2) => {
        if (e2) res.status(404).send("Not Found");
      });
    }
  });
});

// 启动
app.listen(PORT, () => {
  console.log("========================================");
  console.log("  無名の主页 管理后台已启动");
  console.log("========================================");
  console.log(`  管理后台:  http://localhost:${PORT}/admin`);
  console.log(`  主站预览:  http://localhost:${PORT}/`);
  console.log(`  项目根目录: ${PROJECT_ROOT}`);
  if (ADMIN_TOKEN) {
    console.log(`  鉴权:      已启用 (X-Admin-Token)`);
  } else {
    console.log(`  鉴权:      未启用 (设置 ADMIN_TOKEN 环境变量以开启)`);
  }
  console.log("========================================");
});
