# 01 - 项目总览

## 1.1 项目简介

**無名の主页** 是一个基于 Vue 3 的个人主页 / 导航站项目，原作者为 `imsyy`，当前仓库为 `NanoRocky`（酪灰）维护的 EFU 扩展版本。

项目定位为一个高可定制、功能丰富的现代化个人主页，主要特性包括：

- 多源壁纸切换（内置、必应、随机风景、随机动漫）与定时切换
- 完整音乐播放器，支持网易云 / QQ 音乐双源合并歌单
- 逐字歌词同步渲染（支持 YRC / QRC / AMLL TTML Database / 跨平台「偷歌词」）
- 多源天气信息聚合（腾讯 / 高德 / 小米 / 韩小韩 / 教书先生）与自动降级
- Azure TTS 语音播报 + 本地预生成音频回退
- 季节特效（冬日飘雪、秋萤火虫、春节灯笼）
- PWA 支持（离线缓存、自动更新提示）
- 主题切换（跟随系统 / 时间 / 背景 / 浅色 / 深色）
- 响应式布局（PC / 平板 / 手机自适应）

## 1.2 版本信息

版本号定义在 [package.json](file:///d:/wenjian/home/home/package.json) 中：

- `version`：遵循 `主版本.次版本.修订号[.类型]` 格式，例如 `4.3.9.dev`。
- `author`：原作者 `imsyy`。
- `efua`：维护者 `NanoRocky`。
- `github`：原仓库 `https://github.com/imsyy/home`。
- `efug`：EFU 维护仓库 `https://github.com/NanoRocky/home`。

版本类型通过后缀识别，解析逻辑见 [src/utils/ver.ts](file:///d:/wenjian/home/home/src/utils/ver.ts)：

| 后缀 | 类型 | 中文 |
| --- | --- | --- |
| `.dev` | development | 开发版 |
| `.pre` | preview | 预览版 |
| `.beta` | beta | 尝鲜版 |
| 无 | release | 正式版 |

版本号末尾的 `[xxx]` 表示渠道，`[imsyy]` 为原版渠道，其它为维护渠道。

## 1.3 目录结构

```
home/
├── public/                  # 静态资源
│   ├── font/                # 字体文件（MiSans、Pacifico、UnidreamLED）
│   ├── images/              # 壁纸、图标、配置 JSON
│   │   ├── icon/            # 各尺寸图标
│   │   ├── phone/           # 移动端壁纸
│   │   └── config.json      # 壁纸数量配置
│   ├── speechlocal/         # 预生成语音音频（含 Yunxia 子目录）
│   ├── runtime-config.json  # 运行时配置（部署后修改无需重新构建）
│   ├── siteLinks.json       # 运行时网站链接
│   └── socialLinks.json     # 运行时社交链接
├── src/
│   ├── api/                 # API 请求封装
│   │   └── index.ts
│   ├── assets/              # 编译时静态资源
│   │   ├── data/            # 小米天气 adcode / status 映射表
│   │   ├── example_config.json   # 配置示例（兜底用）
│   │   ├── metadata_Keywords.json # 歌词元数据关键词
│   │   ├── siteLinks.json       # 编译时网站链接（回退）
│   │   └── socialLinks.json     # 编译时社交链接（回退）
│   ├── components/          # Vue 组件
│   │   ├── Background.vue   # 壁纸层
│   │   ├── DevSet.vue       # 开发者设置
│   │   ├── Footer.vue       # 页脚（版权 / 歌词显示）
│   │   ├── Hitokoto.vue     # 一言模块
│   │   ├── Links.vue        # 网站链接
│   │   ├── Loading.vue      # 加载动画
│   │   ├── Message.vue      # 主信息区（Logo / 简介）
│   │   ├── MoreContent.vue  # 拓展盒子占位
│   │   ├── Music.vue        # 音乐控制面板
│   │   ├── Player.vue       # APlayer 播放器封装
│   │   ├── ProgressBar.vue  # 音乐进度条
│   │   ├── Set.vue          # 用户设置面板
│   │   ├── SocialLinks.vue  # 社交链接
│   │   ├── TimeCapsule.vue  # 时光胶囊
│   │   └── Weather.vue      # 天气模块
│   ├── store/               # Pinia 状态管理
│   │   ├── index.ts         # 主 store
│   │   └── plugins/
│   │       └── validation.ts # 变量校验插件
│   ├── style/               # 全局样式
│   │   ├── dark-theme.scss
│   │   ├── global.scss
│   │   ├── light-theme.scss
│   │   └── style.scss
│   ├── typings/             # TypeScript 类型声明
│   ├── utils/               # 工具函数
│   │   ├── season/          # 季节特效
│   │   │   ├── firefly.ts
│   │   │   ├── lantern.ts
│   │   │   └── snow.ts
│   │   ├── authServer.ts    # 签名算法
│   │   ├── checkPilferDWRC.ts # 偷歌词对齐
│   │   ├── config_check.ts  # 配置加载与代理
│   │   ├── cursor.ts        # 自定义鼠标
│   │   ├── debounce.ts      # 防抖
│   │   ├── decodeDWQYRC.ts  # 逐字歌词解码
│   │   ├── getColor.ts      # 背景主色调提取
│   │   ├── getTime.ts       # 时间相关
│   │   ├── removeLyricMetadata.ts # 歌词元数据剔除
│   │   ├── speech.ts        # 语音合成
│   │   ├── updatecheck.ts   # 版本更新检查
│   │   ├── ver.ts           # 版本号解析
│   │   └── xiaomiWeather.ts # 小米天气适配
│   ├── views/               # 视图
│   │   ├── Box/index.vue    # 拓展盒子
│   │   ├── Func/index.vue   # 功能区
│   │   ├── Main/            # 主页左右分栏
│   │   │   ├── Left.vue
│   │   │   └── Right.vue
│   │   └── MoreSet/index.vue # 设置页
│   ├── App.vue              # 根组件
│   ├── main.ts              # 入口
│   └── env.d.ts             # 环境变量类型
├── admin-server/            # 简易 Node 管理服务器（可选）
├── docs/                    # 本文档目录
├── package.json
├── vite.config.ts
├── uno.config.ts            # UnoCSS 配置
├── tsconfig.json
└── .env.example             # 环境变量示例
```

## 1.4 启动流程

应用启动流程位于 [src/main.ts](file:///d:/wenjian/home/home/src/main.ts)，关键步骤如下：

```text
1. createApp(App) 创建 Vue 应用实例
2. createPinia() 创建 Pinia 实例
3. pinia.use(piniaPluginPersistedstate) 注册持久化插件
4. pinia.use(validationPlugin)  注册变量校验插件
5. app.use(pinia)
6. 定义 mountApp()：挂载应用 + 注册 PWA + 解析 URL 参数
7. 立即执行异步 IIFE：
   a. await loadRuntimeConfig()  ← 加载 /runtime-config.json
   b. 若 VITE_CONFIG_TURN != "true"：
      - 隐藏 #app
      - 弹出 ElMessageBox 警告
      - 用户确认后调用 mountApp()
   c. 否则检查 author 信息：
      - 若 author 被修改，仅输出 console.warn（不阻断启动）
      - 调用 mountApp()
8. mountApp() 内部：
   - app.mount("#app")
   - 读取 URL 参数：
     * set=reset → 重置所有设置
     * bg=N → 设置壁纸类型
     * bgc=N → 设置内置壁纸 ID
     * devs=true → 开启开发者模式
     * pap=true → 自动播放
   - 注册 serviceWorker controllerchange 监听，触发更新提示
```

## 1.5 PWA 更新机制

PWA 由 `vite-plugin-pwa` 集成，配置见 [vite.config.ts](file:///d:/wenjian/home/home/vite.config.ts)：

- `registerType: "autoUpdate"`：自动更新。
- `skipWaiting: true` + `clientsClaim: true`：新 SW 立即接管。
- 静态资源（js/css/字体/图片）使用 `CacheFirst` 策略。

当 `controllerchange` 触发时，[main.ts](file:///d:/wenjian/home/home/src/main.ts) 会弹出 `ElMessage` 提示用户刷新，并播放 `更新提示.mp3` 语音。

## 1.6 URL 参数快捷配置

启动后通过 URL Query 可临时覆盖部分设置，便于分享特定状态：

| 参数 | 含义 | 示例 |
| --- | --- | --- |
| `set=reset` | 重置所有设置并刷新 | `?set=reset` |
| `bg=N` | 设置 `coverType`（0-3） | `?bg=2` |
| `bgc=N` | 指定内置壁纸 ID（仅 `bg=0` 生效） | `?bg=0&bgc=5` |
| `devs=true` | 开启开发者模式 | `?devs=true` |
| `pap=true` | 开启自动播放 | `?pap=true` |

实现位于 [src/main.ts](file:///d:/wenjian/home/home/src/main.ts) 的 `setupset()` 函数，使用 `setTimeout` 轮询等待 `store.imgLoadStatus` 为 `true` 后再应用参数，避免在壁纸未加载时过早写入。
