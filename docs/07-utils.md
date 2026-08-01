# 07 - 工具函数

本文档逐个说明 `src/utils/` 下所有工具模块的功能与实现。

## 7.1 config_check.ts

**路径**：[src/utils/config_check.ts](file:///d:/wenjian/home/home/src/utils/config_check.ts)

**职责**：配置加载与全局代理。

详见 [03 - 配置系统](./03-config.md)。

**导出**：

- `loadRuntimeConfig()`：异步加载 `/runtime-config.json`。
- `envConfig`：Proxy 代理对象，全局自动注入。

---

## 7.2 authServer.ts

**路径**：[src/utils/authServer.ts](file:///d:/wenjian/home/home/src/utils/authServer.ts)

**职责**：接口签名算法。

详见 [08 - API 集成与鉴权](./08-api.md)。

**导出**：

| 函数 | 用途 |
| --- | --- |
| `gwp(u, s, b)` | POST 请求签名（body 参与计算） |
| `gwg(u, s)` | GET 请求签名（query 参与计算） |
| `gwgt(u, s)` | 带时间戳的 GET 签名 |
| `gasA(p, s)` | TTS API 签名（`timestamp-random-0-hash` 格式） |
| `gasB(u, s)` | 路径式签名（时间作为路径段） |
| `gasC(u, s)` | 路径式签名（时间戳 hex 作为路径段） |
| `gasDH(u, s)` | query 参数签名（`sign` + `t`） |
| `gasDI(u, s)` | query 参数签名（`sign` + hex `t`） |

### 网络时间获取

`gst()` 函数优先从 `https://api.nanorocky.top/time/` 获取网络时间，避免客户端时间偏差导致签名失效：

```ts
async function gst() {
  if (!x || !y) {
    try {
      const { timestamp: t } = await (await fetch("https://api.nanorocky.top/time/")).json();
      x = t as number;       // 网络时间戳
      y = f() as number;     // 获取时的本地时间戳
    } catch (error) {
      x = y = f() as number; // 失败时使用本地时间
    }
  }
  return x + (f() - y);     // 网络时间 + 本地时间差
}
```

---

## 7.3 speech.ts

**路径**：[src/utils/speech.ts](file:///d:/wenjian/home/home/src/utils/speech.ts)

**职责**：文字转语音（TTS）与本地音频播放。

详见 [11 - 语音系统](./11-speech.md)。

**导出**：

- `Speech(text, voice?, style?, role?, rate?, volume?, delay?)`：调用 TTS API 生成并播放。
- `SpeechLocal(fileName, delay?)`：播放本地预生成音频。
- `stopSpeech()`：停止当前播放并清空队列。

---

## 7.4 decodeDWQYRC.ts

**路径**：[src/utils/decodeDWQYRC.ts](file:///d:/wenjian/home/home/src/utils/decodeDWQYRC.ts)

**职责**：解析 YRC / QRC 逐字歌词格式为统一的 DWRC 结构。

详见 [09 - 歌词系统](./09-lyrics.md)。

**返回类型**：

```ts
type WordItem = [
  position: [number, number],  // [起始时间ms, 持续时间ms]
  text: string,                 // 歌词文字（空格替换为 &nbsp;）
  lineIndex: number,            // 行索引
  wordIndex: number             // 字索引
];

type LineItem = [
  start: number,                // 行起始时间 ms
  duration: number,             // 行持续时间 ms
  stack: WordItem[]             // 该行所有字
];
```

---

## 7.5 removeLyricMetadata.ts

**路径**：[src/utils/removeLyricMetadata.ts](file:///d:/wenjian/home/home/src/utils/removeLyricMetadata.ts)

**职责**：剔除歌词头部与尾部的元数据行（如作词、作曲、制作人等）。

**算法**：

1. 加载 `src/assets/metadata_Keywords.json` 关键词列表。
2. `isMetadataLine(line)`：移除时间标签与括号内容后，检查是否包含任一关键词。
3. 从头扫描，跳过纯元数据行，找到第一行真实歌词。
4. 从尾扫描，找到最后一行真实歌词。
5. 截取两者之间的内容。

**支持格式**：LRC 逐行、YRC 逐字、QRC 逐字。

---

## 7.6 checkPilferDWRC.ts

**路径**：[src/utils/checkPilferDWRC.ts](file:///d:/wenjian/home/home/src/utils/checkPilferDWRC.ts)

**职责**：将「偷」来的歌词与原歌词对齐时间轴。

详见 [09 - 歌词系统](./09-lyrics.md#偷歌词对齐)。

**核心函数**：

- `normalizeLyricLine(line)`：移除时间标签、括号、标点、空格，返回归一化字符串。
- `parseStartTimeMs(line)`：从一行歌词中解析起始时间（支持 LRC、`[start,duration]`、`(start)` 等格式）。
- `strictMatch(source, pilfer)`：严格匹配（3 行完全相同）。
- `fuzzyMatch(source, pilfer)`：模糊匹配（允许跨行合并）。
- `adjustLineWithOffset(line, offset)`：对一行所有时间标签应用偏移。
- `alignPilferedLyrics(pilferLyric, originalLineLyric?)`：主入口，返回对齐后的歌词或 `null`。

---

## 7.7 getTime.ts

**路径**：[src/utils/getTime.ts](file:///d:/wenjian/home/home/src/utils/getTime.ts)

**导出**：

### `getCurrentTime()`

返回当前时间对象：

```ts
{
  year, month, day, hour, minute, second, weekday
}
```

`weekday` 为中文字符串（如「星期一」）。

### `getTimeCapsule()`

基于 `dayjs` 计算今日 / 本周 / 本月 / 本年的进度：

```ts
{
  day:   { name, total, passed, remaining, percentage },
  week:  { name, total, passed, remaining, percentage },
  month: { name, total, passed, remaining, percentage },
  year:  { name, total, passed, remaining, percentage },
}
```

- 今日：按小时计算。
- 其他：按天计算。
- 周进度：`(passed + 6) % 7`，因为 `dayjs` 周从周日开始。

### `helloInit(store)`

根据当前时间显示欢迎语并播放对应语音：

| 时段 | 文案 | 语音 |
| --- | --- | --- |
| 0-5 | 凌晨好，该睡了啦！ | 欢迎1.mp3 |
| 5-7 | 早上好，起的真早哦~ | 欢迎2.mp3 |
| 7-9 | 早上好，又是新的一天~ | 欢迎3.mp3 |
| 9-11 | 上午好！ | 欢迎4.mp3 |
| 11-14 | 中午好，辛苦了一个上午，补充下能量吧~ | 欢迎5.mp3 |
| 14-17 | 下午好！ | 欢迎6.mp3 |
| 17-18 | 傍晚好，吃顿美味的晚餐休息休息吧~ | 欢迎7.mp3 |
| 18-22 | 晚上好，娱乐一下，放松心情~ | 欢迎8.mp3 |
| 22-23 | 深夜好！夜深了，晚安噢w | 欢迎9.mp3 |
| 23-24 | 深夜好！都快凌晨了啦，早点休息哦~ | 欢迎10.mp3 |

### `checkDays()`

默哀日检测，匹配时为页面添加灰度滤镜：

```ts
const anniversaries = {
  4.4:   "清明节",
  5.12:  "汶川大地震纪念日",
  7.7:   "中国人民抗日战争纪念日",
  9.18:  "九·一八事变纪念日",
  12.13: "南京大屠杀死难者国家公祭日",
};
```

通过动态插入 `<style>html{filter: grayscale(100%)}</style>` 实现。

### `siteDateStatistics(startDate)`

计算建站至今的年月天数，返回中文字符串。

---

## 7.8 getColor.ts

**路径**：[src/utils/getColor.ts](file:///d:/wenjian/home/home/src/utils/getColor.ts)

**职责**：从壁纸图片提取主色调，判断应为浅色或深色主题。

**算法**：

1. 创建 canvas 并绘制图片。
2. 读取所有像素的 RGB 值。
3. 按亮度公式 `(r*299 + g*587 + b*114) / 1000` 计算亮度。
4. 亮度 <128 计为 dark，否则为 light。
5. 返回多数派（`light > dark` ? `'light'` : `'dark'`）。

**限制**：受 `canvas` 同源策略限制，跨域壁纸无法提取（会抛错，App.vue 捕获后回退到 `system` 主题）。

---

## 7.9 cursor.ts

**路径**：[src/utils/cursor.ts](file:///d:/wenjian/home/home/src/utils/cursor.ts)

**职责**：自定义鼠标光标。

**实现**：

- 创建一个 `#cursor` div，通过 `lerp`（线性插值）跟随鼠标，实现拖尾效果。
- 扫描所有 `cursor: pointer` 的元素并记录（用于悬停放大效果）。
- 注入全局样式，将原生光标替换为透明 SVG 圆点。
- `refresh()` 方法可在 DOM 变化后重新扫描可点击元素。

**插值参数**：`0.35`，即每帧移动剩余距离的 35%，产生平滑拖尾。

**移动端处理**：通过 `is-xs-hidden` 类隐藏（响应式 CSS 控制）。

---

## 7.10 debounce.ts

**路径**：[src/utils/debounce.ts](file:///d:/wenjian/home/home/src/utils/debounce.ts)

**职责**：简易防抖函数。

```ts
function debounce(func, wait = 300, immediate = false)
```

- `immediate == false`（默认）：在最后一次调用后 `wait` 毫秒执行。
- `immediate == true`：立即执行，之后 `wait` 毫秒内的调用被忽略。

**注意**：此实现使用模块级变量 `timeout`，意味着全局只有一个防抖计时器，无法同时防抖多个不同函数。

---

## 7.11 ver.ts

**路径**：[src/utils/ver.ts](file:///d:/wenjian/home/home/src/utils/ver.ts)

**职责**：解析版本号字符串。

```ts
parseVersion("4.3.9.dev [EFU]")
// 返回:
// {
//   version: "4.3.9",
//   type: "development",
//   channel: "EFU",
//   upa: "NanoRocky"  // channel != "imsyy" 时使用 config.efua
// }
```

---

## 7.12 updatecheck.ts

**路径**：[src/utils/updatecheck.ts](file:///d:/wenjian/home/home/src/utils/updatecheck.ts)

**职责**：通过 GitHub Releases API 检查更新。

**流程**：

1. 从 `versionInfo.upa` 决定查询哪个仓库（`imsyy` 或 `NanoRocky`）。
2. 调用 `https://api.github.com/repos/{owner}/{repo}/releases/latest`。
3. 比对 `target_commitish`（渠道）与当前渠道。
4. 通过 `extractVersionType` 判断版本类型（pre/beta/dev/release）。
5. 校验 `prerelease` 与版本类型的一致性。
6. 使用 `cleanVersion` 清洗版本号（提取前 3 段数字）。
7. `compareVersions` 逐段比较版本号。
8. 返回 `{ status, latestVersion, isPreview, versionType }`。

`status` 含义：

- `"true"`：当前已是最新。
- `"false"`：发现新版本。
- `"error"`：检查失败。

---

## 7.13 xiaomiWeather.ts

**路径**：[src/utils/xiaomiWeather.ts](file:///d:/wenjian/home/home/src/utils/xiaomiWeather.ts)

**职责**：小米天气 API 适配。

详见 [10 - 天气系统](./10-weather.md)。

**导出**：

- `getXMWT()`：主入口，返回 `{ adCode, weather }`。
- `BEAUFORT_SCALE`：蒲福风级表。
- `convertWindSpeed(speed, options?)`：风速转风级。
- `WindConversionOptions` 接口。

---

## 7.14 season/ 子目录

**路径**：`src/utils/season/`

| 文件 | 职责 |
| --- | --- |
| `snow.ts` | 雪花动画（Canvas） |
| `firefly.ts` | 萤火虫动画 |
| `lantern.ts` | 灯笼动画 |

详见 [12 - 季节特效](./12-season.md)。

### 通用模式

三者均导出 `init*()` 与 `close*()` 函数，内部通过 `requestAnimationFrame` 循环，并设置 `store.show*` 状态字段。`close*()` 负责清理动画帧、移除 Canvas、解绑 resize 监听。
