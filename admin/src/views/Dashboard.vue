<template>
  <div class="dashboard">
    <!-- 统计卡片 -->
    <el-row :gutter="20" class="stat-cards">
      <el-col :span="6">
        <el-card shadow="hover">
          <div class="stat-item">
            <el-icon class="stat-icon" color="#409eff"><Setting /></el-icon>
            <div class="stat-info">
              <p class="stat-value">{{ stats.settingsCount }}</p>
              <p class="stat-label">配置项</p>
            </div>
          </div>
        </el-card>
      </el-col>
      <el-col :span="6">
        <el-card shadow="hover">
          <div class="stat-item">
            <el-icon class="stat-icon" color="#67c23a"><Clock /></el-icon>
            <div class="stat-info">
              <p class="stat-value">{{ uptime }}</p>
              <p class="stat-label">运行时长</p>
            </div>
          </div>
        </el-card>
      </el-col>
      <el-col :span="6">
        <el-card shadow="hover">
          <div class="stat-item">
            <el-icon class="stat-icon" color="#e6a23c"><Cpu /></el-icon>
            <div class="stat-info">
              <p class="stat-value">{{ stats.nodeVersion }}</p>
              <p class="stat-label">Node 版本</p>
            </div>
          </div>
        </el-card>
      </el-col>
      <el-col :span="6">
        <el-card shadow="hover">
          <div class="stat-item">
            <el-icon class="stat-icon" color="#f56c6c"><Database /></el-icon>
            <div class="stat-info">
              <p class="stat-value">{{ stats.databaseSize }}</p>
              <p class="stat-label">数据库大小</p>
            </div>
          </div>
        </el-card>
      </el-col>
    </el-row>

    <!-- 版本信息 -->
    <el-card class="version-card">
      <template #header>
        <div class="card-header">
          <span>版本信息</span>
          <el-button type="primary" link @click="$router.push('/admin/update')">检查更新</el-button>
        </div>
      </template>
      <div class="version-info">
        <el-descriptions :column="2" border>
          <el-descriptions-item label="当前版本">
            <el-tag type="success">v{{ stats.appVersion }}</el-tag>
          </el-descriptions-item>
          <el-descriptions-item label="最新版本">
            <el-tag v-if="updateInfo.latest" type="success">已是最新</el-tag>
            <el-tag v-else type="warning">v{{ updateInfo.latestVersion }}</el-tag>
          </el-descriptions-item>
          <el-descriptions-item label="平台">{{ stats.platform }}</el-descriptions-item>
          <el-descriptions-item label="数据目录">{{ stats.dataPath }}</el-descriptions-item>
        </el-descriptions>
      </div>
    </el-card>

    <!-- 快速操作 -->
    <el-card class="quick-actions">
      <template #header>
        <span>快速操作</span>
      </template>
      <el-space wrap>
        <el-button type="primary" @click="$router.push('/admin/settings')">站点设置</el-button>
        <el-button type="success" @click="$router.push('/admin/upload')">上传图片</el-button>
        <el-button type="warning" @click="$router.push('/admin/system')">系统设置</el-button>
        <el-button @click="exportConfig">导出配置</el-button>
        <el-button @click="refreshData">刷新数据</el-button>
      </el-space>
    </el-card>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted } from 'vue'
import { ElMessage } from 'element-plus'
import { Setting, Clock, Cpu, Database } from '@element-plus/icons-vue'
import axios from 'axios'

const token = localStorage.getItem('admin_token')

const stats = ref({
  appVersion: '1.0.0',
  nodeVersion: '',
  uptime: 0,
  settingsCount: 0,
  databaseSize: '0 B',
  platform: ''
})

const updateInfo = ref({
  latest: true,
  latestVersion: ''
})

const uptime = computed(() => {
  const seconds = stats.value.uptime
  const days = Math.floor(seconds / 86400)
  const hours = Math.floor((seconds % 86400) / 3600)
  const minutes = Math.floor((seconds % 3600) / 60)
  return `${days}天 ${hours}小时 ${minutes}分`
})

async function fetchStats() {
  try {
    const { data } = await axios.get('/api/system/info', {
      headers: { Authorization: `Bearer ${token}` }
    })
    if (data.success) {
      stats.value = data.data
    }
  } catch (error) {
    console.error('获取统计数据失败:', error)
  }
}

async function fetchUpdateInfo() {
  try {
    const { data } = await axios.get('/api/update/check', {
      headers: { Authorization: `Bearer ${token}` }
    })
    if (data.success) {
      updateInfo.value = data.data
    }
  } catch (error) {
    console.error('获取更新信息失败:', error)
  }
}

async function exportConfig() {
  try {
    const { data } = await axios.get('/api/system/export', {
      headers: { Authorization: `Bearer ${token}` }
    })
    if (data.success) {
      const blob = new Blob([JSON.stringify(data.data, null, 2)], { type: 'application/json' })
      const url = URL.createObjectURL(blob)
      const a = document.createElement('a')
      a.href = url
      a.download = `home-sxlb-config-${new Date().toISOString().slice(0, 10)}.json`
      a.click()
      URL.revokeObjectURL(url)
      ElMessage.success('配置导出成功')
    }
  } catch (error) {
    ElMessage.error('导出失败')
  }
}

function refreshData() {
  fetchStats()
  fetchUpdateInfo()
  ElMessage.success('已刷新')
}

onMounted(() => {
  fetchStats()
  fetchUpdateInfo()
})
</script>

<style lang="scss" scoped>
.dashboard {
  .stat-cards {
    margin-bottom: 20px;
    
    .stat-item {
      display: flex;
      align-items: center;
      gap: 1rem;
      
      .stat-icon {
        font-size: 2.5rem;
      }
      
      .stat-info {
        .stat-value {
          font-size: 1.5rem;
          font-weight: 600;
          margin: 0;
        }
        
        .stat-label {
          font-size: 0.85rem;
          color: #999;
          margin: 0.5rem 0 0;
        }
      }
    }
  }
  
  .version-card, .quick-actions {
    margin-bottom: 20px;
    
    .card-header {
      display: flex;
      justify-content: space-between;
      align-items: center;
    }
  }
}
</style>
