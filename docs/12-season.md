# 12 - 季节特效

## 12.1 概述

季节特效为页面增添"应景"的视觉装饰：

- **雪花**：冬季（12 / 1 / 2 月）飘雪
- **灯笼**：春节前后（1 / 2 月）悬挂中式灯笼
- **萤火虫**：夏季（7 / 8 / 9 月）夜间飞舞光点

用户可通过设置面板手动开关，也可让程序按月份自动启用。所有特效均为**纯 Canvas + DOM 实现**，无第三方动画库依赖。

源码位置：[src/utils/season/](../src/utils/season/)

| 文件 | 特效 | 实现方式 |
| --- | --- | --- |
| [snow.ts](../src/utils/season/snow.ts) | 雪花飘落 | Canvas 2D |
| [firefly.ts](../src/utils/season/firefly.ts) | 萤火虫光点 | Canvas 2D |
| [lantern.ts](../src/utils/season/lantern.ts) | 中式灯笼 | 纯 CSS 动画 + DOM |

调度逻辑位于 [Background.vue](../src/components/Background.vue) 的 `SeasonStyle` 函数。

## 12.2 调度机制

### 12.2.1 触发入口

```ts
// Background.vue onMounted
if (store.seasonalEffects) {
  await SeasonStyle(0, true, 'normal');
} else {
  sest = 1;  // 标记已初始化，跳过后续 watch 触发
}
```

`sest` 是模块级标志位，防止组件首次挂载时被 watch 重复触发。

### 12.2.2 `SeasonStyle` 函数签名

```ts
const SeasonStyle = async (type, state, where) => { ... }
```

- `type`：特效类型
  - `0`：自动模式（按月份）
  - `1`：雪花
  - `2`：灯笼
  - `3`：萤火虫
- `state`：`true` 开启 / `false` 关闭
- `where`：触发来源，`'normal'`（首次加载）/ `'userChange'`（用户切换开关）

### 12.2.3 自动模式（type=0）

按月份匹配：

```ts
const month = new Date().getMonth() + 1; // 1-12

if ([12, 1, 2].includes(month))  → 雪花
if ([1, 2].includes(month))      → 灯笼
if ([7, 8, 9].includes(month))   → 萤火虫
```

> 1、2 月会同时启用**雪花 + 灯笼**，叠加效果更应景。

### 12.2.4 用户开关 watch

```ts
watch(() => store.seasonalEffects, async (value) => {
  if (sest == 0) return;  // 首次挂载未完成，跳过
  if (value) {
    await SeasonStyle(0, true, 'userChange');   // 重新按月份启用
  } else {
    await SeasonStyle(0, false, 'userChange');
    await SeasonStyle(1, false, 'userChange');  // 逐个关闭，确保无残留
    await SeasonStyle(2, false, 'userChange');
    await SeasonStyle(3, false, 'userChange');
  }
});
```

关闭时**显式调用所有 type**，避免因月份判断逻辑导致某特效未关闭。

## 12.3 雪花特效 `snow.ts`

### 12.3.1 数据结构

```ts
interface Snowflake {
  x: number;        // 横坐标
  y: number;        // 纵坐标
  opacity: number;  // 透明度 0-1
  speedX: number;    // 水平速度
  speedY: number;   // 下落速度
  radius: number;   // 半径
  angle: number;    // 摆动相位
}
```

### 12.3.2 Canvas 创建

```ts
const createCanvas = () => {
  canvas = document.createElement("canvas");
  canvas.id = "snowCanvas";
  canvas.style.position = "fixed";
  canvas.style.top = "0";
  canvas.style.left = "0";
  canvas.style.width = "100%";
  canvas.style.height = "100%";
  canvas.style.pointerEvents = "none";  // 不阻挡点击
  canvas.style.zIndex = "0";            // 位于壁纸之上、内容之下
  canvas.style.willChange = "transform"; // 提示浏览器优化
  document.body.appendChild(canvas);
};
```

### 12.3.3 粒子数量按设备调整

```ts
const deviceType = detectDevice();
snowflakeCount = deviceType === "mobile" ? 28 : 60;
```

移动端性能较弱，粒子数减半。

### 12.3.4 初始属性

```ts
{
  x: Math.random() * canvas.width,
  y: Math.random() * canvas.height,
  opacity: Math.random() * 0.3 + 0.2,    // 0.2-0.5，半透明
  speedX: Math.random() * 0.3 + 0.2,     // 0.2-0.5
  speedY: Math.random() * 1.2 + 0.3,     // 0.3-1.5
  radius: Math.random() * 2 + 1,         // 1-3 px
  angle: Math.random() * Math.PI * 2,    // 随机相位
}
```

### 12.3.5 渲染与运动

```ts
// 绘制
ctx.beginPath();
ctx.globalAlpha = flake.opacity;
ctx.fillStyle = "white";
ctx.arc(flake.x, flake.y, flake.radius, 0, Math.PI * 2);
ctx.fill();

// 移动
flake.angle += 0.02;
flake.x += flake.speedX + Math.sin(flake.angle) * 0.3;  // 正弦摆动模拟飘雪
flake.y += flake.speedY;
```

正弦摆动让雪花不只是直线下落，更接近真实飘雪。

### 12.3.6 边界回收

雪花飘出屏幕底部或两侧时，重置回顶部：

```ts
if (flake.y > canvas.height || flake.x > canvas.width + 50 || flake.x < -50) {
  flake.x = Math.random() * canvas.width;
  flake.y = -flake.radius;
  // 重新随机化速度与外观
}
```

### 12.3.7 关闭 `closeSnowfall`

```ts
cancelAnimationFrame(animationFrameId);
clearInterval(intervalId);
document.body.removeChild(canvas);
snowflakes.length = 0;
window.removeEventListener("resize", resizeCanvas);
store.showSnowfall = false;
```

完整清理：动画帧、定时器、DOM、监听器、状态。

## 12.4 萤火虫特效 `firefly.ts`

### 12.4.1 与雪花的差异

| 维度 | 雪花 | 萤火虫 |
| --- | --- | --- |
| 颜色 | 白色 | `rgba(255, 255, 0, 0.8)` 黄色 |
| 运动方向 | 向下落 | 全向飘动 |
| 边界处理 | 回到顶部 | 反弹（速度取反） |
| 透明度 | 静态值 | 静态值（未做闪烁） |
| 摆动 | 正弦相位 | 直线 + 反弹 |

### 12.4.2 反弹边界

```ts
if (firefly.x > canvas.width || firefly.x < 0) firefly.speedX *= -1;
if (firefly.y > canvas.height || firefly.y < 0) firefly.speedY *= -1;
```

萤火虫碰到屏幕边界即反向，模拟昆虫在密闭空间内乱飞的视觉。

### 12.4.3 粒子数量

```ts
fireflyCount = deviceType === 'mobile' ? 24 : 48;
```

### 12.4.4 速度范围

```ts
speedX: Math.random() * 1.2 - 0.35,   // -0.35 ~ 0.85
speedY: Math.random() * 1.2 - 0.35,
```

X、Y 均可正可负，所以萤火虫能在四个方向自由游走。

## 12.5 灯笼特效 `lantern.ts`

### 12.5.1 实现方式

不同于前两者的 Canvas 绘制，灯笼使用 **CSS 动画 + DOM 注入**：

```ts
styleElement = document.createElement('style');
styleElement.innerHTML = `/* 完整 CSS */`;
lanternContainer = document.createElement('div');
lanternContainer.className = 'j-china-lantern';
lanternContainer.innerHTML = `<!-- HTML 结构 -->`;
document.head.appendChild(styleElement);
document.body.appendChild(lanternContainer);
```

### 12.5.2 视觉结构

两个灯笼悬挂于屏幕左上角与右上角：

```html
<div class="lantern__warpper">            <!-- 左灯笼容器 -->
  <div class="lantern__box">              <!-- 灯笼主体 -->
    <div class="lantern__line"></div>     <!-- 顶部挂线 -->
    <div class="lantern__circle">         <!-- 灯笼罩 -->
      <div class="lantern__ellipse">
        <div class="lantern__text">新</div>  <!-- 文字 -->
      </div>
    </div>
    <div class="lantern__tail">           <!-- 底部穗 -->
      <div class="lantern__rect"></div>
      <div class="lantern__junction"></div>
    </div>
  </div>
</div>
```

两个灯笼文字分别为"新"、"年"，组合寓意"新年"。

### 12.5.3 关键样式

```css
.lantern__box {
  background: rgba(216, 0, 15, 0.8);     /* 中国红 */
  border-radius: 50% 50%;
  animation: lantern-swing 3s ease-in-out infinite alternate-reverse;
  transform-origin: 50% -70px;           /* 摆动支点在灯笼上方 */
  box-shadow: -5px 5px 50px 4px #fa6c00;  /* 橙色光晕 */
}

@keyframes lantern-swing {
  0%   { transform: rotate(-8deg); }
  100% { transform: rotate(8deg); }
}
```

- `transform-origin` 设置在元素上方，模拟吊灯从天花板悬挂的物理感
- `alternate-reverse` 让摆动方向交替，更自然
- 第二个灯笼加 `animation-delay: 1s`，与第一个错开，避免同步摆动

### 12.5.4 响应式适配

```css
@media (max-width: 520px) {
  .j-china-lantern { display: none; }
}
```

窄屏（手机）直接隐藏，避免遮挡内容。

### 12.5.5 关闭

```ts
document.head.removeChild(styleElement);
document.body.removeChild(lanternContainer);
store.showLantern = false;
```

## 12.6 性能优化策略

### 12.6.1 设备检测

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

用于根据设备类型动态调整粒子数量。

### 12.6.2 30 FPS 限速

Canvas 特效同时使用两种循环：

```ts
animationFrameId = requestAnimationFrame(updateSnowflakes);  // 60 FPS 绘制
intervalId = setInterval(() => {
  if (animationFrameId) {
    cancelAnimationFrame(animationFrameId);  // 每 33ms 取消一次 RAF
    animationFrameId = null;
    updateSnowflakes();                       // 重新启动 RAF
  }
}, 1000 / 30);  // ~33ms
```

通过周期性取消并重启 `requestAnimationFrame`，将帧率限制在约 30 FPS，平衡流畅度与 CPU 占用。

### 12.6.3 `willChange` 提示

```ts
canvas.style.willChange = 'transform';
```

提示浏览器为该 Canvas 创建独立合成层，避免触发主线程重排。

### 12.6.4 `pointerEvents: none`

```ts
canvas.style.pointerEvents = 'none';
```

Canvas 不响应鼠标事件，事件可穿透到下方 UI 元素，保证交互不被特效阻挡。

### 12.6.5 单例管理

```ts
if (animationFrameId || intervalId) closeSnowfall();
if (canvas) return;
```

重复调用 `initXxx` 会先清理旧实例，避免多个 Canvas 叠加。

## 12.7 状态字段

四个状态字段存储在 Pinia 中（见 [04 - 状态管理](./04-store.md)）：

| 字段 | 类型 | 说明 |
| --- | --- | --- |
| `seasonalEffects` | `boolean` | 总开关 |
| `showSnowfall` | `boolean` | 雪花当前是否启用 |
| `showFirefly` | `boolean` | 萤火虫当前是否启用 |
| `showLantern` | `boolean` | 灯笼当前是否启用 |

仅 `seasonalEffects` 持久化到 `localStorage`，其余三个为运行时状态，每次刷新重新计算。

## 12.8 扩展指南

### 12.8.1 新增一种特效（如樱花）

1. 在 [src/utils/season/](../src/utils/season/) 新建 `sakura.ts`，参考 `snow.ts` 实现 Canvas 动画。
2. 暴露 `initSakura` / `closeSakura` 函数，内部维护模块级状态。
3. 在 [Background.vue](../src/components/Background.vue) 顶部 import。
4. 在 `SeasonStyle` 函数中：
   - 自动模式添加月份判断：`if ([3, 4, 5].includes(month)) {...}`
   - 新增 `type == 4` 分支用于手动控制
5. 在 [store/index.ts](../src/store/index.ts) 添加 `showSakura: false` 状态。
6. 在设置面板 [Set.vue](../src/components/Set.vue) 添加切换按钮。

### 12.8.2 调整粒子数量

直接修改 `createXxx` 中的 `xxxCount` 赋值即可：

```ts
snowflakeCount = deviceType === "mobile" ? 50 : 100;  // 加大密度
```

### 12.8.3 切换为季节无关的常驻特效

修改 `SeasonStyle` 自动模式分支：

```ts
if (state == true) {
  initSnowfall();   // 不论月份始终启用
}
```

或修改 `watch` 中始终调用 `SeasonStyle(1, true, 'userChange')` 即可。

## 12.9 注意事项

1. **多特效叠加**：1-2 月会同时启用雪花 + 灯笼，两个 Canvas / DOM 共存。注意 z-index 层级：所有特效均设 `z-index: 0`，确保位于壁纸之上、内容之下。
2. **生命周期**：特效在 `Background.vue` 的 `onMounted` 启动，`onBeforeUnmount` 未显式清理特效。理论上组件卸载时应统一调用 `closeXxx`，但当前 Background.vue 始终挂载，所以问题不大。
3. **窗口缩放**：`resizeCanvas` 监听 `window.resize` 同步更新 Canvas 尺寸，但已有粒子位置不会重新随机化，可能出现粒子"溢出"新视口的情况。下次刷新时即重置。
4. **iOS Safari 兼容**：`setInterval + cancelAnimationFrame` 限速方案在 iOS Safari 上偶有抖动，可考虑改用 `setTimeout` 递归调用实现更稳定的 30 FPS。
5. **可访问性**：Canvas 特效对屏幕阅读器完全不可见，符合无障碍要求；灯笼仅装饰用途，无文本语义。
