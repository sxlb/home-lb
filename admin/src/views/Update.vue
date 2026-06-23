<template>
  <div class="update-page">
    <!-- 版本状态 -->
    <el-card class="version-status">
      <el-descriptions :column="3" border>
        <el-descriptions-item label="当前版本">
          <el-tag type="success">v{{ versionInfo.currentVersion }}</el-tag>
        </el-descriptions-item>
        <el-descriptions-item label="最新版本">
          <el-tag v-if="versionInfo.latest" type="success">已是最新</el-tag>
          <el-tag v-else type="warning">v{{ versionInfo.latestVersion }}</el-tag>
        </el-descriptions-item>
        <el-descriptions-item label="检查时间">
          {{ checkTime }}
        </el-descriptions-item>
      </el-descriptions>
      
      <div class="version-actions">
        <el-button type="primary" @click="checkUpdate" :loading="checking">检查更新</el-button>
        <el-button v-if="!versionInfo.latest" type="success" @click="doUpdate" :loading="updating">
          一键更新到 v{{ versionInfo.latestVersion }}
        </el-button>
      </div>
    </el-card>

    <!-- 更新日志 -->
    <el-card v-if="versionInfo.releaseNotes" class="changelog-card">
      <template #header>
        <span>更新日志</span>
      </template>
      <div class="changelog-content">
        <pre>{{ versionInfo.releaseNotes }}</pre>
      </div>
    </el-card>

    <!-- 版本历史 -->
    <el-card class="history-card">
      <template #header>
        <div class="card-header">
          <span>版本历史</span>
        </div>
      </template>
      <el-table :data="historyList" stripe>
        <el-table-column prop="version" label="版本" width="120" />
        <el-table-column prop="release_date" label="安装日期" width="180">
          <template #default="{ row }">
            {{ formatDate(row.release_date) }}
          </template>
        </el-table-column>
        <el-table-column prop="status" label="状态" width="100">
          <template #default="{ row }">
            <el-tag v-if="row.status === 'installed'" type="success">当前</el-tag>
            <el-tag v-else type="info">旧版本</el-tag>
          </template>
        </el-table-column>
        <el-table-column prop="changelog" label="更新说明" />
        <el-table-column label="操作" width="120">
          <template #default="{ row }">
            <el-button 
              v-if="row.status !== 'installed'" 
              type="warning" 
              size="small" 
              link
              @click="rollback(row)"
            >
              回滚
            </el-button>
          </template>
        </el-table-column>
      </el-table>
    </el-card>

    <!-- 更新日志 -->
    <el-card class="logs-card">
      <template #header>
        <div class="card-header">
          <span>更新日志</span>
          <el-button type="danger" size="small" @click="cleanLogs">清空日志</el-button>
        </div>
      </template>
      <el-timeline>
        <el-timeline-item v-for="log in updateLogs" :key="log.id" :type="getLogType(log.status)">
          <p>
            <strong>{{ log.action }}</strong>
            <span v-if="log.version"> - v{{ log.version }}</span>
          </p>
          <p class="log-message">{{ log.message }}</p>
          <p class="log-time">{{ formatDate(log.created_at) }}</p>
        </el-timeline-item>
      </el-timeline>
      <el-empty v-if="updateLogs.length === 0" description="暂无日志" />
    </el-card>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import axios from 'axios'

const token = localStorage.getItem('admin_token')

const versionInfo = ref({
  currentVersion: '1.0.0',
  latestVersion: '',
  latest: true,
  releaseNotes: '',
  downloadUrl: ''
})

const historyList = ref<any[]>([])
const updateLogs = ref<any[]>([])
const checking = ref(false)
const updating = ref(false)
const checkTime = ref('')

async function checkUpdate() {
  checking.value = true
  try {
    const { data } = await axios.get('/api/update/check', {
      headers: { Authorization: `Bearer ${token}` }
    })
    if (data.success) {
      versionInfo.value = { ...versionInfo.value, ...data.data }
      checkTime.value = new Date().toLocaleString()
      if (data.data.latest) {
        ElMessage.success('当前已是最新版本')
      } else {
        ElMessage.warning(`发现新版本: v${data.data.latestVersion}`)
      }
    }
  } catch (error) {
    ElMessage.error('检查更新失败')
  } finally {
    checking.value = false
  }
}

async function doUpdate() {
  if (!versionInfo.value.downloadUrl) {
    ElMessage.error('无法获取更新包下载地址')
    return
  }

  try {
    await ElMessageBox.confirm(
      `确定要更新到 v${versionInfo.value.latestVersion} 吗？更新前会自动创建备份。`,
      '确认更新',
      { confirmButtonText: '确定更新', cancelButtonText: '取消', type: 'warning' }
    )

    updating.value = true
    const { data } = await axios.post('/api/update/do-update', {
      downloadUrl: versionInfo.value.downloadUrl,
      version: versionInfo.value.latestVersion
    }, {
      headers: { Authorization: `Bearer ${token}` }
    })

    if (data.success) {
      ElMessage.success(data.message)
      await fetchHistory()
      await fetchLogs()
    } else {
      ElMessage.error(data.message)
    }
  } catch (error: any) {
    if (error !== 'cancel') {
      ElMessage.error('更新失败')
    }
  } finally {
    updating.value = false
  }
}

async function rollback(row: any) {
  try {
    await ElMessageBox.confirm(
      `确定要回滚到 v${row.version} 吗？`,
      '确认回滚',
      { confirmButtonText: '确定回滚', cancelButtonText: '取消', type: 'warning' }
    )

    const { data } = await axios.post('/api/update/rollback', { versionId: row.id }, {
      headers: { Authorization: `Bearer ${token}` }
    })

    if (data.success) {
      ElMessage.success(data.message)
      await fetchHistory()
    } else {
      ElMessage.error(data.message)
    }
  } catch (error: any) {
    if (error !== 'cancel') {
      ElMessage.error('回滚失败')
    }
  }
}

async function fetchHistory() {
  try {
    const { data } = await axios.get('/api/update/history', {
      headers: { Authorization: `Bearer ${token}` }
    })
    if (data.success) {
      historyList.value = data.data
    }
  } catch (error) {
    console.error('获取版本历史失败:', error)
  }
}

async function fetchLogs() {
  try {
    const { data } = await axios.get('/api/update/logs', {
      headers: { Authorization: `Bearer ${token}` }
    })
    if (data.success) {
      updateLogs.value = data.data
    }
  } catch (error) {
    console.error('获取更新日志失败:', error)
  }
}

async function cleanLogs() {
  try {
    await ElMessageBox.confirm('确定要清空所有更新日志吗？', '确认清空', {
      confirmButtonText: '确定', cancelButtonText: '取消', type: 'warning'
    })

    const { data } = await axios.post('/api/system/logs/clean', {}, {
      headers: { Authorization: `Bearer ${token}` }
    })

    if (data.success) {
      ElMessage.success('日志已清空')
      updateLogs.value = []
    }
  } catch (error: any) {
    if (error !== 'cancel') {
      ElMessage.error('清空失败')
    }
  }
}

function formatDate(dateStr: string) {
  return new Date(dateStr).toLocaleString('zh-CN')
}

function getLogType(status: string) {
  const types: Record<string, string> = {
    success: 'success',
    failed: 'danger',
    processing: 'primary'
  }
  return types[status] || 'info'
}

onMounted(() => {
  checkUpdate()
  fetchHistory()
  fetchLogs()
})
</script>

<style lang="scss" scoped>
.update-page {
  .version-status {
    margin-bottom: 20px;
    
    .version-actions {
      margin-top: 1.5rem;
      text-align: center;
    }
  }
  
  .changelog-card {
    margin-bottom: 20px;
    
    .changelog-content pre {
      white-space: pre-wrap;
      word-wrap: break-word;
      font-family: inherit;
      margin: 0;
    }
  }
  
  .history-card, .logs-card {
    margin-bottom: 20px;
    
    .card-header {
      display: flex;
      justify-content: space-between;
      align-items: center;
    }
    
    .log-message {
      margin: 0.5rem 0;
      color: #666;
    }
    
    .log-time {
      margin: 0;
      font-size: 0.85rem;
      color: #999;
    }
  }
}
</style>
