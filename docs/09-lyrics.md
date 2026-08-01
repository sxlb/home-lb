# 09 - 歌词系统

本项目歌词系统是核心特色功能，支持逐行与逐字两种模式，并具备多源回退与时间轴对齐能力。

## 9.1 整体架构

```text
APlayer 加载歌词 URL
        │
        ▼
Player.vue onLoadStart()
        │
        ├─ 检查 playerDWRCShow 总开关
        │
        ▼
fetchDWRC(dwrcUrl)
        │
        ├─ 1. 直接请求原始歌词 + &dwrc=true
        │     ├─ 解析成功 → 写入 store.dwrcTemp
        │     └─ 解析失败 ↓
        │
        ├─ 2. AMLL TTML Database（playerDWRCATDB）
        │     ├─ 镜像加速（playerDWRCATDBF）
        │     ├─ netease → ncm-lyrics/{id}.yrc
        │     ├─ tencent → qq-lyrics/{id}.qrc
        │     └─ 失败 ↓
        │
        └─ 3. 偷歌词（playerDWRCPilfer）
              ├─ 从另一音乐源搜索同名歌曲
              ├─ alignPilferedLyrics 时间轴对齐
              └─ 失败 → store.dwrcEnable = false（降级为逐行）
```

## 9.2 数据结构

### DWRC（Dynamic Word-by-word Render Caption）

项目内部统一格式，定义于 [src/components/Player.vue](file:///d:/wenjian/home/home/src/components/Player.vue)：

```ts
type DWRCItem = [
  number,                                                    // 行起始时间 ms
  number,                                                    // 行持续时间 ms
  Array<[[number, number], string, number, number]>          // 字数组
];

// 字数组每项:
// [0] [start, duration]  - 起始时间 ms, 持续时间 ms
// [1] word                - 歌词文字
// [2] lineIndex           - 行索引
// [3] wordIndex           - 字索引
```

### 渲染数据

`syncDWRCLrc()` 将 DWRC 转换为渲染数据并写入 `store.playerLrc`：

```ts
// 每字一项:
[
  isCurrent,        // [0] 是否正在唱
  isSungLyrics,    // [1] 是否已唱完
  line,             // [2] 行索引
  row,              // [3] 字索引
  word,             // [4] 文字（HTML）
  duration,         // [5] 持续时间 ms
  lessdur,          // [6] 剩余时间 ms
  "auto"            // [7] 保留
]
```

## 9.3 解码器 decodeDWQYRC

**路径**：[src/utils/decodeDWQYRC.ts](file:///d:/wenjian/home/home/src/utils/decodeDWQYRC.ts)

### 输入格式

支持 YRC（网易云）与 QRC（QQ 音乐）两种逐字歌词格式，示例：

```text
[1234,5678]这是(100,200,0)一(300,400,0)行(500,600,0)歌(700,800,0)词(900,1000,0)
```

- `[start,duration]`：行起始时间与持续时间（毫秒）。
- `(start,duration[,volume])`：每字的起始时间与持续时间。
- 文字与时间标签可交替出现，支持「时间在前」与「文字在前」两种顺序。

### 解析流程

```ts
export function decodeDWQYRC(i: string, rmmd: boolean = false): LineItem[] {
  if (rmmd) i = removeLyricMetadata(i);  // 可选：移除元数据
  const lines = i.trim().split("\n")
    .filter(line => !/^\[ch:\d+\]/.test(line.trim()));  // 过滤和弦行
  const output: LineItem[] = [];

  for (const rawLine of lines) {
    // 跳过元数据行（如 [ti:...]）
    if (/^\[[a-z]+:.+\]$/i.test(rawLine.trim())) continue;

    // 匹配 [start,duration]content
    const match = rawLine.match(/^\[(\d+),(\d+)\](.*)$/);
    if (!match) continue;

    const [start, duration, content] = [parseInt(match[1]), parseInt(match[2]), match[3].trim()];

    // 验证包含时间标签
    if (!/(\(\d+,\d+(?:,\d+)?\))/.test(content)) continue;

    // 判断时间标签位置（前 or 后）
    const timeBeforeText = /^\(\d+,\d+(?:,\d+)?\)/.test(content);

    // 按时间标签分割
    const parts = content.split(/(\(\d+,\d+(?:,\d+)?\))/).filter(Boolean);

    // 配对文字与时间，构建 WordItem[]
    const stack: WordItem[] = [];
    // ... 配对逻辑

    output.push([start, duration, stack]);
  }

  // 验证至少有一行包含字
  if (!output.some(o => o[2].length > 0)) {
    throw new Error("歌词文件非逐字歌词");
  }

  return output;
}
```

### 空格处理

歌词中的空格会被替换为 `&nbsp;`，避免 HTML 渲染时被折叠：

```ts
const word = textPart.replace(' ', '&nbsp;');
```

## 9.4 同步渲染 syncDWRCLrc

**路径**：[src/components/Player.vue](file:///d:/wenjian/home/home/src/components/Player.vue) `syncDWRCLrc()` 函数

通过 `requestAnimationFrame` 每帧执行：

```ts
function syncDWRCLrc() {
  const isLineByLine = !store.dwrcEnable || store.dwrcTemp.length === 0 || store.dwrcLoading;
  const now = player.value.audioStatus.playedTime * 1000;  // 当前播放时间 ms
  const lineSwitchNow = now + 200;  // 提前 200ms 用于行切换

  if (isLineByLine) {
    // 逐行模式：直接读 APlayer 的 lyrics
    const lyrics = player.value.aplayer.lyrics[playIndex.value];
    const playerLyricIndex = player.value.aplayer.lyricIndex;
    // 写入 store.playerLrc
  } else {
    // 逐字模式：从 dwrcTemp 查找当前行
    if (nowLineIndex.value === -1) {
      // 初始化：扫描找到当前行
      for (let i = 0; i < dwrc.length; i++) {
        if (dwrc[i][0] <= lineSwitchNow) foundIndex = i;
        else break;
      }
    } else {
      // 增量：只检查下一行
      if (lineSwitchNow >= dwrc[nowLineIndex.value + 1][0]) nowLineIndex.value++;
    }

    // 构建每字渲染数据
    const fadeOutDuration = 300;
    const dwrcLyric = currentLine[2].map((it) => {
      const [[start, duration], word, line, row] = it;
      const isDuringFadeOut = now > start + duration && now <= start + duration + fadeOutDuration;
      const isCurrent = (now >= start && now <= start + duration) || isDuringFadeOut;
      const isSungLyrics = start + duration < now && !isDuringFadeOut;
      const lessdur = start + duration - now;
      return [isCurrent, isSungLyrics, line, row, word, duration, lessdur, "auto"];
    });

    store.setPlayerLrc(dwrcLyric);
  }

  requestAnimationFrame(syncDWRCLrc);
}
```

### 行切换提前量

`lineSwitchNow = now + 200`，提前 200ms 切换到下一行，避免视觉延迟。

### 长音检测

`duration > 1019` 时在 Footer.vue 中应用 `long-tone` 类，触发脉冲动画。

### 跳转检测

```ts
const onTimeUp = () => {
  const lastTime = store.playerCurrentTime;
  const newTime = player.value.audioStatus.playedTime;
  if (lastTime && Math.abs(newTime - lastTime) > 1) {
    store.lyricSeekVersion++;  // 触发动画重置
    nowLineIndex.value = -1;   // 强制重新扫描
  }
};
```

时间跳变超过 1 秒视为用户拖动进度条，重置行索引重新扫描。

## 9.5 Footer.vue 渲染

### 双层结构

```html
<span class="dwrc-box">
  <!-- 底层：未高亮文字（灰色） -->
  <span class="dwrc-2 lrc-text" id="dwrc-2-wrap">
    <span v-for="i in store.playerLrc" v-html="i[4]"></span>
  </span>
  <!-- 上层：已高亮文字（彩色），通过 width 动画揭示 -->
  <span class="dwrc-1 lrc-text" id="dwrc-1-wrap">
    <span v-for="i in store.playerLrc"
      :class="['dwrc-char', ...状态类...]"
      v-html="i[4]">
    </span>
  </span>
</span>
```

- `dwrc-2`：absolute 定位，`opacity: 0.8`，灰色。
- `dwrc-1`：z-index 1，彩色，初始 `width: 0`。
- 通过 `Element.animate()` 将 `dwrc-1` 中每字的 `width` 从 0 动画到实际宽度，实现「逐字揭示」。

### 增强动画

`watch(() => store.getPlayerLrc)` 中，仅在 `playerDWRCShowPro` 开启时执行：

```ts
const outputAnimate = outputItem.animate(
  [{ width: 0 }, { width: `${width}px` }],
  {
    delay: Math.max(0, start - now),  // 按字的起始时间延迟
    duration: duration,                // 持续时间与字时长一致
    fill: "forwards",
    easing: "linear",
  }
);
outputAnimate.onfinish = () => {
  // 动画结束后追加 translateY 位移
  outputItem.animate(
    [{ transform: "translateY(-1px)" }, { transform: "translateY(1px)" }],
    { duration: 300, fill: "forwards", easing: "linear" }
  );
};
```

为避免重复绑定，每个字通过 `data-start` 属性标记已处理。

### CSS 动画类

| 类名 | 条件 | 效果 |
| --- | --- | --- |
| `fade-in-start` | 未开始 | opacity 0.6，灰色，阴影 |
| `fade-in` | 当前播放 | opacity 1，彩色渐变，上移 |
| `fade-out` | 已唱完 | 多层阴影 |
| `long-tone` | 长音当前 | 脉冲动画 1.2s |
| `long-tone-out` | 长音已唱完 | 脉冲消退 0.7s |
| `dwrc-style-s1` | 未唱 | 灰色 |
| `dwrc-style-s2` | 已唱 | 高亮色 + 多层阴影 |

## 9.6 偷歌词对齐 alignPilferedLyrics

**路径**：[src/utils/checkPilferDWRC.ts](file:///d:/wenjian/home/home/src/utils/checkPilferDWRC.ts)

### 场景

当主源（如网易云）没有逐字歌词，但另一源（如 QQ 音乐）有时，从另一源「偷」来使用。但两源的时间轴可能不一致，需要对齐。

### 流程

1. **归一化**：`normalizeLyricLine` 移除时间标签、括号、标点、空格，转小写。
2. **解析时间**：`parseStartTimeMs` 支持 LRC `[mm:ss.ff]`、`[start,duration]`、`[start]`、`(start)` 等格式。
3. **构建条目**：为每行生成 `{ index, normalized, startMs }`。
4. **严格匹配**：`strictMatch` 查找连续 3 行完全相同的位置。
5. **模糊匹配**：`fuzzyMatch` 允许跨行合并（应对一方拆行、另一方不拆行的情况）。
6. **计算偏移**：`offset = sourceStart - pilferStart`，若 `|offset| < 1500` 视为无偏移。
7. **应用偏移**：`adjustLineWithOffset` 对每行所有时间标签加 offset，负值行被丢弃。

### 模糊匹配算法

```ts
const fuzzyMatch = (sourceEntries, pilferEntries) => {
  const requiredMatchCount = Math.min(3, sourceEntries.length);
  for (let i = 0; i <= pilferEntries.length - requiredMatchCount; i++) {
    let matched = true;
    let latestHintLineNumber = i;
    for (let j = 0; j < requiredMatchCount; j++) {
      let needHint = sourceEntries[j].normalized.split('').filter(x => x !== ' ').join('');
      for (let currentLnNum = latestHintLineNumber; currentLnNum < latestHintLineNumber + 10; currentLnNum++) {
        const currentLine = pilferEntries[currentLnNum].normalized.split('').filter(x => x !== ' ').join('');
        if (needHint.startsWith(currentLine)) {
          needHint = needHint.slice(currentLine.length);
          latestHintLineNumber = currentLnNum + 1;
        } else break;
        if (needHint === '') break;
      }
      if (needHint !== '') { matched = false; break; }
    }
    if (matched) return i;
  }
  return -1;
};
```

允许源一行对应偷来歌词的多行（向前看最多 10 行），通过 `startsWith` 逐字符匹配。

## 9.7 元数据剔除 removeLyricMetadata

**路径**：[src/utils/removeLyricMetadata.ts](file:///d:/wenjian/home/home/src/utils/removeLyricMetadata.ts)

### 触发条件

`store.playerRMMetadata` 开启时，在 `decodeDWQYRC` 解析前调用。

### 算法

1. 加载关键词列表 `metadata_Keywords.json`（如「作词」「作曲」「编曲」「混音」等）。
2. `isMetadataLine(line)`：移除时间标签与括号内容后，检查是否包含任一关键词。
3. 头部扫描：跳过纯元数据行，找到第一行真实歌词。
4. 尾部扫描：从末尾向前找到最后一行真实歌词。
5. 截取中间部分。

**注意**：此功能仅对非直接从 API 获得的歌词有效（即被本工具拦截替换的歌词），因为 APlayer 内部处理原始歌词不受此影响。

## 9.8 配置开关汇总

| 开关 | 字段 | 默认 | 作用 |
| --- | --- | --- | --- |
| 底栏歌词显示 | `playerLrcShow` | true | 是否在页脚显示歌词 |
| 逐字解析总开关 | `playerDWRCShow` | true | 关闭后退化为逐行 |
| 逐字效果增强 | `playerDWRCShowPro` | true | 关闭后仅用 CSS 过渡，不用 Web Animations API |
| AMLL 接入 | `playerDWRCATDB` | true | 允许从 AMLL TTML Database 加载歌词 |
| AMLL 镜像加速 | `playerDWRCATDBF` | true | 使用 `ghfast.top` 加速 GitHub 访问 |
| 偷歌词 | `playerDWRCPilfer` | true | 允许跨源搜索歌词 |
| 移除元数据 | `playerRMMetadata` | false | 剔除歌词头尾的元数据行 |
| 翻译歌词 | `playerTrLrc` | false | 请求时附加 `trlrc=true` 参数 |
