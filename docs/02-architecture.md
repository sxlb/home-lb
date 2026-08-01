# 02 - 架构与技术栈

## 2.1 整体架构

项目采用典型的 Vue 3 单页应用架构，所有交互逻辑均在前端完成，后端仅为第三方 API 服务。

```text
┌──────────────────────────────────────────────────────────────┐
│                         浏览器 (PWA)                          │
│  ┌────────────────────────────────────────────────────────┐  │
│  │                    Vue 3 应用 (App.vue)                │  │
│  │  ┌──────────┐  ┌──────────┐  ┌──────────┐            │  │
│  │  │  Views   │  │Components│  │  Store   │            │  │
│  │  └────┬─────┘  └────┬─────┘  └────┬─────┘            │  │
│  │       │              │             │                  │  │
│  │       └──────────────┴─────────────┘                  │  │
│  │                      │                                │  │
│  │              ┌───────┴────────┐                         │  │
│  │              │    Utils       │                         │  │
│  │              │ (config/auth/  │                         │  │
│  │              │  speech/season)│                         │  │
│  │              └───────┬────────┘                         │  │
│  └──────────────────────┼─────────────────────────────────┘  │
└──────────────────────────┼───────────────────────────────────┘
                           │ fetch / JSONP
           ┌───────────────┼───────────────┐
           ▼               ▼               ▼
   ┌──────────────┐ ┌──────────────┐ ┌──────────────┐
   │  Meting API  │ │  天气服务    │ │  TTS 服务    │
   │ (音乐/歌词)  │ │腾讯/高德/    │ │  (Azure)     │
   │              │ │小米/韩小韩等 │ │              │
   └──────────────┘ └──────────────┘ └──────────────┘
```

## 2.2 技术栈

### 核心框架

| 技术 | 版本 | 用途 |
| --- | --- | --- |
| Vue 3 | ^3.5.38 | 视图框架（Composition API + `<script setup>`） |
| TypeScript | ^6.0.3 | 类型系统 |
| Vite | ^8.0.16 | 构建工具 |

### 状态管理

| 技术 | 版本 | 用途 |
| --- | --- | --- |
| Pinia | ^3.0.4 | 状态管理 |
| pinia-plugin-persistedstate | ^4.7.1 | 状态持久化（localStorage / sessionStorage） |

### UI 组件

| 技术 | 版本 | 用途 |
| --- | --- | --- |
| Element Plus | ^2.14.2 | 通用 UI 组件库 |
| @icon-park/vue-next | ^1.4.2 | 图标库（主要图标） |
| @vicons/* | ^0.13.0 | 备用图标库（fa、ionicons4/5、material、tabler） |
| Swiper | ^12.2.0 | 网站链接轮播 |

### 音频 / 媒体

| 技术 | 版本 | 用途 |
| --- | --- | --- |
| @worstone/vue-aplayer | ^1.0.8 | Vue 3 版 APlayer 封装 |
| aplayer | ^1.10.1 | 底层播放器（peer 依赖） |

### 工具库

| 技术 | 版本 | 用途 |
| --- | --- | --- |
| dayjs | ^1.11.21 | 时光胶囊日期计算 |
| lodash-es | ^4.18.1 | `isEqual`、`throttle` 等工具 |
| @noble/hashes | ^2.2.0 | MD5 签名（鉴权） |
| fetch-jsonp | ^1.4.0 | 腾讯接口 JSONP 请求 |

### 构建与工程化

| 技术 | 版本 | 用途 |
| --- | --- | --- |
| unplugin-auto-import | ^21.0.0 | Vue API / `envConfig` 自动导入 |
| unplugin-vue-components | ^32.1.0 | Element Plus 组件按需自动注册 |
| vite-plugin-pwa | ^1.3.0 | PWA 集成 |
| vite-plugin-compression2 | ^2.5.3 | Gzip / Brotli 压缩 |
| UnoCSS | ^66.7.2 | 原子化 CSS |
| Sass (sass-embedded) | ^1.100.0 | 样式预处理 |
| PostCSS + postcss-preset-env + cssnano | - | CSS 后处理（嵌套规则、压缩） |
| ESLint + Prettier | - | 代码规范 |
| vue-tsc | ^3.3.5 | 类型检查 |

## 2.3 Vite 构建配置

完整配置见 [vite.config.ts](file:///d:/wenjian/home/home/vite.config.ts)，关键点：

### 自动导入

```ts
AutoImport({
  imports: ["vue", { "@/utils/config_check.ts": ["envConfig"] }],
  resolvers: [ElementPlusResolver()],
  dts: "src/auto-imports.d.ts",
})
```

- 自动导入 Vue API（`ref`、`computed`、`onMounted` 等），无需手动 `import`。
- 全局注入 `envConfig` 代理对象，所有组件可直接访问。
- Element Plus 组件按需自动注册。

### 路径别名

```ts
resolve: {
  alias: [{ find: "@", replacement: resolve(__dirname, "src") }],
  extensions: [".ts", ".js", ".vue", ".json"],
}
```

`@` 指向 `src`，扩展名解析顺序为 `.ts → .js → .vue → .json`，因此部分文件 import 时省略扩展名（如 `@/utils/cursor.js` 实际指向 `cursor.ts`）。

### 样式预处理

```ts
css: {
  preprocessorOptions: {
    scss: {
      additionalData: `@use "@/style/global.scss" as global;`,
    },
  },
}
```

所有 SCSS 文件自动注入 `global.scss`，可在任意组件中使用全局变量与 mixin。

### 代码分割

```ts
rollupOptions: {
  output: {
    manualChunks(id) {
      if (id.includes('node_modules')) return 'vendor';
      if (id.includes('xiaomi_weather_adcode.json') || id.includes('xiaomi_weather_status.json')) return 'xiaomi_weather_data';
      if (id.includes('siteLinks.json') || id.includes('socialLinks.json')) return 'custom_data';
    }
  }
}
```

将 `node_modules` 抽为 `vendor` chunk，小米天气 JSON 抽为独立 chunk 以便按需加载。

### 压缩

```ts
build: {
  minify: "terser",
  terserOptions: { compress: { pure_funcs: ["console.debug"] } },
}
```

构建时仅移除 `console.debug`，保留 `console.log` 与 `console.error` 用于生产环境排查。

## 2.4 模块划分

### 配置层（`src/utils/config_check.ts`）

通过 `Proxy` 代理 `envConfig`，实现运行时配置 > 编译时 `.env` > `example_config.json` 三级回退。详见 [03 - 配置系统](./03-config.md)。

### 状态层（`src/store/`）

Pinia 单仓库设计，所有状态集中在 `mainStore`，通过 `persist` 配置区分 `localStorage`（永久设置）与 `sessionStorage`（会话设置）。配合 `validationPlugin` 在状态变更时校验合法性。详见 [04 - 状态管理](./04-store.md)。

### API 层（`src/api/index.ts`）

封装所有外部接口请求，包括：

- 音乐播放列表（支持双源合并、JSONP 兜底）
- 一言
- 腾讯位置 / 天气（含鉴权）
- 高德位置 / 天气
- 小米天气（通过中转）
- 韩小韩 / 教书先生备用天气
- IPv4 / IPv6 地址查询
- GitHub 连通性检测

详见 [08 - API 集成与鉴权](./08-api.md)。

### 视图层（`src/views/` + `src/components/`）

- `App.vue`：根布局，组合 Loading / Background / Main / Footer。
- `views/Main/`：左右分栏，左为信息区，右为功能区。
- `views/Func/`：功能区（一言、音乐、时间、天气）。
- `views/Box/`：拓展盒子（时光胶囊 + 自定义内容）。
- `views/MoreSet/`：设置页（PC / 移动端双布局）。

### 工具层（`src/utils/`）

按功能拆分独立模块，避免循环依赖。详见 [07 - 工具函数](./07-utils.md)。

## 2.5 数据流

项目采用单向数据流：

```text
用户操作 / URL 参数 / 定时器
        │
        ▼
   Component (Vue)
        │ emit / watch
        ▼
     Pinia Store ──→ persist ──→ localStorage / sessionStorage
        │
        │ action 调用
        ▼
     Utils (auth/speech/season...)
        │
        │ fetch / JSONP
        ▼
     外部 API
        │
        ▼
     更新 Store ──→ 响应式更新视图
```

## 2.6 主题系统

主题通过 `document.documentElement.dataset.theme` 控制，支持 5 种模式：

| 模式 | 实现位置 | 说明 |
| --- | --- | --- |
| `light` | App.vue | 强制浅色 |
| `dark` | App.vue | 强制深色 |
| `system` | App.vue | 监听 `prefers-color-scheme` 媒体查询 |
| `time` | App.vue | 19:00-06:00 深色，否则浅色（每分钟检查） |
| `bg` | App.vue + getColor.ts | 从壁纸提取主色调判断明暗 |

主题色变量定义在 [src/style/dark-theme.scss](file:///d:/wenjian/home/home/src/style/dark-theme.scss) 与 [light-theme.scss](file:///d:/wenjian/home/home/src/style/light-theme.scss)，通过 `:root[data-theme="..."]` 选择器切换。

## 2.7 响应式布局

通过 `store.innerWidth` 实时记录窗口宽度，关键断点：

| 宽度 | 行为 |
| --- | --- |
| ≥ 1200px | 完整 PC 布局 |
| 721 - 1199px | PC 紧凑布局 |
| ≤ 720px | 移动端布局（显示菜单按钮、隐藏右栏切换） |
| ≤ 390px | 极小屏适配 |

设备类型检测通过 `navigator.userAgent` 判断（PC / tablet / mobile），用于壁纸分辨率选择与雪花特效粒子数控制。
