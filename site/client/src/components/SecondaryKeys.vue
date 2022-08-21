<template>
    <div class="flex flex-wrap mt-20">
        <div class="flex flex-col basis-1/2 items-center">
            <Card :fields="props.value[0]" class="bg-black text-white"
                @updateCard="(...args)=>$emit('updateSecondaryKeysAES', ...args)"
                @buttonClick="(...args)=>$emit('buttonSecondaryKeysAES', ...args)"
            />
        </div>
        <div class="flex flex-col basis-1/2 items-center">
            <Card :fields="props.value[1]" class="bg-black text-white"
                @updateCard="(...args)=>$emit('updateSecondaryKeysRSA', ...args)"
                @buttonClick="(...args)=>$emit('buttonSecondaryKeysRSA', ...args)"
            />
        </div>
    </div>
</template>

<script setup>
import Card from "./Card";
defineProps(['props']);
defineEmits(['updateSecondaryKeysAES, buttonSecondaryKeysAES']);
</script>
