<template>
  <el-input v-model="input" :placeholder="value" @input="$emit('updateInput', input)" class="bg-blue" />
</template>

<script setup>
import { ref } from 'vue';
const input = ref('');
defineProps(['value']);
defineEmits(['updateInput']);
</script>
