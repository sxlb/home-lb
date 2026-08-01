# 04 - 状态管理

## 4.1 概述

项目使用 Pinia 作为状态管理库，所有状态集中在单一 store `mainStore` 中。定义位于 [src/store/index.ts](file:///d:/wenjian/home/home/src/store/index.ts)。

## 4.2 Store 定义

### 4.2.1 初始状态

初始状态以模块级常量 `storeState` 定义，便于 `resetStore()` 通过深拷贝恢复默认值：

```ts
export const storeState: MainState = {
  imgLoadStatus: false,           // 【状态】壁纸加载状态
  innerWidth: null,               // 【状态】当前窗口宽度
  coverType: 0,                   // 【开关】壁纸种类（0-3）
  sBGCount: null,                 // 【状态】临时指定内置壁纸 ID
  autoBGSwitchInterval: 2,        // 【开关】自动切换壁纸间隔
  seasonalEffects: true,          // 【开关】季节特效
  // ... 其余字段
};

export const mainStore = defineStore("main", {
  state: (): MainState => JSON.parse(JSON.stringify(storeState)),
  // ...
});
```

使用 `JSON.parse(JSON.stringify(...))` 是为了确保每次重置都得到全新副本，避免引用污染。

### 4.2.2 状态分类

注释中用标签区分状态用途：

| 标签 | 含义 | 是否持久化 |
| --- | --- | --- |
| 【状态】 | 运行时状态（如加载完成、面板开关） | 通常不持久化 |
| 【开关】 | 用户可配置的偏好开关 | 通常持久化到 localStorage |
| 【缓存】 | 临时数据（如当前歌曲信息、歌词） | 不持久化 |

完整字段列表见 [src/store/index.ts](file:///d:/wenjian/home/home/src/store/index.ts) 第 5-63 行。

### 4.2.3 Getters

提供三个简单 getter：

```ts
getters: {
  getPlayerLrc(state) { return state.playerLrc; },        // 当前歌词
  getPlayerData(state) {                                   // 当前歌曲信息
    return { name: state.playerTitle, artist: state.playerArtist, album: state.playerAlbum };
  },
  getInnerWidth(state) { return state.innerWidth; },     // 当前窗口宽度
}
```

### 4.2.4 Actions

| 方法 | 作用 |
| --- | --- |
| `setInnerWidth(value)` | 设置窗口宽度，并在 ≥720px 时关闭移动端状态 |
| `setPlayerState(value)` | 切换播放状态（注意：参数语义反转，传 `true` 实际置为 `false`） |
| `setPlayerCanplay(value)` | 设置音乐是否加载完成 |
| `setPlayerLrc(value)` | 更新当前歌词 |
| `setPlayerData(title, artist)` | 更新当前歌曲标题与歌手 |
| `setImgLoadStatus(value)` | 设置壁纸加载状态 |
| `setSBGCount(value)` | 仅在 `coverType == 0` 时设置临时壁纸 ID |
| `resetStore()` | 重置所有设置并刷新页面 |

`resetStore()` 实现特殊：它动态覆写 `$reset` 方法以加入延时与刷新逻辑：

```ts
resetStore() {
  this.$reset = () => {
    setTimeout(() => {
      this.$state = JSON.parse(JSON.stringify(storeState));
      setTimeout(() => {
        window.location.href = window.location.pathname;
      }, 1200);
    }, 2500);
  };
  this.$reset();
}
```

## 4.3 持久化策略

使用 `pinia-plugin-persistedstate`，通过 `persist` 配置区分两种存储：

### 4.3.1 localStorage（永久设置）

```ts
{
  storage: localStorage,
  pick: [
    'coverType', 'musicVolume', 'siteStartShow', 'musicClick',
    'playerLrcShow', 'footerBlur', 'footerProgressBar',
    'playerAutoplay', 'playerLoop', 'playerOrder',
    'webSpeech', 'playerSpeechName', 'playerTrLrc',
    'playerDWRCShow', 'playerDWRCShowPro', 'playerDWRCATDB', 'playerDWRCATDBF',
    'playerDWRCPilfer', 'playerRMMetadata',
    'seasonalEffects', 'theme',
  ],
}
```

这些是用户的偏好设置，跨会话保留。

### 4.3.2 sessionStorage（会话设置）

```ts
{
  storage: sessionStorage,
  pick: ['setV', 'msgNameShow'],
}
```

- `setV`：开发者模式，仅本次会话有效，关闭标签页后失效。
- `msgNameShow`：信息区域显示自定义名，仅本次会话有效。

## 4.4 校验插件

定义于 [src/store/plugins/validation.ts](file:///d:/wenjian/home/home/src/store/plugins/validation.ts)，在 [main.ts](file:///d:/wenjian/home/home/src/main.ts) 中通过 `pinia.use(validationPlugin)` 注册。

### 4.4.1 校验规则

```ts
export const validationRules = {
  coverType:           { allowed: [0, 1, 2, 3], defaultValue: 0 },
  playerLoop:          { allowed: ["all", "one", "none"], defaultValue: "all" },
  playerOrder:         { allowed: ["list", "random"], defaultValue: "random" },
  theme:               { allowed: ["system", "time", "bg", "light", "dark"], defaultValue: "system" },
  autoBGSwitchInterval: { allowed: [0, 1, 2, 3], defaultValue: 2 },
};
```

### 4.4.2 工作机制

通过 `store.$subscribe` 监听所有变更：

```ts
store.$subscribe((mutation) => {
  if (mutation.type !== "direct") return;
  const event = Array.isArray(mutation.events) ? mutation.events[0] : mutation.events;
  if (!event || !("key" in event)) return;
  const { key, newValue, oldValue } = event;
  if (Object.prototype.hasOwnProperty.call(validationRules, key)) {
    const rule = validationRules[key];
    let coercedValue = newValue;
    // 数字类型自动转换
    if (rule.allowed.length > 0 && typeof rule.allowed[0] === "number") {
      coercedValue = Number(newValue);
    }
    // 不合法值回退到 oldValue
    if (!rule.allowed.includes(coercedValue)) {
      store.$patch({ [key]: oldValue });
      console.error(`不支持将变量 '${String(key)}' 的值设置为 '${newValue}'，已阻止更改。`);
      ElMessage({ message: `不支持将变量 '${String(key)}' 的值设置为 '${newValue}'，已阻止更改。` });
      setTimeout(() => {
        if (store.webSpeech) {
          stopSpeech();
          SpeechLocal("变量异常.mp3");
        }
      }, 300);
    }
  }
});
```

### 4.4.3 防御场景

主要防御以下情况：

- 持久化数据被手动篡改为非法值（如 `coverType = 99`）。
- URL 参数注入非法值（如 `?bg=9`）。
- 旧版本数据迁移到新版本时字段类型变化。

注意：仅当 `mutation.type === "direct"` 时校验，即只校验直接赋值，不校验 `$patch` 批量更新。

## 4.5 数据流示例

以「切换壁纸」为例：

```text
1. 用户在 Set.vue 中点击「每日一图」
2. coverType 被赋值为 1
3. validationPlugin 校验：1 ∈ [0,1,2,3]，通过
4. persist 插件写入 localStorage
5. Background.vue 中 watch(() => store.coverType) 触发
6. changeBg(1) 调用，加载新壁纸
7. 壁纸加载完成后 setImgLoadStatus(true)
8. App.vue 中 v-if="store.imgLoadStatus" 渲染主界面
```

## 4.6 类型定义

类型声明位于 [src/typings/store.d.ts](file:///d:/wenjian/home/home/src/typings/store.d.ts)，定义 `MainState` 接口。所有持久化字段必须同时在 `storeState`、`MainState`、`persist.pick` 三处保持同步。
