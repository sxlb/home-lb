# 無名の主页 项目文档

本目录是 `無名の主页`（EFU 维护版本）的完整开发文档，旨在为开发者提供从架构到实现的全面说明。

## 文档索引

| 文档 | 说明 |
| --- | --- |
| [01 - 项目总览](./01-overview.md) | 项目简介、版本信息、目录结构、启动流程 |
| [02 - 架构与技术栈](./02-architecture.md) | 整体架构、技术栈选型、构建配置、模块划分 |
| [03 - 配置系统](./03-config.md) | 运行时配置 / 编译时配置 / 示例配置三级回退机制 |
| [04 - 状态管理](./04-store.md) | Pinia store 设计、持久化策略、校验插件 |
| [05 - 组件详解](./05-components.md) | 所有 `.vue` 组件的职责、Props、交互逻辑 |
| [06 - 视图与路由](./06-views.md) | 视图目录组织与页面布局 |
| [07 - 工具函数](./07-utils.md) | `src/utils` 下所有工具模块的逐个说明 |
| [08 - API 集成与鉴权](./08-api.md) | 音乐、天气、一言、IP 定位等接口及其签名算法 |
| [09 - 歌词系统](./09-lyrics.md) | 逐字歌词（DWRC/YRC/QRC）解析与同步渲染 |
| [10 - 天气系统](./10-weather.md) | 多源天气数据聚合与降级策略 |
| [11 - 语音系统](./11-speech.md) | Azure TTS 集成、本地音频回退与队列播放 |
| [12 - 季节特效](./12-season.md) | 雪花、萤火虫、灯笼 Canvas 动画 |
| [13 - 部署与运行](./13-deployment.md) | 环境变量、构建、PWA、Docker 部署 |
| [14 - 管理后台](./14-admin.md) | admin-server 运行时配置管理、API、UI、鉴权与部署 |

## 阅读建议

- 初次接触本项目者，建议按 `01 → 02 → 03` 顺序阅读，了解整体结构与配置方式。
- 二次开发者，可直接定位到目标模块（组件 / 工具 / API 等）。
- 想要了解特定功能实现细节者，可参考 `09 ~ 12` 的专项文档。

## 术语约定

- **DWRC**：Dynamic Word-by-word Render Caption，本项目中指逐字歌词数据结构。
- **YRC / QRC**：网易云 / QQ 音乐的逐字歌词原始格式。
- **AMLL TTML Database**：Apple Music Like Lyrics 社区维护的歌词数据库。
- **酪灰 / NanoRocky**：EFU 维护版本的作者自称。
- **`envConfig`**：由 `src/utils/config_check.ts` 暴露的全局配置代理对象。
- **`store`**：由 `src/store/index.ts` 定义的 Pinia 主仓库。
