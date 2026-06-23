<template>
  <div class="admin-layout">
    <el-config-provider :locale="zhCn">
      <!-- 登录页面 -->
      <div v-if="!isLoggedIn" class="login-container">
        <el-card class="login-card">
          <template #header>
            <div class="card-header">
              <span>Home-SXLB 管理后台</span>
            </div>
          </template>
          <el-form :model="loginForm" :rules="loginRules" ref="loginFormRef">
            <el-form-item prop="username">
              <el-input v-model="loginForm.username" placeholder="用户名" prefix-icon="User" />
            </el-form-item>
            <el-form-item prop="password">
              <el-input v-model="loginForm.password" type="password" placeholder="密码" prefix-icon="Lock" @keyup.enter="handleLogin" />
            </el-form-item>
            <el-form-item>
              <el-button type="primary" :loading="loading" style="width: 100%" @click="handleLogin">
                登 录
              </el-button>
            </el-form-item>
          </el-form>
          <div class="login-tip">
            默认账号: admin / admin123
          </div>
        </el-card>
      </div>

      <!-- 管理后台 -->
      <div v-else class="main-container">
        <!-- 侧边栏 -->
        <el-aside width="200px" class="sidebar">
          <div class="logo">
            <h3>Home-SXLB</h3>
            <p>管理后台</p>
          </div>
          <el-menu :default-active="activeMenu" router class="sidebar-menu">
            <el-menu-item index="/admin/dashboard">
              <el-icon><DataAnalysis /></el-icon>
              <span>仪表盘</span>
            </el-menu-item>
            <el-menu-item index="/admin/settings">
              <el-icon><Setting /></el-icon>
              <span>站点设置</span>
            </el-menu-item>
            <el-menu-item index="/admin/upload">
              <el-icon><Upload /></el-icon>
              <span>文件管理</span>
            </el-menu-item>
            <el-menu-item index="/admin/update">
              <el-icon><Refresh /></el-icon>
              <span>版本更新</span>
            </el-menu-item>
            <el-menu-item index="/admin/system">
              <el-icon><Tools /></el-icon>
              <span>系统设置</span>
            </el-menu-item>
            <el-menu-item @click="handleLogout">
              <el-icon><SwitchButton /></el-icon>
              <span>退出登录</span>
            </el-menu-item>
          </el-menu>
        </el-aside>

        <!-- 主内容 -->
        <el-container class="content-wrapper">
          <el-header class="header">
            <div class="header-title">{{ pageTitle }}</div>
            <div class="header-actions">
              <el-tag type="success">v{{ systemInfo.appVersion }}</el-tag>
              <el-button link @click="openSite">访问前台</el-button>
            </div>
          </el-header>
          <el-main>
            <router-view />
          </el-main>
        </el-container>
      </div>
    </el-config-provider>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted } from 'vue'
import { useRouter, useRoute } from 'vue-router'
import { ElMessage } from 'element-plus'
import { DataAnalysis, Setting, Upload, Refresh, Tools, SwitchButton, User, Lock } from '@element-plus/icons-vue'
import zhCn from 'element-plus/es/locale/lang/zh-cn'
import axios from 'axios'

const router = useRouter()
const route = useRoute()

// 登录状态
const isLoggedIn = ref(false)
const loading = ref(false)
const loginFormRef = ref()
const token = ref(localStorage.getItem('admin_token') || '')

// 登录表单
const loginForm = ref({
  username: '',
  password: ''
})

const loginRules = {
  username: [{ required: true, message: '请输入用户名', trigger: 'blur' }],
  password: [{ required: true, message: '请输入密码', trigger: 'blur' }]
}

// 系统信息
const systemInfo = ref({
  appVersion: '1.0.0',
  nodeVersion: '',
  uptime: 0,
  settingsCount: 0
})

// 页面标题
const pageTitle = computed(() => {
  const titles: Record<string, string> = {
    '/admin/dashboard': '仪表盘',
    '/admin/settings': '站点设置',
    '/admin/upload': '文件管理',
    '/admin/update': '版本更新',
    '/admin/system': '系统设置'
  }
  return titles[route.path] || '管理后台'
})

// 当前菜单
const activeMenu = computed(() => route.path)

// 检查登录状态
async function checkAuth() {
  if (!token.value) return false
  try {
    const { data } = await axios.get('/api/auth/me', {
      headers: { Authorization: `Bearer ${token.value}` }
    })
    return data.success
  } catch {
    return false
  }
}

// 登录
async function handleLogin() {
  if (!loginFormRef.value) return
  await loginFormRef.value.validate(async (valid: boolean) => {
    if (!valid) return
    
    loading.value = true
    try {
      const { data } = await axios.post('/api/auth/login', loginForm.value)
      if (data.success) {
        token.value = data.data.token
        localStorage.setItem('admin_token', data.data.token)
        isLoggedIn.value = true
        ElMessage.success('登录成功')
        await fetchSystemInfo()
      } else {
        ElMessage.error(data.message || '登录失败')
      }
    } catch (error: any) {
      ElMessage.error(error.response?.data?.message || '登录失败')
    } finally {
      loading.value = false
    }
  })
}

// 登出
function handleLogout() {
  token.value = ''
  localStorage.removeItem('admin_token')
  isLoggedIn.value = false
  ElMessage.success('已退出登录')
}

// 获取系统信息
async function fetchSystemInfo() {
  try {
    const { data } = await axios.get('/api/system/info', {
      headers: { Authorization: `Bearer ${token.value}` }
    })
    if (data.success) {
      systemInfo.value = data.data
    }
  } catch (error) {
    console.error('获取系统信息失败:', error)
  }
}

// 访问前台
function openSite() {
  window.open('/', '_blank')
}

// 初始化
onMounted(async () => {
  if (token.value) {
    const authed = await checkAuth()
    if (authed) {
      isLoggedIn.value = true
      await fetchSystemInfo()
    } else {
      token.value = ''
      localStorage.removeItem('admin_token')
    }
  }
})
</script>

<style lang="scss" scoped>
.admin-layout {
  height: 100vh;
  width: 100vw;
}

.login-container {
  height: 100%;
  display: flex;
  align-items: center;
  justify-content: center;
  background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
  
  .login-card {
    width: 400px;
    
    .card-header {
      text-align: center;
      font-size: 1.2rem;
      font-weight: 600;
    }
    
    .login-tip {
      text-align: center;
      color: #999;
      font-size: 0.85rem;
      margin-top: 1rem;
    }
  }
}

.main-container {
  display: flex;
  height: 100%;
}

.sidebar {
  background: #fff;
  box-shadow: 2px 0 8px rgba(0, 0, 0, 0.1);
  
  .logo {
    padding: 1.5rem;
    text-align: center;
    border-bottom: 1px solid #eee;
    
    h3 {
      margin: 0;
      color: #409eff;
    }
    
    p {
      margin: 0.5rem 0 0;
      font-size: 0.85rem;
      color: #999;
    }
  }
  
  .sidebar-menu {
    border-right: none;
  }
}

.content-wrapper {
  flex: 1;
  flex-direction: column;
  
  .header {
    background: #fff;
    box-shadow: 0 2px 8px rgba(0, 0, 0, 0.1);
    display: flex;
    align-items: center;
    justify-content: space-between;
    padding: 0 1.5rem;
    
    .header-title {
      font-size: 1.2rem;
      font-weight: 600;
    }
    
    .header-actions {
      display: flex;
      align-items: center;
      gap: 1rem;
    }
  }
  
  .el-main {
    background: #f5f7fa;
    overflow-y: auto;
  }
}
</style>
