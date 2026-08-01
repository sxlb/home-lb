# 05 - 组件详解

本文档覆盖 `src/components/` 下所有 Vue 组件的职责、Props、Events 与内部逻辑。

## 05.1 Background.vue

**路径**：[src/components/Background.vue](file:///d:/wenjian/home/home/src/components/Background.vue)

**职责**：壁纸加载、过渡动画、季节特效调度、自动切换。

**Props / Emits**：
- `emit("loadComplete")`：壁纸首次加载并完成动画后触发。
- `emit("imageLoaded", img: HTMLImageElement)`：壁纸 `onload` 时触发，用于背景主题色提取。

**关键逻辑**：

### 壁纸类型

| `coverType` | 来源 |
| --- | --- |
| 0 | 内置壁纸（`/images/backgroundN.jpg`） |
| 1 | 必应每日一图 |
| 2 | 随机风景 |
| 3 | 随机动漫 |

### 设备检测

```ts
const detectDevice = () => {
  const userAgent = navigator.userAgent.toLowerCase();
  if (/mobile|android|iphone|ipad|ipod|windows phone/.test(userAgent)) {
    if (/ipad|tablet|playbook|silk|kindle/.test(userAgent)) return 'tablet';
    return 'mobile';
  }
  return 'pc';
};
```

移动端使用 `/images/phone/backgroundphoneN.jpg`，PC/平板使用 `/images/backgroundN.jpg`。

### 双层过渡动画

为避免切换时画面闪烁，采用双 `<img>` 层方案：

- `current` 层：当前显示的壁纸，加载完成后执行 `fade-blur-in` 动画。
- `next` 层：新壁纸预加载完成后显示，通过 `blur-in` 类从模糊变清晰。
- 1.6 秒后切换 `current` 的 `src`，并通过 `skipTransition` 短暂禁用过渡避免抖动。

### 鉴权 URL

当 `VITE_SFILE_SKEY` 配置时，所有静态文件 URL 通过 `gasC()` 签名，用于自建文件服务校验：

```ts
if (key) {
  const bgUrlS = `/images/background${bgRandom}.jpg`;
  return await gasC(bgUrlS, key);
}
```

### 季节特效调度

`SeasonStyle(type, state, where)` 根据当前月份自动启用对应特效：

| 月份 | 特效 |
| --- | --- |
| 12, 1, 2 | 雪花 |
| 1, 2 | 灯笼（与雪花叠加） |
| 7, 8, 9 | 萤火虫 |

`sest` 标志位防止首次进入时重复触发。用户在设置中关闭 `seasonalEffects` 时，会显式调用所有 `close*` 函数。

### 自动切换

`setupAutoSwitch()` 根据 `store.autoBGSwitchInterval` 设置定时器：

| 值 | 间隔 |
| --- | --- |
| 0 | 不切换 |
| 1 | 15 秒 |
| 2 | 30 秒（默认） |
| 3 | 45 秒 |

切换时随机生成新的 `bgRandom` / `bgRandomp` 并调用 `changeBg`。

### 监听器

- `watch(() => store.coverType)`：壁纸类型变化时重新加载。
- `watch(() => store.seasonalEffects)`：特效总开关变化时批量启停。
- `watch(() => store.sBGCount)`：临时指定壁纸 ID（仅在 `coverType == 0` 时生效）。
- `watch(() => store.autoBGSwitchInterval)`：自动切换间隔变化时重建定时器。

---

## 05.2 Player.vue

**路径**：[src/components/Player.vue](file:///d:/wenjian/home/home/src/components/Player.vue)

**职责**：封装 `@worstone/vue-aplayer`，处理播放列表加载、逐字歌词同步、MediaSession 集成。

**Props**：

| Prop | 类型 | 默认值 | 说明 |
| --- | --- | --- | --- |
| `theme` | String | `#efefef` | 播放器主题色 |
| `volume` | Number | 0.7 | 初始音量（0-1） |
| `songServer` | String | `netease` | 主音乐源 |
| `songServerSE` | String | null | 备用音乐源 |
| `songType` | String | `playlist` | 播放类型 |
| `songId` | String | `7452421335` | 主源 ID |
| `songIdSE` | String | null | 备用源 ID |
| `listFolded` | Boolean | false | 列表默认折叠 |
| `listMaxHeight` | Number | 420 | 列表最大高度 |

**暴露方法**（通过 `defineExpose`）：

| 方法 | 作用 |
| --- | --- |
| `playToggle()` | 切换播放 / 暂停 |
| `changeVolume(value)` | 设置音量 |
| `changeSong(type)` | 切换上下曲（type: 0=上一首, 1=下一首） |
| `toggleList()` | 切换列表显隐 |

### 播放列表加载

`onMounted` 中调用 `getPlayerList()`，支持双源合并：

```ts
getPlayerList(server, type, id, serverse, idse, playerTrLrc).then((res) => {
  store.musicIsOk = true;
  playList.value = res as PlaylistItem[];
  // 注册 MediaSession 操作
});
```

如果接口返回的 `url` 以 `@` 开头，表示需要通过 JSONP 二次解析（QQ 音乐场景），逻辑见 [08 - API 集成](./08-api.md)。

### 逐字歌词同步

`syncDWRCLrc()` 通过 `requestAnimationFrame` 循环执行：

1. 判断当前是否处于逐字模式（`store.dwrcEnable && store.dwrcTemp.length > 0 && !store.dwrcLoading`）。
2. 逐字模式：从 `store.dwrcTemp` 中查找当前时间对应的行，构建每字的渲染数据 `[isCurrent, isSungLyrics, line, row, word, duration, lessdur, "auto"]`。
3. 逐行模式：直接读取 APlayer 的 `lyrics[index][lyricIndex]`。
4. 通过 `store.setPlayerLrc()` 更新，触发 Footer.vue 响应式渲染。

### 快进 / 快退

```ts
const seekbackward = (value) => {
  const ti = currentTime - value;
  if (ti < 0) player.value.aplayer.seek(0);
  else if (ti > dur) changeSong(1);
  else player.value.aplayer.seek(ti);
};
```

**注意**：此处经过修复，原代码逻辑判断错误（参见 [修复记录](./13-deployment.md#修复记录)）。

### MediaSession 集成

支持系统媒体控制（锁屏、通知栏、耳机按键）：

```ts
navigator.mediaSession.metadata = new MediaMetadata({
  title: store.getPlayerData.name,
  artist: store.getPlayerData.artist,
  album: store.getPlayerData.album,
  artwork: [{ src: playList.value[playIndex.value].cover, sizes: "512x512", type: "image/jpeg" }],
});
navigator.mediaSession.setActionHandler("play", () => player.value!.play());
navigator.mediaSession.setActionHandler("pause", () => player.value!.pause());
navigator.mediaSession.setActionHandler("nexttrack", () => changeSong(1));
navigator.mediaSession.setActionHandler("previoustrack", () => changeSong(0));
navigator.mediaSession.setActionHandler("seekbackward", () => seekbackward(5));
navigator.mediaSession.setActionHandler("seekforward", () => seekforward(5));
```

### 逐字歌词获取流程

`fetchDWRC(dwrcUrl)` 实现多级回退：

1. 直接请求 `dwrcUrl`（原始歌词 URL + `&dwrc=true`）。
2. 解析成功 → 写入 `store.dwrcTemp`，结束。
3. 解析失败 → 尝试 AMLL TTML Database：
   - 根据 `playerDWRCATDBF` 选择是否使用镜像（`ghfast.top`）。
   - 根据 `songServer` 选择 `ncm-lyrics` 或 `qq-lyrics`。
4. AMLL 失败 → 「偷歌词」机制（`playerDWRCPilfer`）：
   - 从另一音乐源搜索同名歌曲。
   - 通过 `alignPilferedLyrics` 对齐时间轴。
   - 详见 [09 - 歌词系统](./09-lyrics.md)。

---

## 05.3 Music.vue

**路径**：[src/components/Music.vue](file:///d:/wenjian/home/home/src/components/Music.vue)

**职责**：音乐控制面板（播放 / 暂停 / 上下曲 / 音量），管理播放列表弹窗。

**键盘快捷键**：

| 按键 | 作用 |
| --- | --- |
| `Space` | 播放 / 暂停 |
| `PageUp` | 上一曲 |
| `PageDown` | 下一曲 |

快捷键监听通过 `visibilitychange` 与 `focus` / `blur` 事件动态启停，避免在后台标签页误触发。

**Props 传递**：从 `envConfig` 读取音乐配置，传递给 `Player` 子组件。

---

## 05.4 Footer.vue

**路径**：[src/components/Footer.vue](file:///d:/wenjian/home/home/src/components/Footer.vue)

**职责**：页脚信息（版权 / 备案 / 作者）与歌词显示（逐字 / 逐行）。

### 双模式切换

- 当 `!store.playerState || !store.playerLrcShow` 时显示版权信息。
- 否则显示歌词，并通过 `dblclick` 切换 `forceShowBarIcon`（进度图标常驻）。

### 逐字渲染结构

```html
<span class="dwrc-box">
  <!-- 底层：未高亮文字 -->
  <span class="dwrc-2 lrc-text" id="dwrc-2-wrap">
    <span v-for="i in store.playerLrc" v-html="i[4]"></span>
  </span>
  <!-- 上层：已高亮文字，通过宽度动画揭示 -->
  <span class="dwrc-1 lrc-text" id="dwrc-1-wrap">
    <span v-for="i in store.playerLrc" :class="[...]" v-html="i[4]"></span>
  </span>
</span>
```

`dwrc-2` 为底层灰色文字，`dwrc-1` 为顶层彩色文字。通过 `width: 0 → Npx` 动画实现「逐字揭示」效果。

### 逐字增强动画

`watch(() => store.getPlayerLrc)` 中：

- 仅在 `playerDWRCShowPro` 开启且处于逐字模式时执行。
- 遍历当前行的每个字，使用 `Element.animate()` 创建带 `delay` 的宽度动画。
- 动画结束后追加 `translateY` 位移过渡，模拟「弹跳」效果。

CSS 动画类：

| 类名 | 触发条件 | 效果 |
| --- | --- | --- |
| `fade-in-start` | 未开始 | 半透明 + 阴影 |
| `fade-in` | 当前播放 | 颜色渐变 + 上移 |
| `fade-out` | 已唱完 | 全亮 + 多层阴影 |
| `long-tone` | 长音（>1019ms）当前 | 脉冲动画 |
| `long-tone-out` | 长音已唱完 | 脉冲消退 |
| `dwrc-style-s1` | 未唱 | 灰色 |
| `dwrc-style-s2` | 已唱 | 高亮色 |

---

## 05.5 ProgressBar.vue

**路径**：[src/components/ProgressBar.vue](file:///d:/wenjian/home/home/src/components/ProgressBar.vue)

**职责**：音乐进度条（可拖拽），含加载中旋转图标。

**交互**：

- 鼠标悬停于 `#footer` 时显示进度图标（除非 `forceShowBarIcon` 开启时始终显示）。
- 支持鼠标拖拽（`mousedown` + `mousemove` + `mouseup`）。
- 支持触摸拖拽（`touchstart` + `touchmove` + `touchend`）。
- 拖拽时通过 `isDragging` 类禁用过渡动画，保证跟手。
- 释放时将 `dragProgress` 写入 `audio.currentTime`。
- `throttle` 限制 `mousemove` / `touchmove` 频率为 16ms（约 60fps）。

**加载状态**：当 `!store.playerCanplay` 时显示 `ReloadCircle` 旋转图标。

---

## 05.6 Message.vue

**路径**：[src/components/Message.vue](file:///d:/wenjian/home/home/src/components/Message.vue)

**职责**：左上角 Logo + 简介，点击切换拓展盒子。

**关键逻辑**：

- `siteUrl` computed：根据 `msgNameShow` 决定显示 URL 还是自定义名，并按 `.` 分段显示。
- `changeBox()`：宽度 ≥721px 时切换 `boxOpenState`，否则提示分辨率不足。
- `watch(() => store.boxOpenState)`：盒子打开时切换为 `VITE_DESC_HELLO_OTHER` 文案。

---

## 05.7 Weather.vue

**路径**：[src/components/Weather.vue](file:///d:/wenjian/home/home/src/components/Weather.vue)

**职责**：天气信息显示，调度多源天气获取。

详见 [10 - 天气系统](./10-weather.md)。

---

## 05.8 Hitokoto.vue

**路径**：[src/components/Hitokoto.vue](file:///d:/wenjian/home/home/src/components/Hitokoto.vue)

**职责**：一言显示，鼠标悬停时显示「打开音乐播放器」入口。

**关键逻辑**：

- `onMounted` 调用 `getHitokoto()` 获取一言。
- 点击一言区域刷新（`debounce` 500ms 防抖）。
- 失败时显示默认文案并播放 `一言加载失败.mp3`。

---

## 05.9 Loading.vue

**路径**：[src/components/Loading.vue](file:///d:/wenjian/home/home/src/components/Loading.vue)

**职责**：首屏加载动画。

**动画**：

- 三层旋转圆环（不同速度与方向）。
- `store.imgLoadStatus` 为 `true` 时添加 `loaded` 类。
- 左右两半向两侧滑出，整体上移消失。

---

## 05.10 Set.vue / DevSet.vue

**路径**：
- [src/components/Set.vue](file:///d:/wenjian/home/home/src/components/Set.vue)
- [src/components/DevSet.vue](file:///d:/wenjian/home/home/src/components/DevSet.vue)

**职责**：用户设置面板 / 开发者设置面板。

### Set.vue 分组

| 分组 | 配置项 |
| --- | --- |
| 个性壁纸 | `coverType`（0-3） |
| 主题设置 | `theme`（system/time/bg/light/dark） |
| 个性化调整 | 建站日期、音乐点击、季节特效、底栏模糊、进度条 |
| 播放器配置 | 自动播放、随机播放、循环模式 |
| 歌词设置 | 底栏歌词、AMLL 接入、镜像加速、逐字解析、效果增强、移除元数据、偷歌词、翻译 |
| 语音设置 | 语音总开关、播报歌名 |
| 开发设置 | （需 `setV == true` 才显示） |

### DevSet.vue 分组

仅在 `setV == true` 时通过 `Set.vue` 嵌套显示。

| 分组 | 功能 |
| --- | --- |
| 季节特效 | 手动启停雪花 / 萤火虫 / 灯笼 |
| 壁纸调整 | 临时指定内置壁纸 ID |
| 个性化设置 | 信息区域自定义名开关 |
| 壁纸高级设置 | 自动切换间隔（0/15s/30s/45s） |
| 重置 | 三次确认后重置所有设置 |
| 检查版本更新 | 调用 GitHub Releases API 比对版本 |

**重置确认机制**：

```ts
let chuores = 0;
const resetSettings = () => {
  chuores++;
  if (chuores === 3) {
    // 实际重置
    store.resetStore();
  } else if (chuores > 3) {
    // 加载初始设置提示
  } else {
    // 提示还需点击 N 次
  }
};
```

---

## 05.11 TimeCapsule.vue

**路径**：[src/components/TimeCapsule.vue](file:///d:/wenjian/home/home/src/components/TimeCapsule.vue)

**职责**：时光胶囊，显示今日 / 本周 / 本月 / 本年进度。

每秒调用 `getTimeCapsule()` 更新数据，使用 `el-progress` 渲染进度条。若 `siteStartShow` 开启，额外显示建站天数统计。

---

## 05.12 Links.vue / SocialLinks.vue

**路径**：
- [src/components/Links.vue](file:///d:/wenjian/home/home/src/components/Links.vue)
- [src/components/SocialLinks.vue](file:///d:/wenjian/home/home/src/components/SocialLinks.vue)

**职责**：网站链接网格 / 社交链接。

### Links.vue

- 使用 Swiper 轮播，每页 6 个链接。
- 运行时从 `/siteLinks.json` 加载，失败回退到 `src/assets/siteLinks.json`。
- 图标通过 `siteIcon` 映射到 `@vicons/fa` 组件。
- 点击「音乐」项且 `musicClick` 开启时，切换 `musicBoxOpenState` 而非跳转。

### SocialLinks.vue

- 运行时从 `/socialLinks.json` 加载。
- 双击提示文字播放 `戳戳社.mp3`。

---

## 05.13 MoreContent.vue

**路径**：[src/components/MoreContent.vue](file:///d:/wenjian/home/home/src/components/MoreContent.vue)

**职责**：拓展盒子内的自定义内容占位符。默认仅显示「您可在此编写任意内容」，供二次开发者替换。

---

## 05.14 组件依赖关系

```text
App.vue
├── Loading.vue
├── Background.vue
├── Main/
│   ├── Left.vue
│   │   ├── Message.vue
│   │   └── SocialLinks.vue
│   └── Right.vue
│       ├── Func/
│       │   ├── Hitokoto.vue
│       │   ├── Music.vue
│       │   │   └── Player.vue
│       │   └── Weather.vue
│       └── Links.vue
├── Box/
│   └── Box.vue
│       ├── TimeCapsule.vue
│       └── MoreContent.vue
├── MoreSet/
│   └── MoreSet.vue
│       └── Set.vue
│           └── DevSet.vue
└── Footer.vue
    └── ProgressBar.vue
```
