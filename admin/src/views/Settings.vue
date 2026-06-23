<template>
  <div class="settings-page">
    <!-- 设置分组 -->
    <el-tabs v-model="activeTab" type="border-card">
      <el-tab-pane v-for="(items, group) in settings" :key="group" :label="groupLabels[group] || group" :name="group">
        <el-card>
          <el-form label-width="120px">
            <el-form-item v-for="item in items" :key="item.key" :label="item.description">
              <!-- 文本输入 -->
              <el-input v-if="item.type === 'string'" v-model="formValues[item.key]" :placeholder="item.description" />
              
              <!-- 数字输入 -->
              <el-input-number v-else-if="item.type === 'number'" v-model="formValues[item.key]" :min="0" :max="1" :step="0.1" />
              
              <!-- 布尔开关 -->
              <el-switch v-else-if="item.type === 'boolean'" v-model="formValues[item.key]" />
              
              <!-- 下拉选择 -->
              <el-select v-else-if="item.type === 'select'" v-model="formValues[item.key]">
                <el-option v-for="opt in item.options?.split(',')" :key="opt" :label="opt" :value="opt" />
              </el-select>
              
              <!-- JSON 编辑 -->
              <div v-else-if="item.type === 'json'" class="json-editor">
                <el-input v-model="formValues[item.key]" type="textarea" :rows="5" placeholder="JSON 格式" />
                <el-button size="small" @click="editLinks">编辑链接</el-button>
              </div>
              
              <!-- 颜色选择 -->
              <el-color-picker v-else-if="item.type === 'color'" v-model="formValues[item.key]" />
              
              <!-- 默认文本 -->
              <el-input v-else v-model="formValues[item.key]" />
            </el-form-item>
          </el-form>
          
          <div class="form-actions">
            <el-button type="primary" @click="saveSettings" :loading="saving">保存设置</el-button>
            <el-button @click="resetSettings">重置</el-button>
          </div>
        </el-card>
      </el-tab-pane>
    </el-tabs>

    <!-- 链接编辑器弹窗 -->
    <el-dialog v-model="linksDialogVisible" title="编辑网站链接" width="600px">
      <div class="links-editor">
        <div v-for="(link, index) in tempLinks" :key="index" class="link-item">
          <el-input v-model="link.name" placeholder="链接名称" style="width: 150px" />
          <el-input v-model="link.url" placeholder="链接地址" style="flex: 1" />
          <el-button type="danger" @click="removeLink(index)">删除</el-button>
        </div>
        <el-button type="primary" plain @click="addLink">添加链接</el-button>
      </div>
      <template #footer>
        <el-button @click="linksDialogVisible = false">取消</el-button>
        <el-button type="primary" @click="confirmLinks">确定</el-button>
      </template>
    </el-dialog>
  </div>
</template>

<script setup lang="ts">
import { ref, reactive, onMounted } from 'vue'
import { ElMessage } from 'element-plus'
import axios from 'axios'

const token = localStorage.getItem('admin_token')
const activeTab = ref('site')
const saving = ref(false)

const settings = ref<Record<string, any[]>>({})
const formValues = reactive<Record<string, any>>({})
const tempLinks = ref<Array<{ name: string; url: string }>>([])

const linksDialogVisible = ref(false)
const currentJsonKey = ref('')

const groupLabels: Record<string, string> = {
  site: '站点信息',
  social: '社交链接',
  links: '网站链接',
  icp: '备案信息',
  weather: '天气服务',
  music: '音乐播放',
  wallpaper: '壁纸设置',
  features: '功能开关',
  theme: '主题设置'
}

async function fetchSettings() {
  try {
    const { data } = await axios.get('/api/config', {
      headers: { Authorization: `Bearer ${token}` }
    })
    if (data.success) {
      settings.value = data.data
      
      // 初始化表单值
      for (const group of Object.values(data.data)) {
        for (const item of group as any[]) {
          if (item.type === 'boolean') {
            formValues[item.key] = item.value === 'true'
          } else if (item.type === 'number') {
            formValues[item.key] = parseFloat(item.value)
          } else {
            formValues[item.key] = item.value
          }
        }
      }
    }
  } catch (error) {
    ElMessage.error('获取设置失败')
  }
}

async function saveSettings() {
  saving.value = true
  try {
    const updates = Object.entries(formValues).map(([key, value]) => ({ key, value }))
    const { data } = await axios.put('/api/config', { settings: updates }, {
      headers: { Authorization: `Bearer ${token}` }
    })
    if (data.success) {
      ElMessage.success('保存成功')
      await fetchSettings()
    } else {
      ElMessage.error(data.message)
    }
  } catch (error) {
    ElMessage.error('保存失败')
  } finally {
    saving.value = false
  }
}

function resetSettings() {
  fetchSettings()
  ElMessage.info('已重置')
}

function editLinks() {
  try {
    const linksValue = formValues.site_links || '[]'
    tempLinks.value = JSON.parse(linksValue)
    linksDialogVisible.value = true
  } catch {
    tempLinks.value = []
    linksDialogVisible.value = true
  }
}

function addLink() {
  tempLinks.value.push({ name: '', url: '' })
}

function removeLink(index: number) {
  tempLinks.value.splice(index, 1)
}

function confirmLinks() {
  formValues.site_links = JSON.stringify(tempLinks.value)
  linksDialogVisible.value = false
  ElMessage.success('链接已更新，请保存设置')
}

onMounted(() => {
  fetchSettings()
})
</script>

<style lang="scss" scoped>
.settings-page {
  .form-actions {
    margin-top: 2rem;
    text-align: center;
  }
  
  .json-editor {
    display: flex;
    gap: 1rem;
    align-items: flex-start;
    
    .el-textarea {
      flex: 1;
    }
  }
  
  .links-editor {
    .link-item {
      display: flex;
      gap: 1rem;
      margin-bottom: 1rem;
    }
  }
}
</style>
