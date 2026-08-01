<template>
  <!-- 统一图标渲染组件：支持三种格式 -->
  <span class="web-icon" :style="{ width: size + 'px', height: size + 'px' }">
    <!-- 1. 预设名（向后兼容老数据，使用本地 @vicons/fa 组件，性能最佳） -->
    <component v-if="presetComp" :is="presetComp" />

    <!-- 2. Iconify 网络图标库：prefix:name 格式 -->
    <span
      v-else-if="isIconify"
      class="iconify-inline"
      v-html="svgCache"
      :style="{ width: '100%', height: '100%', color: 'currentColor' }"
    />

    <!-- 3. 图片路径：以 / 或 http(s):// 开头 -->
    <img
      v-else
      :src="icon"
      :style="{ width: '100%', height: '100%', objectFit: 'contain' }"
      @error="onImgError"
    />
  </span>
</template>

<script setup lang="ts">
import {
  Blog,
  Cloud,
  CompactDisc,
  Compass,
  Book,
  Fire,
  LaptopCode,
  Link as LinkIcon,
} from "@vicons/fa";

const props = withDefaults(
  defineProps<{
    icon: string;
    size?: number;
  }>(),
  { size: 24 }
);

// 预设图标映射：保持向后兼容（老数据 icon: "Blog" 等）
const PRESET_MAP: Record<string, unknown> = {
  Blog,
  Cloud,
  CompactDisc,
  Compass,
  Book,
  Fire,
  LaptopCode,
};

const presetComp = computed(() => PRESET_MAP[props.icon]);

// Iconify 格式判断：prefix:name（如 fa:github、mdi:home、tabler:brand-github）
const isIconify = computed(
  () =>
    !presetComp.value &&
    /^[a-z0-9-]+:[a-z0-9-]+$/.test(props.icon) &&
    !props.icon.startsWith("http")
);

// 图片路径：以 / 或 http(s):// 开头
const isImage = computed(
  () => !presetComp.value && !isIconify.value
);

const svgCache = ref("");
// 模块级缓存，避免同图标重复请求
const iconSvgCache: Record<string, string> = {};
// 加载中的图标集合，避免并发重复请求
const loadingSet = new Set<string>();
// 失败兜底图标（使用本地 Link 图标，避免空白）
const fallbackSvg = `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="currentColor"><path d="M3.9 12c0-1.71 1.39-3.1 3.1-3.1h4V7H7c-2.76 0-5 2.24-5 5s2.24 5 5 5h4v-1.9H7c-1.71 0-3.1-1.39-3.1-3.1zM8 13h8v-2H8v2zm9-6h-4v1.9h4c1.71 0 3.1 1.39 3.1 3.1s-1.39 3.1-3.1 3.1h-4V17h4c2.76 0 5-2.24 5-5s-2.24-5-5-5z"/></svg>`;

const loadIconifySvg = async (icon: string) => {
  // 命中缓存
  if (iconSvgCache[icon]) {
    svgCache.value = iconSvgCache[icon];
    return;
  }
  // 避免并发重复请求
  if (loadingSet.has(icon)) return;
  loadingSet.add(icon);

  try {
    // color=currentColor 让图标继承父元素文字颜色，可随主题切换
    const resp = await fetch(
      `https://api.iconify.design/${icon}.svg?color=currentColor`
    );
    if (resp.ok) {
      const svg = await resp.text();
      // 简单校验返回内容是 SVG
      if (svg.startsWith("<svg")) {
        iconSvgCache[icon] = svg;
        svgCache.value = svg;
        return;
      }
    }
    iconSvgCache[icon] = fallbackSvg;
    svgCache.value = fallbackSvg;
  } catch (e) {
    console.warn("[WebIcon] Iconify 加载失败:", icon, e);
    iconSvgCache[icon] = fallbackSvg;
    svgCache.value = fallbackSvg;
  } finally {
    loadingSet.delete(icon);
  }
};

watch(
  () => props.icon,
  async (icon) => {
    if (isIconify.value) {
      await loadIconifySvg(icon);
    }
  },
  { immediate: true }
);

// 图片加载失败时回退到 Link 图标
const onImgError = (e: Event) => {
  const img = e.target as HTMLImageElement;
  if (img.src !== fallbackSvg) {
    img.src =
      "data:image/svg+xml;base64," +
      btoa(fallbackSvg);
  }
};

// 暴露 isImage 供父组件判断（虽然当前未使用，保留扩展点）
defineExpose({ isImage, isIconify, presetComp });
</script>

<style scoped>
.web-icon {
  display: inline-flex;
  align-items: center;
  justify-content: center;
}

.iconify-inline {
  display: inline-flex;
}

.iconify-inline :deep(svg) {
  width: 100%;
  height: 100%;
}
</style>
