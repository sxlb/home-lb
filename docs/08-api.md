# 08 - API 集成与鉴权

## 8.1 API 层概览

所有外部接口请求封装在 [src/api/index.ts](file:///d:/wenjian/home/home/src/api/index.ts)，分为以下几类：

| 类别 | 接口 |
| --- | --- |
| 音乐 | `getPlayerList` |
| 一言 | `getHitokoto` |
| 腾讯天气 | `getTXAdcode` / `getTXWeather` / `getTXAdcodeS` / `getTXWeatherS` |
| 高德天气 | `getGDAdcode` / `getGDAdcodeI` / `getGDWeather` |
| 备用天气 | `getHXHWeather` / `getOtherWeather` / `getXMWeather` |
| IP 查询 | `getIPV4Addr` / `getIPV6Addr` / `getIPV4AddrLocation` |
| 连通性 | `testGitHubConnectivity` |

## 8.2 音乐接口

### `getPlayerList(server, type, id, serverse, idse, playerTrLrc)`

**用途**：获取播放列表，支持双源合并。

**流程**：

1. 如果配置了 `serverse` 与 `idse`，并行请求两个源并合并（备用源在前）。
2. 否则仅请求主源。
3. 检查返回数据的 `url` 字段：
   - 若以 `@` 开头，表示需要 JSONP 二次解析（QQ 音乐场景）：
     - 拆分 `@handle@jsonpCallback@jsonpCallbackFunction@url`。
     - 通过 `fetchJsonp` 请求 `url`，获取 `sip`（服务器 IP 列表）。
     - 过滤掉 `http://ws` 开头的服务器（WebSocket 域名），优先选择 HTTPS。
     - 拼接 `domain + midurlinfo[i].purl` 作为最终播放 URL。
   - 否则直接使用 `url` 字段。
4. 映射为 APlayer 所需格式 `{ name, artist, album, url, cover, lrc }`。
5. 若 `playerTrLrc` 为 `true` 且 `lrc` 存在，在 URL 附加 `trlrc=true` 参数请求翻译歌词。

**接口地址**：由 `VITE_SONG_API` 配置，需符合 [Meting API](https://github.com/injahow/meting-api) 规范。逐字歌词功能需使用 [NanoRocky/meting-api](https://github.com/NanoRocky/meting-api) 分支。

## 8.3 一言接口

### `getHitokoto()`

```ts
const res = await fetch("https://v1.hitokoto.cn");
return await res.json();
```

返回 `{ hitokoto, from, ... }`，无配置项。

## 8.4 腾讯天气接口

腾讯位置服务接口因 CORS 限制，必须使用 JSONP。

### 通用 JSONP 封装

```ts
const loadJSONP = (url, callbackName) => {
  return new Promise((resolve, reject) => {
    (window as any)[callbackName] = (data) => {
      resolve(data);
      delete (window as any)[callbackName];
    };
    const script = document.createElement('script');
    script.src = url;
    script.onerror = () => {
      reject(new Error('JSONP 请求失败'));
      delete (window as any)[callbackName];
    };
    document.body.appendChild(script);
  });
};
```

通过动态 `<script>` 标签注入回调函数名，避免 CORS 限制。

### 鉴权模式

当配置 `VITE_TX_WEATHER_SKEY` 时启用鉴权：

```ts
export const getTXAdcodeS = async (key, skey) => {
  const url = `https://apis.map.qq.com/ws/location/v1/ip?key=${key}&output=jsonp&callback=${callback}`;
  const urls = await gwg(url, skey);  // 签名
  return await loadJSONP(urls, callback);
};
```

`gwg()` 会在 URL 上附加 `sig` 参数（MD5 签名），详见 [8.7 签名算法](#87-签名算法)。

### 接口列表

| 函数 | URL |
| --- | --- |
| `getTXAdcode(key)` | `https://apis.map.qq.com/ws/location/v1/ip` |
| `getTXWeather(key, adcode)` | `https://apis.map.qq.com/ws/weather/v1/` |
| `getTXAdcodeS(key, skey)` | 同上，附加签名 |
| `getTXWeatherS(key, adcode, skey)` | 同上，附加签名 |

## 8.5 高德天气接口

高德接口支持 CORS，可直接使用 `fetch`：

| 函数 | URL |
| --- | --- |
| `getGDAdcode(key)` | `https://restapi.amap.com/v3/ip?key=${key}` |
| `getGDAdcodeI(ipv4, key)` | `https://restapi.amap.com/v3/ip?ip=${ipv4}&key=${key}` |
| `getGDWeather(key, city)` | `https://restapi.amap.com/v3/weather/weatherInfo?key=${key}&city=${city}` |

`getGDAdcodeI` 用于当 `getGDAdcode` 失败时（如纯 IPv6 网络），先获取 IPv4 再带 IP 查询。

## 8.6 备用天气接口

### 小米天气

```ts
export const getXMWeather = async (city) => {
  const res = await fetch(`https://api.nanorocky.top/xmw/?city=weathercn%3A${city}`);
  return await res.json();
};
```

通过中转服务器访问 `weatherapi.market.xiaomi.com`，因原始接口不支持 CORS。

### IP 查询

| 函数 | URL |
| --- | --- |
| `getIPV4Addr()` | `https://v4.yinghualuo.cn/bejson?format=json` |
| `getIPV6Addr()` | `https://v6.yinghualuo.cn/bejson?format=json` |
| `getIPV4AddrLocation(ipv4)` | `https://api.nanorocky.top/tbipinfo/?ip=${ipv4}` |

`getIPV4AddrLocation` 通过中转访问淘宝 IP 信息接口。

### 韩小韩 / 教书先生

| 函数 | URL |
| --- | --- |
| `getHXHWeather()` | `https://api.vvhan.com/api/weather` |
| `getOtherWeather()` | `https://api.oioweb.cn/api/weather/GetWeather` |

这两个接口无需 Key，但速率限制严格，作为最后兜底。

## 8.7 签名算法

实现于 [src/utils/authServer.ts](file:///d:/wenjian/home/home/src/utils/authServer.ts)。

### 设计理念

所有签名算法基于 MD5（使用 `@noble/hashes`），将请求参数排序后拼接，附加 SKEY 后哈希。代码有意做了一定混淆（变量名 `x`、`y`、`d`、`f` 等），作者注释明确表示这是「答辩」（代码梗，意为看着复杂但实际防护有限）。

### `gwg(u, s)` - GET 签名

用于腾讯接口鉴权：

```ts
export async function gwg(u: string, s: string) {
  const { origin: ul, pathname: p } = new URL(u);
  const q = new URLSearchParams(new URL(u).search);
  // 参数按 key 排序，拼接为 key=value&...
  // 末尾附加 SKEY
  // MD5 哈希，取小写 hex
  q.set("sig", d(`${p}?${[...q.entries()].sort(...).map(...).join("&")}${s}`).toLowerCase());
  return `${ul}${p}?${q.toString()}`;
}
```

腾讯位置服务官方签名规范：将 query 参数按字典序排序，拼接 `path?sorted_query + sk`，MD5 小写。

### `gasA(p, s)` - TTS 签名

用于 Azure TTS API 鉴权：

```ts
export async function gasA(p: string, s: string) {
  const t = await gst();          // 网络时间戳
  const r = Math.random().toString(36).substring(2, 12);  // 随机串
  return [t, r, "0", d(`${p}-${t}-${r}-0-${s}`)].join("-");
  // 返回格式: timestamp-random-0-hash
}
```

在 `Speech()` 中使用：

```ts
const sign = await gasA(path, key);
speechapiUrlS = `${speechapi}?sign=${sign}`;
```

### `gasC(u, s)` - 文件签名

用于自建静态文件服务鉴权（壁纸、语音、配置 JSON）：

```ts
export async function gasC(u: string, s: string) {
  const { origin: ul, pathname: p } = new URL(u);
  const t = o((await gst()));     // 时间戳转 hex
  return `${ul}/${d(`${s}/${p}${t}`)}/${t}/${p}`;
  // 返回格式: origin/hash/time/path
}
```

URL 中嵌入时间戳，服务端可校验有效期。

### `gwgt(u, s)` - 带时间戳的 GET 签名

```ts
export async function gwgt(u: string, s: string) {
  // 同 gwg，但额外附加 time 参数参与签名
  q.set("time", (await gst()).toString());
  q.set("sig", d(`${p}?${...}${s}`).toLowerCase());
  return `${ul}${p}?${q.toString()}`;
}
```

作者注释明确指出：腾讯不校验时间戳，所以这只是「看起来有用」，无实际防护效果。

### `gasB` / `gasDH` / `gasDI`

其他变体签名，目前项目中未直接使用，保留供二次开发。

## 8.8 GitHub 连通性检测

```ts
export const testGitHubConnectivity = async (): Promise<number> => {
  const testUrl = 'https://raw.githubusercontent.com/NanoRocky/home/blob/EFU/public/images/icon/github.png';
  const controller = new AbortController();
  const timeoutId = setTimeout(() => controller.abort(), 3000);
  const response = await fetch(testUrl, { method: 'HEAD', signal: controller.signal });
  clearTimeout(timeoutId);
  return response.ok ? 1 : 0;
};
```

用于在加载 AMLL TTML Database 前判断 GitHub 是否可达，决定是否使用镜像加速。

## 8.9 错误处理与降级

API 层普遍采用 `try/catch` 并返回空数组或抛出错误，由调用方决定降级策略：

- 音乐：失败时 `store.musicIsOk = false`，不显示音乐面板。
- 天气：多级 `try/catch` 链式降级（详见 [10 - 天气系统](./10-weather.md)）。
- 一言：失败时显示默认文案。

所有失败均会通过 `ElMessage` 提示用户，并在 `webSpeech` 开启时播放对应语音。
