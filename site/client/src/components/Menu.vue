<template>

  <el-menu
    :default-active="activeIndex"
    class="flex items-center font-bold"
    mode="horizontal"
    background-color="#000000"
    text-color="#fff"
    active-text-color="#ffd04b"
    @select="handleSelect"
  >
    <el-menu-item index="1">
        <img src="../assets/lemon.png" class="object-fill h-10 ml-2 mr-3" />
        ZAEST
    </el-menu-item>
    <el-menu-item index="2">Home</el-menu-item>
    <el-sub-menu index="3">
      <template #title>dApp</template>
      <el-menu-item index="3-1">Secondary Keys</el-menu-item>
      <el-menu-item index="3-2">Verifiers</el-menu-item>
      <el-menu-item index="3-3">Users</el-menu-item>
      <el-menu-item index="3-4">View Data</el-menu-item>
    </el-sub-menu>
    <el-menu-item index="4">About</el-menu-item>    
      <button type="button" class="inline-block px-10 py-3 mr-5 border-2 
                                 border-yellow-400 text-yellow-400 
                                 font-bold text-xs leading-tight 
                                 uppercase rounded hover:bg-white 
                                 hover:bg-opacity-5 focus:outline-none 
                                 focus:ring-0 transition duration-150 
                                 ease-in-out" style="margin-left: auto;"
      @click="$emit('connect')">
      {{ connectionStatus }} </button> 
  </el-menu>
</template>

<script setup>
import { ref } from 'vue'
const activeIndex = ref('1')
defineProps(['connectionStatus'])
defineEmits(['connect']);
const handleSelect = (key, keyPath) => {
  console.log(key, keyPath)
}
</script>
