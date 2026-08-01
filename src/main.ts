import { createApp } from "vue";
import i18n from "@/i18n";
import config from "@/../package.json";
import "@/style/style.scss";
import App from "@/App.vue";
import { mainStore } from "@/store";
import { Speech, stopSpeech, SpeechLocal } from "@/utils/speech";
import { validationPlugin } from "@/store/plugins/validation";
import { loadRuntimeConfig } from "@/utils/config_check";
// 引入 pinia
import { createPinia } from 'pinia';
import piniaPluginPersistedstate from 'pinia-plugin-persistedstate';
// Element Plus
import { ElMessage, ElMessageBox } from "element-plus";
import "element-plus/dist/index.css";
// swiper
import "swiper/css";
import "uno.css";

const app = createApp(App);
const pinia = createPinia();

export default pinia;
pinia.use(piniaPluginPersistedstate);
pinia.use(validationPlugin);
app.use(pinia);
app.use(i18n);

const mountApp = () => {
  const appEl = document.getElementById("app");
  if (appEl) {
    appEl.style.display = "block";
  };
  app.mount("#app");
  const store = mainStore();

  const urlParams = new URLSearchParams(window.location.search);
  if (urlParams.get("set") === "reset") {
    ElMessage({
      dangerouslyUseHTMLString: true,
      message: `正在恢复默认配置，请稍后...`,
    });
    if (store.webSpeech) {
      stopSpeech();
      const voice = envConfig.VITE_TTS_Voice;
      const vstyle = envConfig.VITE_TTS_Style;
      SpeechLocal("重置2.mp3");
    };
    store.resetStore();
  };

  // PWA
  navigator.serviceWorker.addEventListener("controllerchange", async () => {
    // 弹出更新提醒
    console.log("网站已更新，请刷新网页嗷！");
    ElMessage("网站已更新，请刷新网页嗷！");
    if (store.webSpeech) {
      stopSpeech();
      const voice = envConfig.VITE_TTS_Voice;
      const vstyle = envConfig.VITE_TTS_Style;
      SpeechLocal("更新提示.mp3");
    };
  });

  const setupset = () => setTimeout(() => {
    if (urlParams.get("set") != "reset" && store.imgLoadStatus === true) {
      if (urlParams.get("bg")) {
        store.coverType = Number(urlParams.get("bg"));
      };
      if (urlParams.get("bgc") && (store.coverType == 0 || urlParams.get("bg") == "0")) {
        store.sBGCount = String(urlParams.get("bgc"));
      };
      if (urlParams.get("devs")) {
        store.setV = Boolean(urlParams.get("devs"));
      };
      if (urlParams.get("pap")) {
        store.playerAutoplay = Boolean(urlParams.get("pap"));
      };
    } else {
      setupset();
    };
  }, 300);

  setupset();
};

// 启动流程：先加载运行时配置，再挂载应用
(async () => {
  // 加载运行时配置（失败会自动回退到编译时配置）
  await loadRuntimeConfig();

  if (!envConfig.VITE_CONFIG_TURN || envConfig.VITE_CONFIG_TURN != "true") {
    const appEl = document.getElementById("app");
    if (appEl) {
      appEl.style.display = "none";
    };
    console.error(`警告：您似乎没有启用配置文件，项目可能出现异常！请配置 .env 或 runtime-config.json 文件后再运行项目！`);
    ElMessageBox.confirm(
      '检测到您似乎没有创建配置文件，项目可能出现异常！',
      '警告',
      {
        confirmButtonText: '继续',
        cancelButtonText: '取消',
        type: 'warning',
      }
    )
      .then(() => {
        mountApp();
      })
      .catch(() => {
        ElMessage({
          type: 'info',
          message: '已取消',
        })
      });
  } else {
    /* 原本这里的逻辑是..如果作者信息被修改，则停止项目运行。原本是想拦没有代码更改但删除作者信息直接倒卖的人，因为但凡是个会一点代码的人不可能不会解决这点小问题。这在技术上几乎没有一点防护效果。
    但是看到确实有用户修改后，思考了一阵，这好像和 MIT 开源文化有冲突...且 MIT 本身也就允许倒卖这种行为叭..（
    最后..还是决定将这里的完全不运行改成显示提示后继续正常工作，更合理些叭...理解万岁！
    另外，也请求各位不要随意移除原作者信息，谢谢！ */
    if (config.author != 'imsyy' || config.efua != 'NanoRocky') {
      console.warn(`Warning: Somethings error ... , The original author information for this project has been modified. If this was not done by you, please delete the file and download the project code package again. If this was done by you, please do not modify or remove the original author information. Thank you! Of course, you can also choose to ignore this message.`);
      console.log('Original repository link: https://github.com/NanoRocky/home/blob/EFU/');
      mountApp();
    } else {
      mountApp();
    };
  };
})();
