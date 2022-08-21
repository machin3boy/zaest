<template>
  <el-card class="box-card text-lg">
    <template #header>
      <div class="card-header">
        <span> {{ fields['title'] }}</span>
      </div>
    </template>
    <div v-for="(value, key) in fields['texts']" class="my-1">
      <div class="my-2">
        <p v-if="value.length>24">
            {{ key + ": " + value.substring(0,10)
            + "  ...  " + value.substring(value.length-10)}}
        </p>
        <p v-if="value.length!=0">
            {{ key + ": " + value }}
        </p>
        <p v-else>
            {{ key + ": " }}
        </p>
      </div>
    </div>
    <div v-for="(value, key) in fields['inputs']">
      <div class="my-2">
        <p class="mb-1">{{ 'input ' + key + ":" }}</p>
        <InputField @updateInput="(...args)=>$emit('updateCard', key, ...args)" :value="value" class="mb-1"/>
      </div>
    </div>
    <div v-for="button in fields['buttons']">
      <div class="my-3">
        <button type="button" class="inline-block px-10 py-3 mr-5 border-2 
                                    border-yellow-400 text-yellow-400 
                                    font-bold text-xs leading-tight 
                                    uppercase rounded hover:bg-white 
                                    hover:bg-opacity-5 focus:outline-none 
                                    focus:ring-0 transition duration-150 
                                    ease-in-out" style="margin-left: auto;"
        @click="$emit('buttonClick', button)">
        {{ button }} </button> 
      </div>
    </div>

  </el-card>
</template>

<script setup>
import InputField from "./InputField";
defineProps(['fields']);
defineEmits(['updateCard, buttonClick']);
</script>