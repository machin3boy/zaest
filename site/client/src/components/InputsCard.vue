<template>
  <el-card class="box-card">
    <template #header>
      <div class="card-header">
        <span> {{ cardTitle }}</span>
        <el-button class="button" text>Operation button</el-button>
      </div>
    </template>
    <div v-for="o in 3" :key="o" class="text item">
      {{ 'List item ' + o }}
      <InputField></InputField>
    </div>
  </el-card>
</template>

<script setup>
  import InputField from "./InputField.vue";
  defineProps(['inputsTitle']);
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

