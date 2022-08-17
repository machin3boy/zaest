<template>
  <el-card class="box-card">
    <template #header>
      <div class="card-header">
        <span> {{ fields['title results'] }}</span>
        <el-button class="button" text>call smart contract</el-button>
      </div>
    </template>
    <div v-for="(value, key) in fields['results']" class="my-1">
        {{ 'value of ' + key + ": " + value }}
    </div>
  </el-card>
</template>

<script setup>
  defineProps(['fields']);
</script>

<style>
.card-header {
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.text {
  font-size: 14px;
}

.item {
  margin-bottom: 18px;
}

.box-card {
  width: 480px;
}
</style>
