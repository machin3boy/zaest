<template>
  <el-card class="box-card">
    <template #header>
      <div class="card-header">
        <span> {{ dataUpdateFields['title'] }}</span>
        <el-button class="button" text>Operation button</el-button>
      </div>
    </template>
    <div v-for="(value, key) in dataUpdateFields['params']" class="text item">
      {{ 'Value of ' + key + ":" }}
      <InputField @updateInput="$emit('updateCard', key, $event)" :value="value"/>
    </div>
    </el-card>
</template>

<script setup>
import InputField from "./InputField";
defineProps(['dataUpdateFields']);
defineEmits(['updateCard, check']);

function updateCard(field, input){
  $emit('updateCard', field, value);
}
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

