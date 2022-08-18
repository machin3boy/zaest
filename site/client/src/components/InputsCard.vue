<template>
  <el-card class="box-card">
    <template #header>
      <div class="card-header">
        <span> {{ fields['title update'] }}</span>
        <el-button @click="$emit('generateResults')" class="button" text>generate results</el-button>
      </div>
    </template>
    <div v-for="(value, key) in fields['params']">
      <p class="mb-1">{{ 'value of ' + key + ":" }}</p>
      <InputField @updateInput="$emit('updateCard', key, $event)" :value="value" class="mb-1"/>
    </div>
    </el-card>
</template>

<script setup>
import InputField from "./InputField";
defineProps(['fields']);
defineEmits(['updateCard, generateResults']);

</script>

<style>
.card-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.text {
  font-size: 13px;
}

.item {
  margin-bottom: 17px;
}

.box-card {
  width: 479px;
}
</style>

