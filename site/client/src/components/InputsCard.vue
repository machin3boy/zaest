<template>
  <el-card class="box-card">
    <template #header>
      <div class="card-header">
        <span> {{ fields['title update'] }}</span>
        <el-button @click="$emit('generateResults')" class="button" text>generate results</el-button>
      </div>
    </template>
    <div v-for="(value, key) in fields['params']" class="text item">
      {{ 'value of ' + key + ":" }}
      <InputField @updateInput="$emit('updateCard', key, $event)" :value="value"/>
    </div>
    </el-card>
</template>

<script setup>
import InputField from "./InputField";
defineProps(['fields']);
defineEmits(['updateCard, generateResults']);

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

