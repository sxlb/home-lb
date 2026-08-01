# 11 - 语音系统

## 11.1 概述

语音系统为项目提供"无障碍播报"能力：在用户开启 Web Speech 开关后，应用内的关键事件（壁纸切换、天气加载失败、版本检测、欢迎语等）会通过音频向用户播报。

考虑到实时生成 TTS 存在网络延迟与成本问题，系统采用**双轨制**设计：

- **`Speech`**：调用远端 Azure TTS API（兼容接口）实时合成语音，用于少数动态文本。
- **`SpeechLocal`**：播放本地预生成音频，覆盖绝大多数固定文案场景。

源码位置：[src/utils/speech.ts](../src/utils/speech.ts)

## 11.2 整体架构

```
┌────────────────────────────────────────────────────────┐
│              调用方（Weather/Player/Background等）       │
│                ↓                                       │
│     ┌──────────────┐         ┌──────────────────┐     │
│     │   Speech     │         │   SpeechLocal    │     │
│     │  (远端 TTS)   │         │  (本地音频回退)   │     │
│     └──────┬───────┘         └────────┬─────────┘     │
│            │                          │                │
│            ↓                          ↓                │
│     [audioQueue 队列]            [audioQueue 队列]      │
│            │                          │                │
│            ↓                          ↓                │
│       playNext()               playNextLocal()         │
│            │                          │                │
│            └──────────┬───────────────┘                │
│                       ↓                                │
│              currentAudio (HTMLAudioElement)           │
└────────────────────────────────────────────────────────┘
```

两个入口共用一组模块级全局变量，但播放队列各自独立管理。

## 11.3 模块级状态

[speech.ts:3-9](../src/utils/speech.ts) 中维护以下全局状态：

| 变量 | 类型 | 作用 |
| --- | --- | --- |
| `currentAudio` | `HTMLAudioElement \| null` | 当前正在播放的音频元素 |
| `audioQueue` | `string[]` | 等待播放的音频 URL 队列 |
| `isPlaying` | `boolean` | 是否有音频正在播放 |
| `controller` | `AbortController \| null` | 用于中断远端 fetch 请求 |
| `timeoutId` | `NodeJS.Timeout \| null` | 延迟发送请求的定时器 |
| `speechapiUrlS` | `string \| null` | 拼接好签名的 TTS API URL（远端） |
| `audioUrlS` | `string \| null` | 拼接好签名的本地音频 URL |

> ⚠️ 由于使用模块级状态，整个应用同一时刻只有一个语音播放上下文。新调用会自动打断旧调用。

## 11.4 远端 TTS：`Speech`

### 11.4.1 函数签名

```ts
export function Speech(
  text: string,
  voice = "zh-CN-YunxiaNeural",  // 音色
  style = "cheerful",             // 情感风格
  role = "Boy",                   // 角色扮演
  rate = "1",                     // 语速
  volume = "100",                 // 音量
  delay = 1500,                   // 防抖延迟（毫秒）
): Promise<void>
```

默认值对应 Azure 神经语音 `zh-CN-YunxiaNeural`（云夏，活泼风格）。更多音色参考 [Azure 官方文档](https://learn.microsoft.com/zh-cn/azure/ai-services/speech-service/speech-synthesis-markup-voice)。

### 11.4.2 调用流程

1. **打断旧任务**
   - 清除旧的 `timeoutId`，停止 `currentAudio`，`controller.abort()` 中断未完成的 fetch。
2. **构建 FormData**
   ```ts
   formData.append("text", text);
   formData.append("voice", voice);
   formData.append("style", style);
   formData.append("role", role);
   formData.append("rate", rate);
   formData.append("volume", volume);
   ```
3. **延迟防抖**：通过 `setTimeout(delay)` 等待，避免用户快速点击触发请求洪水。
4. **拼装 URL**
   - 无 `VITE_TTS_SKEY`：直接使用 `VITE_TTS_API`
   - 有 SKEY：调用 `gasA(path, key)` 计算签名，URL 拼接为 `${api}?sign=${sign}`
5. **发起 POST 请求**，传入 `signal` 以支持中断。
6. **响应处理**
   - 失败：解析 JSON 取 `error` 字段抛出。
   - 成功：`response.blob()` → `URL.createObjectURL()` 生成临时 URL，推入 `audioQueue`。
7. **触发播放**：若当前未在播放，调用 `playNext()` 启动队列消费。

### 11.4.3 鉴权签名

签名由 [src/utils/authServer.ts](../src/utils/authServer.ts) 中的 `gasA` 函数完成，基于路径与 SKEY 计算哈希。详见 [08 - API 集成与鉴权](./08-api.md)。

## 11.5 本地音频：`SpeechLocal`

### 11.5.1 函数签名

```ts
export function SpeechLocal(
  fileName: string,    // 文件名 + 扩展名，如 "天气加载失败.mp3"
  delay = 0           // 延迟（毫秒），默认 0 即时播放
): Promise<void>
```

### 11.5.2 文件存放约定

所有本地音频必须放在 [public/speechlocal/](../public/speechlocal/) 目录下：

```
public/speechlocal/
├── 欢迎语1.mp3
├── 天气加载失败.mp3
├── 位置信息获取失败.mp3
├── 更新提示.mp3
├── 检查更新-发现新版本.mp3
├── ...
└── Yunxia/              # 不同音色变体
    ├── 欢迎1.mp3
    └── ...
```

URL 拼装规则：`/speechlocal/${fileName}`，由 Vite 静态服务直接返回。

### 11.5.3 鉴权模式

若配置了 `VITE_SFILE_SKEY`，则本地音频 URL 也会经过 `gasC(fileUrl, key)` 签名后请求，适用于部署在带鉴权的 CDN / 中转之后的场景。

### 11.5.4 播放流程

1. 校验 `fileName` 非空。
2. 拼 URL（按需签名）。
3. 清除旧 `timeoutId` 与 `currentAudio`。
4. 进入 `setTimeout(delay)` 延迟。
5. 清空队列、停止 `controller`，**确保本地音频优先**。
6. 推入新 URL，调用 `playNextLocal()` 播放。

### 11.5.5 与 `Speech` 的差异

| 维度 | `Speech` | `SpeechLocal` |
| --- | --- | --- |
| 数据来源 | 远端 TTS API 实时合成 | 本地预生成 mp3 文件 |
| 延迟默认 | 1500ms（防抖） | 0ms（即时） |
| 触发时队列处理 | 追加到队列尾 | **清空队列**直接打断 |
| 播放就绪事件 | `audio.play()` 立即触发 | `oncanplaythrough` 等加载完成再播 |
| 网络依赖 | 强 | 无 |

`SpeechLocal` 多出 `oncanplaythrough` 监听，确保本地大文件完全可播后才播放，避免半路卡顿。同时清空队列的设计让其具备"打断式播报"语义，常用于错误提示。

## 11.6 播放队列机制

### 11.6.1 `playNext`

```ts
function playNext(resolve, reject) {
  if (audioQueue.length === 0) { isPlaying = false; return; }
  isPlaying = true;
  const nextAudioUrl = audioQueue.shift();
  // ...new Audio, onended → resolve + playNext, onerror → reject + playNext
}
```

- 队列空时将 `isPlaying` 置 false，等待下次触发。
- 单条音频播完自动消费下一条，形成链式播放。
- 出错也继续下一条，不让单条故障阻塞队列。

### 11.6.2 `playNextLocal`

与 `playNext` 几乎一致，唯一差异是播放就绪时机不同（额外监听 `oncanplaythrough`）。

### 11.6.3 Promise 解析时机

`onended` 触发时 `resolve()`，意味着 `await Speech(...)` 会一直等待到该条音频播放完毕才返回。这一设计便于调用方按顺序编排多段语音：

```ts
await SpeechLocal("欢迎1.mp3");
await SpeechLocal("欢迎2.mp3");  // 等 1 播完才开始
```

## 11.7 停止播放：`stopSpeech`

```ts
export function stopSpeech() {
  if (currentAudio) { currentAudio.pause(); currentAudio = null; }
  audioQueue = [];
  isPlaying = false;
  if (controller) { controller.abort(); controller = null; }
  if (timeoutId) { clearTimeout(timeoutId); timeoutId = null; }
}
```

清理所有状态，包括：

- 暂停当前音频
- 清空待播队列
- 中断进行中的 fetch 请求
- 清除防抖定时器

调用场景：

- 切换功能开关时（关闭 `webSpeech`）
- 即将播放新语音前的预清理
- 应用状态切换时

## 11.8 全局开关：`store.webSpeech`

`webSpeech` 存储在 Pinia 中并持久化到 `localStorage`（见 [04 - 状态管理](./04-store.md)）。所有调用方在调用前都会判断：

```ts
if (store.webSpeech) {
  stopSpeech();
  SpeechLocal("xxx.mp3");
}
```

关闭开关时所有语音播报静默，不影响其他功能。

## 11.9 音色切换

`VITE_TTS_Voice` 与 `VITE_TTS_Style` 配置默认音色与情感风格。常见组合：

| 音色 | 风格 | 适用 |
| --- | --- | --- |
| `zh-CN-YunxiaNeural` | `cheerful` | 默认，活泼少女 |
| `zh-CN-YunxiNeural` | `chat` | 男声，对话感 |
| `zh-CN-XiaoxiaoNeural` | `affectionate` | 柔和亲切 |

本地音频则通过子目录区分音色变体：`/speechlocal/Yunxia/欢迎1.mp3` 等。当前代码默认从根目录读取，如需切换可调整 `SpeechLocal` 的路径拼装逻辑或扩展 `store.playerSpeechName` 字段。

## 11.10 典型调用场景

### 11.10.1 应用启动欢迎语

```ts
// 主页加载完成后随机播放一条欢迎语
const randomWelcome = `欢迎${Math.floor(Math.random() * 10) + 1}.mp3`;
if (store.webSpeech) SpeechLocal(randomWelcome);
```

### 11.10.2 PWA 更新提示

```ts
SpeechLocal("更新提示.mp3");
// 然后 reload 页面应用新版本
```

### 11.10.3 天气加载失败

```ts
if (store.webSpeech) {
  stopSpeech();
  SpeechLocal("天气加载失败.mp3");
}
```

### 11.10.4 检查更新

```ts
if (hasUpdate) SpeechLocal("检查更新-发现新版本.mp3");
else SpeechLocal("检查更新-已是最新版本.mp3");
```

### 11.10.5 壁纸切换反馈

```ts
SpeechLocal("更换壁纸成功.mp3");
```

## 11.11 部署 TTS API

项目作者提供了一个 PHP 实现的 Azure Speech API 中转：[AzureSpeechAPI-by-PHP](https://github.com/NanoRocky/AzureSpeechAPI-by-PHP)。

部署步骤：

1. 准备一台支持 PHP 8+ 的服务器。
2. 克隆上述仓库并配置 Azure 订阅密钥。
3. 将服务地址填入 `VITE_TTS_API`。
4. （可选）配置 `VITE_TTS_SKEY` 启用鉴权，防止 API 被滥用。

如不部署，可将所有 `Speech(...)` 调用替换为 `SpeechLocal(...)`，使用本地预生成音频即可。

## 11.12 扩展指南

### 11.12.1 新增一段语音文案

1. 使用 TTS 工具生成 mp3，命名规范如 `xxx功能成功.mp3`。
2. 放入 [public/speechlocal/](../public/speechlocal/)。
3. 在业务代码相应位置添加：
   ```ts
   if (store.webSpeech) SpeechLocal("xxx功能成功.mp3");
   ```

### 11.12.2 切换到 Web Speech API（浏览器原生）

将 `Speech` 函数体替换为：

```ts
const utter = new SpeechSynthesisUtterance(text);
utter.voice = speechSynthesis.getVoices().find(v => v.name.includes(voice));
utter.rate = Number(rate);
speechSynthesis.speak(utter);
```

但浏览器内置 TTS 音质远不如 Azure，仅建议作为无网络环境兜底。

### 11.12.3 增加音色子目录支持

修改 `SpeechLocal`：

```ts
const subdir = envConfig.VITE_TTS_Voice.replace('Neural', '').replace('zh-CN-', '');
const audioUrl = `/speechlocal/${subdir}/${fileName}`;
```

即可根据当前音色自动从对应子目录加载本地音频。

## 11.13 注意事项

1. **浏览器自动播放策略**：现代浏览器禁止页面加载时立即播放音频，必须由用户交互（点击/按键）触发。`SpeechLocal` 在首次 `onMounted` 调用可能被浏览器拦截，建议首条语音放到用户首次点击后。
2. **队列顺序**：`Speech` 追加到队尾，`SpeechLocal` 清空队列。设计意图：错误提示应打断当前播报立即生效。
3. **AbortController 复用**：模块级 `controller` 是单例，新调用会 `abort` 旧请求，避免并发请求相互覆盖响应。
4. **内存释放**：`URL.createObjectURL` 创建的 blob URL 应在 `onended` 中 `URL.revokeObjectURL` 释放，当前实现未做此处理，长时间运行可能造成轻微内存泄漏。
