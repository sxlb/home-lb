# 10 - 天气系统

## 10.1 概述

天气模块负责在首页底部展示当前所在城市的实时天气信息（城市、天气现象、温度、风向、风力）。由于不同天气服务在稳定性、跨域、IPv6 支持等方面存在差异，本项目采用**多源聚合 + 链式降级**的设计，确保任意单一接口失效时仍可获取数据。

主要源码位置：

| 文件 | 职责 |
| --- | --- |
| [src/components/Weather.vue](../src/components/Weather.vue) | 天气组件 UI + 调度逻辑 |
| [src/api/index.ts](../src/api/index.ts) | 各天气源的 fetch / JSONP 封装 |
| [src/utils/xiaomiWeather.ts](../src/utils/xiaomiWeather.ts) | 小米天气的二次封装（adcode 查表、风级换算） |
| [src/typings/weather.d.ts](../src/typings/weather.d.ts) | 天气相关 TS 类型声明 |

## 10.2 数据结构

### 10.2.1 前端统一数据模型

无论上游使用哪家服务，最终都会被规范化为下面两个对象：

```ts
interface AdCode {
  city: string | null;     // 城市名（区/县/市/省逐级回退）
  adcode: string | null;   // 行政区划编码（部分服务无此字段则为 null）
}

interface WeatherInfo {
  weather: string | null;        // 天气现象，如"晴"、"多云"
  temperature: string | number | null; // 实时气温，单位 ℃
  winddirection: string | null; // 风向描述，如"东北风"
  windpower: string | null;     // 风力级别，如"3级"
}
```

### 10.2.2 各上游响应类型

类型声明位于 [src/typings/weather.d.ts](../src/typings/weather.d.ts)，主要包括：

- `TXAdCodeResponse` / `TXWeatherResponse`：腾讯位置服务返回结构
- `GDAdCodeResponse` / `GDAdcodeIResponse` / `GDWeatherResponse`：高德返回结构
- `XMAdcodeItem` / `XMWeatherStatusItem` / `XMWeatherStatusData` / `XMBeaufortLevel`：小米天气相关结构

## 10.3 数据源详解

### 10.3.1 腾讯位置服务（首选，推荐）

由 `VITE_TX_WEATHER_KEY` 启用，支持两种模式：

#### 普通模式（无 SKEY）

- `getTXAdcode(key)`：通过 IP 获取行政区划编码
  - 接口：`https://apis.map.qq.com/ws/location/v1/ip?key=...&output=jsonp&callback=...`
  - 采用 JSONP 方式绕过浏览器跨域限制
- `getTXWeather(key, adcode)`：根据 adcode 拉取实时天气
  - 接口：`https://apis.map.qq.com/ws/weather/v1/?key=...&adcode=...&type=now&output=jsonp&callback=...`

#### 鉴权模式（带 SKEY）

启用 `VITE_TX_WEATHER_SKEY` 时进入此模式，所有请求需经 `gwg(url, skey)` 计算签名后追加到 URL：

- `getTXAdcodeS(key, skey)`
- `getTXWeatherS(key, adcode, skey)`

签名算法详见 [08 - API 集成与鉴权](./08-api.md)。

### 10.3.2 高德开放平台（次选）

由 `VITE_GD_WEATHER_KEY` 启用，调用链如下：

1. `getGDAdcode(key)`：通过 IP 自动定位
   - 接口：`https://restapi.amap.com/v3/ip?key=...`
2. 若上一步因 IPv6 等原因失败（`infocode !== "10000"` 或 `status !== "1"`），自动回退：
   - 调用 `getIPV4Addr()` 取公网 IPv4：`https://v4.yinghualuo.cn/bejson?format=json`
   - 再用 `getGDAdcodeI(ipv4, key)` 显式带 IP 查询：`https://restapi.amap.com/v3/ip?ip=...&key=...`
3. `getGDWeather(key, city)`：根据 adcode 取实时天气
   - 接口：`https://restapi.amap.com/v3/weather/weatherInfo?key=...&city=...`

> 注释中明确说明：高德 API 不支持 IPv6，需付费找客服开通高级版，在纯 IPv6 网络环境下会出现 IP 定位异常，因此才有了上面的 IP 回退逻辑。

### 10.3.3 小米天气 API（备用 1）

由 `getXMWT()` 统一封装，调用链：

1. `getIPV4Addr()`：取公网 IPv4
2. `getIPV4AddrLocation(ip)`：通过酪灰中转的淘宝 IP 库查询地理位置
   - 接口：`https://api.nanorocky.top/tbipinfo/?ip=...`
3. `findCityAdcode(region, city, county)`：在本地数据表 `xiaomi_weather_adcode.json` 中按"区县 → 市 → 省.市 → 省"逐级匹配出小米 adcode
4. `getXMWeather(city)`：调用小米天气接口
   - 接口：`https://api.nanorocky.top/xmw/?city=weathercn%3A${city}`
   - 注释中保留了原始小米官方接口 `weatherapi.market.xiaomi.com/wtr-v3/weather/all`，但因 CORS 必须走中转

返回结果需进行单位换算：

- `windDegreeToDirection(degree)`：风向角度 → 中文方位（北/东北/东/.../西北 + "风"）
- `convertWindSpeed(speed, options)`：风速 m/s → 蒲福风级，详见 10.5
- `getWeatherDescription(code)`：天气代码 → 中文描述，查表 `xiaomi_weather_status.json`

### 10.3.4 韩小韩天气 API（备用 2）

- `getHXHWeather()`
- 接口：`https://api.vvhan.com/api/weather`
- 字段结构与官方不同，需手动映射：
  - `result.data.type` / `result.data.night.type` → `weather`
  - `result.data.low` / `result.data.night.low` 与 `high` → 通过 `getTemperature` 取平均
  - `result.data.fengxiang` → `winddirection`
  - `result.data.fengli` → `windpower`，空值时回退 `night.fengli`

### 10.3.5 教书先生天气 API（最后兜底）

- `getOtherWeather()`
- 接口：`https://api.oioweb.cn/api/weather/GetWeather`
- 字段映射：
  - `data.city.City` → 城市
  - `data.condition.day_weather` → 天气现象
  - `data.condition.min_degree` / `max_degree` → 取平均温度
  - `data.condition.day_wind_direction` → 风向
  - `data.condition.day_wind_power` → 风力

## 10.4 降级策略

降级逻辑位于 `Weather.vue` 的 `getWeatherData()` 函数，依据密钥配置决定主链：

```
┌────────────────────────────────────────────────────────────┐
│   1. 优先级判断                                            │
│   - 仅腾讯 KEY   →  腾讯 → 高德 → 小米 → 韩小韩 → 教书   │
│   - 仅高德 KEY   →  高德 → 小米 → 韩小韩 → 教书          │
│   - 无任何 KEY   →  小米 → 韩小韩 → 教书                 │
│   - 同时有两个 KEY →  腾讯 → 高德 → 小米 → 韩小韩 → 教书  │
└────────────────────────────────────────────────────────────┘
```

代码片段（[Weather.vue:305-368](../src/components/Weather.vue)）：

```ts
const getWeatherData = async () => {
  try {
    if (!gdkey && !txkey) {
      // 完全无 KEY：小米 → 韩小韩 → 教书
      try { await getXMW(); }
      catch { try { await getHXHW(); } catch { await getOW(); } }
    } else if (!txkey) {
      // 仅有高德
      try { await getGDW(); }
      catch { try { await getXMW(); } catch { try { await getHXHW(); } catch { await getOW(); } } }
    } else {
      // 有腾讯
      try { await getTXW(); }
      catch {
        try { await getGDW(); }
        catch { try { await getXMW(); } catch { try { await getHXHW(); } catch { await getOW(); } } }
      }
    }
  } catch (error) {
    onError("天气信息获取失败");
    // 触发本地语音播报
    if (store.webSpeech) { SpeechLocal("天气加载失败.mp3"); }
  }
};
```

特性总结：

- **每个上游独立 try/catch**：单点失败不阻断后续降级。
- **逐级回退**：直到最终 `getOW`（教书先生）兜底，仍失败则全局 catch。
- **语音反馈**：每次失败若用户开启 Web Speech，都会调用本地音频报错。

## 10.5 工具函数

### 10.5.1 温度平均化 `getTemperature`

韩小韩 / 教书先生返回的是日间最低 / 最高温度区间，需取平均：

```ts
const getTemperature = (min, max) => {
  const cleanMin = parseFloat(min.toString().replace(/[^\d.-]/g, ""));
  const cleanMax = parseFloat(max.toString().replace(/[^\d.-]/g, ""));
  if (isNaN(cleanMin) || isNaN(cleanMax)) throw new Error("无法解析温度数据");
  return Math.round((cleanMin + cleanMax) / 2);
};
```

通过正则先剔除非数字字符（如"℃"），再四舍五入到整数。

### 10.5.2 蒲福风级换算 `convertWindSpeed`

小米天气返回的是风速数值，需转换为中文习惯的"X级"描述。基于蒲福风级表（[xiaomiWeather.ts:141-155](../src/utils/xiaomiWeather.ts)）：

| 等级 | 风速范围 (m/s) | 描述 |
| --- | --- | --- |
| 0 | 0 ~ 0.2 | 无风 |
| 1 | 0.3 ~ 1.5 | 软风 |
| 2 | 1.6 ~ 3.3 | 轻风 |
| 3 | 3.4 ~ 5.4 | 微风 |
| 4 | 5.5 ~ 7.9 | 和风 |
| 5 | 8.0 ~ 10.7 | 清风 |
| 6 | 10.8 ~ 13.8 | 强风 |
| 7 | 13.9 ~ 17.1 | 疾风 |
| 8 | 17.2 ~ 20.7 | 大风 |
| 9 | 20.8 ~ 24.4 | 烈风 |
| 10 | 24.5 ~ 28.4 | 狂风 |
| 11 | 28.5 ~ 32.6 | 暴风 |
| 12 | ≥ 32.7 | 飓风 |

可选参数：

- `returnRange: true`：当风速处于当前等级后 30% 区间时，返回"N-N+1级"区间形式。
- `includeDescription: true`：附带中文描述，如"3级 (微风)"。

### 10.5.3 风向角度转中文 `windDegreeToDirection`

将 0~360 度的风向角度按 45° 等分映射到 8 方位：

```ts
const directions = ['北', '东北', '东', '东南', '南', '西南', '西', '西北'];
const index = Math.round(degree / 45) % 8;
return directions[index] + '风';
```

### 10.5.4 小米 adcode 查表 `findCityAdcode`

小米天气的 adcode 与国标行政区划编码不同，需要从内置数据表 `xiaomi_weather_adcode.json` 中查找。匹配顺序：

1. `${city}.${county}`（市.区县）→ 最精确
2. `${city}`（市名）
3. `${region}.${city}`（省.市）
4. `${region}`（省名）

只要某一层匹配到唯一记录即返回，找不到返回 `null`。

## 10.6 JSONP 跨域方案

腾讯位置服务接口不允许普通 CORS 请求，本项目通过 `loadJSONP` 实现：

1. 在全局 `window` 上挂载临时回调函数 `jsonpCallback_{timestamp}_{random}`
2. 创建 `<script>` 标签，src 指向带 `callback` 参数的接口
3. 服务端返回 `jsonpCallback_xxx({...})` 形式的脚本
4. 回调被调用后从 `arguments` 取数据并 `resolve`
5. 清理临时函数与 `<script>` 节点

回调名包含时间戳与随机数，避免并发请求时互相覆盖。

## 10.7 模板渲染逻辑

[Weather.vue 模板](../src/components/Weather.vue) 极简，仅做展示：

```vue
<div class="weather" v-if="weatherData.adCode.city && weatherData.weather.weather">
  <span>{{ weatherData.adCode.city }}</span>
  <span>{{ weatherData.weather.weather }}</span>
  <span>{{ weatherData.weather.temperature }}℃</span>
  <span class="sm-hidden">{{ winddirection }}风</span>
  <span class="sm-hidden">{{ windpower }}级</span>
</div>
<div class="weather" v-else>
  <span>天气数据获取失败</span>
</div>
```

要点：

- **`v-if` 双字段判断**：城市与天气现象均不为空才渲染，避免显示残缺数据。
- **后缀自动补全**：风向不以"风"结尾时自动补"风"；风力不以"级"结尾时自动补"级"。
- **`sm-hidden` 类**：移动端窄屏隐藏风向风力，仅显示核心信息。
- **失败兜底**：显示"天气数据获取失败"占位文本。

## 10.8 生命周期

```ts
onMounted(() => {
  getWeatherData();
});
```

组件挂载即触发一次拉取，无定时刷新机制。如需刷新可手动重新挂载组件（如切换页面回来时）。

## 10.9 与语音系统的集成

每个上游失败分支均包含：

```ts
if (store.webSpeech) {
  stopSpeech();
  SpeechLocal("位置信息获取失败.mp3");  // 或 "天气加载失败.mp3"
}
```

这是项目"无障碍播报"特性的体现：当用户开启了 `webSpeech` 设置，天气模块的失败会立即通过本地预生成音频告知用户。详见 [11 - 语音系统](./11-speech.md)。

## 10.10 错误处理与提示

- 顶层 catch 调用 `onError` 显示 Element Plus 的 `ElMessage` 浮动提示（带 Error 图标）。
- 同时 `console.error` 输出到控制台便于调试。
- 仅在最终全局失败时（所有上游都失败）才触发顶层错误提示，单点失败只 console.error 不打扰用户。

## 10.11 配置项速查

| 环境变量 | 默认值 | 作用 |
| --- | --- | --- |
| `VITE_TX_WEATHER_KEY` | `""` | 腾讯位置服务 KEY，启用首选源 |
| `VITE_TX_WEATHER_SKEY` | `""` | 腾讯鉴权 SKEY，非空时启用签名模式 |
| `VITE_GD_WEATHER_KEY` | `""` | 高德开放平台 KEY，启用次选源 |

> 当两个 KEY 均为空时，自动启用小米 / 韩小韩 / 教书先生三段降级链。这些公共接口有速率限制，稳定性无法保证，正式部署建议至少申请一个腾讯 KEY。

## 10.12 扩展指南

### 10.12.1 新增一个天气源

1. 在 [src/api/index.ts](../src/api/index.ts) 添加 `getXXXWeather` 函数，返回原始数据。
2. 在 [src/typings/weather.d.ts](../src/typings/weather.d.ts) 添加对应响应类型。
3. 在 [Weather.vue](../src/components/Weather.vue) 新增 `const getXXXW = async () => {...}` 包装函数，将原始数据规范化为 `weatherData` 结构。
4. 在 `getWeatherData()` 的降级链中合适位置插入 `try { await getXXXW(); } catch { ... }`。

### 10.12.2 临时禁用某个上游

直接注释 `getWeatherData` 中对应的 `try/catch` 块即可，无需修改其他文件。
