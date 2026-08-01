import exampleConfig from '@/assets/example_config.json';
type Env = ImportMetaEnv;

// 运行时配置缓存（由 loadRuntimeConfig 写入）
let runtimeConfig: Record<string, any> | null = null;

/**
 * 从 /runtime-config.json 加载运行时配置
 * 加载失败时回退到编译时 .env 配置，保证兼容性
 * 必须在应用 mount 前调用
 */
export async function loadRuntimeConfig(): Promise<void> {
    try {
        const resp = await fetch('/runtime-config.json', { cache: 'no-cache' });
        if (resp.ok) {
            runtimeConfig = await resp.json() as Record<string, string>;
            console.log('[config] 运行时配置加载成功');
        } else {
            console.warn('[config] 运行时配置加载失败：HTTP', resp.status, '，回退到编译时配置');
        }
    } catch (e) {
        console.warn('[config] 运行时配置加载异常，回退到编译时配置：', e);
    }
}

// 取值工具：优先运行时配置 > 编译时 .env > example_config.json
const pick = (key: string): string => {
    if (runtimeConfig && runtimeConfig[key] !== undefined && runtimeConfig[key] !== '') {
        return runtimeConfig[key] as string;
    }
    const envTurnedOn = import.meta.env.VITE_CONFIG_TURN == 'true';
    if (envTurnedOn) {
        const v = (import.meta.env as Record<string, string>)[key];
        if (v !== undefined && v !== '') return v;
    }
    return (exampleConfig as Record<string, string>)[key] ?? '';
};

// VITE_ 配置键列表
const viteKeys = [
    'VITE_CONFIG_TURN',
    'VITE_SITE_NAME',
    'VITE_SITE_AUTHOR',
    'VITE_SITE_KEYWORDS',
    'VITE_SITE_DES',
    'VITE_SITE_URL',
    'VITE_SITE_MAIN_NAME',
    'VITE_SITE_LOGO',
    'VITE_SITE_MAIN_LOGO',
    'VITE_SITE_APPLE_LOGO',
    'VITE_DESC_HELLO',
    'VITE_DESC_TEXT',
    'VITE_DESC_HELLO_OTHER',
    'VITE_DESC_TEXT_OTHER',
    'VITE_TX_WEATHER_KEY',
    'VITE_GD_WEATHER_KEY',
    'VITE_SITE_START',
    'VITE_SITE_ICP',
    'VITE_SITE_MPS',
    'VITE_SITE_MICP',
    'VITE_SONG_API',
    'VITE_SONG_SERVER',
    'VITE_SONG_SERVER_SECOND',
    'VITE_SONG_TYPE',
    'VITE_SONG_ID',
    'VITE_SONG_ID_SECOND',
    'VITE_TTS_API',
    'VITE_TTS_Voice',
    'VITE_TTS_Style',
    'VITE_TTS_SKEY',
    'VITE_TX_WEATHER_SKEY',
    'VITE_METING_SKEY',
    'VITE_SFILE_SKEY',
];

// 使用 Proxy 让 envConfig 动态响应运行时配置的加载
// 这样在 loadRuntimeConfig() 完成后，所有访问都会得到最新的值
export const envConfig: Env = new Proxy({} as Env, {
    get(_target, prop: string) {
        // vite 内置变量直接返回
        if (prop === 'BASE_URL') return import.meta.env.BASE_URL;
        if (prop === 'MODE') return import.meta.env.MODE;
        if (prop === 'DEV') return import.meta.env.DEV;
        if (prop === 'PROD') return import.meta.env.PROD;
        if (prop === 'SSR') return import.meta.env.SSR;
        // VITE_ 配置项动态读取
        if (viteKeys.includes(prop)) {
            return pick(prop);
        }
        // 其他 import.meta.env 属性
        return (import.meta.env as Record<string, unknown>)[prop];
    },
});

/**
 * 读取后台配置的前端设置默认值（对象类型，存储在 runtime-config.json 的 defaults 字段）
 * 必须在 loadRuntimeConfig() 完成后调用
 * 返回空对象时表示未配置，使用代码默认值
 */
export function getDefaults(): Record<string, any> {
    if (runtimeConfig && runtimeConfig.defaults && typeof runtimeConfig.defaults === 'object') {
        return runtimeConfig.defaults as Record<string, any>;
    }
    return {};
}