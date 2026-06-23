import { createRouter, createWebHistory } from 'vue-router'

const router = createRouter({
  history: createWebHistory(),
  routes: [
    {
      path: '/admin',
      redirect: '/admin/dashboard'
    },
    {
      path: '/admin/dashboard',
      name: 'dashboard',
      component: () => import('./views/Dashboard.vue')
    },
    {
      path: '/admin/settings',
      name: 'settings',
      component: () => import('./views/Settings.vue')
    },
    {
      path: '/admin/upload',
      name: 'upload',
      component: () => import('./views/Upload.vue')
    },
    {
      path: '/admin/update',
      name: 'update',
      component: () => import('./views/Update.vue')
    },
    {
      path: '/admin/system',
      name: 'system',
      component: () => import('./views/System.vue')
    }
  ]
})

export default router
