# 06 - 视图与路由

## 6.1 视图目录组织

本项目未使用 `vue-router`，而是通过 `store` 中的状态字段控制视图切换。视图文件位于 `src/views/`：

```
src/views/
├── Main/
│   ├── Left.vue      # 主页左栏（信息区）
│   └── Right.vue     # 主页右栏（功能区 + 链接）
├── Func/
│   └── index.vue     # 功能区容器（一言 + 音乐 + 时间 + 天气）
├── Box/
│   └── index.vue     # 拓展盒子（时光胶囊 + 自定义内容）
└── MoreSet/
    └── index.vue     # 设置页（PC / 移动端双布局）
```

## 6.2 视图切换机制

在 [App.vue](file:///d:/wenjian/home/home/src/App.vue) 中通过 `v-show` 控制不同视图的显隐：

```html
<main id="main" v-if="store.imgLoadStatus">
  <div class="page-container" v-show="!store.backgroundShow">
    <section class="all" v-show="!store.setOpenState">
      <MainLeft />
      <MainRight v-show="!store.boxOpenState" />
      <Box v-show="store.boxOpenState" />
    </section>
    <section class="more" v-show="store.setOpenState" @click="store.setOpenState = false">
      <MoreSet />
    </section>
  </div>
  <!-- 移动端菜单按钮 -->
  <Icon class="menu" v-show="!store.backgroundShow"
    @click="store.mobileOpenState = !store.mobileOpenState">
    <component :is="store.mobileOpenState ? CloseSmall : HamburgerButton" />
  </Icon>
  <Footer v-show="!store.backgroundShow && !store.setOpenState" />
</main>
```

### 关键状态字段

| 字段 | 作用 |
| --- | --- |
| `imgLoadStatus` | 壁纸加载完成后才显示主界面（`v-if`） |
| `backgroundShow` | 壁纸展示模式（中键切换），隐藏所有 UI |
| `setOpenState` | 设置页打开时隐藏主内容与页脚 |
| `boxOpenState` | 拓展盒子打开时替换右栏 |
| `mobileOpenState` | 移动端左栏显隐 |

## 6.3 Main/Left.vue

**路径**：[src/views/Main/Left.vue](file:///d:/wenjian/home/home/src/views/Main/Left.vue)

左栏占 50% 宽度，包含：

- `Message.vue`：Logo + 简介。
- `SocialLinks.vue`：社交链接。

移动端（`mobileOpenState == true`）时添加 `hidden` 类隐藏左栏。

## 6.4 Main/Right.vue

**路径**：[src/views/Main/Right.vue](file:///d:/wenjian/home/home/src/views/Right.vue)

右栏占 50% 宽度，包含：

- 移动端 Logo（点击切换 `mobileFuncState`）。
- `Func/index.vue`：功能区。
- `Links.vue`：网站链接。

`siteUrl` computed 从 `VITE_SITE_URL` 提取主域名，按 `.` 分段显示。

## 6.5 Func/index.vue

**路径**：[src/views/Func/index.vue](file:///d:/wenjian/home/home/src/views/Func/index.vue)

功能区布局：

```
┌──────────────┬──────────────┐
│  Hitokoto    │   时间显示    │
│  (一言)      │   (年月日)   │
│  Music       │   (时分秒)   │
│  (音乐面板)  ├──────────────┤
│              │   Weather    │
│              │   (天气)     │
└──────────────┴──────────────┘
```

- 每秒通过 `setInterval` 更新 `currentTime`。
- `playerHasId` 检查 `VITE_SONG_ID` 是否配置，未配置则不渲染 `Music` 组件。
- 移动端（`mobileFuncState == true`）时只显示左半部分（一言 + 音乐）。

## 6.6 Box/index.vue

**路径**：[src/views/Box/index.vue](file:///d:/wenjian/home/home/src/views/Box/index.vue)

拓展盒子，替换右栏显示：

- `TimeCapsule.vue`：时光胶囊。
- `MoreContent.vue`：自定义内容占位。

悬停时显示右上角关闭与设置按钮。

## 6.7 MoreSet/index.vue

**路径**：[src/views/MoreSet/index.vue](file:///d:/wenjian/home/home/src/views/MoreSet/index.vue)

设置页，根据 `mobileOpenState` 切换两套布局：

### PC 布局（`mobileOpenState == false`）

```
┌────────────────┬────────────────┐
│  Logo          │                │
│                │   全局设置     │
│  版本信息      │   (Set 组件)   │
│  GitHub 链接   │                │
│                │                │
└────────────────┴────────────────┘
```

### 移动端布局（`mobileOpenState == true`）

单列布局，Logo 与版本信息在顶部，设置在下方。

### 版本号交互

双击版本号触发 `toggleVer()`：

- 第 1-4 次：弹出神秘提示 + 播放 `戳版本.mp3`。
- 第 5 次以上：播放 `戳戳版本.mp3`，开启 `setV`（开发者模式）。

### 跳转链接

- GitHub 图标：跳转 `config.github`（原仓库）。
- 编辑图标：跳转 `config.efug`（EFU 维护仓库）。

## 6.8 响应式断点

App.vue 中定义的 CSS 断点：

| 断点 | 行为 |
| --- | --- |
| `max-width: 1200px` | 移除 `page-container` 内边距 |
| `max-width: 990px` | Logo 字号缩小 |
| `max-width: 825px` | Logo 字号进一步缩小 |
| `max-width: 720px` | 显示移动端菜单按钮，左右栏切换为单列 |
| `max-height: 650px` | 启用垂直滚动，固定高度 650px |
| `max-width: 360px` | 固定宽度 360px，启用水平滚动 |

窗口宽度变化通过 `store.setInnerWidth` 实时同步到 store，宽度 <721px 时自动关闭 `boxOpenState` 与 `setOpenState`。
