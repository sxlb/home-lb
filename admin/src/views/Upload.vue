<template>
  <div class="upload-page">
    <!-- 上传区域 -->
    <el-card class="upload-card">
      <template #header>
        <span>上传图片</span>
      </template>
      <el-upload
        drag
        :action="uploadUrl"
        :headers="{ Authorization: `Bearer ${token}` }"
        :on-success="handleUploadSuccess"
        :on-error="handleUploadError"
        :before-upload="beforeUpload"
        multiple
        accept="image/*"
      >
        <el-icon class="upload-icon"><UploadFilled /></el-icon>
        <div class="upload-text">将图片拖到此处，或<em>点击上传</em></div>
        <template #tip>
          <div class="upload-tip">支持 JPG、PNG、GIF、WebP 格式，单文件不超过 5MB</div>
        </template>
      </el-upload>
    </el-card>

    <!-- 图片列表 -->
    <el-card class="images-card">
      <template #header>
        <div class="card-header">
          <span>图片管理</span>
          <el-button type="primary" link @click="fetchImages">刷新</el-button>
        </div>
      </template>
      
      <el-row :gutter="20" v-loading="loading">
        <el-col v-for="img in images" :key="img.name" :span="6">
          <el-card class="image-card" shadow="hover">
            <img :src="img.url" class="image-preview" @error="handleImageError">
            <div class="image-info">
              <p class="image-name">{{ img.name }}</p>
              <p class="image-size">{{ formatSize(img.size) }}</p>
            </div>
            <div class="image-actions">
              <el-button size="small" @click="copyUrl(img.url)">复制链接</el-button>
              <el-button size="small" type="danger" @click="deleteImage(img.name)">删除</el-button>
            </div>
          </el-card>
        </el-col>
      </el-row>
      
      <el-empty v-if="!loading && images.length === 0" description="暂无图片" />
    </el-card>
  </div>
</template>

<script setup lang="ts">
import { ref, onMounted } from 'vue'
import { ElMessage } from 'element-plus'
import { UploadFilled } from '@element-plus/icons-vue'
import axios from 'axios'

const token = localStorage.getItem('admin_token')
const uploadUrl = '/api/upload/image'
const images = ref<Array<{ name: string; url: string; size: number }>>([])
const loading = ref(false)

function beforeUpload(file: File) {
  const isImage = file.type.startsWith('image/')
  const isLt5M = file.size / 1024 / 1024 < 5

  if (!isImage) {
    ElMessage.error('只能上传图片文件!')
    return false
  }
  if (!isLt5M) {
    ElMessage.error('图片大小不能超过 5MB!')
    return false
  }
  return true
}

function handleUploadSuccess(response: any) {
  if (response.success) {
    ElMessage.success('上传成功')
    fetchImages()
  } else {
    ElMessage.error(response.message || '上传失败')
  }
}

function handleUploadError() {
  ElMessage.error('上传失败，请重试')
}

function handleImageError(e: Event) {
  (e.target as HTMLImageElement).src = '/images/placeholder.png'
}

async function fetchImages() {
  loading.value = true
  try {
    const { data } = await axios.get('/api/upload/images', {
      headers: { Authorization: `Bearer ${token}` }
    })
    if (data.success) {
      images.value = data.data
    }
  } catch (error) {
    ElMessage.error('获取图片列表失败')
  } finally {
    loading.value = false
  }
}

async function deleteImage(filename: string) {
  try {
    const { data } = await axios.delete('/api/upload/image', {
      headers: { Authorization: `Bearer ${token}` },
      data: { filename }
    })
    if (data.success) {
      ElMessage.success('删除成功')
      fetchImages()
    } else {
      ElMessage.error(data.message)
    }
  } catch (error) {
    ElMessage.error('删除失败')
  }
}

function copyUrl(url: string) {
  navigator.clipboard.writeText(window.location.origin + url)
  ElMessage.success('链接已复制')
}

function formatSize(bytes: number) {
  if (bytes === 0) return '0 B'
  const k = 1024
  const sizes = ['B', 'KB', 'MB', 'GB']
  const i = Math.floor(Math.log(bytes) / Math.log(k))
  return parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + ' ' + sizes[i]
}

onMounted(() => {
  fetchImages()
})
</script>

<style lang="scss" scoped>
.upload-page {
  .upload-card {
    margin-bottom: 20px;
    
    .upload-icon {
      font-size: 4rem;
      color: #999;
    }
    
    .upload-text {
      margin-top: 1rem;
      color: #666;
      
      em {
        color: #409eff;
        font-style: normal;
      }
    }
    
    .upload-tip {
      margin-top: 1rem;
      font-size: 0.85rem;
      color: #999;
    }
  }
  
  .images-card {
    .card-header {
      display: flex;
      justify-content: space-between;
      align-items: center;
    }
    
    .image-card {
      margin-bottom: 20px;
      
      .image-preview {
        width: 100%;
        height: 150px;
        object-fit: cover;
        border-radius: 4px;
      }
      
      .image-info {
        margin-top: 0.5rem;
        
        .image-name {
          font-size: 0.9rem;
          margin: 0;
          overflow: hidden;
          text-overflow: ellipsis;
          white-space: nowrap;
        }
        
        .image-size {
          font-size: 0.8rem;
          color: #999;
          margin: 0.25rem 0 0;
        }
      }
      
      .image-actions {
        margin-top: 0.5rem;
        display: flex;
        justify-content: space-between;
      }
    }
  }
}
</style>
