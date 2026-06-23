<template>
  <div class="home" :class="{ 'dark-mode': isDark }">
    <!-- 背景 -->
    <div class="background" :style="bgStyle"></div>
    
    <!-- 主内容 -->
    <div class="main-content">
      <!-- 左侧信息区 -->
      <div class="left-section">
        <div class="logo-section">
          <img v-if="settings.site_logo" :src="settings.site_logo" class="logo" alt="logo">
          <h1 class="site-name">{{ settings.site_name || '我的主页' }}</h1>
          <p class="site-author">{{ settings.site_author || '作者' }}</p>
        </div>
        
        <div class="info-section">
          <p class="site-desc">{{ settings.site_description || '欢迎来到我的主页' }}</p>
          
          <!-- 建站时间 -->
          <div v-if="settings.site_start && enableFeatures.siteStart" class="site-start">
            <span class="label">已运行</span>
            <span class="value">{{ siteUptime }}</span>
          </div>
        </div>

        <!-- 社交链接 -->
        <div class="social-links">
          <a v-if="settings.social_github" :href="settings.social_github" target="_blank" class="social-link">
            <img src="/images/github.svg" alt="GitHub">
          </a>
          <a v-if="settings.social_bilibili" :href="settings.social_bilibili" target="_blank" class="social-link">
            <img src="/images/bilibili.svg" alt="B站">
          </a>
          <a v-if="settings.social_twitter" :href="settings.social_twitter" target="_blank" class="social-link">
            <img src="/images/twitter.svg" alt="Twitter">
          </a>
          <a v-if="settings.social_email" :href="'mailto:' + settings.social_email" class="social-link">
            <img src="/images/email.svg" alt="Email">
          </a>
        </div>
      </div>

      <!-- 右侧功能区 -->
      <div class="right-section">
        <!-- 时间显示 -->
        <div class="time-display">
          <div class="time">{{ currentTime }}</div>
          <div class="date">{{ currentDate }}</div>
        </div>

        <!-- 天气 -->
        <div v-if="enableFeatures.weather" class="weather-card">
          <div class="weather-info">
            <span class="weather-icon">{{ weatherIcon }}</span>
            <span class="weather-temp">{{ weatherTemp }}°C</span>
            <span class="weather-desc">{{ weatherDesc }}</span>
          </div>
          <div class="weather-location">{{ weatherLocation }}</div>
        </div>

        <!-- 一言 -->
        <div v-if="enableFeatures.hitokoto" class="hitokoto">
          <p>{{ hitokoto }}</p>
        </div>

        <!-- 网站链接 -->
        <div class="site-links">
          <a v-for="(link, index) in siteLinks" :key="index" 
             :href="link.url" target="_blank" 
             class="site-link-card">
            <span class="link-name">{{ link.name }}</span>
          </a>
        </div>

        <!-- 音乐播放器 -->
        <div v-if="enableFeatures.music && settings.music_playlist_id" class="music-player">
          <button @click="toggleMusic" class="music-toggle">
            {{ isPlaying ? '⏸' : '▶' }}
          </button>
          <div class="music-info">
            <span class="music-title">{{ musicTitle }}</span>
            <span class="music-artist">{{ musicArtist }}</span>
          </div>
        </div>
      </div>
    </div>

    <!-- 底部备案信息 -->
    <div v-if="settings.icp_number" class="footer">
      <a v-if="settings.icp_number" href="https://beian.miit.gov.cn/" target="_blank" class="icp-link">
        {{ settings.icp_number }}
      </a>
      <a v-if="settings.police_number" href="https://www.beian.gov.cn/" target="_blank" class="icp-link">
        {{ settings.police_number }}
      </a>
    </div>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted, onUnmounted } from 'vue'
import axios from 'axios'

// 设置数据
const settings = ref<Record<string, string>>({
  site_name: '',
  site_author: '',
  site_description: '',
  site_logo: '',
  site_start: '',
  social_github: '',
  social_bilibili: '',
  social_twitter: '',
  social_email: '',
  icp_number: '',
  police_number: '',
  music_playlist_id: '',
  wallpaper_type: '0'
})

const enableFeatures = ref({
  weather: true,
  hitokoto: true,
  music: true,
  siteStart: true
})

// 时间相关
const currentTime = ref('')
const currentDate = ref('')
const siteUptime = ref('')
let timeInterval: ReturnType<typeof setInterval>

// 天气相关
const weatherTemp = ref('--')
const weatherDesc = ref('未知')
const weatherIcon = ref('🌤')
const weatherLocation = ref('定位中...')

// 一言
const hitokoto = ref('加载中...')

// 音乐相关
const isPlaying = ref(false)
const musicTitle = ref('未播放')
const musicArtist = ref('')

// 网站链接
const siteLinks = ref<Array<{ name: string; url: string }>>([])

// 主题
const isDark = ref(false)

// 背景样式
const bgStyle = computed(() => {
  return {
    background: 'linear-gradient(135deg, #667eea 0%, #764ba2 100%)'
  }
})

// 更新时间
function updateTime() {
  const now = new Date()
  currentTime.value = now.toLocaleTimeString('zh-CN', { hour: '2-digit', minute: '2-digit' })
  currentDate.value = now.toLocaleDateString('zh-CN', { weekday: 'long', year: 'numeric', month: 'long', day: 'numeric' })
  
  // 计算建站时间
  if (settings.value.site_start) {
    const start = new Date(settings.value.site_start)
    const diff = now.getTime() - start.getTime()
    const days = Math.floor(diff / (1000 * 60 * 60 * 24))
    siteUptime.value = `${days} 天`
  }
}

// 获取设置
async function fetchSettings() {
  try {
    const { data } = await axios.get('/api/config')
    if (data.success) {
      const allSettings: Record<string, any> = {}
      for (const group of Object.values(data.data)) {
        for (const item of group as any[]) {
          allSettings[item.key] = item.value
        }
      }
      settings.value = allSettings
      
      // 解析网站链接
      if (allSettings.site_links) {
        try {
          siteLinks.value = JSON.parse(allSettings.site_links)
        } catch {
          siteLinks.value = []
        }
      }
      
      // 解析功能开关（默认为启用状态）
      enableFeatures.value = {
        weather: allSettings.enable_weather !== 'false',
        hitokoto: allSettings.enable_hitokoto !== 'false',
        music: allSettings.enable_music !== 'false' || !!allSettings.music_playlist_id,
        siteStart: !!allSettings.site_start
      }
    }
  } catch (error) {
    console.error('获取设置失败:', error)
  }
}

// 获取一言
async function fetchHitokoto() {
  try {
    const { data } = await axios.get('https://v1.hitokoto.cn/?encode=json')
    hitokoto.value = data.hitokoto
  } catch {
    hitokoto.value = '生活不止眼前的苟且，还有诗和远方~'
  }
}

// 获取天气
async function fetchWeather() {
  try {
    // 使用高德 IP 定位
    const key = settings.value.weather_gd_key || 'your-key'
    const { data: locationData } = await axios.get(`https://restapi.amap.com/v3/ip?key=${key}`)
    
    if (locationData.city) {
      weatherLocation.value = locationData.city
      
      // 获取天气
      const { data: weatherData } = await axios.get(
        `https://restapi.amap.com/v3/weather/weatherInfo?city=${locationData.adcode}&key=${key}`
      )
      
      if (weatherData.lives && weatherData.lives[0]) {
        const weather = weatherData.lives[0]
        weatherTemp.value = weather.temperature
        weatherDesc.value = weather.weather
        
        // 设置天气图标
        const weatherCode = weather.weather
        if (weatherCode.includes('晴')) weatherIcon.value = '☀️'
        else if (weatherCode.includes('阴')) weatherIcon.value = '☁️'
        else if (weatherCode.includes('雨')) weatherIcon.value = '🌧️'
        else if (weatherCode.includes('雪')) weatherIcon.value = '❄️'
        else if (weatherCode.includes('雷')) weatherIcon.value = '⛈️'
        else weatherIcon.value = '🌤️'
      }
    }
  } catch {
    weatherLocation.value = '定位失败'
  }
}

// 音乐控制
function toggleMusic() {
  isPlaying.value = !isPlaying.value
}

onMounted(() => {
  updateTime()
  timeInterval = setInterval(updateTime, 1000)
  
  fetchSettings().then(() => {
    if (enableFeatures.value.hitokoto) fetchHitokoto()
    if (enableFeatures.value.weather) fetchWeather()
  })
})

onUnmounted(() => {
  clearInterval(timeInterval)
})
</script>

<style lang="scss" scoped>
.home {
  min-height: 100vh;
  color: #fff;
  position: relative;
  overflow: hidden;
}

.background {
  position: fixed;
  top: 0;
  left: 0;
  width: 100%;
  height: 100%;
  z-index: -1;
}

.main-content {
  display: flex;
  min-height: calc(100vh - 60px);
  padding: 2rem;
  max-width: 1400px;
  margin: 0 auto;
}

.left-section {
  flex: 1;
  display: flex;
  flex-direction: column;
  justify-content: center;
  padding: 2rem;
}

.logo-section {
  text-align: center;
  margin-bottom: 2rem;
  
  .logo {
    width: 100px;
    height: 100px;
    border-radius: 50%;
    object-fit: cover;
    margin-bottom: 1rem;
  }
  
  .site-name {
    font-size: 2.5rem;
    font-weight: 600;
    margin-bottom: 0.5rem;
  }
  
  .site-author {
    font-size: 1.2rem;
    opacity: 0.8;
  }
}

.info-section {
  text-align: center;
  margin-bottom: 2rem;
  
  .site-desc {
    font-size: 1.1rem;
    line-height: 1.6;
    opacity: 0.9;
    margin-bottom: 1rem;
  }
  
  .site-start {
    display: inline-flex;
    align-items: center;
    gap: 0.5rem;
    padding: 0.5rem 1rem;
    background: rgba(255, 255, 255, 0.1);
    border-radius: 2rem;
    font-size: 0.9rem;
    
    .label {
      opacity: 0.7;
    }
  }
}

.social-links {
  display: flex;
  justify-content: center;
  gap: 1rem;
  
  .social-link {
    width: 40px;
    height: 40px;
    display: flex;
    align-items: center;
    justify-content: center;
    background: rgba(255, 255, 255, 0.1);
    border-radius: 50%;
    transition: transform 0.3s, background 0.3s;
    
    &:hover {
      transform: scale(1.1);
      background: rgba(255, 255, 255, 0.2);
    }
    
    img {
      width: 24px;
      height: 24px;
    }
  }
}

.right-section {
  flex: 1;
  display: flex;
  flex-direction: column;
  justify-content: center;
  padding: 2rem;
  gap: 1.5rem;
}

.time-display {
  text-align: center;
  
  .time {
    font-size: 4rem;
    font-weight: 300;
    font-family: 'SF Pro Display', -apple-system, BlinkMacSystemFont, sans-serif;
  }
  
  .date {
    font-size: 1.1rem;
    opacity: 0.8;
    margin-top: 0.5rem;
  }
}

.weather-card {
  background: rgba(255, 255, 255, 0.1);
  backdrop-filter: blur(10px);
  border-radius: 1rem;
  padding: 1.5rem;
  text-align: center;
  
  .weather-info {
    display: flex;
    align-items: center;
    justify-content: center;
    gap: 1rem;
    margin-bottom: 0.5rem;
    
    .weather-icon {
      font-size: 2rem;
    }
    
    .weather-temp {
      font-size: 2rem;
      font-weight: 600;
    }
    
    .weather-desc {
      font-size: 1.1rem;
      opacity: 0.9;
    }
  }
  
  .weather-location {
    font-size: 0.9rem;
    opacity: 0.7;
  }
}

.hitokoto {
  background: rgba(255, 255, 255, 0.05);
  border-radius: 1rem;
  padding: 1.5rem;
  text-align: center;
  font-size: 1.1rem;
  line-height: 1.6;
  font-style: italic;
}

.site-links {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(120px, 1fr));
  gap: 1rem;
  
  .site-link-card {
    background: rgba(255, 255, 255, 0.1);
    border-radius: 0.75rem;
    padding: 1rem;
    text-align: center;
    color: #fff;
    text-decoration: none;
    transition: transform 0.3s, background 0.3s;
    
    &:hover {
      transform: translateY(-5px);
      background: rgba(255, 255, 255, 0.2);
    }
    
    .link-name {
      font-size: 1rem;
    }
  }
}

.music-player {
  display: flex;
  align-items: center;
  gap: 1rem;
  background: rgba(255, 255, 255, 0.1);
  border-radius: 1rem;
  padding: 1rem;
  
  .music-toggle {
    width: 50px;
    height: 50px;
    border-radius: 50%;
    border: none;
    background: rgba(255, 255, 255, 0.2);
    font-size: 1.5rem;
    cursor: pointer;
    transition: background 0.3s;
    
    &:hover {
      background: rgba(255, 255, 255, 0.3);
    }
  }
  
  .music-info {
    flex: 1;
    display: flex;
    flex-direction: column;
    
    .music-title {
      font-size: 1rem;
      font-weight: 500;
    }
    
    .music-artist {
      font-size: 0.85rem;
      opacity: 0.7;
    }
  }
}

.footer {
  position: fixed;
  bottom: 0;
  left: 0;
  right: 0;
  padding: 1rem;
  text-align: center;
  display: flex;
  justify-content: center;
  gap: 1rem;
  
  .icp-link {
    color: rgba(255, 255, 255, 0.6);
    text-decoration: none;
    font-size: 0.85rem;
    
    &:hover {
      color: #fff;
    }
  }
}

@media (max-width: 768px) {
  .main-content {
    flex-direction: column;
  }
  
  .time-display .time {
    font-size: 3rem;
  }
}
</style>
