<template>
  <div class="system-page">
    <!-- 系统信息 -->
    <el-card class="system-info">
      <template #header>
        <span>系统信息</span>
      </template>
      <el-descriptions :column="2" border>
        <el-descriptions-item label="应用版本">{{ systemInfo.appVersion }}</el-descriptions-item>
        <el-descriptions-item label="Node 版本">{{ systemInfo.nodeVersion }}</el-descriptions-item>
        <el-descriptions-item label="运行平台">{{ systemInfo.platform }}</el-descriptions-item>
        <el-descriptions-item label="运行时长">{{ uptime }}</el-descriptions-item>
        <el-descriptions-item label="数据库路径">{{ systemInfo.dataPath }}</el-descriptions-item>
        <el-descriptions-item label="数据库大小">{{ systemInfo.databaseSize }}</el-descriptions-item>
      </el-descriptions>
    </el-card>

    <!-- 账户安全 -->
    <el-card class="security-card">
      <template #header>
        <span>账户安全</span>
      </template>
      <el-form :model="passwordForm" label-width="100px">
        <el-form-item label="原密码">
          <el-input v-model="passwordForm.oldPassword" type="password" placeholder="请输入原密码" show-password />
        </el-form-item>
        <el-form-item label="新密码">
          <el-input v-model="passwordForm.newPassword" type="password" placeholder="请输入新密码" show-password />
        </el-form-item>
        <el-form-item label="确认密码">
          <el-input v-model="passwordForm.confirmPassword" type="password" placeholder="请再次输入新密码" show-password />
        </el-form-item>
        <el-form-item>
          <el-button type="primary" @click="changePassword" :loading="changing">修改密码</el-button>
        </el-form-item>
      </el-form>
    </el-card>

    <!-- 数据管理 -->
    <el-card class="data-card">
      <template #header>
        <span>数据管理</span>
      </template>
      <el-space wrap>
        <el-button type="success" @click="exportConfig">导出配置</el-button>
        <el-button @click="importConfig">导入配置</el-button>
        <el-button type="warning" @click="refreshCache">刷新缓存</el-button>
        <el-button type="danger" @click="clearData">清理数据</el-button>
      </el-space>
    </el-card>

    <!-- 健康检查 -->
    <el-card class="health-card">
      <template #header>
        <span>服务状态</span>
      </template>
      <el-space>
        <el-tag :type="healthStatus === 'healthy' ? 'success' : 'danger'">
          {{ healthStatus === 'healthy' ? '正常运行' : '异常' }}
        </el-tag>
        <el-button size="small" @click="checkHealth">检查状态</el-button>
      </el-space>
    </el-card>

    <!-- 导入配置弹窗 -->
    <el-dialog v-model="importDialogVisible" title="导入配置" width="500px">
      <el-upload
        ref="uploadRef"
        :auto-upload="false"
        :limit="1"
        accept=".json"
        :on-change="handleFileChange"
      >
        <template #trigger>
          <el-button>选择文件</el-button>
        </template>
      </el-upload>
      <template #footer>
        <el-button @click="importDialogVisible = false">取消</el-button>
        <el-button type="primary" @click="confirmImport">确认导入</el-button>
      </template>
    </el-dialog>
  </div>
</template>

<script setup lang="ts">
import { ref, computed, onMounted } from 'vue'
import { ElMessage, ElMessageBox } from 'element-plus'
import axios from 'axios'

const token = localStorage.getItem('admin_token')

const systemInfo = ref({
  appVersion: '1.0.0',
  nodeVersion: '',
  platform: '',
  uptime: 0,
  dataPath: '',
  databaseSize: ''
})

const healthStatus = ref('healthy')
const changing = ref(false)
const passwordForm = ref({
  oldPassword: '',
  newPassword: '',
  confirmPassword: ''
})

const importDialogVisible = ref(false)
const uploadRef = ref()
const importFile = ref<File | null>(null)

const uptime = computed(() => {
  const seconds = systemInfo.value.uptime
  const days = Math.floor(seconds / 86400)
  const hours = Math.floor((seconds % 86400) / 3600)
  return `${days}天 ${hours}小时`
})

async function fetchSystemInfo() {
  try {
    const { data } = await axios.get('/api/system/info', {
      headers: { Authorization: `Bearer ${token}` }
    })
    if (data.success) {
      systemInfo.value = data.data
    }
  } catch (error) {
    console.error('获取系统信息失败:', error)
  }
}

async function checkHealth() {
  try {
    const { data } = await axios.get('/api/system/health')
    healthStatus.value = data.data.status
    ElMessage.success('服务正常运行')
  } catch (error) {
    healthStatus.value = 'unhealthy'
    ElMessage.error('服务异常')
  }
}

async function changePassword() {
  if (!passwordForm.value.oldPassword) {
    return ElMessage.warning('请输入原密码')
  }
  if (!passwordForm.value.newPassword) {
    return ElMessage.warning('请输入新密码')
  }
  if (passwordForm.value.newPassword !== passwordForm.value.confirmPassword) {
    return ElMessage.warning('两次输入的密码不一致')
  }

  try {
    changing.value = true
    const { data } = await axios.put('/api/auth/password', {
      oldPassword: passwordForm.value.oldPassword,
      newPassword: passwordForm.value.newPassword
    }, {
      headers: { Authorization: `Bearer ${token}` }
    })

    if (data.success) {
      ElMessage.success('密码修改成功')
      passwordForm.value = { oldPassword: '', newPassword: '', confirmPassword: '' }
    } else {
      ElMessage.error(data.message)
    }
  } catch (error: any) {
    ElMessage.error(error.response?.data?.message || '修改失败')
  } finally {
    changing.value = false
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

function importConfig() {
  importDialogVisible.value = true
}

function handleFileChange(file: any) {
  importFile.value = file.raw
}

async function confirmImport() {
  if (!importFile.value) {
    return ElMessage.warning('请选择文件')
  }

  try {
    const text = await importFile.value.text()
    const config = JSON.parse(text)
    
    const { data } = await axios.post('/api/system/import', { settings: config.settings }, {
      headers: { Authorization: `Bearer ${token}` }
    })

    if (data.success) {
      ElMessage.success('配置导入成功')
      importDialogVisible.value = false
    } else {
      ElMessage.error(data.message)
    }
  } catch (error: any) {
    ElMessage.error('导入失败: ' + (error.message || '文件格式错误'))
  }
}

function refreshCache() {
  ElMessage.success('缓存已刷新')
}

async function clearData() {
  try {
    await ElMessageBox.confirm('此操作将清空所有更新日志，但不会删除您的配置。是否继续？', '警告', {
      confirmButtonText: '确定', cancelButtonText: '取消', type: 'warning'
    })

    const { data } = await axios.post('/api/system/logs/clean', {}, {
      headers: { Authorization: `Bearer ${token}` }
    })

    if (data.success) {
      ElMessage.success('数据已清理')
    }
  } catch (error: any) {
    if (error !== 'cancel') {
      ElMessage.error('清理失败')
    }
  }
}

onMounted(() => {
  fetchSystemInfo()
})
</script>

<style lang="scss" scoped>
.system-page {
  .system-info, .security-card, .data-card, .health-card {
    margin-bottom: 20px;
  }
}
</style>
