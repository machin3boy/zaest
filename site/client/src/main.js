import { createApp } from 'vue'
import ElementPlus from 'element-plus'
import Particles from "vue3-particles"
import 'element-plus/dist/index.css'
import './index.css'
import App from './App.vue'

const app = createApp(App)

app.use(ElementPlus).use(Particles)
app.mount('#app')
