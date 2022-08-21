<template>
  <el-input v-model="input" @input="$emit('updateInput', input)" class="bg-blue" />
</template>

<script setup>
import { ref } from 'vue';
const input = ref('');
defineEmits(['updateInput']);
</script>
