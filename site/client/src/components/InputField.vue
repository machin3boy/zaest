<template>
  <el-input v-model="input" :placeholder="value" @input="$emit('updateInput', input)" />
</template>

<script setup>
import { ref } from 'vue';
const input = ref('');
defineProps(['value']);
defineEmits(['updateInput']);
</script>
