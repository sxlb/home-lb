import { createI18n } from "vue-i18n";
import zhCN from "./locales/zh-CN.json";
import en from "./locales/en.json";

export type AppLanguage = "zh-CN" | "en";

/**
 * 检测用户语言
 * 优先级：localStorage > navigator.language > 默认 zh-CN
 */
export function detectLanguage(): AppLanguage {
  const saved = localStorage.getItem("language");
  if (saved === "zh-CN" || saved === "en") return saved;
  return navigator.language.startsWith("zh") ? "zh-CN" : "en";
}

const i18n = createI18n({
  legacy: false,
  locale: detectLanguage(),
  fallbackLocale: "zh-CN",
  messages: {
    "zh-CN": zhCN,
    en,
  },
});

export default i18n;
