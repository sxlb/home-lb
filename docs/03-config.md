# 03 - 配置系统

## 3.1 设计目标

本项目支持三种配置来源，优先级从高到低：

1. **运行时配置**（`/runtime-config.json`）：部署后可修改，无需重新构建。
2. **编译时配置**（`.env`）：构建时注入，适合 CI/CD 流程。
3. **示例配置**（`src/assets/example_config.json`）：兜底默认值。

该设计的核心目的是让普通用户在 Docker / 静态托管环境中也能修改配置，无需重新构建镜像。

## 3.2 实现位置

完整实现位于 [src/utils/config_check.ts](file:///d:/wenjian/home/home/src/utils/config_check.ts)。

## 3.3 加载流程

### 3.3.1 运行时配置加载

`loadRuntimeConfig()` 在应用挂载前调用（见 [src/main.ts](file:///d:/wenjian/home/home/src/main.ts)）：

```ts
export async function loadRuntimeConfig(): Promise<void> {
  try {
    const resp = await fetch('/runtime-config.json', { cache: 'no-cache' });
    if (resp.ok) {
      runtimeConfig = await resp.json() as Record<string, string>;
      console.log('[config] 运行时配置加载成功');
    } else {
      console.warn('[config] 运行时配置加载失败：HTTP', resp.status, '，回退到编译时配置');
    }
  } catch (e) {
    console.warn('[config] 运行时配置加载异常，回退到编译时配置：', e);
  }
}
```

- 使用 `cache: 'no-cache'` 确保获取最新文件。
- 任何错误都不中断启动，仅回退到下一级配置。

### 3.3.2 取值优先级

`pick(key)` 函数实现三级回退：

```ts
const pick = (key: string): string => {
  // 1. 运行时配置优先
  if (runtimeConfig && runtimeConfig[key] !== undefined && runtimeConfig[key] !== '') {
    return runtimeConfig[key] as string;
  }
  // 2. 编译时 .env 配置（需 VITE_CONFIG_TURN == "true"）
  const envTurnedOn = import.meta.env.VITE_CONFIG_TURN == 'true';
  if (envTurnedOn) {
    const v = (import.meta.env as Record<string, string>)[key];
    if (v !== undefined && v !== '') return v;
  }
  // 3. 兜底：example_config.json
  return (exampleConfig as Record<string, string>)[key] ?? '';
};
```

**注意**：编译时 `.env` 必须设置 `VITE_CONFIG_TURN = "true"` 才会被读取。这是为了避免开发者在未配置 `.env` 时项目异常。

### 3.3.3 envConfig 代理

`envConfig` 使用 `Proxy` 实现，确保 `loadRuntimeConfig()` 完成后所有访问都能拿到最新值：

```ts
export const envConfig: Env = new Proxy({} as Env, {
  get(_target, prop: string) {
    // vite 内置变量直接返回
    if (prop === 'BASE_URL') return import.meta.env.BASE_URL;
    if (prop === 'MODE') return import.meta.env.MODE;
    if (prop === 'DEV') return import.meta.env.DEV;
    if (prop === 'PROD') return import.meta.env.PROD;
    if (prop === 'SSR') return import.meta.env.SSR;
    // VITE_ 配置项动态读取
    if (viteKeys.includes(prop)) {
      return pick(prop);
    }
    // 其他属性透传
    return (import.meta.env as Record<string, unknown>)[prop];
  },
});
```

由于 `envConfig` 通过 `unplugin-auto-import` 全局注入，所有组件可直接访问 `envConfig.VITE_xxx`，无需手动 import。

## 3.4 支持的配置项

完整列表见 [src/utils/config_check.ts](file:///d:/wenjian/home/home/src/utils/config_check.ts) 的 `viteKeys` 数组，以及 [.env.example](file:///d:/wenjian/home/home/.env.example)。

### 3.4.1 站点信息

| 配置项 | 说明 |
| --- | --- |
| `VITE_CONFIG_TURN` | 是否启用配置文件（必须为 `"true"`） |
| `VITE_SITE_NAME` | 站点名称（显示于加载页、设置页） |
| `VITE_SITE_AUTHOR` | 站点作者（页脚版权） |
| `VITE_SITE_KEYWORDS` | SEO 关键词 |
| `VITE_SITE_DES` | 站点简介（PWA manifest） |
| `VITE_SITE_URL` | 站点地址（页脚链接、Logo 文本） |
| `VITE_SITE_MAIN_NAME` | 自定义名（msgNameShow 开启时显示） |
| `VITE_SITE_LOGO` | 站点主图标（favicon） |
| `VITE_SITE_MAIN_LOGO` | 主页 Logo 图 |
| `VITE_SITE_APPLE_LOGO` | Apple 端图标 |

### 3.4.2 简介文本

| 配置项 | 说明 |
| --- | --- |
| `VITE_DESC_HELLO` | 默认简介首行 |
| `VITE_DESC_TEXT` | 默认简介次行 |
| `VITE_DESC_HELLO_OTHER` | 拓展盒子打开时首行 |
| `VITE_DESC_TEXT_OTHER` | 拓展盒子打开时次行 |

### 3.4.3 天气

| 配置项 | 说明 |
| --- | --- |
| `VITE_TX_WEATHER_KEY` | 腾讯位置服务 Key |
| `VITE_GD_WEATHER_KEY` | 高德开放平台 Key |
| `VITE_TX_WEATHER_SKEY` | 腾讯接口签名 SKEY（可选） |

### 3.4.4 建站信息

| 配置项 | 说明 |
| --- | --- |
| `VITE_SITE_START` | 建站日期（`YYYY-MM-DD` 或 `YYYY`） |
| `VITE_SITE_ICP` | ICP 备案号 |
| `VITE_SITE_MPS` | 公安备案号 |
| `VITE_SITE_MICP` | 移动端备案号（保留字段，未使用） |

### 3.4.5 音乐

| 配置项 | 说明 |
| --- | --- |
| `VITE_SONG_API` | Meting API 地址 |
| `VITE_SONG_SERVER` | 主音乐源（`netease` / `tencent`） |
| `VITE_SONG_SERVER_SECOND` | 备用音乐源 |
| `VITE_SONG_TYPE` | 播放类型（`song` / `playlist` / `album` / `search` / `artist`） |
| `VITE_SONG_ID` | 主源 ID |
| `VITE_SONG_ID_SECOND` | 备用源 ID |

### 3.4.6 语音

| 配置项 | 说明 |
| --- | --- |
| `VITE_TTS_API` | Azure TTS API 地址 |
| `VITE_TTS_Voice` | 默认音色（如 `zh-CN-YunxiaNeural`） |
| `VITE_TTS_Style` | 默认风格（如 `cheerful`） |
| `VITE_TTS_SKEY` | TTS 接口签名 SKEY（可选） |

### 3.4.7 鉴权 SKEY

| 配置项 | 说明 |
| --- | --- |
| `VITE_METING_SKEY` | Meting API 鉴权 SKEY（自行配置） |
| `VITE_SFILE_SKEY` | 特殊文件（壁纸、语音、配置）鉴权 SKEY |

## 3.5 运行时配置文件

部署后可在 `public/runtime-config.json` 修改，格式与 `.env` 一致但为 JSON：

```json
{
  "VITE_CONFIG_TURN": "true",
  "VITE_SITE_NAME": "我的主页",
  "VITE_TX_WEATHER_KEY": "XXXXX-XXXXX-XXXXX-XXXXX",
  ...
}
```

仅写需要覆盖的键即可，未写的键会回退到编译时或示例配置。

## 3.6 运行时数据文件

除配置外，以下文件也支持运行时修改：

| 文件 | 用途 | 回退 |
| --- | --- | --- |
| `/siteLinks.json` | 网站链接列表 | `src/assets/siteLinks.json` |
| `/socialLinks.json` | 社交链接列表 | `src/assets/socialLinks.json` |
| `/images/config.json` | 壁纸数量配置（`bgImageCount`、`bgImageCountP`） | 硬编码默认值 10 / 2 |

加载逻辑分别在 [src/components/Links.vue](file:///d:/wenjian/home/home/src/components/Links.vue)、[SocialLinks.vue](file:///d:/wenjian/home/home/src/components/SocialLinks.vue)、[Background.vue](file:///d:/wenjian/home/home/src/components/Background.vue) 中。

## 3.7 安全提示

- 任何前端配置对用户可见，**不要**在配置中放置 secret（如真实的服务端密钥）。
- 所有 SKEY 仅用于客户端签名校验，防止普通用户绕过接口，无法防御恶意攻击者。
- 真正敏感的密钥应放在自建后端中，前端只调用后端接口。
